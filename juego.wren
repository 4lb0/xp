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
    var modo = Request.post("modo", "experto")
    if (modo != "casual" && modo != "facil") modo = "experto"
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
      aviso = "Esa carta se juega antes de elegir un Misterio."
    } else if (g.jugadas > 0) {
      aviso = "Ya jugaron una carta este ciclo."
    } else {
      var c = Card.get(row["cardId"])
      if (c == null) {
        aviso = "No pudimos leer esa carta."
      } else if (c.isSupport) {
        `UPDATE games SET fase = 'apoyo', apoyoCarta = ?, apoyoOrigen = 'mano', fasePrevia = 'listo', jugadas = 1 WHERE id = ?`.query(rowId, g.id)
        Game.log(g.id, "Preparan el apoyo: " + c.name + ".")
      } else if (c.isTool) {
        // Solo una Herramienta activa por equipo: la nueva pisa la anterior.
        var anteriores = Game.rows(g.id, "herramientas")
        for (t in anteriores) Game.move(t["id"], "descarte")
        if (!anteriores.isEmpty) Game.log(g.id, "La nueva Herramienta reemplaza a la anterior: solo hay una activa.")
        Game.move(rowId, "herramientas")
        `UPDATE games SET jugadas = 1 WHERE id = ?`.query(g.id)
        Game.log(g.id, "Herramienta en juego: " + c.name + ".")
      } else if (c.effect == "heal_shield") {
        Game.apply(g.id, g, {"pistas": 0, "energia": 0, "escudo": 1}, true, [])
        Game.move(rowId, "descarte")
        `UPDATE games SET jugadas = 1 WHERE id = ?`.query(g.id)
        Game.log(g.id, "Soldadura Submarina: +1 Escudo.")
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
          Game.move(rowId, "descarte")
          `UPDATE games SET jugadas = 1 WHERE id = ?`.query(g.id)
        }
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
      aviso = "Ya resolvieron un misterio este ciclo."
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
      var dados = opt["dados"]
      var dice = Game.roll(dados)
      var d1 = dice[0]
      var d2 = dados == 2 ? dice[1] : 0
      var parity = opt["tipoPrueba"] == "cara" || opt["tipoPrueba"] == "seca"
      if (parity && g.giro) d1 = 7 - d1
      `UPDATE games SET dado1 = ?, dado2 = ?, tirado = 1, giro = 0 WHERE id = ?`.query(d1, d2, g.id)
      Game.log(g.id, "Tiran en la app: " + d1.toString + (dados == 2 ? " y " + d2.toString : "") + ".")
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
      Game.log(g.id, "Dados de la mesa: " + d1.toString + (dados == 2 ? " y " + d2.toString : "") + ".")
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
      aviso = "Ya jugaron una carta este ciclo."
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
      Game.move(rowId, "descarte")
      Game.log(g.id, "Turbo de Emergencia: +2 al total.")
    } else if (c.effect == "flip_parity") {
      `UPDATE games SET giro = 1, jugadas = 1 WHERE id = ?`.query(g.id)
      Game.move(rowId, "descarte")
      Game.log(g.id, "Giro Brusco preparado: el dado se va a invertir.")
    } else if (c.effect == "reroll_parity") {
      `UPDATE games SET focosM = 1, jugadas = 1 WHERE id = ?`.query(g.id)
      Game.move(rowId, "descarte")
      Game.log(g.id, "Focos Abisales preparados: si falla, relanzan el dado.")
    } else if (c.effect == "reduce_damage") {
      `UPDATE games SET blindajeM = 1, jugadas = 1 WHERE id = ?`.query(g.id)
      Game.move(rowId, "descarte")
      Game.log(g.id, "Blindaje de Titanio preparado: −1 daño al Escudo.")
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
      Game.log(g.id, "Ahorro de Oxígeno: en este misterio no gastan Energía.")
    } else {
      aviso = "Esa carta no se usa durante la prueba."
    }
  } else if (accion == "resolver") {
    var c = Card.get(g.pruebaCarta)
    var opt = c == null ? null : c.option(g.pruebaOpcion)
    if (opt == null) {
      aviso = "No hay una prueba para resolver."
    } else if (!g.tirado) {
      aviso = "Primero tienen que tirar los dados."
    } else {
      var tools = Game.ids(g.id, "herramientas")
      var d1 = g.dado1
      var d2 = g.dado2
      var ok = Game.evalTest(opt["tipoPrueba"], opt["objetivo"], d1, d2, g.bonus, Game.hasEffect(tools, "plus_one_sum"))
      if (!ok && g.suerte) {
        var dice = Game.roll(opt["dados"])
        d1 = dice[0]
        d2 = opt["dados"] == 2 ? dice[1] : 0
        ok = Game.evalTest(opt["tipoPrueba"], opt["objetivo"], d1, d2, g.bonus, Game.hasEffect(tools, "plus_one_sum"))
        Game.log(g.id, "Suerte del Principiante: nueva tirada " + d1.toString + (opt["dados"] == 2 ? " y " + d2.toString : "") + ".")
      } else if (!ok && g.focosM) {
        d1 = Game.roll(1)[0]
        ok = Game.evalTest(opt["tipoPrueba"], opt["objetivo"], d1, d2, g.bonus, Game.hasEffect(tools, "plus_one_sum"))
        Game.log(g.id, "Focos Abisales: nueva tirada " + d1.toString + ".")
      }
      var eff = Game.parseEffects(ok ? opt["exito"] : opt["fallo"])
      var res = Game.apply(g.id, g, eff, ok, tools)
      var mesaRow = `SELECT id FROM game_cards WHERE gameId = ? AND cardId = ? AND zone = 'mesa'`.first(g.id, g.pruebaCarta)
      if (mesaRow != null) Game.move(mesaRow["id"], "descarte")
      var texto = (ok ? "Prueba superada" : "Prueba fallida") + ": " + c.name + " — " + opt["texto"] + "."
      if (!res["notas"].isEmpty) texto = texto + " " + res["notas"].join(". ") + "."
      var nextFase = "resuelto"
      `UPDATE games SET fase = ?, resultado = ?, resueltas = 1, ultimo = ?, dado1 = ?, dado2 = ?, tirado = 0, bonus = 0, giro = 0, suerte = 0, focosM = 0 WHERE id = ?`.query([nextFase, ok ? "ganada" : "perdida", texto, d1, d2, g.id])
      Game.log(g.id, texto)
      if (res["status"] == "victoria") Game.log(g.id, "¡Seis Pistas! El misterio queda resuelto.")
      if (res["status"] == "derrota") Game.log(g.id, "La expedición se pierde en la oscuridad.")
    }
  } else if (accion == "usar_ayuda") {
    if (g.fase == "apoyo") {
      aviso = "Primero elegí el recurso del apoyo pendiente."
    } else if (g.fase == "emboscada") {
      aviso = "Primero elijan la emboscada inicial."
    } else {
      var row = `SELECT id, cardId FROM game_cards WHERE id = ? AND gameId = ? AND zone = 'ayuda'`.first(rowId, g.id)
      if (row == null) {
        aviso = "Ese apoyo ya no está en el área."
      } else {
        var c = Card.get(row["cardId"])
        `UPDATE games SET fase = 'apoyo', apoyoCarta = ?, apoyoOrigen = 'ayuda', fasePrevia = ? WHERE id = ?`.query(row["id"], g.fase, g.id)
        Game.log(g.id, "Usan el apoyo: " + c.name + ".")
      }
    }
  } else if (accion == "elegir_apoyo") {
    var recurso = Request.post("recurso", "energia")
    var row = g.apoyoCarta == null ? null : `SELECT id, cardId FROM game_cards WHERE id = ? AND gameId = ?`.first(g.apoyoCarta, g.id)
    var c = row == null ? null : Card.get(row["cardId"])
    if (c == null) {
      aviso = "No hay un apoyo pendiente."
    } else {
      var v = c.value
      var volver = g.fasePrevia == null ? "listo" : g.fasePrevia
      if (recurso == "escudo") {
        `UPDATE games SET escudo = MIN(6, escudo + ?), fase = ?, apoyoCarta = NULL, apoyoOrigen = NULL, fasePrevia = NULL WHERE id = ?`.query(v, volver, g.id)
        Game.log(g.id, "Apoyo " + c.name + ": +" + v.toString + " Escudo.")
      } else {
        `UPDATE games SET energia = MIN(6, energia + ?), fase = ?, apoyoCarta = NULL, apoyoOrigen = NULL, fasePrevia = NULL WHERE id = ?`.query(v, volver, g.id)
        Game.log(g.id, "Apoyo " + c.name + ": +" + v.toString + " Energía.")
      }
      Game.move(row["id"], "descarte")
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
  } else if (accion == "terminar") {
    if (g.fase != "resuelto") {
      aviso = "Primero resuelvan un misterio."
    } else {
      var sobra = Game.count(g.id, "mano") - 3
      if (sobra > 0) {
        var mano = `SELECT id, cardId FROM game_cards WHERE gameId = ? AND zone = 'mano' ORDER BY RANDOM()`.fetch(g.id)
        for (i in 0...sobra) {
          if (i < mano.count) {
            var c = Card.get(mano[i]["cardId"])
            Game.move(mano[i]["id"], "descarte")
            Game.log(g.id, "Descarte al azar: " + (c == null ? "una carta" : c.name) + ".")
          }
        }
      }
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
      `UPDATE games SET jugador = 1, turno = turno + 1, fase = 'listo', pruebaCarta = NULL, pruebaOpcion = NULL, dado1 = 0, dado2 = 0, tirado = 0, bonus = 0, cebo = 0, ahorro = 0, blindajeUsado = 0, blindajeM = 0, focosUsado = 0, focosM = 0, jugadas = 0, resueltas = 0, resultado = NULL, giro = 0, suerte = 0, empujado = 0, pistasTurno = 0 WHERE id = ?`.query(g.id)
      var g3 = Game.find(g.id)
      if (g3 != null && Game.hasTool(g.id, "energy_start") && g3.energia <= 4) {
        `UPDATE games SET energia = energia + 1 WHERE id = ?`.query(g.id)
        Game.log(g.id, "Generador Auxiliar: +1 Energía al empezar.")
      }
      var g4 = Game.find(g.id)
      if (g4 != null && Game.hasTool(g.id, "shield_start") && g4.escudo <= 4) {
        `UPDATE games SET escudo = MIN(6, escudo + 1) WHERE id = ?`.query(g.id)
        Game.log(g.id, "Generador de Escudo: +1 Escudo al empezar.")
      }
      Game.draw(g.id, "equipo", "mano", 2)
      Game.log(g.id, "Ciclo " + (g.turno + 1).toString + ".")
    }
  }

  return Response.redirect("/juego" + (aviso == "" ? "" : "?aviso=" + Util.urlEncode(aviso)))
}

// Primer ingreso con cantidad de jugadores en la URL
if (g == null && (Request.get("jugadores") != null || Request.get("modo") != null)) {
  var modo = Request.get("modo", "experto")
  if (modo != "casual" && modo != "facil") modo = "experto"
  var id = Game.create(1, modo)
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
      <h1>Prepará la expedición</h1>
      <p class="lead">Se puede jugar solo o en equipo. La mesa es una: el equipo XP contra el juego.</p>
      <p class="hint">Siempre 3 cartas de Misterio en la mesa y 2 de robo por ciclo. No importa cuántos jueguen.</p>
      <form method="post" class="panel start-form">
        <input type="hidden" name="accion" value="nueva" />
        <label for="modo"><strong>Modo</strong></label>
        <select id="modo" name="modo">
          <option value="experto" selected>Experto — 5 y 5, sin apoyos</option>
          <option value="casual">Normal — 5 y 5 + 1 carta de apoyo</option>
          <option value="facil">Asistido — 6 y 6 + 2 cartas de apoyo</option>
        </select>
        <button class="btn btn-primary">Iniciar expedición</button>
      </form>
      <p class="hint">Todavía pueden leer <a href="/reglas">las reglas</a> antes de empezar.</p>
    </section>
  </main>)
}

var mesa = Game.cardsIn(g.id, "mesa")
var emboscadasIniciales = mesa.where { |m| m["card"].entry != "" }.toList
var hand = Game.cardsIn(g.id, "mano")
var tools = Game.cardsIn(g.id, "herramientas")
var ayuda = Game.cardsIn(g.id, "ayuda")
var logs = Game.lastLogs(g.id, 8)
var mazo = Game.count(g.id, "misterio")
var descarte = Game.count(g.id, "descarte")
var top = Game.hasTool(g.id, "peek") ? Game.topCard(g.id) : null

var pendingCard = g.pruebaCarta == null ? null : Card.get(g.pruebaCarta)
var pendingOpt = pendingCard == null ? null : pendingCard.option(g.pruebaOpcion)

var supportCard = null
if (g.apoyoCarta != null) {
  var srow = `SELECT cardId FROM game_cards WHERE id = ?`.first(g.apoyoCarta)
  if (srow != null) supportCard = Card.get(srow["cardId"])
}

var previewOk = false
var previewEstab = false
var previewBrazo = false
var previewBlindaje = false
var previewCebo = false
var previewAhorro = false
var previewChips = []
if (g.tirado && pendingOpt != null) {
  var tIds = Game.ids(g.id, "herramientas")
  previewEstab = Game.hasEffect(tIds, "plus_one_sum") && pendingOpt["dados"] == 2
  previewOk = Game.evalTest(pendingOpt["tipoPrueba"], pendingOpt["objetivo"], g.dado1, g.dado2, g.bonus, Game.hasEffect(tIds, "plus_one_sum"))
  var succ = Game.parseEffects(pendingOpt["exito"])
  var fail = Game.parseEffects(pendingOpt["fallo"])
  previewBrazo = previewOk && succ["pistas"] > 0 && Game.hasEffect(tIds, "extra_clue_six") && (g.dado1 == 6 || g.dado2 == 6)
  previewBlindaje = !previewOk && fail["escudo"] < 0 && g.blindajeM
  previewCebo = !previewOk && fail["escudo"] < 0 && g.cebo
  previewAhorro = !previewOk && fail["energia"] < 0 && g.ahorro
  previewChips = previewOk ? pendingOpt["exitoChips"] : pendingOpt["falloChips"]
}

var handCount = hand.count
var puedeElegir = g.status == "activa" && g.fase == "listo" && g.resueltas == 0
var puedeJugar = g.status == "activa" && g.jugadas == 0 && g.fase == "listo"
var maniobrasPrueba = hand.where { |h| ["plus_two", "reroll_all", "cancel_shield_loss", "no_energy_cost", "reduce_damage", "flip_parity", "reroll_parity"].contains(h["card"].effect) }.toList

var finalTitulo = "La expedición continúa"
var finalTexto = ""
if (g.status == "victoria") {
  finalTitulo = "Lo encontraron"
  finalTexto = "Seis Pistas. La última sombra se hunde en la fosa y, por un instante, el Megalodón está ahí. El mundo seguirá creyendo que es un mito, como el monstruo del lago Ness. Ustedes ya saben la verdad."
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
      <span class="pill">{{ g.modo == "facil" ? "Asistido" : (g.modo == "casual" ? "Modo normal" : "Modo experto") }}</span>
      <span class="pill">Ciclo {{ g.turno }}</span>
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

  {{ g.status == "activa" && g.fase == "emboscada" && <section class="panel ambush-choice">
    <p class="eyebrow">Emboscada inicial</p>
    <h2>Elijan qué golpe recibe el equipo</h2>
    <p class="muted">Las tres cartas iniciales están boca arriba. Solo una emboscada se aplica al empezar: elijan cuál sufrir.</p>
    <div class="card-grid">
      {{ emboscadasIniciales.map{|item| <article class="card" data-family="{{ item["card"].family }}">
        <span class="card-art"><span class="card-emoji" aria-hidden="true">{{ item["card"].emoji }}</span></span>
        <span class="card-family">Emboscada inicial</span>
        <h3>{{ item["card"].name }}</h3>
        <p class="entry-badge">Al entrar
          {{ item["card"].entryChips.map{|c| <span class="chip {{ c["cls"] }}" title="{{ c["title"] }}" aria-label="{{ c["title"] }}">{{ c["icon"] }} {{ c["text"] }}</span>} }}
        </p>
        <section class="card-text">{{ item["card"].body }}</section>
        <form method="post" class="option-form">
          <input type="hidden" name="accion" value="elegir_emboscada" />
          <input type="hidden" name="rowId" value="{{ item["rowId"] }}" />
          <button class="btn btn-primary btn-small">Sufrir esta emboscada</button>
        </form>
      </article>} }}
    </div>
  </section> }}

  {{ g.status == "activa" && g.fase == "apoyo" && supportCard != null && <section class="test-panel support-choice">
    <p class="eyebrow">Apoyo del equipo</p>
    <span class="card-emoji test-emoji" aria-hidden="true">{{ supportCard.emoji }}</span>
    <h2>{{ supportCard.name }}</h2>
    <p>Elegí el recurso. La carta se gasta.</p>
    <div class="action-row">
      <form method="post">
        <input type="hidden" name="accion" value="elegir_apoyo" />
        <input type="hidden" name="recurso" value="energia" />
        <button class="btn btn-primary"><span class="chip chip-energia">⚡ +{{ supportCard.value }}</span> Energía</button>
      </form>
      <form method="post">
        <input type="hidden" name="accion" value="elegir_apoyo" />
        <input type="hidden" name="recurso" value="escudo" />
        <button class="btn btn-primary"><span class="chip chip-escudo">🛡️ +{{ supportCard.value }}</span> Escudo</button>
      </form>
    </div>
  </section> }}

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
    <p class="option-chips">
      <span class="chip-label">Éxito</span>
      {{ pendingOpt["exitoChips"].map{|c| <span class="chip {{ c["cls"] }}" title="{{ c["title"] }}" aria-label="{{ c["title"] }}">{{ c["icon"] }} {{ c["text"] }}</span>} }}
      <span class="chip-label">Fallo</span>
      {{ pendingOpt["falloChips"].map{|c| <span class="chip {{ c["cls"] }}" title="{{ c["title"] }}" aria-label="{{ c["title"] }}">{{ c["icon"] }} {{ c["text"] }}</span>} }}
    </p>

    <div class="dice-row roller-stage">
      {{ Layout.die(g.tirado ? g.dado1 : 0, "die-large") }}
      {{ pendingOpt["dados"] == 2 && Layout.die(g.tirado ? g.dado2 : 0, "die-large") }}
    </div>

    {{ g.bonus > 0 && <p class="hint">Bonificación acumulada: +{{ g.bonus }} al total.</p> }}
    {{ g.giro && <p class="hint">Giro Brusco preparado: el dado se va a invertir.</p> }}
    {{ g.suerte && <p class="hint">Suerte del Principiante preparada: si falla, se tira de nuevo.</p> }}
    {{ g.focosM && <p class="hint">Focos Abisales preparados: si falla, relanzan el dado.</p> }}
    {{ g.cebo && <p class="hint">Lanzar Cebo: el próximo daño al Escudo se cancela.</p> }}
    {{ g.ahorro && <p class="hint">Ahorro de Oxígeno: este ciclo no gastan Energía.</p> }}

    {{ !g.tirado && <section class="roll-controls">
      {{ g.jugadas == 0 && maniobrasPrueba.count > 0 && <section class="maneuvers">
        <p class="hint">Todas las Maniobras se juegan <strong>antes</strong> de tirar. Giro invierte el dado; Focos lo relanza si la prueba falla.</p>
        <div class="action-row">
          {{ maniobrasPrueba.map{|h| <form method="post" class="inline-form">
            <input type="hidden" name="accion" value="maniobra" />
            <input type="hidden" name="rowId" value="{{ h["rowId"] }}" />
            <button class="btn btn-ghost btn-small">Usar {{ h["card"].name }}</button>
          </form>} }}
        </div>
      </section> }}
      {{ g.jugadas > 0 && <p class="hint">Ya jugaron su carta de este ciclo. Tiren cuando quieran.</p> }}
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

    {{ g.tirado && pendingOpt != null && <section class="panel test-preview">
      <p class="eyebrow">Resultado de esta tirada</p>
      <p>Con estos dados: <strong>{{ previewOk ? "superada" : "fallida" }}</strong>.</p>
      {{ g.bonus > 0 && <p class="hint">Turbo: +{{ g.bonus }} al total.</p> }}
      {{ previewEstab && <p class="hint">Estabilizadores: +1 al total.</p> }}
      {{ previewBrazo && <p class="hint">Brazo Robótico: +1 Pista extra por el 6.</p> }}
      {{ previewBlindaje && <p class="hint">Blindaje de Titanio: el daño al Escudo se reduce 1.</p> }}
      {{ previewCebo && <p class="hint">Lanzar Cebo: el daño al Escudo se cancela.</p> }}
      {{ previewAhorro && <p class="hint">Ahorro de Oxígeno: no se gasta Energía.</p> }}
      <p class="option-chips">
        <span class="chip-label">Se aplica</span>
        {{ previewChips.map{|c| <span class="chip {{ c["cls"] }}" title="{{ c["title"] }}">{{ c["icon"] }} {{ c["text"] }}</span>} }}
      </p>
      {{ g.suerte && !previewOk && <p class="hint">Suerte del Principiante: al resolver, se relanza una vez.</p> }}
      {{ g.focosM && !previewOk && <p class="hint">Focos Abisales: al resolver, se relanza el dado.</p> }}
      <p class="hint">El efecto se aplica en esta tirada, al resolver. No se calcula al cerrar el misterio.</p>
    </section> }}

    {{ g.tirado && <section class="test-actions">
      <p class="muted">Tirada registrada. Ya no pueden jugar Maniobras: resuelvan.</p>
      <div class="action-row">
        <form method="post" class="inline-form">
          <input type="hidden" name="accion" value="resolver" />
          <button class="btn btn-primary">Resolver la prueba</button>
        </form>
      </div>
    </section> }}
  </section> }}

  {{ g.status == "activa" && g.fase == "resuelto" && <section class="panel result-panel">
    <p class="eyebrow">Resultado</p>
    <h2>{{ g.resultado == "ganada" ? "Prueba superada" : "Prueba fallida" }}</h2>
    <p class="muted">{{ g.ultimo }}</p>
    <p>Revisen los contadores. Al terminar el ciclo, las cartas que sobren de 3 se descartan al azar.</p>
    <form method="post">
      <input type="hidden" name="accion" value="terminar" />
      <button class="btn btn-primary">Terminar ciclo y reponer la mesa</button>
    </form>
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
        {{ item["card"].entry != "" && <p class="entry-badge">Al entrar
          {{ item["card"].entryChips.map{|c| <span class="chip {{ c["cls"] }}" title="{{ c["title"] }}" aria-label="{{ c["title"] }}">{{ c["icon"] }} {{ c["text"] }}</span>} }}
        </p> }}
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
                <span class="option-effects">
                  <span class="chip-label">Éxito</span>
                  {{ o["exitoChips"].map{|c| <span class="chip {{ c["cls"] }}" title="{{ c["title"] }}" aria-label="{{ c["title"] }}">{{ c["icon"] }} {{ c["text"] }}</span>} }}
                  <span class="chip-label">Fallo</span>
                  {{ o["falloChips"].map{|c| <span class="chip {{ c["cls"] }}" title="{{ c["title"] }}" aria-label="{{ c["title"] }}">{{ c["icon"] }} {{ c["text"] }}</span>} }}
                </span>
              </button>
            </form>
          </li>} }}
        </ul>
      </article>} }}
    </div>
    {{ mesa.isEmpty && <p class="muted">No quedan cartas activas. Repongan la mesa al terminar el ciclo.</p> }}
  </section> }}

  {{ g.status == "activa" && <section class="split">
    <div>
      {{ !ayuda.isEmpty && <section class="help-zone">
        <div class="section-head">
          <h2>Ayuda del equipo</h2>
          <p>Una vez, en cualquier momento</p>
        </div>
        <div class="hand">
          {{ ayuda.map{|a| <article class="card card-support" data-family="apoyo">
            <span class="card-art"><span class="card-emoji" aria-hidden="true">{{ a["card"].emoji }}</span></span>
            <span class="card-family">Apoyo · una vez</span>
            <h3>{{ a["card"].name }}</h3>
            <p>Elegí <span class="chip chip-energia">⚡ +{{ a["card"].value }}</span> o <span class="chip chip-escudo">🛡️ +{{ a["card"].value }}</span>.</p>
            <form method="post">
              <input type="hidden" name="accion" value="usar_ayuda" />
              <input type="hidden" name="rowId" value="{{ a["rowId"] }}" />
              <button class="btn btn-ghost btn-small" {{ g.fase == "apoyo" ? "disabled" : "" }}>Usar apoyo</button>
            </form>
          </article>} }}
        </div>
      </section> }}

      <div class="section-head">
        <h2>Mano del equipo</h2>
        <p>{{ handCount }} cartas · al final quedan 3</p>
      </div>
      <div class="hand">
        {{ hand.map{|h| <article class="card" data-family="{{ h["card"].isSupport ? "apoyo" : (h["card"].isTool ? "herramienta" : "maniobra") }}">
          <span class="card-art"><span class="card-emoji" aria-hidden="true">{{ h["card"].emoji }}</span></span>
          <span class="card-family">{{ h["card"].isSupport ? "Apoyo" : (h["card"].isTool ? "Herramienta" : "Maniobra") }}</span>
          <h3>{{ h["card"].name }}</h3>
          <section class="card-text">{{ h["card"].body }}</section>
          <div class="action-row">
            {{ h["card"].playNow ? <form method="post" class="inline-form">
              <input type="hidden" name="accion" value="jugar" />
              <input type="hidden" name="rowId" value="{{ h["rowId"] }}" />
              <button class="btn btn-primary btn-small" {{ puedeJugar ? "" : "disabled" }}>Jugar</button>
            </form> : <p class="hint card-hint">Elegí un Misterio y usala antes de tirar.</p> }}
          </div>
        </article>} }}
      </div>
      {{ hand.isEmpty && <p class="muted">Sin cartas en mano. Al terminar el ciclo roban 2.</p> }}
      <p class="hint">{{ g.jugadas == 0 ? "Todavía pueden jugar 1 carta este ciclo." : "Ya jugaron su carta de este ciclo." }} Al final del ciclo, las que sobren de 3 se descartan al azar.</p>
    </div>

    <aside>
      <div class="section-head">
        <h2>Herramienta activa</h2>
        <p>{{ tools.count }} / 1 · una por equipo</p>
      </div>
      {{ tools.map{|t| <article class="card card-tool" data-family="herramienta">
        <span class="card-art"><span class="card-emoji" aria-hidden="true">{{ t["card"].emoji }}</span></span>
        <span class="card-family">Herramienta</span>
        <h3>{{ t["card"].name }}</h3>
        <section class="card-text">{{ t["card"].body }}</section>

      </article>} }}
      {{ tools.isEmpty && <p class="muted">Todavía no jugaron ninguna Herramienta.</p> }}

      {{ top != null && <section class="panel peek">
        <p class="eyebrow">Sonar de Alta Frecuencia</p>
        <p>La próxima carta del mazo es <strong>{{ top.name }}</strong>.</p>
      </section> }}

      <div class="section-head aside-subhead">
        <h2>Acciones base</h2>
        <p>No son cartas</p>
      </div>

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
        <p>Cada ciclo: roban 2, juegan 1 carta como máximo y resuelven 1 misterio. Al final se descartan al azar hasta 3 y el submarino consume 1 Energía.</p>
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
