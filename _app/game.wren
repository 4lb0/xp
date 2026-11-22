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
  saltar { _row["saltar"].toNum == 1 }
  reparado { _row["reparado"].toNum == 1 }
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
    var en = modo == "facil" ? 6 : 5
    var es = modo == "facil" ? 6 : 5
    `INSERT INTO games (players, energia, escudo, modo) VALUES (?, ?, ?, ?)`.query([players, en, es, modo])
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
    Game.draw(id, "misterio", "mesa", 3)
    Game.draw(id, "equipo", "mano", 3)
    `UPDATE games SET ultimo = ? WHERE id = ?`.query("La expedición empieza. El submarino se hunde en la fosa.", id)
    Game.log(id, "Comienza la expedición con " + players.toString + " jugadores, modo " + modo + ".")
    var g0 = Game.find(id)
    for (r in Game.rows(id, "mesa")) {
      var c = Card.get(r["cardId"])
      if (c != null && c.entry != "") {
        Game.apply(id, g0, Game.parseEffects(c.entry), true, [])
        Game.log(id, "Emboscada al entrar: " + c.name + " — " + c.entryLabel + ".")
        g0 = Game.find(id)
      }
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

  static draw(id, from, to, amount) {
    var last = null
    for (i in 1..amount) {
      var row = `SELECT id, cardId FROM game_cards WHERE gameId = ? AND zone = ? ORDER BY ord`.first(id, from)
      if (row == null) return last
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
    var eff = {"pistas": 0, "energia": 0, "escudo": 0, "turno": 0}
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
    var dTu = eff["turno"] == null ? 0 : eff["turno"]
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
    var blindaje = tools.contains("reduce_damage") && !g.blindajeUsado
    if (dEs < 0 && blindaje) {
      dEs = dEs + 1
      blindajeAplicado = true
      notas.add("Blindaje de Titanio absorbió 1 de daño")
    }
    if (ok && dPi > 0 && tools.contains("extra_clue_six") && (g.dado1 == 6 || g.dado2 == 6)) {
      dPi = dPi + 1
      notas.add("Brazo Robótico sumó 1 Pista extra")
    }
    var saltar = (dTu < 0 || g.saltar) ? 1 : 0
    var en = Game.clamp(g.energia + dEn, 0, 6)
    var es = Game.clamp(g.escudo + dEs, 0, 6)
    var pi = Game.clamp(g.pistas + dPi, 0, 6)
    var status = "activa"
    if (pi >= 6) {
      status = "victoria"
    } else if (en <= 0 || es <= 0) {
      status = "derrota"
    }
    `UPDATE games SET energia = ?, escudo = ?, pistas = ?, status = ?, cebo = ?, blindajeUsado = ?, pistasTurno = pistasTurno + ?, saltar = ? WHERE id = ?`.query([en, es, pi, status, ceboUsado ? 0 : (g.cebo ? 1 : 0), blindajeAplicado ? 1 : (g.blindajeUsado ? 1 : 0), dPi > 0 ? dPi : 0, saltar, id])
    return {"energia": en, "escudo": es, "pistas": pi, "status": status, "saltar": saltar, "notas": notas}
  }
}
