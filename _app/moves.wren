// Compara las zonas de la partida antes y después de una acción para saber
// qué cartas se movieron. La animación del cliente usa esta lista para
// destacar solo lo nuevo: no adivina ni anima la página entera.
import "/_app/game" for Game
import "/_app/cards" for Card

class Moves {
  static zones() {
    return ["misterio", "equipo", "mano", "mesa", "herramientas", "ayuda", "descarteJuego", "descarteEquipo"]
  }

  // Guarda el estado actual en la sesión y devuelve los movimientos que
  // ocurrieron desde la última vez que se renderizó /juego.
  static take(gameId, session) {
    var current = {}
    for (zone in Moves.zones()) {
      var rows = {}
      for (r in Game.rows(gameId, zone)) {
        rows[r["id"].toString] = r["cardId"]
      }
      current[zone] = rows
    }

    var seen = null
    var raw = session.get("xpSeen")
    if (raw != null && raw.startsWith("{")) {
      var parsed = Json.parse(raw)
      if (parsed != null && parsed["game"] == gameId.toString) seen = parsed["zones"]
    }
    if (seen == null) seen = {}

    var out = []
    for (zone in Moves.zones()) {
      for (rowId in current[zone].keys) {
        var cardId = current[zone][rowId]
        var from = null
        for (prevZone in Moves.zones()) {
          var prev = seen[prevZone]
          if (prev != null && prev[rowId] != null) {
            from = prevZone
            break
          }
        }
        // Reparto inicial: no estaba en ninguna zona vista.
        if (from == null) from = cardId.startsWith("m") ? "misterio" : "equipo"
        if (from == zone) continue

        var kind = "move"
        if (zone == "descarteJuego" || zone == "descarteEquipo") {
          kind = "discard"
        } else if (zone == "herramientas" || zone == "ayuda") {
          kind = "play"
        } else if (from == "misterio" || from == "equipo") {
          kind = "draw"
        }

        var card = Card.get(cardId)
        out.add({
          "rowId": rowId,
          "cardId": cardId,
          "from": from,
          "to": zone,
          "kind": kind,
          "deck": cardId.startsWith("m") ? "juego" : "equipo",
          "name": card == null ? "" : card.name,
          "emoji": card == null ? "" : card.emoji
        })
      }
    }

    session.set("xpSeen", Json.stringify({"game": gameId.toString, "zones": current}))
    return out
  }
}
