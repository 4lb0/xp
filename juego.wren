import "_app/template" for Layout
import "_app/cards" for Card
import "_app/game" for Game

var session = Session.new()
var g = Game.find(session.get("gameId"))

// ---------- Acciones ----------

if (Request.isPost) {
  var accion = Request.post("accion", "")

  if (accion == "nueva") {
    if (g != null) Game.destroy(g.id)
    var n = Num.fromString(Request.post("jugadores", "3"))
    if (n < 2) n = 2
    if (n > 6) n = 6
    var modo = Request.post("modo", "normal") == "facil" ? "facil" : "normal"
    var id = Game.create(n, modo)
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

  if (g.status != "activa") {
    return Response.redirect("/juego?aviso=" + Util.urlEncode("La expedición terminó. Empezá una nueva."))
  }

  var rowId = Request.post("rowId", "")
  var optLabel = Request.post("opt", "")

  if (accion == "jugar") {
    var row = `SELECT * FROM game_cards WHERE id = ? AND gameId = ? AND zone = 'mano'`.first(rowId, g.id)
    if (row == null) {
      aviso = "Esa carta ya no está en tu mano."
    } else if (g.jugadas > 0) {
      aviso = "Ya jugaron una carta este turno."
    } else {
      var c = Card.get(row["cardId"])
      if (c == null) {
        aviso = "No pudimos leer esa carta."
      } else if (c.isTool) {
        if (Game.count(g.id, "herramientas") >= 4) {
          var oldest = Game.rows(g.id, "herramientas").first
          if (oldest != null) Game.move(oldest["id"], "descarte")
          Game.log(g.id, "Se retira una Herramienta para hacer lugar.")
        }
        Game.move(rowId, "herramientas")
        `UPDATE games SET jugadas = 1 WHERE id = ?`.query(g.id)
        Game.log(g.id, "Herramienta en juego: " + c.name + ".")
      } else if (c.effect == "heal_shield") {
        Game.apply(g.id, g, {"pistas": 0, "energia": 0, "escudo": 1}, true, [])
        Game.move(rowId, "descarte")
        `UPDATE games SET jugadas = 1 WHERE id = ?`.query(g.id)
        Game.log(g.id, "Soldadura Submarina: +3 Escudo.")
      } else if (c.effect == "heal_energy") {
        Game.apply(g.id, g, {"pistas": 0, "energia": 2, "escudo": 0}, true, [])
        Game.move(rowId, "descarte")
        `UPDATE games SET jugadas = 1 WHERE id = ?`.query(g.id)
        Game.log(g.id, "Batería de Respaldo: +2 Energía.")
      } else if (c.effect == "clue_for_energy") {
        Game.apply(g.id, g, {"pistas": 1, "energia": -1, "escudo": 0}, true, [])
        Game.move(rowId, "descarte")
        `UPDATE games SET jugadas = 1 WHERE id = ?`.query(g.id)
        Game.log(g.id, "Análisis Rápido: −1 Energía, +1 Pista.")
      } else if (c.effect == "discard_active") {
        var activas = Game.rows(g.id, "mesa")
        if (!activas.isEmpty) {
          Game.move(activas[0]["id"], "descarte")
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
        Game.move(rowId, "descarte")
        `UPDATE games SET jugadas = 1 WHERE id = ?`.query(g.id)
        Game.log(g.id, "Señuelo Luminoso: una carta activa se cambia por otra.")
      } else {
        aviso = "Esa Maniobra se juega durante una prueba de dados."
      }
    }
  } else if (accion == "descartar") {
    var row = `SELECT id FROM game_cards WHERE id = ? AND gameId = ? AND zone = 'mano'`.first(rowId, g.id)
    if (row != null) {
      Game.move(row["id"], "descarte")
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
        `UPDATE games SET fase = 'prueba', pruebaCarta = ?, pruebaOpcion = ?, dado1 = 0, dado2 = 0, tirado = 0, bonus = 0 WHERE id = ?`.query(row["cardId"], optLabel, g.id)
        Game.log(g.id, "Eligen " + c.name + ".")
      }
    }
  } else if (accion == "tirar") {
    var c = Card.get(g.pruebaCarta)
    var opt = c == null ? null : c.option(g.pruebaOpcion)
    if (opt == null) {
      aviso = "No hay una prueba preparada."
    } else {
      var push = g.fase == "empujon"
      var dados = push ? 2 : opt["dados"]
      var dice = Game.roll(dados)
      var d1 = dice[0]
      var d2 = dados == 2 ? dice[1] : 0
      var parity = !push && (opt["tipoPrueba"] == "cara" || opt["tipoPrueba"] == "seca")
      if (parity && g.giro) d1 = 7 - d1
      `UPDATE games SET dado1 = ?, dado2 = ?, tirado = 1, giro = 0 WHERE id = ?`.query(d1, d2, g.id)
      Game.log(g.id, (push ? "Empujón: " : "Tiran en la app: ") + d1.toString + (dados == 2 ? " y " + d2.toString : "") + ".")
    }
  } else if (accion == "mesa") {
    var d1 = Num.fromString(Request.post("d1", "0"))
    var d2 = Num.fromString(Request.post("d2", "0"))
    var c = Card.get(g.pruebaCarta)
    var opt = c == null ? null : c.option(g.pruebaOpcion)
    var push = g.fase == "empujon"
    var dados = push ? 2 : (opt == null ? 0 : opt["dados"])
    if (opt == null) {
      aviso = "No hay una prueba preparada."
    } else if (d1 < 1 || d1 > 6 || (dados == 2 && (d2 < 1 || d2 > 6))) {
      aviso = "Elegí valores de 1 a 6 para cada dado."
    } else {
      var parity = !push && (opt["tipoPrueba"] == "cara" || opt["tipoPrueba"] == "seca")
      if (parity && g.giro) d1 = 7 - d1
      `UPDATE games SET dado1 = ?, dado2 = ?, tirado = 1, giro = 0 WHERE id = ?`.query(d1, dados == 2 ? d2 : 0, g.id)
      Game.log(g.id, (push ? "Empujón en la mesa: " : "Dados de la mesa: ") + d1.toString + (dados == 2 ? " y " + d2.toString : "") + ".")
    }
  } else if (accion == "maniobra") {
    var row = `SELECT * FROM game_cards WHERE id = ? AND gameId = ? AND zone = 'mano'`.first(rowId, g.id)
    var c = row == null ? null : Card.get(row["cardId"])
    var opt = g.pruebaCarta == null ? null : (Card.get(g.pruebaCarta) == null ? null : Card.get(g.pruebaCarta).option(g.pruebaOpcion))
    var parity = opt != null && (opt["tipoPrueba"] == "cara" || opt["tipoPrueba"] == "seca")
    if (c == null) {
      aviso = "Esa carta ya no está en tu mano."
    } else if (g.fase != "prueba") {
      aviso = "Esa Maniobra se usa cuando hay una prueba de dados."
    } else if (g.jugadas > 0) {
      aviso = "Ya jugaron una carta este turno."
    } else if (g.fase != "prueba") {
      aviso = "Esa Maniobra se usa antes de resolver el misterio."
    } else if (c.effect == "flip_parity" && !parity) {
      aviso = "Giro Brusco solo sirve en pruebas de Cara o Seca."
    } else if (c.effect == "flip_parity" && !g.tirado) {
      aviso = "Giro Brusco se juega después de tirar: cambia un dado que ya vieron."
    } else if (g.tirado && c.effect != "flip_parity") {
      aviso = "Esa Maniobra se juega antes de tirar: se compromete a ciegas."
    } else if (c.effect == "plus_two") {
      `UPDATE games SET bonus = bonus + 2, jugadas = 1 WHERE id = ?`.query(g.id)
      Game.move(rowId, "descarte")
      Game.log(g.id, "Turbo de Emergencia: +2 al total.")
    } else if (c.effect == "flip_parity") {
      var nuevo = 7 - g.dado1
      `UPDATE games SET dado1 = ?, jugadas = 1 WHERE id = ?`.query(nuevo, g.id)
      Game.move(rowId, "descarte")
      Game.log(g.id, "Giro Brusco: el dado pasa de Cara a Seca (o al revés).")
    } else if (c.effect == "reroll_all") {
      `UPDATE games SET suerte = 1, jugadas = 1 WHERE id = ?`.query(g.id)
      Game.move(rowId, "descarte")
      Game.log(g.id, "Suerte del Principiante preparada: si falla, se tira de nuevo.")
    } else if (c.effect == "cancel_shield_loss") {
      `UPDATE games SET cebo = 1, jugadas = 1 WHERE id = ?`.query(g.id)
      Game.move(rowId, "descarte")
      Game.log(g.id, "Lanzar Cebo: el próximo daño al Escudo se cancela.")
    } else if (c.effect == "no_energy_cost") {
      `UPDATE games SET ahorro = 1, jugadas = 1 WHERE id = ?`.query(g.id)
      Game.move(rowId, "descarte")
      Game.log(g.id, "Ahorro de Oxígeno: este turno no gastan Energía.")
    } else {
      aviso = "Esa carta no se usa durante la prueba."
    }
  } else if (accion == "focos") {
    var opt = g.pruebaCarta == null ? null : (Card.get(g.pruebaCarta) == null ? null : Card.get(g.pruebaCarta).option(g.pruebaOpcion))
    var parity = opt != null && (opt["tipoPrueba"] == "cara" || opt["tipoPrueba"] == "seca")
    if (g.fase != "prueba" || !g.tirado || !parity) {
      aviso = "Los Focos Abisales solo relanzan un dado de Cara o Seca."
    } else if (!Game.hasTool(g.id, "reroll_parity") || g.focosUsado) {
      aviso = "Los Focos Abisales ya se usaron este turno."
    } else {
      var d = Game.roll(1)[0]
      `UPDATE games SET dado1 = ?, focosUsado = 1 WHERE id = ?`.query(d, g.id)
      Game.log(g.id, "Focos Abisales: relanzan el dado y sale " + d.toString + ".")
    }
  } else if (accion == "resolver") {
    var c = Card.get(g.pruebaCarta)
    var opt = c == null ? null : c.option(g.pruebaOpcion)
    if (opt == null) {
      aviso = "No hay una prueba para resolver."
    } else if (!g.tirado) {
      aviso = "Primero tienen que tirar los dados."
    } else if (g.fase == "empujon") {
      var tools = Game.ids(g.id, "herramientas")
      var total = g.dado1 + g.dado2 + (tools.contains("plus_one_sum") ? 1 : 0)
      var okp = total >= 8
      var res = Game.apply(g.id, g, okp ? {"pistas": 1, "energia": 0, "escudo": 0} : {"pistas": 0, "energia": 0, "escudo": -1}, okp, tools)
      var texto = okp ? "Empujón logrado: +1 Pista." : "El empujón falla: −1 Escudo."
      `UPDATE games SET fase = 'resuelto', empujado = 1, ultimo = ?, tirado = 0, dado1 = 0, dado2 = 0, bonus = 0, giro = 0, suerte = 0 WHERE id = ?`.query(texto, g.id)
      Game.log(g.id, texto)
    } else {
      var tools = Game.ids(g.id, "herramientas")
      var d1 = g.dado1
      var d2 = g.dado2
      var ok = Game.evalTest(opt["tipoPrueba"], opt["objetivo"], d1, d2, g.bonus, tools.contains("plus_one_sum"))
      if (!ok && g.suerte) {
        var dice = Game.roll(opt["dados"])
        d1 = dice[0]
        d2 = opt["dados"] == 2 ? dice[1] : 0
        ok = Game.evalTest(opt["tipoPrueba"], opt["objetivo"], d1, d2, g.bonus, tools.contains("plus_one_sum"))
        Game.log(g.id, "Suerte del Principiante: nueva tirada " + d1.toString + (opt["dados"] == 2 ? " y " + d2.toString : "") + ".")
      }
      var eff = Game.parseEffects(ok ? opt["exito"] : opt["fallo"])
      var res = Game.apply(g.id, g, eff, ok, tools)
      var mesaRow = `SELECT id FROM game_cards WHERE gameId = ? AND cardId = ? AND zone = 'mesa'`.first(g.id, g.pruebaCarta)
      if (mesaRow != null) Game.move(mesaRow["id"], "descarte")
      var texto = (ok ? "Prueba superada" : "Prueba fallida") + ": " + c.name + " — " + opt["texto"] + "."
      if (!res["notas"].isEmpty) texto = texto + " " + res["notas"].join(". ") + "."
      var nextFase = (ok && res["status"] == "activa") ? "empujon" : "resuelto"
      `UPDATE games SET fase = ?, resultado = ?, resueltas = 1, ultimo = ?, dado1 = ?, dado2 = ?, tirado = 0, bonus = 0, giro = 0, suerte = 0 WHERE id = ?`.query([nextFase, ok ? "ganada" : "perdida", texto, d1, d2, g.id])
      Game.log(g.id, texto)
      if (res["status"] == "victoria") Game.log(g.id, "¡Seis Pistas! El misterio queda resuelto.")
      if (res["status"] == "derrota") Game.log(g.id, "La expedición se pierde en la oscuridad.")
    }
  } else if (accion == "reparar") {
    if (g.fase != "listo") {
      aviso = "Reparen antes de elegir un misterio."
    } else if (g.reparado) {
      aviso = "Ya repararon el casco este turno."
    } else if (g.energia < 2) {
      aviso = "Necesitan al menos 2 de Energía para reparar."
    } else {
      `UPDATE games SET energia = energia - 1, escudo = MIN(6, escudo + 2), reparado = 1 WHERE id = ?`.query(g.id)
      Game.log(g.id, "Reparación de casco: −1 Energía, +2 Escudo.")
    }
  } else if (accion == "asegurar") {
    if (g.fase != "empujon") {
      aviso = "No hay un empujón pendiente."
    } else if (g.tirado) {
      aviso = "Ya arriesgaron: tienen que resolver el empujón."
    } else {
      `UPDATE games SET fase = 'resuelto', empujado = 1, ultimo = ? WHERE id = ?`.query("El equipo asegura la Pista y no arriesga más.", g.id)
      Game.log(g.id, "El equipo asegura la Pista y no arriesga más.")
    }
  } else if (accion == "dado") {
    var d = Game.roll(1)[0]
    return Response.redirect("/juego?dado=" + d.toString)
  } else if (accion == "cancelar") {
    if (g.tirado) {
      aviso = "Ya tiraron: no pueden volver atrás. Resuelvan la prueba."
    } else {
      `UPDATE games SET fase = 'listo', pruebaCarta = NULL, pruebaOpcion = NULL, dado1 = 0, dado2 = 0, tirado = 0, bonus = 0, cebo = 0, ahorro = 0, giro = 0, suerte = 0 WHERE id = ?`.query(g.id)
      Game.log(g.id, "El equipo duda y vuelve a mirar las cartas.")
    }
  } else if (accion == "arpon") {
    var tools = g.fase == "listo" ? Game.cardsIn(g.id, "herramientas") : []
    var harpoon = null
    for (t in tools) {
      if (t["card"].effect == "harpoon") harpoon = t
    }
    if (harpoon == null) {
      aviso = "No tienen el Arpón Rastreador en la mesa."
    } else if (g.energia < 2) {
      aviso = "El Arpón necesita 2 de Energía."
    } else if (g.fase != "listo") {
      aviso = "El Arpón se usa antes de elegir un misterio."
    } else {
      Game.apply(g.id, g, {"pistas": 0, "energia": -2, "escudo": 0}, true, [])
      var trasGasto = Game.find(g.id)
      var d = Game.roll(1)[0]
      if (trasGasto.status == "activa" && d % 2 == 0) {
        var g2 = Game.find(g.id)
        Game.apply(g.id, g2, {"pistas": 1, "energia": 0, "escudo": 0}, true, [])
        Game.move(harpoon["rowId"], "descarte")
        Game.log(g.id, "Arpón Rastreador: sale " + d.toString + " (CARA). +1 Pista y la carta se descarta.")
      } else {
        Game.log(g.id, "Arpón Rastreador: sale " + d.toString + " (SECA). El arpón vuelve a la mesa.")
      }
    }
  } else if (accion == "terminar") {
    if (g.fase != "resuelto") {
      aviso = "Primero resuelvan un misterio."
    } else if (Game.count(g.id, "mano") > 3) {
      aviso = "Antes de pasar el turno, descartá hasta quedarte con 3 cartas."
    } else {
      var g2 = Game.find(g.id)
      if (g2.ahorro) {
        Game.log(g.id, "Ahorro de Oxígeno: el consumo del submarino no gasta Energía.")
      } else {
        var en = Game.clamp(g2.energia - 1, 0, 6)
        `UPDATE games SET energia = ? WHERE id = ?`.query(en, g.id)
        Game.log(g.id, "El submarino consume 1 Energía.")
        if (en <= 0) {
          `UPDATE games SET status = 'derrota' WHERE id = ?`.query(g.id)
          Game.log(g.id, "La Energía llegó a cero. La expedición termina.")
          return Response.redirect("/juego")
        }
      }
      var nueva = Game.draw(g.id, "misterio", "mesa", 1)
      if (nueva != null) {
        var nc = Card.get(nueva)
        if (nc != null && nc.entry != "") {
          var g4 = Game.find(g.id)
          var resEntrada = Game.apply(g.id, g4, Game.parseEffects(nc.entry), true, Game.ids(g.id, "herramientas"))
          Game.log(g.id, "Emboscada al entrar: " + nc.name + " — " + nc.entryLabel + ".")
          if (resEntrada["status"] != "activa") return Response.redirect("/juego")
        }
      }
      var next = g.jugador >= g.players ? 1 : g.jugador + 1
      var gSkip = Game.find(g.id)
      if (gSkip.saltar) {
        next = next >= gSkip.players ? 1 : next + 1
        Game.log(g.id, "El equipo pierde un turno reparando la emboscada. Juega el jugador " + next.toString + ".")
      }
      `UPDATE games SET jugador = ?, turno = turno + 1, fase = 'listo', pruebaCarta = NULL, pruebaOpcion = NULL, dado1 = 0, dado2 = 0, tirado = 0, bonus = 0, cebo = 0, ahorro = 0, blindajeUsado = 0, focosUsado = 0, jugadas = 0, resueltas = 0, resultado = NULL, giro = 0, suerte = 0, empujado = 0, pistasTurno = 0, saltar = 0, reparado = 0 WHERE id = ?`.query(next, g.id)
      var g3 = Game.find(g.id)
      if (g3 != null && Game.hasTool(g.id, "energy_start") && g3.energia <= 3) {
        `UPDATE games SET energia = energia + 1 WHERE id = ?`.query(g.id)
        Game.log(g.id, "Generador Auxiliar: +1 Energía al empezar el turno.")
      }
      Game.draw(g.id, "equipo", "mano", 2)
      Game.log(g.id, "Turno " + (g.turno + 1).toString + ": juega el jugador " + next.toString + ".")
    }
  }

  return Response.redirect("/juego" + (aviso == "" ? "" : "?aviso=" + Util.urlEncode(aviso)))
}

// Primer ingreso con cantidad de jugadores en la URL
if (g == null && Request.get("jugadores") != null) {
  var n = Num.fromString(Request.get("jugadores", "3"))
  if (n < 2) n = 2
  if (n > 6) n = 6
  var modo = Request.get("modo", "normal") == "facil" ? "facil" : "normal"
  var id = Game.create(n, modo)
  session.set("gameId", id.toString)
  return Response.redirect("/juego")
}

// ---------- Datos para la vista ----------

var aviso = Util.urlDecode(Request.get("aviso", ""))
var dadoLibre = Request.get("dado")

if (g == null) {
  return Layout.render(<main>
    <section class="hero-start">
      <p class="eyebrow">Preparación</p>
      <h1>¿Cuántos bajan al agua?</h1>
      <p class="lead">De 2 a 6 jugadores. La mesa decide entre todos: nadie tiene un rol secreto.</p>
      <p class="hint">Siempre 3 cartas de Misterio en la mesa y 2 de robo por turno, sin importar cuántos jueguen.</p>
      <form method="post" class="panel start-form">
        <input type="hidden" name="accion" value="nueva" />
        <label for="players"><strong>Jugadores</strong></label>
        <select id="players" name="jugadores">
          <option value="2">2 jugadores</option>
          <option value="3" selected>3 jugadores</option>
          <option value="4">4 jugadores</option>
          <option value="5">5 jugadores</option>
          <option value="6">6 jugadores</option>
        </select>
        <label for="modo"><strong>Modo</strong></label>
        <select id="modo" name="modo">
          <option value="normal" selected>Normal — 5 Energía y 5 Escudo</option>
          <option value="facil">Fácil — 6 y 6, para los más chicos</option>
        </select>
        <button class="btn btn-primary">Iniciar expedición</button>
      </form>
      <p class="hint">Todavía pueden leer <a href="/reglas">las reglas</a> antes de empezar.</p>
    </section>
  </main>)
}

var mesa = Game.cardsIn(g.id, "mesa")
var hand = Game.cardsIn(g.id, "mano")
var tools = Game.cardsIn(g.id, "herramientas")
var logs = Game.lastLogs(g.id, 8)
var mazo = Game.count(g.id, "misterio")
var descarte = Game.count(g.id, "descarte")
var top = Game.hasTool(g.id, "peek") ? Game.topCard(g.id) : null

var pendingCard = g.pruebaCarta == null ? null : Card.get(g.pruebaCarta)
var pendingOpt = pendingCard == null ? null : pendingCard.option(g.pruebaOpcion)

var handCount = hand.count
var puedeElegir = g.status == "activa" && g.fase == "listo" && g.resueltas == 0
var puedeJugar = g.status == "activa" && g.jugadas == 0 && g.fase == "listo"
var puedeReparar = g.status == "activa" && g.fase == "listo" && !g.reparado && g.energia >= 2
var maniobrasPrueba = hand.where { |h| ["plus_two", "reroll_all", "cancel_shield_loss", "no_energy_cost"].contains(h["card"].effect) }.toList
var girosPrueba = hand.where { |h| h["card"].effect == "flip_parity" }.toList

var finalTitulo = "La expedición continúa"
var finalTexto = ""
if (g.status == "victoria") {
  finalTitulo = "Misterio resuelto"
  finalTexto = "Seis Pistas. El Megalodón se aleja hacia la fosa y el equipo sube con la respuesta. La expedición vuelve a casa."
} else if (g.status == "derrota" && g.energia <= 0) {
  finalTitulo = "Sin aire"
  finalTexto = "La Energía llegó a cero. El submarino se queda quieto en la oscuridad y la expedición termina ahí."
} else if (g.status == "derrota") {
  finalTitulo = "El casco cedió"
  finalTexto = "El Escudo llegó a cero. El vehículo no resiste la presión y la fosa se queda con el secreto."
}

// ---------- Vista ----------

return Layout.render(<main class="game">

  <header class="board-head">
    <div>
      <p class="eyebrow">Expedición en curso</p>
      <h1>La fosa del Megalodón</h1>
    </div>
    <div class="board-meta">
      <span class="pill">{{ g.modo == "facil" ? "Modo fácil" : "Modo normal" }}</span>
      <span class="pill">Turno {{ g.turno }}</span>
      <span class="pill">Jugador {{ g.jugador }} de {{ g.players }}</span>
      <span class="pill">Mazo {{ mazo }}</span>
      <span class="pill">Descarte {{ descarte }}</span>
    </div>
  </header>

  <section class="gauges-board" aria-label="Contadores de la expedición">
    <article class="counter">
      {{ Layout.die(g.energia, "die-teal") }}
      <span class="counter-body">
        <span class="counter-label">Energía</span>
        <span class="counter-value">{{ g.energia }} / 6</span>
      </span>
    </article>
    <article class="counter">
      {{ Layout.die(g.escudo, "die-gold") }}
      <span class="counter-body">
        <span class="counter-label">Escudo</span>
        <span class="counter-value">{{ g.escudo }} / 6</span>
      </span>
    </article>
    <article class="counter">
      {{ Layout.die(g.pistas, "die-coral") }}
      <span class="counter-body">
        <span class="counter-label">Pistas</span>
        <span class="counter-value">{{ g.pistas }} / 6</span>
      </span>
    </article>
  </section>

  {{ aviso != "" && <p class="aviso" role="status">{{ aviso }}</p> }}

  {{ g.status != "activa" && <section class="panel ending">
    <p class="eyebrow">Fin de la partida</p>
    <h2>{{ finalTitulo }}</h2>
    <p>{{ finalTexto }}</p>
    <p class="muted">Energía {{ g.energia }} · Escudo {{ g.escudo }} · Pistas {{ g.pistas }}</p>
    <form method="post">
      <input type="hidden" name="accion" value="reiniciar" />
      <button class="btn btn-primary">Nueva expedición</button>
    </form>
  </section> }}

  {{ g.status == "activa" && g.fase == "prueba" && pendingCard != null && <section class="test-panel">
    <p class="eyebrow">Prueba de dados</p>
    <span class="card-emoji test-emoji" aria-hidden="true">{{ pendingCard.emoji }}</span>
    <h2>{{ pendingCard.name }}</h2>
    <p class="muted">{{ pendingCard.family == "exploracion" ? "Exploración" : (pendingCard.family == "peligro" ? "Peligro" : "Dilema") }}</p>
    <p class="test-action">{{ pendingOpt["texto"] }}</p>
    <p><span class="test-badge test-{{ pendingOpt["tipoPrueba"] }}">{{ pendingOpt["pruebaLabel"] }}</span></p>

    <div class="dice-row roller-stage">
      {{ Layout.die(g.tirado ? g.dado1 : 0, "die-large") }}
      {{ pendingOpt["dados"] == 2 && Layout.die(g.tirado ? g.dado2 : 0, "die-large") }}
    </div>

    {{ g.bonus > 0 && <p class="hint">Bonificación acumulada: +{{ g.bonus }} al total.</p> }}
    {{ g.giro && <p class="hint">Giro Brusco preparado: el dado se va a invertir.</p> }}
    {{ g.suerte && <p class="hint">Suerte del Principiante preparada: si falla, se tira de nuevo.</p> }}
    {{ g.cebo && <p class="hint">Lanzar Cebo: el próximo daño al Escudo se cancela.</p> }}
    {{ g.ahorro && <p class="hint">Ahorro de Oxígeno: este turno no gastan Energía.</p> }}

    {{ !g.tirado && <section class="roll-controls">
      {{ g.jugadas == 0 && maniobrasPrueba.count > 0 && <section class="maneuvers">
        <p class="hint">Turbo, Suerte, Cebo y Ahorro se juegan <strong>antes</strong> de tirar. Giro Brusco va después: cambia un dado que ya vieron.</p>
        <div class="action-row">
          {{ maniobrasPrueba.map{|h| <form method="post" class="inline-form">
            <input type="hidden" name="accion" value="maniobra" />
            <input type="hidden" name="rowId" value="{{ h["rowId"] }}" />
            <button class="btn btn-ghost btn-small">Usar {{ h["card"].name }}</button>
          </form>} }}
        </div>
      </section> }}
      {{ g.jugadas > 0 && <p class="hint">Ya jugaron su carta de este turno. Tiren cuando quieran.</p> }}
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
      <p class="hint">CARA = par (2, 4, 6). SECA = impar (1, 3, 5).</p>
    </section> }}

    {{ g.tirado && <section class="test-actions">
      <p class="muted">Tirada registrada. Ya no pueden jugar Maniobras: resuelvan.</p>
      <div class="action-row">
        {{ g.jugadas == 0 && girosPrueba.map{|h| <form method="post" class="inline-form">
          <input type="hidden" name="accion" value="maniobra" />
          <input type="hidden" name="rowId" value="{{ h["rowId"] }}" />
          <button class="btn btn-ghost btn-small">Giro Brusco: invertir el dado</button>
        </form>} }}
        {{ Game.hasTool(g.id, "reroll_parity") && !g.focosUsado && (pendingOpt["tipoPrueba"] == "cara" || pendingOpt["tipoPrueba"] == "seca") && <form method="post" class="inline-form">
          <input type="hidden" name="accion" value="focos" />
          <button class="btn btn-ghost btn-small">Focos Abisales: relanzar</button>
        </form> }}
      </div>
      <div class="action-row">
        <form method="post" class="inline-form">
          <input type="hidden" name="accion" value="resolver" />
          <button class="btn btn-primary">Resolver la prueba</button>
        </form>
      </div>
    </section> }}
  </section> }}

  {{ g.status == "activa" && g.fase == "empujon" && pendingCard != null && <section class="test-panel push-panel">
    <p class="eyebrow">Oportunidad</p>
    <span class="card-emoji test-emoji" aria-hidden="true">{{ pendingCard.emoji }}</span>
    <h2>¿Profundizan?</h2>
    <p class="muted">{{ g.ultimo }}</p>
    <p><strong>Empujón:</strong> dos dados, 8+ para ganar 1 Pista extra. Si falla, pierden 1 de Escudo.</p>
    <p class="hint">Es una tirada aparte: no gasta carta ni Maniobra. Pueden asegurar la Pista y terminar el turno.</p>

    <div class="dice-row roller-stage">
      {{ Layout.die(g.tirado ? g.dado1 : 0, "die-large") }}
      {{ Layout.die(g.tirado ? g.dado2 : 0, "die-large") }}
    </div>

    {{ !g.tirado && <section class="roll-controls">
      <form method="post" class="roll-form">
        <input type="hidden" name="accion" value="tirar" />
        <button class="btn btn-primary">Arriesgar y tirar en la app</button>
      </form>
      <form method="post" class="roll-form">
        <input type="hidden" name="accion" value="mesa" />
        <label class="die-select">Dado 1
          <select name="d1">
            {{ [1, 2, 3, 4, 5, 6].map{|n| <option value="{{ n }}">{{ n }}</option>} }}
          </select>
        </label>
        <label class="die-select">Dado 2
          <select name="d2">
            {{ [1, 2, 3, 4, 5, 6].map{|n| <option value="{{ n }}">{{ n }}</option>} }}
          </select>
        </label>
        <button class="btn btn-ghost">Arriesgar con dados de la mesa</button>
      </form>
    </section> }}

    {{ g.tirado && <form method="post" class="push-form">
      <input type="hidden" name="accion" value="resolver" />
      <button class="btn btn-primary">Resolver el empujón</button>
    </form> }}

    {{ !g.tirado && <form method="post" class="push-form">
      <input type="hidden" name="accion" value="asegurar" />
      <button class="btn btn-ghost">Asegurar la Pista</button>
    </form> }}
  </section> }}

  {{ g.status == "activa" && g.fase == "resuelto" && <section class="panel result-panel">
    <p class="eyebrow">Resultado</p>
    <h2>{{ g.resultado == "ganada" ? "Prueba superada" : "Prueba fallida" }}</h2>
    <p class="muted">{{ g.ultimo }}</p>
    <p>Revisen los contadores. Antes de pasar el dispositivo, descarten hasta quedar con 3 cartas.</p>
    {{ handCount > 3 && <p class="hint">Tienen {{ handCount }} cartas. Descartá abajo las que sobren.</p> }}
    {{ handCount <= 3 && <form method="post">
      <input type="hidden" name="accion" value="terminar" />
      <button class="btn btn-primary">Terminar turno y reponer la mesa</button>
    </form> }}
  </section> }}

  {{ g.status == "activa" && g.fase == "listo" && <section>
    <div class="section-head">
      <h2>Cartas activas en la mesa</h2>
      <p>Elijan una carta y resuelvan su opción. Las emboscadas tienen una sola.</p>
    </div>
    <div class="card-grid">
      {{ mesa.map{|item| <article class="card" data-family="{{ item["card"].family }}">
        <span class="card-art"><span class="card-emoji" aria-hidden="true">{{ item["card"].emoji }}</span></span>
        <span class="card-family">{{ item["card"].family == "exploracion" ? "Exploración" : (item["card"].family == "peligro" ? "Peligro" : "Dilema") }}{{ item["card"].entry != "" ? " · Emboscada" : "" }}</span>
        <h3>{{ item["card"].name }}</h3>
        {{ item["card"].entry != "" && <p class="entry-badge">Al entrar: {{ item["card"].entryLabel }}</p> }}
        <section class="card-text">{{ item["card"].body }}</section>
        <ul class="card-options">
          {{ item["card"].options.map{|o| <li class="option-row">
            <form method="post" class="option-form">
              <input type="hidden" name="accion" value="elegir" />
              <input type="hidden" name="rowId" value="{{ item["rowId"] }}" />
              <input type="hidden" name="opt" value="{{ o["label"] }}" />
              <button class="option-btn" {{ puedeElegir ? "" : "disabled" }}>
                <span class="option-text">{{ o["texto"] }}</span>
                <span class="test-badge test-{{ o["tipoPrueba"] }}">{{ o["pruebaLabel"] }}</span>
                <span class="option-effects">Éxito: {{ o["exitoLabel"] }} · Fallo: {{ o["falloLabel"] }}</span>
              </button>
            </form>
          </li>} }}
        </ul>
      </article>} }}
    </div>
    {{ mesa.isEmpty && <p class="muted">No quedan cartas activas. Repongan la mesa al terminar el turno.</p> }}
  </section> }}

  {{ g.status == "activa" && <section class="split">
    <div>
      <div class="section-head">
        <h2>Mano del equipo</h2>
        <p>{{ handCount }} cartas · descartás al final</p>
      </div>
      <div class="hand">
        {{ hand.map{|h| <article class="card" data-family="{{ h["card"].isTool ? "herramienta" : "maniobra" }}">
          <span class="card-art"><span class="card-emoji" aria-hidden="true">{{ h["card"].emoji }}</span></span>
          <span class="card-family">{{ h["card"].isTool ? "Herramienta" : "Maniobra" }}</span>
          <h3>{{ h["card"].name }}</h3>
          <section class="card-text">{{ h["card"].body }}</section>
          <div class="action-row">
            <form method="post" class="inline-form">
              <input type="hidden" name="accion" value="jugar" />
              <input type="hidden" name="rowId" value="{{ h["rowId"] }}" />
              <button class="btn btn-primary btn-small" {{ puedeJugar ? "" : "disabled" }}>Jugar</button>
            </form>
            <form method="post" class="inline-form">
              <input type="hidden" name="accion" value="descartar" />
              <input type="hidden" name="rowId" value="{{ h["rowId"] }}" />
              <button class="btn btn-ghost btn-small">Descartar</button>
            </form>
          </div>
        </article>} }}
      </div>
      {{ hand.isEmpty && <p class="muted">Sin cartas en mano. Al terminar el turno roban 2.</p> }}
      <p class="hint">{{ g.jugadas == 0 ? "Todavía pueden jugar 1 carta este turno." : "Ya jugaron su carta de este turno." }} Al final del turno tienen que quedar con 3.</p>
    </div>

    <aside>
      <div class="section-head">
        <h2>Herramientas activas</h2>
        <p>{{ tools.count }} / 4</p>
      </div>
      {{ tools.map{|t| <article class="card card-tool" data-family="herramienta">
        <span class="card-art"><span class="card-emoji" aria-hidden="true">{{ t["card"].emoji }}</span></span>
        <span class="card-family">Herramienta</span>
        <h3>{{ t["card"].name }}</h3>
        <section class="card-text">{{ t["card"].body }}</section>
        {{ t["card"].effect == "harpoon" && g.fase == "listo" && <form method="post">
          <input type="hidden" name="accion" value="arpon" />
          <button class="btn btn-ghost btn-small" {{ g.energia >= 2 ? "" : "disabled" }}>Lanzar arpón (2 Energía)</button>
        </form> }}
      </article>} }}
      {{ tools.isEmpty && <p class="muted">Todavía no bajaron ninguna Herramienta.</p> }}

      {{ top != null && <section class="panel peek">
        <p class="eyebrow">Sonar de Alta Frecuencia</p>
        <p>La próxima carta del mazo es <strong>{{ top.name }}</strong>.</p>
      </section> }}

      <section class="panel">
        <p class="eyebrow">Reparación de casco</p>
        <p class="muted">Una vez por turno: 1 Energía → 2 Escudo.</p>
        <form method="post">
          <input type="hidden" name="accion" value="reparar" />
          <button class="btn btn-ghost btn-small" {{ puedeReparar ? "" : "disabled" }}>Reparar casco</button>
        </form>
        {{ g.reparado && <p class="hint">Ya repararon este turno; el casco aguanta un poco más.</p> }}
      </section>

      <section class="panel">
        <p class="eyebrow">Dado libre</p>
        <p class="muted">Para una tirada suelta, sin carta de por medio.</p>
        <div class="dice-row" style="justify-content: flex-start">
          {{ Layout.die(dadoLibre == null ? 0 : Num.fromString(dadoLibre), "die-large") }}
          <form method="post" class="inline-form">
            <input type="hidden" name="accion" value="dado" />
            <button class="btn btn-ghost btn-small">Tirar un D6</button>
          </form>
        </div>
      </section>

      <section class="panel">
        <p class="eyebrow">Regla rápida</p>
        <p>Cada turno: roban 2, juegan 1 carta como máximo y resuelven 1 misterio. Al final descartan hasta 3 y el submarino consume 1 Energía.</p>
        <a href="/reglas" class="btn btn-ghost btn-small">Ver reglas completas</a>
      </section>
    </aside>
  </section> }}

  <section class="log-section">
    <div class="section-head">
      <h2>Bitácora de la expedición</h2>
    </div>
    <ul class="log">
      {{ logs.map{|l| <li><time>{{ l["createdAt"] }}</time> <span>{{ l["text"] }}</span></li>} }}
    </ul>
    {{ logs.isEmpty && <p class="muted">Todavía no pasó nada. Todo está por descubrirse.</p> }}
    {{ g.status == "activa" && <form method="post" class="restart-form">
      <input type="hidden" name="accion" value="reiniciar" />
      <button class="btn btn-ghost btn-small">Abandonar y empezar de nuevo</button>
    </form> }}
  </section>
</main>)
