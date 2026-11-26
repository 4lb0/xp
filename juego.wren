import "_app/template" for Layout
import "_app/moves" for Moves
import "_app/cards" for Card
import "_app/game" for Game
import "_app/views" for Views

var session = Session.new()
var g = Game.find(session.get("gameId"))
var cookieToken = Cookie.get("xpGame")
if (g == null && cookieToken != null && cookieToken != "") {
  g = Game.findByToken(cookieToken)
  if (g != null) {
    session.set("gameId", g.id.toString)
    // La sesión es nueva: marcamos las zonas como vistas para no animar el
    // reparto completo al reenganchar la partida.
    Moves.take(g.id, session)
  }
}
if (g != null) {
  var token = Game.ensureToken(g.id)
  if (token != null && token != cookieToken) {
    Cookie.set("xpGame", token, {"Max-Age": "7776000"})
  }
} else if (cookieToken != null && cookieToken != "") {
  // La cookie apunta a una partida que ya no existe.
  Cookie.delete("xpGame")
}

// ---------- Acciones ----------

if (Request.isPost) {
  if (!session.csrfOk) {
    return Response.redirect("/juego?aviso=" + Util.urlEncode("La sesión venció. Recargá la página y volvé a intentar."))
  }
  var accion = Request.post("accion", "")

  if (accion == "nueva") {
    if (g != null) Game.destroy(g.id)
    var modo = Request.post("modo", "casual")
    if (modo != "experto" && modo != "casual" && modo != "facil") modo = "casual"
    session.set("modo", modo)
    var id = Game.create(1, modo)
    session.set("gameId", id.toString)
    Cookie.set("xpGame", Game.ensureToken(id), {"Max-Age": "7776000"})
    return Response.redirect("/juego")
  }

  if (g == null) return Response.redirect("/juego")

  if (accion == "reiniciar") {
    Game.destroy(g.id)
    session.set("gameId", "")
    Cookie.delete("xpGame")
    return Response.redirect("/juego")
  }

  var aviso = ""
  var anim = ""
  var anchor = ""

  if (g.status != "activa") {
    return Response.redirect("/juego?aviso=" + Util.urlEncode("La expedición terminó. Empezá una nueva."))
  }

  var rowId = Request.post("rowId", "")
  var optLabel = Request.post("opt", "")

  if (accion == "elegir_emboscada") {
    if (g.fase != "emboscada") {
      aviso = "Ya eligieron la emboscada inicial."
    } else {
      var row = `SELECT * FROM game_cards WHERE id = ? AND gameId = ? AND zone = 'mesa'`.first(rowId, g.id)
      var c = row == null ? null : Card.get(row["cardId"])
      if (c == null || c.entry == "") {
        aviso = "Esa carta no es una emboscada."
      } else {
        var res = Game.apply(g.id, g, Game.parseEffects(c.entry), true, [])
        Game.log(g.id, "Emboscada inicial: " + c.name + " — " + c.entryLabel + ".")
        `UPDATE games SET fase = 'listo' WHERE id = ?`.query(g.id)
        if (res["status"] != "activa") return Response.redirect("/juego")
      }
    }
  } else if (accion == "jugar") {
    var row = `SELECT * FROM game_cards WHERE id = ? AND gameId = ? AND zone = 'mano'`.first(rowId, g.id)
    if (row == null) {
      aviso = "Esa carta ya no está en tu mano."
    } else if (g.fase != "listo") {
      aviso = "Esa carta se juega antes de elegir la Misión."
    } else if (g.jugadas > 0) {
      aviso = "Ya jugaron una carta este turno."
    } else {
      var c = Card.get(row["cardId"])
      if (c == null) {
        aviso = "No pudimos leer esa carta."
      } else if (c.isSupport) {
        // Las cartas de apoyo suman Energía y Escudo a la vez.
        Game.apply(g.id, g, {"pistas": 0, "energia": c.value, "escudo": c.value}, true, [])
        Game.move(rowId, "descarteEquipo")
        `UPDATE games SET jugadas = 1 WHERE id = ?`.query(g.id)
        Game.log(g.id, "Maniobra de apoyo " + c.name + ": +" + c.value.toString + " Energía y +" + c.value.toString + " Escudo.")
      } else if (c.isTool) {
        // Solo una Herramienta activa por equipo: la nueva pisa la anterior.
        var anteriores = Game.rows(g.id, "herramientas")
        for (t in anteriores) Game.move(t["id"], "descarteEquipo")
        if (!anteriores.isEmpty) Game.log(g.id, "La nueva Herramienta reemplaza a la anterior: solo hay una activa.")
        Game.move(rowId, "herramientas")
        `UPDATE games SET jugadas = 1 WHERE id = ?`.query(g.id)
        Game.log(g.id, "Herramienta en juego: " + c.name + ".")
      } else if (c.effect == "heal_shield") {
        Game.apply(g.id, g, {"pistas": 0, "energia": 0, "escudo": 1}, true, [])
        Game.move(rowId, "descarteEquipo")
        `UPDATE games SET jugadas = 1 WHERE id = ?`.query(g.id)
        Game.log(g.id, "Soldadura Submarina: +1 Escudo.")
      } else if (c.effect == "heal_energy") {
        Game.apply(g.id, g, {"pistas": 0, "energia": 2, "escudo": 0}, true, [])
        Game.move(rowId, "descarteEquipo")
        `UPDATE games SET jugadas = 1 WHERE id = ?`.query(g.id)
        Game.log(g.id, "Batería de Respaldo: +2 Energía.")
      } else if (c.effect == "clue_for_energy") {
        if (g.energia < 1) {
          aviso = "Análisis Rápido necesita 1 de Energía."
        } else {
          Game.apply(g.id, g, {"pistas": 1, "energia": -1, "escudo": 0}, true, [])
          Game.move(rowId, "descarteEquipo")
          `UPDATE games SET jugadas = 1 WHERE id = ?`.query(g.id)
          Game.log(g.id, "Análisis Rápido: −1 Energía, +1 Pista.")
        }
      } else if (c.effect == "harpoon") {
        if (g.energia < 2) {
          aviso = "El Arpón Rastreador necesita 2 de Energía."
        } else {
          Game.apply(g.id, g, {"pistas": 0, "energia": -2, "escudo": 0}, true, [])
          `UPDATE games SET fase = 'maniobra', maniobraRow = ?, jugadas = 1, dado1 = 0, dado2 = 0 WHERE id = ?`.query(rowId, g.id)
          Game.log(g.id, "Arpón Rastreador: gastan 2 Energía y preparan la tirada.")
        }
      } else if (c.effect == "discard_active") {
        var activas = Game.rows(g.id, "mesa")
        if (!activas.isEmpty) {
          Game.move(activas[0]["id"], "descarteJuego")
          var nueva = Game.draw(g.id, "misterio", "mesa", 1)
          if (nueva != null) {
            var nc = Card.get(nueva)
            if (nc != null && nc.entry != "") {
              var gs = Game.find(g.id)
              Game.apply(g.id, gs, Game.parseEffects(nc.entry), true, Game.ids(g.id, "herramientas"))
              Game.log(g.id, "Emboscada al entrar: " + nc.name + " — " + nc.entryLabel + ".")
            }
          }
        }
        Game.move(rowId, "descarteEquipo")
        `UPDATE games SET jugadas = 1 WHERE id = ?`.query(g.id)
        Game.log(g.id, "Señuelo Luminoso: una carta activa se cambia por otra.")
      } else {
        aviso = "Esa Maniobra se juega durante una prueba de dados."
      }
    }
  } else if (accion == "descartar") {
    var row = `SELECT id FROM game_cards WHERE id = ? AND gameId = ? AND zone = 'mano'`.first(rowId, g.id)
    if (row != null) {
      Game.move(row["id"], "descarteEquipo")
      Game.log(g.id, "Una carta de Equipo va al descarte.")
    }
  } else if (accion == "elegir") {
    if (g.fase != "listo") {
      aviso = "Ya hay una prueba en curso."
    } else if (g.resueltas > 0) {
      aviso = "Ya resolvieron una Misión este turno."
    } else {
      var row = `SELECT * FROM game_cards WHERE id = ? AND gameId = ? AND zone = 'mesa'`.first(rowId, g.id)
      if (row == null) {
        aviso = "Esa carta ya no está en la mesa."
      } else {
        var c = Card.get(row["cardId"])
        var opt = c.option(optLabel)
        var parity = opt != null && (opt["tipoPrueba"] == "par" || opt["tipoPrueba"] == "impar")
        // La mano se mantiene entre turnos: elegir la Misión no descarta nada.
        // Giro Brusco y Focos Abisales solo sirven en Par o Impar. Si la
        // opción elegida es de dados, la Maniobra preparada se pierde.
        var pierdeGiro = g.giro && !parity
        var pierdeFocos = g.focosM && !parity
        var giroVal = pierdeGiro ? 0 : (g.giro ? 1 : 0)
        var focosVal = pierdeFocos ? 0 : (g.focosM ? 1 : 0)
        `UPDATE games SET fase = 'prueba', pruebaCarta = ?, pruebaOpcion = ?, dado1 = 0, dado2 = 0, tirado = 0, giro = ?, focosM = ? WHERE id = ?`.query([row["cardId"], optLabel, giroVal, focosVal, g.id])
        Game.log(g.id, "Eligen " + c.name + ".")
        if (pierdeGiro) Game.log(g.id, "Giro Brusco no sirve fuera de Par o Impar: se pierde.")
        if (pierdeFocos) Game.log(g.id, "Focos Abisales no sirven fuera de Par o Impar: se pierden.")
      }
    }
  } else if (accion == "tirar") {
    var c = Card.get(g.pruebaCarta)
    var opt = c == null ? null : c.option(g.pruebaOpcion)
    if (opt == null || g.fase != "prueba") {
      aviso = "No hay una prueba preparada."
    } else {
      var dados = opt["dados"]
      var dice = Game.roll(dados)
      var d1 = dice[0]
      var d2 = dados == 2 ? dice[1] : 0
      var parity = opt["tipoPrueba"] == "par" || opt["tipoPrueba"] == "impar"
      if (parity && g.giro) d1 = 7 - d1
      `UPDATE games SET dado1 = ?, dado2 = ?, tirado = 1, giro = 0 WHERE id = ?`.query(d1, d2, g.id)
      anim = "dados"
      Game.log(g.id, "Tiran en la app: " + d1.toString + (dados == 2 ? " y " + d2.toString : "") + ".")
      var auto = Game.resolve(g.id)
      if (auto["error"] != "") aviso = auto["error"]
      anchor = "#resultado"
    }
  } else if (accion == "mesa") {
    var d1 = Num.fromString(Request.post("d1", "0"))
    var d2 = Num.fromString(Request.post("d2", "0"))
    var c = Card.get(g.pruebaCarta)
    var opt = c == null ? null : c.option(g.pruebaOpcion)
    var dados = opt == null ? 0 : opt["dados"]
    if (opt == null || g.fase != "prueba") {
      aviso = "No hay una prueba preparada."
    } else if (d1 < 1 || d1 > 6 || (dados == 2 && (d2 < 1 || d2 > 6))) {
      aviso = "Elegí valores de 1 a 6 para cada dado."
    } else {
      var parity = opt["tipoPrueba"] == "par" || opt["tipoPrueba"] == "impar"
      if (parity && g.giro) d1 = 7 - d1
      `UPDATE games SET dado1 = ?, dado2 = ?, tirado = 1, giro = 0 WHERE id = ?`.query(d1, dados == 2 ? d2 : 0, g.id)
      anim = "dados"
      Game.log(g.id, "Dados de la mesa: " + d1.toString + (dados == 2 ? " y " + d2.toString : "") + ".")
      var auto = Game.resolve(g.id)
      if (auto["error"] != "") aviso = auto["error"]
      anchor = "#resultado"
    }
  } else if (accion == "tirar_maniobra") {
    // Maniobras que piden un dado (hoy, el Arpón Rastreador). Usan la misma
    // mesa de dados que las pruebas: app o lo que salió en la mesa.
    if (g.fase != "maniobra" || g.maniobraRow == null) {
      aviso = "No hay una tirada de Maniobra pendiente."
    } else {
      var origen = Request.post("origen", "app")
      var d = 0
      var valido = true
      if (origen == "mesa") {
        d = Num.fromString(Request.post("d1", "0"))
        if (d < 1 || d > 6) valido = false
      } else {
        d = Game.roll(1)[0]
      }
      if (!valido) {
        aviso = "Elegí un valor de 1 a 6."
      } else {
        var fila = g.maniobraRow
        var par = d % 2 == 0
        `UPDATE games SET dado1 = ?, fase = 'listo', maniobraRow = NULL WHERE id = ?`.query(d, g.id)
        Game.move(fila, "descarteEquipo")
        if (par) {
          // El Arpón no es una prueba: la tirada no recibe Maniobras ni activa
          // el Brazo Robótico. Solo se guarda el dado para mostrarlo.
          Game.apply(g.id, g, {"pistas": 1, "energia": 0, "escudo": 0}, true, [])
          aviso = "Arpón Rastreador: sale " + d.toString + " (PAR). +1 Pista."
        } else {
          aviso = "Arpón Rastreador: sale " + d.toString + " (IMPAR). Sin pista."
        }
        Game.log(g.id, aviso)
      }
    }
  } else if (accion == "maniobra") {
    var row = `SELECT * FROM game_cards WHERE id = ? AND gameId = ? AND zone = 'mano'`.first(rowId, g.id)
    var c = row == null ? null : Card.get(row["cardId"])
    if (c == null) {
      aviso = "Esa carta ya no está en tu mano."
    } else if (g.fase != "listo") {
      aviso = "Esa Maniobra se prepara antes de elegir la Misión."
    } else if (g.jugadas > 0) {
      aviso = "Ya jugaron una carta este turno."
    } else if (c.effect == "plus_two") {
      `UPDATE games SET bonus = bonus + 2, jugadas = 1 WHERE id = ?`.query(g.id)
      Game.move(rowId, "preparada")
      Game.log(g.id, "Turbo de Emergencia: +2 al total.")
    } else if (c.effect == "flip_parity") {
      `UPDATE games SET giro = 1, jugadas = 1 WHERE id = ?`.query(g.id)
      Game.move(rowId, "preparada")
      Game.log(g.id, "Giro Brusco preparado: el dado se va a invertir.")
    } else if (c.effect == "reroll_parity") {
      `UPDATE games SET focosM = 1, jugadas = 1 WHERE id = ?`.query(g.id)
      Game.move(rowId, "preparada")
      Game.log(g.id, "Focos Abisales preparados: si falla, relanzan el dado.")
    } else if (c.effect == "reduce_damage") {
      `UPDATE games SET blindajeM = 1, jugadas = 1 WHERE id = ?`.query(g.id)
      Game.move(rowId, "preparada")
      Game.log(g.id, "Blindaje de Titanio preparado: −1 daño al Escudo.")
    } else if (c.effect == "reroll_all") {
      `UPDATE games SET suerte = 1, jugadas = 1 WHERE id = ?`.query(g.id)
      Game.move(rowId, "preparada")
      Game.log(g.id, "Suerte del Principiante preparada: si falla, se tira de nuevo.")
    } else if (c.effect == "cancel_shield_loss") {
      `UPDATE games SET cebo = 1, jugadas = 1 WHERE id = ?`.query(g.id)
      Game.move(rowId, "preparada")
      Game.log(g.id, "Lanzar Cebo: el próximo daño al Escudo se cancela.")
    } else if (c.effect == "no_energy_cost") {
      `UPDATE games SET ahorro = 1, jugadas = 1 WHERE id = ?`.query(g.id)
      Game.move(rowId, "preparada")
      Game.log(g.id, "Ahorro de Oxígeno: en esta Misión no gastan Energía.")
    } else {
      aviso = "Esa carta no se usa durante la prueba."
    }
  } else if (accion == "reroll") {
    var c = g.pruebaCarta == null ? null : Card.get(g.pruebaCarta)
    var opt = c == null ? null : c.option(g.pruebaOpcion)
    if (opt == null || g.fase != "reroll") {
      aviso = "No hay una tirada pendiente para repetir."
    } else {
      var soloUno = g.focosM && !g.suerte
      var dadosTotales = opt["dados"]
      // Con un efecto de un solo dado, el equipo elige cuál repetir.
      var cual = Num.fromString(Request.post("dado", "1"))
      if (!soloUno || dadosTotales == 1 || cual != 2) cual = 1
      var origen = Request.post("origen", "app")
      var d1 = g.dado1
      var d2 = g.dado2
      var valido = true
      if (origen == "mesa") {
        if (soloUno) {
          var v = Num.fromString(Request.post("d1", "0"))
          if (v < 1 || v > 6) valido = false
          if (cual == 2) {
            d2 = v
          } else {
            d1 = v
          }
        } else {
          d1 = Num.fromString(Request.post("d1", "0"))
          if (dadosTotales == 2) d2 = Num.fromString(Request.post("d2", "0"))
          if (d1 < 1 || d1 > 6) valido = false
          if (dadosTotales == 2 && (d2 < 1 || d2 > 6)) valido = false
        }
      } else {
        if (soloUno) {
          if (cual == 2) {
            d2 = Game.roll(1)[0]
          } else {
            d1 = Game.roll(1)[0]
          }
        } else {
          d1 = Game.roll(1)[0]
          if (dadosTotales == 2) d2 = Game.roll(1)[0]
        }
      }
      if (!valido) {
        aviso = "Elegí valores de 1 a 6 para cada dado."
      } else {
        var carta = g.suerte ? "Suerte del Principiante" : "Focos Abisales"
        var tirada = d1.toString + (dadosTotales == 2 ? " y " + d2.toString : "")
        `UPDATE games SET dado1 = ?, dado2 = ?, fase = 'prueba', tirado = 1 WHERE id = ?`.query(d1, d2, g.id)
        // Se consume solo el efecto usado: si queda otra re-tirada, la prueba
        // vuelve a frenarse en la resolución.
        if (soloUno) {
          `UPDATE games SET focosM = 0 WHERE id = ?`.query(g.id)
        } else {
          `UPDATE games SET suerte = 0 WHERE id = ?`.query(g.id)
        }
        anim = "dados"
        Game.log(g.id, carta + ": vuelven a tirar " + tirada + ".")
        var res = Game.resolve(g.id)
        if (res["error"] != "") aviso = res["error"]
      }
    }
  } else if (accion == "aceptar") {
    if (g.fase != "reroll") {
      aviso = "No hay una tirada pendiente."
    } else {
      `UPDATE games SET fase = 'prueba', suerte = 0, focosM = 0 WHERE id = ?`.query(g.id)
      var res = Game.resolve(g.id)
      if (res["error"] != "") aviso = res["error"]
      anchor = "#resultado"
    }
  } else if (accion == "resolver") {
    var res = Game.resolve(g.id)
    if (res["error"] != "") aviso = res["error"]
  } else if (accion == "cancelar") {
    if (g.tirado) {
      aviso = "Ya tiraron: no pueden volver atrás. Resuelvan la prueba."
    } else {
      // La Maniobra del turno ya está jugada: volver a elegir la Misión no
      // devuelve la carta ni borra el efecto preparado.
      `UPDATE games SET fase = 'listo', pruebaCarta = NULL, pruebaOpcion = NULL, dado1 = 0, dado2 = 0, tirado = 0 WHERE id = ?`.query(g.id)
      Game.log(g.id, "El equipo vuelve a elegir la Misión.")
    }
  } else if (accion == "descartar_mano") {
    if (g.fase != "descarte") {
      aviso = "No hay cartas de más en la mano."
    } else {
      var row = `SELECT id, cardId FROM game_cards WHERE id = ? AND gameId = ? AND zone = 'mano'`.first(rowId, g.id)
      if (row == null) {
        aviso = "Esa carta ya no está en la mano."
      } else {
        Game.move(row["id"], "descarteEquipo")
        var c = Card.get(row["cardId"])
        Game.log(g.id, (c == null ? "Una carta" : c.name) + " va al descarte: la mano queda en 3.")
        if (Game.count(g.id, "mano") <= Game.handSize) {
          `UPDATE games SET fase = 'listo' WHERE id = ?`.query(g.id)
          Game.log(g.id, "La mano está lista para el turno.")
        }
      }
    }
  } else if (accion == "terminar") {
    if (g.fase != "resuelto") {
      aviso = "Primero resuelvan una Misión."
    } else {
      // La mano se mantiene entre turnos: no se descarta al cerrar.
      var g2 = Game.find(g.id)
      if (g2.ahorro) {
        Game.log(g.id, "Ahorro de Oxígeno: el consumo del submarino no gasta Energía.")
      } else {
        var en = g2.energia - 1
        if (en < 0) en = 0
        `UPDATE games SET energia = ? WHERE id = ?`.query(en, g.id)
        Game.log(g.id, "El submarino consume 1 Energía.")
      }

      // Pagar el cierre es obligatorio: si no queda Energía (o el Escudo ya
      // estaba en 0), la expedición termina en ese momento.
      var gPago = Game.find(g.id)
      if (gPago.pistas < 6 && (gPago.energia <= 0 || gPago.escudo <= 0)) {
        `UPDATE games SET status = 'derrota' WHERE id = ?`.query(g.id)
        Game.log(g.id, "No pueden pagar el cierre: la Energía o el Escudo llegaron a 0. La expedición termina.")
        return Response.redirect("/juego")
      }

      var nueva = Game.draw(g.id, "misterio", "mesa", 1)
      if (nueva != null) {
        var nc = Card.get(nueva)
        if (nc != null && nc.entry != "") {
          var g4 = Game.find(g.id)
          Game.apply(g.id, g4, Game.parseEffects(nc.entry), true, Game.ids(g.id, "herramientas"))
          Game.log(g.id, "Emboscada al entrar: " + nc.name + " — " + nc.entryLabel + ".")
        }
      }
      if (Game.find(g.id).status != "activa") {
        return Response.redirect("/juego")
      }

      `UPDATE games SET jugador = 1, turno = turno + 1, fase = 'listo', pruebaCarta = NULL, pruebaOpcion = NULL, dado1 = 0, dado2 = 0, tirado = 0, bonus = 0, cebo = 0, ahorro = 0, blindajeUsado = 0, blindajeM = 0, focosUsado = 0, focosM = 0, jugadas = 0, resueltas = 0, resultado = NULL, giro = 0, suerte = 0, empujado = 0, pistasTurno = 0, maniobraRow = NULL WHERE id = ?`.query(g.id)
      var g3 = Game.find(g.id)
      if (g3 != null && Game.hasTool(g.id, "energy_start") && g3.energia <= 4) {
        `UPDATE games SET energia = MIN(12, energia + 1) WHERE id = ?`.query(g.id)
        Game.log(g.id, "Generador Auxiliar: +1 Energía al empezar.")
      }
      var g4 = Game.find(g.id)
      if (g4 != null && Game.hasTool(g.id, "shield_start") && g4.escudo <= 4) {
        `UPDATE games SET escudo = MIN(12, escudo + 1) WHERE id = ?`.query(g.id)
        Game.log(g.id, "Generador de Escudo: +1 Escudo al empezar.")
      }
      // Robás 1 carta por turno. Si la mano queda por encima de 3, elegís
      // cuál descartar antes de empezar.
      var robada = Game.draw(g.id, "equipo", "mano", 1)
      if (robada != null) Game.log(g.id, "Roban 1 carta de Equipo.")
      if (Game.count(g.id, "mano") > Game.handSize) {
        `UPDATE games SET fase = 'descarte' WHERE id = ?`.query(g.id)
        Game.log(g.id, "La mano supera 3 cartas: eligen cuál descartar.")
      }
      Game.log(g.id, "Turno " + (g.turno + 1).toString + ".")
    }
  }

  var qs = ""
  if (aviso != "") qs = "?aviso=" + Util.urlEncode(aviso)
  if (anim != "") qs = qs + (qs == "" ? "?" : "&") + "anim=" + anim
  return Response.redirect("/juego" + qs + anchor)
}

// ---------- Datos para la vista ----------

var aviso = Util.urlDecode(Request.get("aviso", ""))
var anim = Request.get("anim", "")
var modoGuardado = session.get("modo")
var modoInicial = (modoGuardado == "experto" || modoGuardado == "casual" || modoGuardado == "facil") ? modoGuardado : "casual"

if (g == null) {
  return Layout.render(<main>
    <section class="hero-start">
      <p class="eyebrow">Preparación</p>
      <h1>Prepará la expedición</h1>
      <p class="lead">Podés jugar solo o en cooperativo con amigos. La mesa es una: el equipo XP contra el juego.</p>
      <p class="hint">Siempre 3 cartas de Misión en la mesa y una mano de 3 que se mantiene entre turnos. No importa cuántos jueguen.</p>
      <form method="post" class="panel start-form">
{{ session.csrf }}
        <input type="hidden" name="accion" value="nueva" />
        <label for="modo"><strong>Modo</strong></label>
        <select id="modo" name="modo">
          {{ Views.modeOptions(modoInicial) }}
        </select>
        <button class="btn btn-primary">Iniciar expedición</button>
      </form>
      <p class="hint">Todavía pueden leer <a href="/reglas">las reglas</a> antes de empezar.</p>
    </section>
  </main>, "La expedición · XP")
}

var mesa = Game.cardsIn(g.id, "mesa")
var hand = Game.cardsIn(g.id, "mano")
var tools = Game.cardsIn(g.id, "herramientas")
var activeTool = tools.isEmpty ? null : tools.first["card"]
var logs = Game.lastLogs(g.id, 8)
var mazoJuego = Game.count(g.id, "misterio")
var mazoEquipo = Game.count(g.id, "equipo")
var descarteJuego = Game.count(g.id, "descarteJuego")
var descarteEquipo = Game.count(g.id, "descarteEquipo")
var descarteJuegoCards = Game.cardsIn(g.id, "descarteJuego")
var descarteEquipoCards = Game.cardsIn(g.id, "descarteEquipo")
var moves = Moves.take(g.id, session)
var movesJson = Json.stringify(moves)
var peekCard = Game.hasTool(g.id, "peek") ? Game.topCard(g.id) : null
var preparadas = Game.cardsIn(g.id, "preparada")
var preparada = preparadas.isEmpty ? null : preparadas.first

var pendingCard = g.pruebaCarta == null ? null : Card.get(g.pruebaCarta)
var pendingOpt = pendingCard == null ? null : pendingCard.option(g.pruebaOpcion)

var maniobraCard = null
if (g.maniobraRow != null) {
  var mrow = `SELECT cardId FROM game_cards WHERE id = ?`.first(g.maniobraRow)
  if (mrow != null) maniobraCard = Card.get(mrow["cardId"])
}

// El total de la prueba se muestra con las sumas ya aplicadas, para que la
// mesa de dados sea la misma antes y después de tirar.
var estab = Game.hasEffect(Game.ids(g.id, "herramientas"), "plus_one_sum")
var totalPrueba = g.dado1 + g.dado2 + g.bonus
if (estab && pendingOpt != null && pendingOpt["tipoPrueba"] == "suma") totalPrueba = totalPrueba + 1

var handCount = hand.count
var focoHref = "#cartas-activas"
if (g.fase == "maniobra") focoHref = "#maniobra"
if (g.fase == "prueba" || g.fase == "reroll") focoHref = "#prueba"
if (g.fase == "descarte") focoHref = "#mano"
if (g.fase == "resuelto") focoHref = "#resultado"
var puedeElegir = g.status == "activa" && g.fase == "listo" && g.resueltas == 0
var puedeJugar = g.status == "activa" && g.jugadas == 0 && g.fase == "listo"
var gaugesEnding = Views.gauges(g, "ending-gauges")
// Mientras haya una tirada pendiente, la mesa queda bloqueada y la bandeja de
// dados se muestra fija arriba.
var esperaTirada = g.fase == "prueba" || g.fase == "reroll" || g.fase == "maniobra"

var finalTitulo = "La expedición continúa"
var finalTexto = ""
if (g.status == "victoria") {
  finalTitulo = "Lo encontraron"
  finalTexto = "Seis Pistas. La última sombra se hunde en la fosa y, por un instante, el Megalodón está ahí. El mundo seguirá creyendo que es un mito, como el monstruo del lago Ness. Ustedes ya saben la verdad."
} else if (g.status == "derrota") {
  finalTitulo = "La expedición se pierde"
  finalTexto = "Al cerrar el turno, la Energía o el Escudo estaba en 0. El submarino se queda sin aire y sin casco en la oscuridad."
}

// ---------- Mesa ----------

var modoLabel = g.modo == "facil" ? "Asistido" : (g.modo == "casual" ? "Normal" : "Experto")

var faseEyebrow = "Encuentro"
var fasePrompt = "Jueguen su carta de Equipo (o no) y elijan una Misión de la mesa."
if (g.fase == "emboscada") {
  faseEyebrow = "Emboscada"
  fasePrompt = "Entraron varias emboscadas a la vez: elijan cuál cobra."
} else if (g.fase == "maniobra") {
  faseEyebrow = "Maniobra con dados"
  fasePrompt = "Tiren un dado y apliquen lo que diga la carta."
} else if (g.fase == "prueba") {
  faseEyebrow = "Prueba de dados"
  fasePrompt = "Tiren los dados. También pueden cargar lo que salió en la mesa."
} else if (g.fase == "reroll") {
  faseEyebrow = "Tirada fallida"
  fasePrompt = "Pueden volver a tirar o aceptar el fallo."
} else if (g.fase == "descarte") {
  faseEyebrow = "Tope de mano"
  fasePrompt = "Robaron 1 carta y la mano pasó de 3: elijan cuál descartar."
} else if (g.fase == "resuelto") {
  faseEyebrow = "Resultado"
  fasePrompt = "Cierren el turno: se repone la mesa y se pasa el turno."
}

var mesaFaltan = 3 - mesa.count
if (mesaFaltan < 0) mesaFaltan = 0
var manoFaltan = Game.handSize - handCount
if (manoFaltan < 0) manoFaltan = 0
var ultimaLinea = logs.isEmpty ? "Todavía no pasó nada." : logs[0]["text"]

// ---------- Vista ----------

return Layout.render(<main class="game table-board" data-moves="{{ movesJson }}" data-anim="{{ anim }}" data-outcome="{{ g.status == "victoria" || g.status == "derrota" ? g.status : "" }}">
  {{ g.status == "activa" && <aside class="game-rail" aria-label="Menú de la expedición">
    <div class="game-rail-body">
      {{ Views.railState(g) }}
      <p class="rail-meta">Turno {{ g.turno }}</p>
      <nav class="rail-nav">
        <a href="{{ focoHref }}" aria-label="Ir a la acción actual">{{ Layout.icon("🌊") }} <span class="rail-label">Mesa</span><span class="rail-label-short">Mesa</span> <b>{{ mesa.count }}</b></a>
        <a href="#mano" aria-label="Ver la mano">{{ Layout.icon("🖐️") }} <span class="rail-label">Mano</span><span class="rail-label-short">Mano</span> <b>{{ handCount }}</b></a>
        <a href="#herramientas" class="{{ activeTool == null ? "is-empty" : "" }}" data-tool="{{ activeTool == null ? "Sin Herramienta activa" : activeTool.name }}" title="{{ activeTool == null ? "Sin Herramienta activa" : activeTool.name }}" aria-label="Herramienta: {{ activeTool == null ? "ninguna activa" : activeTool.name }}">
          {{ Layout.icon("🔧") }} <span class="rail-label">Herramienta</span><span class="rail-label-short">Herram.</span>
          <span class="rail-dot {{ activeTool == null ? "" : "on" }}" aria-hidden="true"></span>
        </a>
        <a href="/reglas" title="Reglas completas" aria-label="Reglas completas">{{ Layout.icon("📖") }} <span class="rail-label">Reglas</span><span class="rail-label-short">Reglas</span></a>
        <a href="/" title="Inicio" aria-label="Inicio">{{ Layout.icon("🏠") }} <span class="rail-label">Inicio</span><span class="rail-label-short">Inicio</span></a>
      </nav>
    </div>
  </aside> }}

  <header class="board-head">
    <div class="board-title">
      <p class="eyebrow">Expedición en curso</p>
      <h1>La fosa del Megalodón</h1>
    </div>
    <div class="board-meta">
      <span class="pill">{{ modoLabel }}</span>
      <nav class="board-nav" aria-label="Accesos de la expedición">
        <a href="/reglas">{{ Layout.icon("📖") }} Reglas</a>
        <a href="/">{{ Layout.icon("🏠") }} Inicio</a>
      </nav>
      <div class="view-tools" role="group" aria-label="Preferencias de la partida">
        <button class="pref-toggle" id="toggle-motion" type="button" aria-pressed="true">
          {{ Layout.icon("✨") }} Animaciones
        </button>
        <button class="pref-toggle" id="toggle-sound" type="button" aria-pressed="true">
          {{ Layout.icon("🔊") }} Sonido
        </button>
      </div>
    </div>
  </header>

  {{ g.status == "activa" && <section class="felt" aria-label="Mesa de juego">
    {{ aviso != "" && <p class="aviso" role="status">{{ aviso }}</p> }}

    <section class="zone zone-encounter {{ g.fase == "emboscada" ? "is-ambush" : "" }}" id="cartas-activas">
      <div class="zone-head">
        <h2>Encuentro</h2>
        <span class="zone-count">{{ mesa.count }} de 3 Misiones</span>
      </div>
      <div class="zone-body">
        <div class="card-row">
          {{ mesa.map{|item| <article class="card {{ (puedeElegir || (g.fase == "emboscada" && item["card"].entry != "")) ? "is-actionable" : "" }} {{ pendingCard != null && item["card"].id == pendingCard.id ? "is-pending" : "" }}" data-family="{{ item["card"].family }}" data-row="{{ item["rowId"] }}">
            {{ Views.cardArt(item["card"]) }}
            {{ Views.cardFamily(item["card"], (item["card"].family == "exploracion" ? "Exploración" : (item["card"].family == "peligro" ? "Peligro" : "Dilema")) + (item["card"].entry != "" ? " · Emboscada" : ""), false) }}
            {{ Views.cardTitle(item["card"]) }}
            {{ item["card"].entry != "" && <p class="entry-badge" title="El costo de entrar se resuelve una sola vez, cuando la carta entra a la mesa. Si ya está en la mesa, no se vuelve a cobrar.">Al entrar <span class="muted entry-done">ya resuelto</span>
              {{ item["card"].entryChips.map{|c| <span class="chip {{ c["cls"] }}" title="{{ c["title"] }}" aria-label="{{ c["title"] }}">{{ Layout.icon(c["icon"]) }} {{ c["text"] }}</span>} }}
            </p> }}
            {{ Views.cardText(item["card"]) }}
            <form method="post" class="card-action option-form ambush-action {{ item["card"].entry == "" ? "is-hidden" : "" }}">
{{ session.csrf }}
              <input type="hidden" name="accion" value="elegir_emboscada" />
              <input type="hidden" name="rowId" value="{{ item["rowId"] }}" />
              <button class="btn btn-primary btn-small">Sufrir esta emboscada</button>
            </form>
            <ul class="card-options">
              {{ item["card"].options.map{|o| <li class="option-row">
                <form method="post" class="option-form">
{{ session.csrf }}
                  <input type="hidden" name="accion" value="elegir" />
                  <input type="hidden" name="rowId" value="{{ item["rowId"] }}" />
                  <input type="hidden" name="opt" value="{{ o["label"] }}" />
                  <button class="option-btn" {{ puedeElegir ? "" : "disabled" }}>
                    <span class="option-key" aria-hidden="true">{{ o["label"] }}</span>
                    <span class="option-body">
                      <span class="option-text">{{ o["texto"] }}</span>
                      <span class="test-badge test-{{ o["tipoPrueba"] }}">{{ o["pruebaLabel"] }}</span>
                      <span class="option-effects">
                        <span class="chip-label">Éxito</span>
                        {{ o["exitoChips"].map{|c| <span class="chip {{ c["cls"] }}" title="{{ c["title"] }}" aria-label="{{ c["title"] }}">{{ Layout.icon(c["icon"]) }} {{ c["text"] }}</span>} }}
                        <span class="chip-label">Fallo</span>
                        {{ o["falloChips"].map{|c| <span class="chip {{ c["cls"] }}" title="{{ c["title"] }}" aria-label="{{ c["title"] }}">{{ Layout.icon(c["icon"]) }} {{ c["text"] }}</span>} }}
                      </span>
                    </span>
                  </button>
                </form>
              </li>} }}
            </ul>
          </article>} }}
          {{ mesaFaltan > 0 && (1..mesaFaltan).map{|i| <article class="card card-slot" aria-hidden="true">
            <span class="slot-mark">{{ Layout.icon("🃏") }}</span>
            <span class="slot-text">Lugar libre</span>
          </article>} }}
        </div>

        <aside class="pile-rack" aria-label="Mazos y descartes">
          <button type="button" class="pile" id="pila-misterio" data-pile="misterio" aria-haspopup="dialog" aria-label="Mazos y descartes · {{ mazoJuego }} Misiones en el mazo" aria-controls="mazos-dialog">
            <span class="pile-stack"><img src="/img/dorso-mision-thumb.png" width="84" height="118" alt="" /><span class="pile-count">{{ mazoJuego }}</span></span>
            <span class="pile-name">Misiones</span>
          </button>
          <button type="button" class="pile" id="pila-descarte-juego" data-pile="descarteJuego" aria-haspopup="dialog" aria-label="Mazos y descartes · {{ descarteJuego }} Misiones en el descarte" aria-controls="mazos-dialog">
            <span class="pile-stack pile-discard">{{ descarteJuego > 0 && <span class="pile-face" aria-hidden="true">{{ descarteJuegoCards[-1]["card"].emoji }}</span> }}<span class="pile-count">{{ descarteJuego }}</span></span>
            <span class="pile-name">Descarte</span>
          </button>
          <button type="button" class="pile" id="pila-equipo" data-pile="equipo" aria-haspopup="dialog" aria-label="Mazos y descartes · {{ mazoEquipo }} cartas de Equipo en el mazo" aria-controls="mazos-dialog">
            <span class="pile-stack"><img src="/img/dorso-equipo-thumb.png" width="84" height="118" alt="" /><span class="pile-count">{{ mazoEquipo }}</span></span>
            <span class="pile-name">Equipo</span>
          </button>
          <button type="button" class="pile" id="pila-descarte-equipo" data-pile="descarteEquipo" aria-haspopup="dialog" aria-label="Mazos y descartes · {{ descarteEquipo }} cartas de Equipo en el descarte" aria-controls="mazos-dialog">
            <span class="pile-stack pile-discard">{{ descarteEquipo > 0 && <span class="pile-face" aria-hidden="true">{{ descarteEquipoCards[-1]["card"].emoji }}</span> }}<span class="pile-count">{{ descarteEquipo }}</span></span>
            <span class="pile-name">Descarte</span>
          </button>
        </aside>
      </div>
    </section>

    <section class="zone zone-own">
      <div class="zone-head">
        <h2>Su lado de la mesa</h2>
        <span class="zone-count">Herramienta y Maniobra</span>
      </div>
      <div class="zone-body">
        <div class="slot-column" id="herramientas">
          <p class="slot-label">{{ Layout.icon("🔧") }} Herramienta activa <span>{{ tools.count }} / 1</span></p>
          {{ tools.map{|t| <article class="card card-tool" data-family="herramienta" data-row="{{ t["rowId"] }}">
            {{ Views.cardArt(t["card"]) }}
            {{ Views.cardFamily(t["card"], t["card"].typeLabel, true) }}
            {{ Views.cardTitle(t["card"]) }}
            {{ Views.cardBadge(t["card"]) }}
            {{ Views.cardChips(t["card"]) }}
            {{ Views.cardText(t["card"]) }}
          </article>} }}
          {{ tools.isEmpty && <article class="card card-slot card-slot-sm" aria-hidden="true">
            <span class="slot-mark">{{ Layout.icon("🔧") }}</span>
            <span class="slot-text">Sin Herramienta</span>
          </article> }}
        </div>

        {{ preparada != null && <div class="slot-column" id="preparada">
          <p class="slot-label">{{ Layout.icon("🃏") }} Maniobra del turno <span>se resuelve en la prueba</span></p>
          <article class="card card-maneuver" data-family="maniobra" data-row="{{ preparada["rowId"] }}">
            {{ Views.cardArt(preparada["card"]) }}
            {{ Views.cardFamily(preparada["card"], preparada["card"].typeLabel, true) }}
            {{ Views.cardTitle(preparada["card"]) }}
            {{ Views.cardBadge(preparada["card"]) }}
            {{ Views.cardChips(preparada["card"]) }}
            {{ Views.cardText(preparada["card"]) }}
          </article>
        </div> }}

        {{ peekCard != null && <div class="peek-column">
          <p class="slot-label">{{ Layout.icon("🔍") }} Sonar de Alta Frecuencia</p>
          <section class="card peek" data-family="{{ peekCard.family }}">
            {{ Views.cardArt(peekCard) }}
            {{ Views.cardFamily(peekCard, "Próxima Misión", false) }}
            {{ Views.cardTitle(peekCard) }}
            {{ peekCard.entry != "" && <p class="entry-badge">Al entrar
              {{ peekCard.entryChips.map{|c| <span class="chip {{ c["cls"] }}" title="{{ c["title"] }}">{{ Layout.icon(c["icon"]) }} {{ c["text"] }}</span>} }}
            </p> }}
            {{ Views.cardText(peekCard) }}
            <ul class="mini-options">
              {{ peekCard.options.map{|o| <li>
                <strong>{{ o["texto"] }}</strong>
                <span class="test-badge test-{{ o["tipoPrueba"] }}">{{ o["pruebaLabel"] }}</span>
                <span class="option-effects">
                  <span class="chip-label">Éxito</span>
                  {{ o["exitoChips"].map{|c| <span class="chip {{ c["cls"] }}" title="{{ c["title"] }}">{{ Layout.icon(c["icon"]) }} {{ c["text"] }}</span>} }}
                  <span class="chip-label">Fallo</span>
                  {{ o["falloChips"].map{|c| <span class="chip {{ c["cls"] }}" title="{{ c["title"] }}">{{ Layout.icon(c["icon"]) }} {{ c["text"] }}</span>} }}
                </span>
              </li>} }}
            </ul>
          </section>
        </div> }}
      </div>
    </section>

    <div class="felt-top">
      {{ Views.gauges(g, "") }}
      <div class="felt-prompt" role="status">
        <p class="eyebrow">{{ faseEyebrow }}</p>
        <p class="felt-prompt-text">{{ fasePrompt }}</p>
      </div>
      <p class="turn-plate"><span>Turno</span><b>{{ g.turno }}</b></p>
      <nav class="felt-nav board-nav" aria-label="Accesos de la expedición">
        <a href="{{ focoHref }}">{{ Layout.icon("🌊") }} Mesa <b>{{ mesa.count }}</b></a>
        <a href="#mano">{{ Layout.icon("🖐️") }} Mano <b>{{ handCount }}</b></a>
        <a href="#herramientas" title="{{ activeTool == null ? "Sin Herramienta activa" : activeTool.name }}">{{ Layout.icon("🔧") }} Herramienta</a>
        <a href="/reglas">{{ Layout.icon("📖") }} Reglas</a>
        <a href="/">{{ Layout.icon("🏠") }} Inicio</a>
      </nav>
    </div>

    {{ esperaTirada && <div class="roll-gate-backdrop" aria-hidden="true"></div> }}

    {{ g.fase == "maniobra" && maniobraCard != null && <section class="tray test-panel {{ esperaTirada ? "is-gate" : "" }}" id="maniobra">
      <div class="tray-main">
        <h2>{{ maniobraCard.name }}</h2>
        <p class="muted">{{ Layout.icon(maniobraCard.typeIcon) }} {{ maniobraCard.typeLabel }} · {{ maniobraCard.id }}</p>
        <p class="test-action">Tirá un dado. Si sale par, ganan 1 Pista.</p>
        <p><span class="test-badge test-par">PAR · 2, 4 o 6</span></p>
      </div>
      <div class="tray-dice">
        <div class="dice-row roller-stage">{{ Layout.die(0, "die-large dice-roll") }}</div>
        <p class="hint dice-help">PAR = 2, 4 o 6. IMPAR = 1, 3 o 5.</p>
      </div>
      <section class="roll-controls tray-actions">
        <form method="post" class="roll-form">
{{ session.csrf }}
          <input type="hidden" name="accion" value="tirar_maniobra" />
          <input type="hidden" name="origen" value="app" />
          <button class="btn btn-primary">Tirar en la app</button>
        </form>
        <form method="post" class="roll-form">
{{ session.csrf }}
          <input type="hidden" name="accion" value="tirar_maniobra" />
          <input type="hidden" name="origen" value="mesa" />
          {{ Views.dieSelect("d1", "Dado") }}
          <button class="btn btn-ghost">Ya tiré en la mesa</button>
        </form>
      </section>
    </section> }}

    {{ (g.fase == "prueba" || g.fase == "reroll") && pendingCard != null && pendingOpt != null && <section class="tray test-panel {{ esperaTirada ? "is-gate" : "" }}" id="prueba">
      <div class="tray-main">
        <h2>{{ pendingCard.name }}</h2>
        <p class="muted">{{ pendingCard.family == "exploracion" ? "Exploración" : (pendingCard.family == "peligro" ? "Peligro" : "Dilema") }} · {{ pendingCard.id }}</p>
        <p class="test-action">{{ pendingOpt["texto"] }}</p>
        <p><span class="test-badge test-{{ pendingOpt["tipoPrueba"] }}">{{ pendingOpt["pruebaLabel"] }}</span></p>
        <p class="option-chips">
          <span class="chip-label">Éxito</span>
          {{ pendingOpt["exitoChips"].map{|c| <span class="chip {{ c["cls"] }}" title="{{ c["title"] }}" aria-label="{{ c["title"] }}">{{ Layout.icon(c["icon"]) }} {{ c["text"] }}</span>} }}
          <span class="chip-label">Fallo</span>
          {{ pendingOpt["falloChips"].map{|c| <span class="chip {{ c["cls"] }}" title="{{ c["title"] }}" aria-label="{{ c["title"] }}">{{ Layout.icon(c["icon"]) }} {{ c["text"] }}</span>} }}
        </p>
        {{ g.fase == "reroll" && <p class="hint hint-danger">La prueba falló. {{ g.suerte ? "Suerte del Principiante: vuelvan a tirar los dados." : "Focos Abisales: relancen un dado." }}</p> }}
        {{ g.giro && <p class="hint">Giro Brusco preparado: el dado se va a invertir.</p> }}
        {{ g.suerte && <p class="hint">Suerte del Principiante preparada: si falla, se tira de nuevo.</p> }}
        {{ g.focosM && <p class="hint">Focos Abisales preparados: si falla, relanzan el dado.</p> }}
        {{ g.cebo && <p class="hint">Lanzar Cebo: el próximo daño al Escudo se cancela.</p> }}
        {{ g.ahorro && <p class="hint">Ahorro de Oxígeno: este turno no gastan Energía.</p> }}
      </div>

      <div class="tray-dice">
        <div class="dice-row roller-stage">
          {{ Layout.die(g.tirado ? g.dado1 : 0, "die-large dice-roll") }}
          {{ pendingOpt["dados"] == 2 && Layout.die(g.tirado ? g.dado2 : 0, "die-large dice-roll") }}
        </div>
        {{ g.tirado && (pendingOpt["tipoPrueba"] == "suma" || pendingOpt["tipoPrueba"] == "dado") && <p class="hint dice-total">
          Total <strong>{{ totalPrueba }}</strong> de <strong>{{ pendingOpt["objetivo"] }}</strong>{{ g.bonus > 0 ? " · incluye +" + g.bonus.toString + " de las Maniobras" : "" }}
        </p> }}
        <p class="hint dice-help">PAR = 2, 4 o 6. IMPAR = 1, 3 o 5.</p>
      </div>

      {{ g.fase == "prueba" && !g.tirado && <section class="roll-controls tray-actions">
        <form method="post" class="roll-form">
{{ session.csrf }}
          <input type="hidden" name="accion" value="tirar" />
          <button class="btn btn-primary">Tirar en la app</button>
        </form>
        <form method="post" class="roll-form">
{{ session.csrf }}
          <input type="hidden" name="accion" value="mesa" />
          {{ Views.dieSelect("d1", "Dado 1") }}
          {{ pendingOpt["dados"] == 2 && Views.dieSelect("d2", "Dado 2") }}
          <button class="btn btn-ghost">Ya tiré en la mesa</button>
        </form>
      </section> }}

      {{ g.fase == "reroll" && <section class="roll-controls tray-actions">
        <form method="post" class="roll-form">
{{ session.csrf }}
          <input type="hidden" name="accion" value="reroll" />
          <input type="hidden" name="origen" value="app" />
          {{ g.focosM && !g.suerte && pendingOpt["dados"] == 2 && <label class="die-select">Repetir
            <select name="dado">
              <option value="1">Dado 1 ({{ g.dado1 }})</option>
              <option value="2">Dado 2 ({{ g.dado2 }})</option>
            </select>
          </label> }}
          <button class="btn btn-primary">Volver a tirar en la app</button>
        </form>
        <form method="post" class="roll-form">
{{ session.csrf }}
          <input type="hidden" name="accion" value="reroll" />
          <input type="hidden" name="origen" value="mesa" />
          {{ g.focosM && !g.suerte && pendingOpt["dados"] == 2 && <label class="die-select">Repetir
            <select name="dado">
              <option value="1">Dado 1 ({{ g.dado1 }})</option>
              <option value="2">Dado 2 ({{ g.dado2 }})</option>
            </select>
          </label> }}
          {{ Views.dieSelect("d1", "Nuevo valor") }}
          {{ g.suerte && pendingOpt["dados"] == 2 && Views.dieSelect("d2", "Dado 2") }}
          <button class="btn btn-ghost">Ya tiré en la mesa</button>
        </form>
        <form method="post">
{{ session.csrf }}
          <input type="hidden" name="accion" value="aceptar" />
          <button class="btn btn-ghost btn-small">Aceptar el fallo</button>
        </form>
      </section> }}
    </section> }}

    {{ g.fase == "resuelto" && <section class="tray result-panel" id="resultado" role="status" aria-live="polite">
      <div class="tray-main">
        <h2>{{ g.resultado == "ganada" ? "Prueba superada" : "Prueba fallida" }}</h2>
        {{ pendingCard != null && pendingOpt != null && <p class="muted">{{ pendingCard.name }} — {{ pendingOpt["texto"] }}</p> }}
        <p class="muted">{{ g.ultimo }}</p>
        {{ pendingOpt != null && <p class="option-chips">
          <span class="chip-label">{{ g.resultado == "ganada" ? "Éxito" : "Fallo" }}</span>
          {{ (g.resultado == "ganada" ? pendingOpt["exitoChips"] : pendingOpt["falloChips"]).map{|c| <span class="chip {{ c["cls"] }}" title="{{ c["title"] }}">{{ Layout.icon(c["icon"]) }} {{ c["text"] }}</span>} }}
        </p> }}
      </div>
      <div class="tray-dice">
        <div class="dice-row">
          {{ Layout.die(g.dado1, "dice-roll") }}
          {{ pendingOpt != null && pendingOpt["dados"] == 2 && Layout.die(g.dado2, "dice-roll") }}
        </div>
      </div>
      <div class="tray-actions">
        <p class="hint">Al cerrar el turno, el submarino paga 1 Energía y entra 1 Misión.</p>
        {{ g.energia == 1 && <p class="hint hint-danger">Pagar el cierre deja la Energía en 0: la expedición termina.</p> }}
        <form method="post">
{{ session.csrf }}
          <input type="hidden" name="accion" value="terminar" />
          <button class="btn btn-primary">Terminar turno y reponer la mesa</button>
        </form>
      </div>
    </section> }}

    <section class="zone zone-hand" id="mano">
      <div class="zone-head">
        <h2>Mano del equipo</h2>
        <span class="zone-count">{{ handCount }} cartas · tope 3</span>
      </div>
      <div class="card-row hand-main">
        {{ hand.map{|h| <article class="card {{ (puedeJugar || g.fase == "descarte") ? "is-actionable" : "is-locked" }}" data-row="{{ h["rowId"] }}" data-family="{{ h["card"].isSupport ? "apoyo" : (h["card"].isTool ? "herramienta" : "maniobra") }}">
          {{ h["card"].isSupport && <span class="card-ribbon">🎁 Apoyo</span> }}
          {{ Views.cardArt(h["card"]) }}
          {{ Views.cardFamily(h["card"], h["card"].typeLabel, true) }}
          {{ Views.cardTitle(h["card"]) }}
          {{ Views.cardBadge(h["card"]) }}
          {{ Views.cardChips(h["card"]) }}
          {{ Views.cardText(h["card"]) }}
          <div class="card-action">
            {{ g.fase == "descarte" && <form method="post" class="inline-form">
{{ session.csrf }}
              <input type="hidden" name="accion" value="descartar_mano" />
              <input type="hidden" name="rowId" value="{{ h["rowId"] }}" />
              <button class="btn btn-ghost btn-small">Descartar</button>
            </form> }}
            {{ g.fase != "descarte" && h["card"].playNow && <form method="post" class="inline-form">
{{ session.csrf }}
              <input type="hidden" name="accion" value="jugar" />
              <input type="hidden" name="rowId" value="{{ h["rowId"] }}" />
              <button class="btn btn-primary btn-small" {{ puedeJugar ? "" : "disabled" }}>Jugar</button>
            </form> }}
            {{ g.fase != "descarte" && !h["card"].playNow && h["card"].isPrep && <form method="post" class="inline-form">
{{ session.csrf }}
              <input type="hidden" name="accion" value="maniobra" />
              <input type="hidden" name="rowId" value="{{ h["rowId"] }}" />
              <button class="btn btn-ghost btn-small" {{ puedeJugar ? "" : "disabled" }}>Preparar</button>
            </form> }}
            {{ g.fase != "descarte" && !h["card"].playNow && !h["card"].isPrep && <p class="hint card-hint">Esta Maniobra se usa durante la prueba.</p> }}
          </div>
        </article>} }}
        {{ manoFaltan > 0 && (1..manoFaltan).map{|i| <article class="card card-slot card-slot-sm" aria-hidden="true">
          <span class="slot-mark">{{ Layout.icon("🖐️") }}</span>
          <span class="slot-text">Lugar libre</span>
        </article>} }}
      </div>
      <p class="zone-foot">{{ g.fase == "descarte" ? "Eligen qué carta descartar: la mano queda en 3." : (g.fase == "listo" ? (g.jugadas == 0 ? "Pueden jugar 1 carta de Equipo este turno." : "Ya jugaron su carta de Equipo este turno.") : "La mano se mantiene: al cerrar el turno roban 1 y descartan hasta 3.") }}</p>
    </section>
  </section> }}

  {{ g.status != "activa" && <section class="panel ending {{ g.status }}">
    <p class="eyebrow">Fin de la partida</p>
    <h2>{{ finalTitulo }}</h2>
    <p>{{ finalTexto }}</p>
    {{ gaugesEnding }}
    <form method="post">
{{ session.csrf }}
      <input type="hidden" name="accion" value="reiniciar" />
      <button class="btn btn-primary">Nueva expedición</button>
    </form>
  </section> }}

  <details class="log-box">
    <summary>
      <span class="log-box-title">{{ Layout.icon("📖") }} Bitácora</span>
      <span class="log-box-last">{{ ultimaLinea }}</span>
      <span class="log-box-hint">Ver todo</span>
    </summary>
    <ul class="log">
      {{ logs.map{|l| <li><time datetime="{{ l["iso"] }}">{{ l["hora"] }}</time> <span>{{ l["text"] }}</span></li>} }}
    </ul>
    {{ logs.isEmpty && <p class="muted">Todavía no pasó nada. Todo está por descubrirse.</p> }}
    {{ g.status == "activa" && <form method="post" class="restart-form">
{{ session.csrf }}
      <input type="hidden" name="accion" value="reiniciar" />
      <button class="btn btn-ghost btn-small">Abandonar y empezar de nuevo</button>
    </form> }}
  </details>

  <dialog id="mazos-dialog" class="mazos-dialog" aria-labelledby="mazos-title">
    <div class="mazos-dialog-head">
      <div>
        <p class="eyebrow">Estado de los mazos</p>
        <h2 id="mazos-title">Mazos y descartes</h2>
      </div>
      <button type="button" class="dialog-close" data-close aria-label="Cerrar">×</button>
    </div>
    <div class="mazos-grid">
      <section class="mazos-pile mazos-pile-juego">
        <div class="mazos-pile-head">
          <img src="/img/dorso-mision-thumb.png" width="42" height="59" alt="" />
          <div>
            <h3>Mazo de Misiones</h3>
            <p><strong>{{ mazoJuego }}</strong> en el mazo · <strong>{{ descarteJuego }}</strong> en descarte</p>
          </div>
        </div>
        <h4>Descartadas</h4>
        {{ descarteJuegoCards.isEmpty && <p class="muted">Todavía no hay Misiones en el descarte.</p> }}
        {{ !descarteJuegoCards.isEmpty && <ul class="discard-list">
          {{ descarteJuegoCards.map{|d| <li>
            <span class="discard-emoji" aria-hidden="true">{{ d["card"].emoji }}</span>
            <span class="discard-body"><strong>{{ d["card"].name }}</strong><small>{{ d["card"].id }} · {{ d["card"].family == "exploracion" ? "Exploración" : (d["card"].family == "peligro" ? "Peligro" : "Dilema") }}</small></span>
          </li>} }}
        </ul> }}
      </section>
      <section class="mazos-pile mazos-pile-equipo">
        <div class="mazos-pile-head">
          <img src="/img/dorso-equipo-thumb.png" width="42" height="59" alt="" />
          <div>
            <h3>Mazo de Equipo</h3>
            <p><strong>{{ mazoEquipo }}</strong> en el mazo · <strong>{{ descarteEquipo }}</strong> en descarte</p>
          </div>
        </div>
        <h4>Descartadas</h4>
        {{ descarteEquipoCards.isEmpty && <p class="muted">Todavía no hay Equipo en el descarte.</p> }}
        {{ !descarteEquipoCards.isEmpty && <ul class="discard-list">
          {{ descarteEquipoCards.map{|d| <li>
            <span class="discard-emoji" aria-hidden="true">{{ d["card"].emoji }}</span>
            <span class="discard-body"><strong>{{ d["card"].name }}</strong><small>{{ d["card"].id }} · {{ d["card"].typeLabel }}</small></span>
          </li>} }}
        </ul> }}
      </section>
    </div>
  </dialog>
</main>, "La expedición · XP", true)
