import "cards" for Card

class Game {
  construct new(row) { _row = row }

  id { _row["id"].toNum }
  players { _row["players"].toNum }
  modo { _row["modo"] || "normal" }
  energia { _row["energia"].toNum }
  escudo { _row["escudo"].toNum }
  pistas { _row["pistas"].toNum }
  turno { _row["turno"].toNum }
  jugador { _row["jugador"].toNum }
  status { _row["status"] }
  fase { _row["fase"] }
  pruebaCarta { _row["pruebaCarta"] }
  pruebaOpcion { _row["pruebaOpcion"] }
  dado1 { _row["dado1"].toNum }
  dado2 { _row["dado2"].toNum }
  tirado { _row["tirado"].toNum == 1 }
  bonus { _row["bonus"].toNum }
  cebo { _row["cebo"].toNum == 1 }
  ahorro { _row["ahorro"].toNum == 1 }
  giro { _row["giro"].toNum == 1 }
  suerte { _row["suerte"].toNum == 1 }
  empujado { _row["empujado"].toNum == 1 }
  pistasTurno { _row["pistasTurno"].toNum }
  blindajeM { _row["blindajeM"].toNum == 1 }
  focosM { _row["focosM"].toNum == 1 }
  apoyoCarta { _row["apoyoCarta"] == null ? null : _row["apoyoCarta"].toNum }
  apoyoOrigen { _row["apoyoOrigen"] }
  fasePrevia { _row["fasePrevia"] }
  blindajeUsado { _row["blindajeUsado"].toNum == 1 }
  focosUsado { _row["focosUsado"].toNum == 1 }
  jugadas { _row["jugadas"].toNum }
  resueltas { _row["resueltas"].toNum }
  resultado { _row["resultado"] }
  ultimo { _row["ultimo"] }

  static find(id) {
    if (id == null) return null
    var row = `SELECT * FROM games WHERE id = ?`.first(id)
    return row == null ? null : row.to(Game)
  }

  static create(players, modo) {
    var en = 6
    var es = 6
    var ap = 0
    `INSERT INTO games (players, energia, escudo, modo, apoyo) VALUES (?, ?, ?, ?, ?)`.query([players, en, es, modo, ap])
    var id = `SELECT MAX(id) AS id FROM games`.first["id"].toNum
    for (i in 1..60) {
      var m = Card.get("m" + Util.lpad(i.toString, 2, "0"))
      if (m == null) continue
      `INSERT INTO game_cards (gameId, cardId, zone) VALUES (?, ?, 'misterio')`.query(id, m.id)
    }
    for (i in 1..30) {
      var c = Card.get("e" + Util.lpad(i.toString, 2, "0"))
      if (c == null) continue
      for (k in 1..c.copies) {
        `INSERT INTO game_cards (gameId, cardId, zone) VALUES (?, ?, 'equipo')`.query(id, c.id)
      }
    }
    `UPDATE game_cards SET ord = RANDOM() WHERE gameId = ?`.query(id)
    if (modo != "experto") {
      `UPDATE game_cards SET zone = 'ayuda' WHERE gameId = ? AND cardId = 'e17'`.query(id)
    }
    if (modo == "facil") {
      `UPDATE game_cards SET zone = 'ayuda' WHERE gameId = ? AND cardId = 'e18'`.query(id)
    }
    Game.draw(id, "misterio", "mesa", 3)
    Game.draw(id, "equipo", "mano", 3)
    `UPDATE games SET ultimo = ? WHERE id = ?`.query("La expedición empieza. El submarino se hunde en la fosa.", id)
    var modoLabel = modo == "facil" ? "Asistido" : (modo == "casual" ? "Normal" : "Experto")
    Game.log(id, "Comienza la expedición en modo " + modoLabel + ".")
    var g0 = Game.find(id)
    var emboscadas = []
    for (r in Game.rows(id, "mesa")) {
      var c = Card.get(r["cardId"])
      if (c != null && c.entry != "") emboscadas.add(c)
    }
    if (emboscadas.count == 1) {
      var c = emboscadas[0]
      Game.apply(id, g0, Game.parseEffects(c.entry), true, [])
      Game.log(id, "Emboscada al entrar: " + c.name + " — " + c.entryLabel + ".")
    } else if (emboscadas.count > 1) {
      `UPDATE games SET fase = 'emboscada' WHERE id = ?`.query(id)
      Game.log(id, "Tres cartas en la mesa: elijan qué emboscada inicial sufrir.")
    }
    return id
  }

  static destroy(id) {
    `DELETE FROM game_cards WHERE gameId = ?`.query(id)
    `DELETE FROM game_log WHERE gameId = ?`.query(id)
    `DELETE FROM games WHERE id = ?`.query(id)
  }

  static log(id, text) {
    `INSERT INTO game_log (gameId, text) VALUES (?, ?)`.query(id, text)
  }

  static lastLogs(id, n) {
    var rows = `SELECT text, createdAt FROM game_log WHERE gameId = ? ORDER BY id DESC LIMIT ?`.fetch(id, n)
    return rows
  }

  static recycleDiscard(id, from) {
    var prefix = from == "misterio" ? "m%" : "e%"
    var rows = `SELECT id FROM game_cards WHERE gameId = ? AND zone = 'descarte' AND cardId LIKE ?`.fetch(id, prefix)
    if (rows.isEmpty) return false
    for (r in rows) {
      `UPDATE game_cards SET zone = ?, ord = RANDOM() WHERE id = ?`.query(from, r["id"])
    }
    Game.log(id, from == "misterio" ? "Se mezcla el descarte del Mazo del Juego." : "Se mezcla el descarte del Mazo del Equipo.")
    return true
  }

  static draw(id, from, to, amount) {
    var last = null
    for (i in 1..amount) {
      var row = `SELECT id, cardId FROM game_cards WHERE gameId = ? AND zone = ? ORDER BY ord`.first(id, from)
      if (row == null) {
        if (!Game.recycleDiscard(id, from)) return last
        row = `SELECT id, cardId FROM game_cards WHERE gameId = ? AND zone = ? ORDER BY ord`.first(id, from)
        if (row == null) return last
      }
      `UPDATE game_cards SET zone = ? WHERE id = ?`.query(to, row["id"])
      last = row["cardId"]
    }
    return last
  }

  static rows(id, zone) {
    return `SELECT * FROM game_cards WHERE gameId = ? AND zone = ? ORDER BY id`.fetch(id, zone)
  }

  static count(id, zone) {
    return `SELECT COUNT(*) AS n FROM game_cards WHERE gameId = ? AND zone = ?`.first(id, zone)["n"].toNum
  }

  static ids(id, zone) {
    return Game.rows(id, zone).map { |r| r["cardId"] }
  }

  // Las herramientas se guardan como cardId (e01, e07...). Sus efectos
  // (plus_one_sum, extra_clue_six...) hay que resolverlos contra la carta.
  static hasEffect(cardIds, effect) {
    for (cid in cardIds) {
      var c = Card.get(cid)
      if (c != null && c.effect == effect) return true
    }
    return false
  }

  static cardsIn(id, zone) {
    var out = []
    for (r in Game.rows(id, zone)) {
      var c = Card.get(r["cardId"])
      if (c != null) out.add({"rowId": r["id"], "card": c})
    }
    return out
  }

  static topCard(id) {
    var row = `SELECT cardId FROM game_cards WHERE gameId = ? AND zone = 'misterio' ORDER BY ord`.first(id)
    return row == null ? null : Card.get(row["cardId"])
  }

  static move(rowId, zone) {
    `UPDATE game_cards SET zone = ? WHERE id = ?`.query(zone, rowId)
  }

  static hasTool(id, effect) {
    for (item in Game.cardsIn(id, "herramientas")) {
      if (item["card"].effect == effect) return true
    }
    return false
  }

  static roll(n) {
    var out = []
    for (i in 1..n) {
      out.add(`SELECT (ABS(RANDOM()) % 6) + 1 AS d`.first["d"].toNum)
    }
    return out
  }

  static clamp(n, lo, hi) { n < lo ? lo : (n > hi ? hi : n) }

  static parseEffects(text) {
    var eff = {"pistas": 0, "energia": 0, "escudo": 0}
    if (text == null || text.trim == "") return eff
    for (piece in text.split(",")) {
      var t = piece.trim
      if (t == "") continue
      var i = t.indexOf("+")
      var sign = 1
      if (i == -1) {
        i = t.indexOf("-")
        sign = -1
      }
      if (i < 1) continue
      var key = t[0...i].trim
      var val = Num.fromString(t[i + 1..t.count - 1].trim)
      if (eff.containsKey(key)) eff[key] = val * sign
    }
    return eff
  }

  static evalTest(kind, target, d1, d2, bonus, estabilizadores) {
    if (kind == "cara") return d1 % 2 == 0
    if (kind == "seca") return d1 % 2 == 1
    if (kind == "dobles") return d1 == d2
    if (kind == "sin1") return d1 != 1 && d1 != 6 && d2 != 1 && d2 != 6
    if (kind == "suma") return d1 + d2 + bonus + (estabilizadores ? 1 : 0) >= target
    return d1 + bonus >= target
  }

  // Aplica un resultado ya evaluado. Devuelve el texto para el registro.
  static apply(id, g, eff, ok, tools) {
    var dEn = eff["energia"] == null ? 0 : eff["energia"]
    var dEs = eff["escudo"] == null ? 0 : eff["escudo"]
    var dPi = eff["pistas"] == null ? 0 : eff["pistas"]
    var notas = []
    var ceboUsado = false
    var blindajeAplicado = false
    if (dEn < 0 && g.ahorro) {
      dEn = 0
      notas.add("Ahorro de Oxígeno evitó el gasto de Energía")
    }
    if (dEs < 0 && g.cebo) {
      dEs = 0
      ceboUsado = true
      notas.add("Lanzar Cebo evitó el daño al Escudo")
    }
    var blindaje = (Game.hasEffect(tools, "reduce_damage") || g.blindajeM) && !g.blindajeUsado
    if (dEs < 0 && blindaje) {
      dEs = dEs + 1
      blindajeAplicado = true
      notas.add("Blindaje de Titanio absorbió 1 de daño")
    }
    if (ok && dPi > 0 && Game.hasEffect(tools, "extra_clue_six") && (g.dado1 == 6 || g.dado2 == 6)) {
      dPi = dPi + 1
      notas.add("Brazo Robótico sumó 1 Pista extra")
    }
    var en = g.energia + dEn
    var es = g.escudo + dEs
    var pi = g.pistas + dPi
    if (en < 0) en = 0
    if (es < 0) es = 0
    if (pi < 0) pi = 0
    var status = "activa"
    if (pi >= 6) status = "victoria"
    `UPDATE games SET energia = ?, escudo = ?, pistas = ?, status = ?, cebo = ?, blindajeUsado = ?, blindajeM = ?, pistasTurno = pistasTurno + ? WHERE id = ?`.query([en, es, pi, status, ceboUsado ? 0 : (g.cebo ? 1 : 0), blindajeAplicado ? 1 : (g.blindajeUsado ? 1 : 0), blindajeAplicado ? 0 : (g.blindajeM ? 1 : 0), dPi > 0 ? dPi : 0, id])
    return {"energia": en, "escudo": es, "pistas": pi, "status": status, "notas": notas}
  }

  // Resuelve la prueba ya tirada. Devuelve un mapa con ok/error/status.
  static resolve(id) {
    var g = Game.find(id)
    if (g == null) return {"ok": false, "error": "No hay una partida activa.", "status": "activa"}
    var c = g.pruebaCarta == null ? null : Card.get(g.pruebaCarta)
    var opt = c == null ? null : c.option(g.pruebaOpcion)
    if (opt == null) return {"ok": false, "error": "No hay una prueba para resolver.", "status": "activa"}
    if (!g.tirado) return {"ok": false, "error": "Primero tienen que tirar los dados.", "status": "activa"}

    var tools = Game.ids(id, "herramientas")
    var estab = Game.hasEffect(tools, "plus_one_sum")
    var d1 = g.dado1
    var d2 = g.dado2
    var ok = Game.evalTest(opt["tipoPrueba"], opt["objetivo"], d1, d2, g.bonus, estab)
    if (!ok && g.suerte) {
      var dice = Game.roll(opt["dados"])
      d1 = dice[0]
      d2 = opt["dados"] == 2 ? dice[1] : 0
      ok = Game.evalTest(opt["tipoPrueba"], opt["objetivo"], d1, d2, g.bonus, estab)
      Game.log(id, "Suerte del Principiante: nueva tirada " + d1.toString + (opt["dados"] == 2 ? " y " + d2.toString : "") + ".")
    } else if (!ok && g.focosM) {
      d1 = Game.roll(1)[0]
      ok = Game.evalTest(opt["tipoPrueba"], opt["objetivo"], d1, d2, g.bonus, estab)
      Game.log(id, "Focos Abisales: nueva tirada " + d1.toString + ".")
    }

    // Guardar los dados definitivos antes de aplicar para que Brazo Robótico vea el 6 real.
    `UPDATE games SET dado1 = ?, dado2 = ? WHERE id = ?`.query(d1, d2, id)
    g = Game.find(id)
    var eff = Game.parseEffects(ok ? opt["exito"] : opt["fallo"])
    var res = Game.apply(id, g, eff, ok, tools)
    var mesaRow = `SELECT id FROM game_cards WHERE gameId = ? AND cardId = ? AND zone = 'mesa'`.first(id, g.pruebaCarta)
    if (mesaRow != null) Game.move(mesaRow["id"], "descarte")
    var texto = (ok ? "Prueba superada" : "Prueba fallida") + ": " + c.name + " — " + opt["texto"] + "."
    if (!res["notas"].isEmpty) texto = texto + " " + res["notas"].join(". ") + "."
    `UPDATE games SET fase = 'resuelto', resultado = ?, resueltas = 1, ultimo = ?, dado1 = ?, dado2 = ?, tirado = 0, bonus = 0, giro = 0, suerte = 0, focosM = 0 WHERE id = ?`.query([ok ? "ganada" : "perdida", texto, d1, d2, id])
    Game.log(id, texto)
    if (res["status"] == "victoria") Game.log(id, "¡Seis Pistas! El misterio queda resuelto.")
    return {"ok": ok, "error": "", "status": res["status"], "texto": texto}
  }
}
