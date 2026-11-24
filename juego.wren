import "_app/template" for Layout
import "_app/moves" for Moves
import "_app/cards" for Card
import "_app/game" for Game

var session = Session.new()
var g = Game.find(session.get("gameId"))

// ---------- Acciones ----------

if (Request.isPost) {
  var accion = Request.post("accion", "")

  if (accion == "nueva") {
    if (g != null) Game.destroy(g.id)
    var modo = Request.post("modo", "casual")
    if (modo != "experto" && modo != "casual" && modo != "facil") modo = "casual"
    session.set("modo", modo)
    var id = Game.create(1, modo)
    session.set("gameId", id.toString)
    return Response.redirect("/juego")
  }

  if (g == null) return Response.redirect("/juego")

  if (accion == "reiniciar") {
    Game.destroy(g.id)
    session.set("gameId", "")
    return Response.redirect("/juego")
  }

  var aviso = ""
  var anim = ""

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
    } else if (g.fase != "listo" && !(g.fase == "prueba" && !g.tirado)) {
      aviso = "Esa carta se juega antes de tirar."
    } else if (g.jugadas > 0) {
      aviso = "Ya jugaron una carta este turno."
    } else {
      var c = Card.get(row["cardId"])
      if (c == null) {
        aviso = "No pudimos leer esa carta."
      } else if (c.isSupport) {
        `UPDATE games SET fase = 'apoyo', apoyoCarta = ?, apoyoOrigen = 'mano', fasePrevia = ?, jugadas = 1 WHERE id = ?`.query(rowId, g.fase, g.id)
        Game.log(g.id, "Preparan la maniobra de apoyo: " + c.name + ".")
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
          var gA = Game.find(g.id)
          if (gA.status == "activa") {
            var d = Game.roll(1)[0]
            if (d % 2 == 0) {
              Game.apply(g.id, gA, {"pistas": 1, "energia": 0, "escudo": 0}, true, [])
              Game.log(g.id, "Arpón Rastreador: sale " + d.toString + " (CARA). +1 Pista.")
            } else {
              Game.log(g.id, "Arpón Rastreador: sale " + d.toString + " (SECA). Sin pista.")
            }
          }
          Game.move(rowId, "descarteEquipo")
          `UPDATE games SET jugadas = 1 WHERE id = ?`.query(g.id)
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
      aviso = "Ya resolvieron un misterio este turno."
    } else {
      var row = `SELECT * FROM game_cards WHERE id = ? AND gameId = ? AND zone = 'mesa'`.first(rowId, g.id)
      if (row == null) {
        aviso = "Esa carta ya no está en la mesa."
      } else {
        var c = Card.get(row["cardId"])
        `UPDATE games SET fase = 'prueba', pruebaCarta = ?, pruebaOpcion = ?, dado1 = 0, dado2 = 0, tirado = 0 WHERE id = ?`.query(row["cardId"], optLabel, g.id)
        Game.log(g.id, "Eligen " + c.name + ".")
      }
    }
  } else if (accion == "tirar") {
    var c = Card.get(g.pruebaCarta)
    var opt = c == null ? null : c.option(g.pruebaOpcion)
    if (opt == null) {
      aviso = "No hay una prueba preparada."
    } else {
      var dados = opt["dados"]
      var dice = Game.roll(dados)
      var d1 = dice[0]
      var d2 = dados == 2 ? dice[1] : 0
      var parity = opt["tipoPrueba"] == "cara" || opt["tipoPrueba"] == "seca"
      if (parity && g.giro) d1 = 7 - d1
      `UPDATE games SET dado1 = ?, dado2 = ?, tirado = 1, giro = 0 WHERE id = ?`.query(d1, d2, g.id)
      anim = "dados"
      Game.log(g.id, "Tiran en la app: " + d1.toString + (dados == 2 ? " y " + d2.toString : "") + ".")
      var auto = Game.resolve(g.id)
      if (auto["error"] != "") aviso = auto["error"]
    }
  } else if (accion == "mesa") {
    var d1 = Num.fromString(Request.post("d1", "0"))
    var d2 = Num.fromString(Request.post("d2", "0"))
    var c = Card.get(g.pruebaCarta)
    var opt = c == null ? null : c.option(g.pruebaOpcion)
    var dados = opt == null ? 0 : opt["dados"]
    if (opt == null) {
      aviso = "No hay una prueba preparada."
    } else if (d1 < 1 || d1 > 6 || (dados == 2 && (d2 < 1 || d2 > 6))) {
      aviso = "Elegí valores de 1 a 6 para cada dado."
    } else {
      var parity = opt["tipoPrueba"] == "cara" || opt["tipoPrueba"] == "seca"
      if (parity && g.giro) d1 = 7 - d1
      `UPDATE games SET dado1 = ?, dado2 = ?, tirado = 1, giro = 0 WHERE id = ?`.query(d1, dados == 2 ? d2 : 0, g.id)
      anim = "dados"
      Game.log(g.id, "Dados de la mesa: " + d1.toString + (dados == 2 ? " y " + d2.toString : "") + ".")
      var auto = Game.resolve(g.id)
      if (auto["error"] != "") aviso = auto["error"]
    }
  } else if (accion == "maniobra") {
    var row = `SELECT * FROM game_cards WHERE id = ? AND gameId = ? AND zone = 'mano'`.first(rowId, g.id)
    var c = row == null ? null : Card.get(row["cardId"])
    var opt = g.pruebaCarta == null ? null : (Card.get(g.pruebaCarta) == null ? null : Card.get(g.pruebaCarta).option(g.pruebaOpcion))
    var parity = opt != null && (opt["tipoPrueba"] == "cara" || opt["tipoPrueba"] == "seca")
    if (c == null) {
      aviso = "Esa carta ya no está en tu mano."
    } else if (g.fase != "prueba" && g.fase != "listo") {
      aviso = "Esa Maniobra se usa antes de tirar."
    } else if (g.jugadas > 0) {
      aviso = "Ya jugaron una carta este turno."
    } else if (c.effect == "flip_parity" && !parity) {
      aviso = "Giro Brusco solo sirve en pruebas de Cara o Seca."
    } else if (c.effect == "flip_parity" && g.tirado) {
      aviso = "Giro Brusco se prepara antes de tirar."
    } else if (c.effect == "reroll_parity" && !parity) {
      aviso = "Focos Abisales solo sirven en pruebas de Cara o Seca."
    } else if (c.effect == "reroll_parity" && g.tirado) {
      aviso = "Focos Abisales se preparan antes de tirar."
    } else if (c.effect == "reduce_damage" && g.tirado) {
      aviso = "Blindaje de Titanio se prepara antes de tirar."
    } else if (g.tirado) {
      aviso = "Todas las Maniobras se juegan antes de tirar: se comprometen a ciegas."
    } else if (c.effect == "plus_two") {
      `UPDATE games SET bonus = bonus + 2, jugadas = 1 WHERE id = ?`.query(g.id)
      Game.move(rowId, "descarteEquipo")
      Game.log(g.id, "Turbo de Emergencia: +2 al total.")
    } else if (c.effect == "flip_parity") {
      `UPDATE games SET giro = 1, jugadas = 1 WHERE id = ?`.query(g.id)
      Game.move(rowId, "descarteEquipo")
      Game.log(g.id, "Giro Brusco preparado: el dado se va a invertir.")
    } else if (c.effect == "reroll_parity") {
      `UPDATE games SET focosM = 1, jugadas = 1 WHERE id = ?`.query(g.id)
      Game.move(rowId, "descarteEquipo")
      Game.log(g.id, "Focos Abisales preparados: si falla, relanzan el dado.")
    } else if (c.effect == "reduce_damage") {
      `UPDATE games SET blindajeM = 1, jugadas = 1 WHERE id = ?`.query(g.id)
      Game.move(rowId, "descarteEquipo")
      Game.log(g.id, "Blindaje de Titanio preparado: −1 daño al Escudo.")
    } else if (c.effect == "reroll_all") {
      `UPDATE games SET suerte = 1, jugadas = 1 WHERE id = ?`.query(g.id)
      Game.move(rowId, "descarteEquipo")
      Game.log(g.id, "Suerte del Principiante preparada: si falla, se tira de nuevo.")
    } else if (c.effect == "cancel_shield_loss") {
      `UPDATE games SET cebo = 1, jugadas = 1 WHERE id = ?`.query(g.id)
      Game.move(rowId, "descarteEquipo")
      Game.log(g.id, "Lanzar Cebo: el próximo daño al Escudo se cancela.")
    } else if (c.effect == "no_energy_cost") {
      `UPDATE games SET ahorro = 1, jugadas = 1 WHERE id = ?`.query(g.id)
      Game.move(rowId, "descarteEquipo")
      Game.log(g.id, "Ahorro de Oxígeno: en este misterio no gastan Energía.")
    } else {
      aviso = "Esa carta no se usa durante la prueba."
    }
  } else if (accion == "reroll") {
    var c = g.pruebaCarta == null ? null : Card.get(g.pruebaCarta)
    var opt = c == null ? null : c.option(g.pruebaOpcion)
    if (opt == null || g.fase != "reroll") {
      aviso = "No hay una tirada pendiente para repetir."
    } else {
      var solaUna = g.focosM && !g.suerte
      var origen = Request.post("origen", "app")
      var d1 = 0
      var d2 = g.dado2
      var valido = true
      if (origen == "mesa") {
        d1 = Num.fromString(Request.post("d1", "0"))
        if (!solaUna && opt["dados"] == 2) d2 = Num.fromString(Request.post("d2", "0"))
        if (d1 < 1 || d1 > 6) valido = false
        if (!solaUna && opt["dados"] == 2 && (d2 < 1 || d2 > 6)) valido = false
      } else {
        d1 = Game.roll(1)[0]
        if (!solaUna && opt["dados"] == 2) d2 = Game.roll(1)[0]
      }
      if (!valido) {
        aviso = "Elegí valores de 1 a 6 para cada dado."
      } else {
        var carta = g.suerte ? "Suerte del Principiante" : "Focos Abisales"
        var tirada = d1.toString + ((!solaUna && opt["dados"] == 2) ? " y " + d2.toString : "")
        `UPDATE games SET dado1 = ?, dado2 = ?, fase = 'prueba', tirado = 1, suerte = 0, focosM = 0 WHERE id = ?`.query(d1, d2, g.id)
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
    }
  } else if (accion == "resolver") {
    var res = Game.resolve(g.id)
    if (res["error"] != "") aviso = res["error"]
  } else if (accion == "usar_ayuda") {
    if (g.fase == "apoyo") {
      aviso = "Primero elegí el recurso de la maniobra de apoyo pendiente."
    } else if (g.fase == "emboscada") {
      aviso = "Primero elijan la emboscada inicial."
    } else {
      var row = `SELECT id, cardId FROM game_cards WHERE id = ? AND gameId = ? AND zone = 'ayuda'`.first(rowId, g.id)
      if (row == null) {
        aviso = "Esa maniobra de apoyo ya no está en el área."
      } else {
        var c = Card.get(row["cardId"])
        `UPDATE games SET fase = 'apoyo', apoyoCarta = ?, apoyoOrigen = 'ayuda', fasePrevia = ? WHERE id = ?`.query(row["id"], g.fase, g.id)
        Game.log(g.id, "Usan la maniobra de apoyo: " + c.name + ".")
      }
    }
  } else if (accion == "elegir_apoyo") {
    var recurso = Request.post("recurso", "energia")
    var row = g.apoyoCarta == null ? null : `SELECT id, cardId FROM game_cards WHERE id = ? AND gameId = ?`.first(g.apoyoCarta, g.id)
    var c = row == null ? null : Card.get(row["cardId"])
    if (c == null) {
      aviso = "No hay una maniobra de apoyo pendiente."
    } else {
      var v = c.value
      var volver = g.fasePrevia == null ? "listo" : g.fasePrevia
      if (recurso == "escudo") {
        `UPDATE games SET escudo = MIN(12, escudo + ?), fase = ?, apoyoCarta = NULL, apoyoOrigen = NULL, fasePrevia = NULL WHERE id = ?`.query(v, volver, g.id)
        Game.log(g.id, "Maniobra de apoyo " + c.name + ": +" + v.toString + " Escudo.")
      } else {
        `UPDATE games SET energia = MIN(12, energia + ?), fase = ?, apoyoCarta = NULL, apoyoOrigen = NULL, fasePrevia = NULL WHERE id = ?`.query(v, volver, g.id)
        Game.log(g.id, "Maniobra de apoyo " + c.name + ": +" + v.toString + " Energía.")
      }
      Game.move(row["id"], "descarteEquipo")
    }
  } else if (accion == "cancelar") {
    if (g.tirado) {
      aviso = "Ya tiraron: no pueden volver atrás. Resuelvan la prueba."
    } else {
      `UPDATE games SET fase = 'listo', pruebaCarta = NULL, pruebaOpcion = NULL, dado1 = 0, dado2 = 0, tirado = 0, bonus = 0, cebo = 0, ahorro = 0, giro = 0, suerte = 0 WHERE id = ?`.query(g.id)
      Game.log(g.id, "El equipo duda y vuelve a mirar las cartas.")
    }
  } else if (accion == "terminar") {
    if (g.fase != "resuelto") {
      aviso = "Primero resuelvan un misterio."
    } else {
      // Al cerrar el turno se descarta toda la mano. No hay azar.
      var mano = `SELECT id, cardId FROM game_cards WHERE gameId = ? AND zone = 'mano'`.fetch(g.id)
      if (!mano.isEmpty) {
        var nombres = []
        for (m in mano) {
          var c = Card.get(m["cardId"])
          if (c != null) nombres.add(c.name)
          Game.move(m["id"], "descarteEquipo")
        }
        Game.log(g.id, "Se descarta toda la mano: " + nombres.join(", ") + ".")
      }

      var g2 = Game.find(g.id)
      if (g2.ahorro) {
        Game.log(g.id, "Ahorro de Oxígeno: el consumo del submarino no gasta Energía.")
      } else {
        var en = g2.energia - 1
        if (en < 0) en = 0
        `UPDATE games SET energia = ? WHERE id = ?`.query(en, g.id)
        Game.log(g.id, "El submarino consume 1 Energía.")
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

      // La derrota no es inmediata: solo al cerrar el turno con ambos en 0.
      var gFin = Game.find(g.id)
      if (gFin != null && gFin.energia <= 0 && gFin.escudo <= 0) {
        `UPDATE games SET status = 'derrota' WHERE id = ?`.query(g.id)
        Game.log(g.id, "La Energía y el Escudo llegaron a cero al cerrar el turno. La expedición termina.")
        return Response.redirect("/juego")
      }

      `UPDATE games SET jugador = 1, turno = turno + 1, fase = 'listo', pruebaCarta = NULL, pruebaOpcion = NULL, dado1 = 0, dado2 = 0, tirado = 0, bonus = 0, cebo = 0, ahorro = 0, blindajeUsado = 0, blindajeM = 0, focosUsado = 0, focosM = 0, jugadas = 0, resueltas = 0, resultado = NULL, giro = 0, suerte = 0, empujado = 0, pistasTurno = 0 WHERE id = ?`.query(g.id)
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
      var enMano = Game.count(g.id, "mano")
      var aRobar = 3 - enMano
      if (aRobar > 0) Game.draw(g.id, "equipo", "mano", aRobar)
      Game.log(g.id, "Turno " + (g.turno + 1).toString + ".")
    }
  }

  var qs = ""
  if (aviso != "") qs = "?aviso=" + Util.urlEncode(aviso)
  if (anim != "") qs = qs + (qs == "" ? "?" : "&") + "anim=" + anim
  return Response.redirect("/juego" + qs)
}

// Primer ingreso con cantidad de jugadores en la URL
if (g == null && (Request.get("jugadores") != null || Request.get("modo") != null)) {
  var modo = Request.get("modo", "casual")
  if (modo != "experto" && modo != "casual" && modo != "facil") modo = "casual"
  session.set("modo", modo)
  var id = Game.create(1, modo)
  session.set("gameId", id.toString)
  return Response.redirect("/juego")
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
      <p class="hint">Siempre 3 cartas de Misterio en la mesa y la mano se repone a 3. No importa cuántos jueguen.</p>
      <form method="post" class="panel start-form">
        <input type="hidden" name="accion" value="nueva" />
        <label for="modo"><strong>Modo</strong></label>
        <select id="modo" name="modo">
          <option value="experto" {{ modoInicial == "experto" ? "selected" : "" }}>Experto — 6 y 6, sin apoyos</option>
          <option value="casual" {{ modoInicial == "casual" ? "selected" : "" }}>Normal — 6 y 6 + 1 carta de apoyo</option>
          <option value="facil" {{ modoInicial == "facil" ? "selected" : "" }}>Asistido — 6 y 6 + 2 cartas de apoyo</option>
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
var ayuda = Game.cardsIn(g.id, "ayuda")
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

var pendingCard = g.pruebaCarta == null ? null : Card.get(g.pruebaCarta)
var pendingOpt = pendingCard == null ? null : pendingCard.option(g.pruebaOpcion)

var supportCard = null
if (g.apoyoCarta != null) {
  var srow = `SELECT cardId FROM game_cards WHERE id = ?`.first(g.apoyoCarta)
  if (srow != null) supportCard = Card.get(srow["cardId"])
}

var pendingParity = pendingOpt != null && (pendingOpt["tipoPrueba"] == "cara" || pendingOpt["tipoPrueba"] == "seca")
var maniobrasParidad = ["flip_parity", "reroll_parity"]

var handCount = hand.count
var focoHref = "#cartas-activas"
if (g.fase == "apoyo") focoHref = "#apoyo"
if (g.fase == "prueba") focoHref = "#prueba"
if (g.fase == "reroll") focoHref = "#reroll"
if (g.fase == "resuelto") focoHref = "#resultado"
var puedeElegir = g.status == "activa" && g.fase == "listo" && g.resueltas == 0
var puedeJugar = g.status == "activa" && g.jugadas == 0 && (g.fase == "listo" || (g.fase == "prueba" && !g.tirado))
var maniobrasPrueba = hand.where { |h| ["plus_two", "reroll_all", "cancel_shield_loss", "no_energy_cost", "reduce_damage", "flip_parity", "reroll_parity"].contains(h["card"].effect) }.toList

var finalTitulo = "La expedición continúa"
var finalTexto = ""
if (g.status == "victoria") {
  finalTitulo = "Lo encontraron"
  finalTexto = "Seis Pistas. La última sombra se hunde en la fosa y, por un instante, el Megalodón está ahí. El mundo seguirá creyendo que es un mito, como el monstruo del lago Ness. Ustedes ya saben la verdad."
} else if (g.status == "derrota") {
  finalTitulo = "La expedición se pierde"
  finalTexto = "Al cerrar el turno, la Energía y el Escudo estaban en 0. El submarino se queda sin aire y sin casco en la oscuridad."
}

// ---------- Mesa ----------

var modoLabel = g.modo == "facil" ? "Asistido" : (g.modo == "casual" ? "Normal" : "Experto")

var faseEyebrow = "Encuentro"
var fasePrompt = "Elijan un Misterio de la mesa y resuelvan una de sus opciones."
if (g.fase == "emboscada") {
  faseEyebrow = "Emboscada"
  fasePrompt = "Entraron varias emboscadas a la vez: elijan cuál cobra."
} else if (g.fase == "apoyo") {
  faseEyebrow = "Maniobra de apoyo"
  fasePrompt = "Elijan el recurso que entrega la carta. Después se descarta."
} else if (g.fase == "prueba") {
  faseEyebrow = g.tirado ? "Prueba en curso" : "Prueba de dados"
  fasePrompt = g.tirado ? "La tirada está hecha. Resuelvan la prueba para cobrar el efecto." : "Comprometan una Maniobra o tiren los dados. También pueden cargar lo que salió en la mesa."
} else if (g.fase == "reroll") {
  faseEyebrow = "Tirada fallida"
  fasePrompt = "Pueden volver a tirar o aceptar el fallo."
} else if (g.fase == "resuelto") {
  faseEyebrow = "Resultado"
  fasePrompt = "Cierren el turno: se descarta la mano y se repone la mesa."
}

var mesaFaltan = 3 - mesa.count
if (mesaFaltan < 0) mesaFaltan = 0
var manoFaltan = 3 - handCount
if (manoFaltan < 0) manoFaltan = 0
var ultimaLinea = logs.isEmpty ? "Todavía no pasó nada." : logs[0]["text"]

// ---------- Vista ----------

return Layout.render(<main class="game table-board" data-moves="{{ movesJson }}" data-anim="{{ anim }}" data-outcome="{{ g.status == "victoria" || g.status == "derrota" ? g.status : "" }}">
  {{ g.status == "activa" && <aside class="game-rail" aria-label="Menú de la expedición">
    <div class="game-rail-body">
      <div class="rail-state">
        <span class="rail-stat rail-energia" title="Energía {{ g.energia }}"><b>{{ g.energia }}</b><small>⚡</small></span>
        <span class="rail-stat rail-escudo" title="Escudo {{ g.escudo }}"><b>{{ g.escudo }}</b><small>🛡️</small></span>
        <span class="rail-stat rail-pistas" title="Pistas {{ g.pistas }}"><b>{{ g.pistas }}</b><small>🔍</small></span>
      </div>
      <p class="rail-meta">Turno {{ g.turno }}</p>
      <nav class="rail-nav">
        <a href="{{ focoHref }}" aria-label="Ir a la acción actual">{{ Layout.icon("🌊") }} <span class="rail-label">Mesa</span><span class="rail-label-short">Mesa</span> <b>{{ mesa.count }}</b></a>
        <a href="#mano" aria-label="Ver la mano">{{ Layout.icon("🖐️") }} <span class="rail-label">Mano</span><span class="rail-label-short">Mano</span> <b>{{ handCount }}</b></a>
        <a href="#herramientas" class="{{ activeTool == null ? "is-empty" : "" }}" data-tool="{{ activeTool == null ? "Sin Herramienta activa" : activeTool.name }}" title="{{ activeTool == null ? "Sin Herramienta activa" : activeTool.name }}" aria-label="Herramienta: {{ activeTool == null ? "ninguna activa" : activeTool.name }}">
          {{ Layout.icon("🔧") }} <span class="rail-label">Herramienta</span><span class="rail-label-short">Herram.</span>
          <span class="rail-dot {{ activeTool == null ? "" : "on" }}" aria-hidden="true"></span>
        </a>
        <a href="#ayuda" class="{{ ayuda.isEmpty ? "is-empty" : "" }}" aria-label="Apoyo del equipo">{{ Layout.icon("🎒") }} <span class="rail-label">Apoyo</span><span class="rail-label-short">Apoyo</span> <b>{{ ayuda.count }}</b></a>
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
        <a href="/reglas">Reglas</a>
        <a href="/">Inicio</a>
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
    <div class="felt-top">
      <section class="gauges-board" aria-label="Contadores de la expedición">
        <article class="counter">
          {{ Layout.die(g.energia, "die-teal") }}
          <span class="counter-body">
            <span class="counter-label">Energía</span>
            <span class="counter-value">{{ g.energia }}</span>
          </span>
        </article>
        <article class="counter">
          {{ Layout.die(g.escudo, "die-gold") }}
          <span class="counter-body">
            <span class="counter-label">Escudo</span>
            <span class="counter-value">{{ g.escudo }}</span>
          </span>
        </article>
        <article class="counter">
          {{ Layout.die(g.pistas, "die-coral") }}
          <span class="counter-body">
            <span class="counter-label">Pistas</span>
            <span class="counter-value">{{ g.pistas }}</span>
          </span>
        </article>
      </section>
      <div class="felt-prompt" role="status">
        <p class="eyebrow">{{ faseEyebrow }}</p>
        <p class="felt-prompt-text">{{ fasePrompt }}</p>
      </div>
      <p class="turn-plate"><span>Turno</span><b>{{ g.turno }}</b></p>
    </div>

    {{ aviso != "" && <p class="aviso" role="status">{{ aviso }}</p> }}

    {{ g.fase == "apoyo" && supportCard != null && <section class="tray support-choice" id="apoyo">
      <div class="tray-main">
        <h2>{{ supportCard.name }}</h2>
        <p>Elegí el recurso. La carta se gasta.</p>
      </div>
      <div class="tray-card">
        <span class="card-emoji" aria-hidden="true">{{ supportCard.emoji }}</span>
        <span class="card-name">{{ supportCard.name }}</span>
      </div>
      <div class="action-row">
        <form method="post">
          <input type="hidden" name="accion" value="elegir_apoyo" />
          <input type="hidden" name="recurso" value="energia" />
          <button class="btn btn-primary"><span class="chip chip-energia">{{ Layout.icon("⚡") }} +{{ supportCard.value }}</span> Energía</button>
        </form>
        <form method="post">
          <input type="hidden" name="accion" value="elegir_apoyo" />
          <input type="hidden" name="recurso" value="escudo" />
          <button class="btn btn-primary"><span class="chip chip-escudo">{{ Layout.icon("🛡️") }} +{{ supportCard.value }}</span> Escudo</button>
        </form>
      </div>
    </section> }}

    {{ g.fase == "reroll" && pendingCard != null && pendingOpt != null && <section class="tray reroll-panel" id="reroll">
      <div class="tray-main">
        <h2>Pueden volver a tirar</h2>
        <p class="muted">{{ pendingCard.name }} — {{ pendingOpt["texto"] }}</p>
        <p>{{ g.focosM ? "Focos Abisales: relancen el dado." : "Suerte del Principiante: vuelvan a tirar los dados." }}</p>
      </div>
      <div class="tray-dice">
        {{ Layout.die(g.dado1, "die-large dice-roll") }}
        {{ pendingOpt["dados"] == 2 && Layout.die(g.dado2, "die-large dice-roll") }}
      </div>
      <section class="roll-controls tray-actions">
        <form method="post" class="roll-form">
          <input type="hidden" name="accion" value="reroll" />
          <input type="hidden" name="origen" value="app" />
          <button class="btn btn-primary">Volver a tirar en la app</button>
        </form>
        <form method="post" class="roll-form">
          <input type="hidden" name="accion" value="reroll" />
          <input type="hidden" name="origen" value="mesa" />
          <label class="die-select">Dado 1
            <select name="d1">
              {{ [1, 2, 3, 4, 5, 6].map{|n| <option value="{{ n }}">{{ n }}</option>} }}
            </select>
          </label>
          {{ g.suerte && pendingOpt["dados"] == 2 && <label class="die-select">Dado 2
            <select name="d2">
              {{ [1, 2, 3, 4, 5, 6].map{|n| <option value="{{ n }}">{{ n }}</option>} }}
            </select>
          </label> }}
          <button class="btn btn-ghost">Ya tiré en la mesa</button>
        </form>
        <form method="post">
          <input type="hidden" name="accion" value="aceptar" />
          <button class="btn btn-ghost btn-small">Aceptar el fallo</button>
        </form>
      </section>
    </section> }}

    {{ g.fase == "prueba" && pendingCard != null && <section class="tray test-panel" id="prueba">
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
        {{ g.bonus > 0 && <p class="hint">Bonificación acumulada: +{{ g.bonus }} al total.</p> }}
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
        <p class="hint dice-help">CARA = par (2, 4, 6). SECA = impar (1, 3, 5).</p>
      </div>

      {{ !g.tirado && <section class="roll-controls tray-actions">
        {{ g.jugadas == 0 && maniobrasPrueba.count > 0 && <section class="maneuvers">
          <p class="hint">Las Maniobras se juegan <strong>antes</strong> de tirar: se comprometen a ciegas.</p>
          <div class="action-row">
            {{ maniobrasPrueba.map{|h| <form method="post" class="inline-form">
              <input type="hidden" name="accion" value="maniobra" />
              <input type="hidden" name="rowId" value="{{ h["rowId"] }}" />
              <button class="btn btn-ghost btn-small"><span aria-hidden="true">{{ h["card"].emoji }} {{ h["card"].name }}
                {{ h["card"].helpChips.map{|c| <span class="chip {{ c["cls"] }}" title="{{ c["title"] }}">{{ Layout.icon(c["icon"]) }} {{ c["text"] }}</span>} }}
              </button>
            </form>} }}
          </div>
        </section> }}
        {{ g.jugadas > 0 && <p class="hint">Ya jugaron su carta de Equipo este turno. Tiren cuando quieran.</p> }}
        <form method="post" class="roll-form">
          <input type="hidden" name="accion" value="tirar" />
          <button class="btn btn-primary">Tirar en la app</button>
        </form>
        <form method="post" class="roll-form">
          <input type="hidden" name="accion" value="mesa" />
          <label class="die-select">Dado 1
            <select name="d1">
              {{ [1, 2, 3, 4, 5, 6].map{|n| <option value="{{ n }}">{{ n }}</option>} }}
            </select>
          </label>
          {{ pendingOpt["dados"] == 2 && <label class="die-select">Dado 2
            <select name="d2">
              {{ [1, 2, 3, 4, 5, 6].map{|n| <option value="{{ n }}">{{ n }}</option>} }}
            </select>
          </label> }}
          <button class="btn btn-ghost">Ya tiré en la mesa</button>
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
        <p class="hint">Al cerrar el turno se descarta toda la mano, se roba 1 del Mazo de Misterios y se repone la mano a 3.</p>
        <form method="post">
          <input type="hidden" name="accion" value="terminar" />
          <button class="btn btn-primary">Terminar turno y reponer la mesa</button>
        </form>
      </div>
    </section> }}

    <section class="zone zone-encounter {{ g.fase == "emboscada" ? "is-ambush" : "" }}" id="cartas-activas">
      <div class="zone-head">
        <h2>Encuentro</h2>
        <span class="zone-count">{{ mesa.count }} de 3 Misterios</span>
      </div>
      <div class="zone-body">
        <div class="card-row">
          {{ mesa.map{|item| <article class="card {{ (puedeElegir || (g.fase == "emboscada" && item["card"].entry != "")) ? "is-actionable" : "" }} {{ pendingCard != null && item["card"].id == pendingCard.id ? "is-pending" : "" }}" data-family="{{ item["card"].family }}" data-row="{{ item["rowId"] }}">
            <span class="card-art"><span class="card-emoji" aria-hidden="true">{{ item["card"].emoji }}</span></span>
            <span class="card-family">{{ item["card"].family == "exploracion" ? "Exploración" : (item["card"].family == "peligro" ? "Peligro" : "Dilema") }}{{ item["card"].entry != "" ? " · Emboscada" : "" }} · <span class="card-id">{{ item["card"].id }}</span></span>
            <h3>{{ item["card"].name }}</h3>
            {{ item["card"].entry != "" && <p class="entry-badge" title="El costo de entrar se resuelve una sola vez, cuando la carta entra a la mesa. Si ya está en la mesa, no se vuelve a cobrar.">Al entrar <span class="muted entry-done">ya resuelto</span>
              {{ item["card"].entryChips.map{|c| <span class="chip {{ c["cls"] }}" title="{{ c["title"] }}" aria-label="{{ c["title"] }}">{{ Layout.icon(c["icon"]) }} {{ c["text"] }}</span>} }}
            </p> }}
            <section class="card-text">{{ item["card"].body }}</section>
            <form method="post" class="card-action option-form ambush-action {{ item["card"].entry == "" ? "is-hidden" : "" }}">
              <input type="hidden" name="accion" value="elegir_emboscada" />
              <input type="hidden" name="rowId" value="{{ item["rowId"] }}" />
              <button class="btn btn-primary btn-small">Sufrir esta emboscada</button>
            </form>
            <ul class="card-options">
              {{ item["card"].options.map{|o| <li class="option-row">
                <form method="post" class="option-form">
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
          <button type="button" class="pile" id="pila-misterio" data-pile="misterio" aria-haspopup="dialog" aria-label="Mazos y descartes · {{ mazoJuego }} Misterios en el mazo" aria-controls="mazos-dialog">
            <span class="pile-stack"><img src="/img/dorso-misterio-thumb.png" width="84" height="118" alt="" /><span class="pile-count">{{ mazoJuego }}</span></span>
            <span class="pile-name">Misterios</span>
          </button>
          <button type="button" class="pile" id="pila-descarte-juego" data-pile="descarteJuego" aria-haspopup="dialog" aria-label="Mazos y descartes · {{ descarteJuego }} Misterios en el descarte" aria-controls="mazos-dialog">
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
        <span class="zone-count">Herramienta y apoyo</span>
      </div>
      <div class="zone-body">
        <div class="slot-column" id="herramientas">
          <p class="slot-label">{{ Layout.icon("🔧") }} Herramienta activa <span>{{ tools.count }} / 1</span></p>
          {{ tools.map{|t| <article class="card card-tool" data-family="herramienta" data-row="{{ t["rowId"] }}">
            <span class="card-art"><span class="card-emoji" aria-hidden="true">{{ t["card"].emoji }}</span></span>
            <span class="card-family">{{ Layout.icon(t["card"].typeIcon) }} {{ t["card"].typeLabel }} · <span class="card-id">{{ t["card"].id }}</span></span>
            <h3>{{ t["card"].name }}</h3>
            <span class="use-badge {{ t["card"].useClass }}" title="{{ t["card"].useHint }}">{{ Layout.icon(t["card"].useIcon) }} {{ t["card"].useLabel }}</span>
            <div class="effect-chips">
              {{ t["card"].helpChips.map{|h| <span class="chip {{ h["cls"] }}" title="{{ h["title"] }}" aria-label="{{ h["title"] }}">{{ Layout.icon(h["icon"]) }} {{ h["text"] }}</span>} }}
            </div>
            <section class="card-text">{{ t["card"].body }}</section>
          </article>} }}
          {{ tools.isEmpty && <article class="card card-slot card-slot-sm" aria-hidden="true">
            <span class="slot-mark">{{ Layout.icon("🔧") }}</span>
            <span class="slot-text">Sin Herramienta</span>
          </article> }}
        </div>

        <div class="slot-column" id="ayuda">
          <p class="slot-label">{{ Layout.icon("🎒") }} Apoyo del equipo <span>{{ ayuda.count }}</span></p>
          {{ ayuda.map{|a| <article class="card card-support" data-family="apoyo" data-row="{{ a["rowId"] }}">
            <span class="card-ribbon">🎁 Apoyo</span>
            <span class="card-art"><span class="card-emoji" aria-hidden="true">{{ a["card"].emoji }}</span></span>
            <span class="card-family">{{ Layout.icon(a["card"].typeIcon) }} {{ a["card"].typeLabel }} · <span class="card-id">{{ a["card"].id }}</span></span>
            <h3>{{ a["card"].name }}</h3>
            <span class="use-badge {{ a["card"].useClass }}" title="{{ a["card"].useHint }}">{{ Layout.icon(a["card"].useIcon) }} {{ a["card"].useLabel }}</span>
            <div class="effect-chips">
              {{ a["card"].helpChips.map{|h| <span class="chip {{ h["cls"] }}" title="{{ h["title"] }}" aria-label="{{ h["title"] }}">{{ Layout.icon(h["icon"]) }} {{ h["text"] }}</span>} }}
            </div>
            <section class="card-text">{{ a["card"].body }}</section>
            <form method="post">
              <input type="hidden" name="accion" value="usar_ayuda" />
              <input type="hidden" name="rowId" value="{{ a["rowId"] }}" />
              <button class="btn btn-ghost btn-small" {{ g.fase == "apoyo" ? "disabled" : "" }}>Usar maniobra</button>
            </form>
          </article>} }}
          {{ ayuda.isEmpty && <article class="card card-slot card-slot-sm" aria-hidden="true">
            <span class="slot-mark">{{ Layout.icon("🎒") }}</span>
            <span class="slot-text">Sin apoyo</span>
          </article> }}
        </div>

        {{ peekCard != null && <div class="peek-column">
          <p class="slot-label">{{ Layout.icon("🔍") }} Sonar de Alta Frecuencia</p>
          <section class="card peek" data-family="{{ peekCard.family }}">
            <span class="card-art"><span class="card-emoji" aria-hidden="true">{{ peekCard.emoji }}</span></span>
            <span class="card-family">Próximo Misterio · <span class="card-id">{{ peekCard.id }}</span></span>
            <h3>{{ peekCard.name }}</h3>
            {{ peekCard.entry != "" && <p class="entry-badge">Al entrar
              {{ peekCard.entryChips.map{|c| <span class="chip {{ c["cls"] }}" title="{{ c["title"] }}">{{ Layout.icon(c["icon"]) }} {{ c["text"] }}</span>} }}
            </p> }}
            <section class="card-text">{{ peekCard.body }}</section>
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

    <section class="zone zone-hand" id="mano">
      <div class="zone-head">
        <h2>Mano del equipo</h2>
        <span class="zone-count">{{ handCount }} cartas · se repone a 3</span>
      </div>
      <div class="card-row hand-main">
        {{ hand.map{|h| <article class="card {{ puedeJugar ? "is-actionable" : "is-locked" }}" data-row="{{ h["rowId"] }}" data-family="{{ h["card"].isSupport ? "apoyo" : (h["card"].isTool ? "herramienta" : "maniobra") }}">
          {{ h["card"].isSupport && <span class="card-ribbon">🎁 Apoyo</span> }}
          <span class="card-art"><span class="card-emoji" aria-hidden="true">{{ h["card"].emoji }}</span></span>
          <span class="card-family">{{ Layout.icon(h["card"].typeIcon) }} {{ h["card"].typeLabel }} · <span class="card-id">{{ h["card"].id }}</span></span>
          <h3>{{ h["card"].name }}</h3>
          <span class="use-badge {{ h["card"].useClass }}" title="{{ h["card"].useHint }}">{{ Layout.icon(h["card"].useIcon) }} {{ h["card"].useLabel }}</span>
          <div class="effect-chips">
            {{ h["card"].helpChips.map{|h2| <span class="chip {{ h2["cls"] }}" title="{{ h2["title"] }}" aria-label="{{ h2["title"] }}">{{ Layout.icon(h2["icon"]) }} {{ h2["text"] }}</span>} }}
          </div>
          <section class="card-text">{{ h["card"].body }}</section>
          <div class="card-action">
            {{ h["card"].playNow && <form method="post" class="inline-form">
              <input type="hidden" name="accion" value="jugar" />
              <input type="hidden" name="rowId" value="{{ h["rowId"] }}" />
              <button class="btn btn-primary btn-small" {{ puedeJugar ? "" : "disabled" }}>Jugar</button>
            </form> }}
            {{ !h["card"].playNow && (h["card"].isPrep || (pendingParity && maniobrasParidad.contains(h["card"].effect))) && <form method="post" class="inline-form">
              <input type="hidden" name="accion" value="maniobra" />
              <input type="hidden" name="rowId" value="{{ h["rowId"] }}" />
              <button class="btn btn-ghost btn-small" {{ puedeJugar ? "" : "disabled" }}>Preparar</button>
            </form> }}
            {{ !h["card"].playNow && !h["card"].isPrep && !(pendingParity && maniobrasParidad.contains(h["card"].effect)) && <p class="hint card-hint">Elegí un Misterio de Cara o Seca y usala antes de tirar.</p> }}
          </div>
        </article>} }}
        {{ manoFaltan > 0 && (1..manoFaltan).map{|i| <article class="card card-slot card-slot-sm" aria-hidden="true">
          <span class="slot-mark">{{ Layout.icon("🖐️") }}</span>
          <span class="slot-text">Lugar libre</span>
        </article>} }}
      </div>
      <p class="zone-foot">{{ g.jugadas == 0 ? "Todavía pueden jugar 1 carta de Equipo este turno." : "Ya jugaron su carta de Equipo este turno." }} Al cerrar el turno se descarta toda la mano y se repone.</p>
    </section>
  </section> }}

  {{ g.status != "activa" && <section class="panel ending {{ g.status }}">
    <p class="eyebrow">Fin de la partida</p>
    <h2>{{ finalTitulo }}</h2>
    <p>{{ finalTexto }}</p>
    <div class="gauges-board ending-gauges">
      <article class="counter">
        {{ Layout.die(g.energia, "die-teal") }}
        <span class="counter-body">
          <span class="counter-label">Energía</span>
          <span class="counter-value">{{ g.energia }}</span>
        </span>
      </article>
      <article class="counter">
        {{ Layout.die(g.escudo, "die-gold") }}
        <span class="counter-body">
          <span class="counter-label">Escudo</span>
          <span class="counter-value">{{ g.escudo }}</span>
        </span>
      </article>
      <article class="counter">
        {{ Layout.die(g.pistas, "die-coral") }}
        <span class="counter-body">
          <span class="counter-label">Pistas</span>
          <span class="counter-value">{{ g.pistas }}</span>
        </span>
      </article>
    </div>
    <form method="post">
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
          <img src="/img/dorso-misterio-thumb.png" width="42" height="59" alt="" />
          <div>
            <h3>Mazo de Misterios</h3>
            <p><strong>{{ mazoJuego }}</strong> en el mazo · <strong>{{ descarteJuego }}</strong> en descarte</p>
          </div>
        </div>
        <h4>Descartadas</h4>
        {{ descarteJuegoCards.isEmpty && <p class="muted">Todavía no hay Misterios en el descarte.</p> }}
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
