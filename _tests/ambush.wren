// Emboscadas simultáneas: con varias en el reparto inicial se elige una y
// solo esa cobra. Una emboscada ya en la mesa no vuelve a cobrar.
import "/_app/game" for Game

class Fixture {
  static reset(id) {
    `UPDATE games SET energia = 6, escudo = 6, pistas = 0, pistasTurno = 0,
       fase = 'listo', status = 'activa', turno = 1, jugador = 1,
       pruebaCarta = NULL, pruebaOpcion = NULL, dado1 = 0, dado2 = 0,
       tirado = 0, bonus = 0, cebo = 0, ahorro = 0, giro = 0, suerte = 0,
       blindajeM = 0, blindajeUsado = 0, focosM = 0, jugadas = 0,
       resueltas = 0, resultado = NULL, ultimo = NULL
       WHERE id = ?`.query(id)
  }

  // Deja exactamente las cartas indicadas en la mesa.
  static mesa(id, cardIds) {
    `UPDATE game_cards SET zone = 'misterio' WHERE gameId = ? AND zone = 'mesa'`.query(id)
    for (cid in cardIds) {
      `UPDATE game_cards SET zone = 'mesa' WHERE gameId = ? AND cardId = ?`.query(id, cid)
    }
  }
}

// --- Detección y elección con dos emboscadas ---

Test.post("/juego", {"accion": "nueva", "modo": "casual"}).status(302)
var gid = `SELECT MAX(id) AS id FROM games`.first["id"].toNum

// m20 cobra Escudo −1 y m28 cobra Energía −1: así se ve cuál se aplicó.
Fixture.mesa(gid, ["m20", "m28", "m01"])
Fixture.reset(gid)
Game.enterInitial(gid)

var g = Game.find(gid)
Test.assert(g.fase == "emboscada", "con dos emboscadas la partida espera la elección")
Test.assert(g.energia == 6 && g.escudo == 6 && g.pistas == 0, "no se cobra ninguna emboscada antes de elegir")
var amb = Game.cardsIn(gid, "mesa").where { |m| m["card"].entry != "" }.toList
Test.assert(amb.count == 2, "la mesa conserva las dos emboscadas")

Test.get("/juego")
  .status(200)
  .textContains("Entraron varias emboscadas a la vez")
  .textContains("Sufrir esta emboscada")

var rowM20 = `SELECT id FROM game_cards WHERE gameId = ? AND cardId = 'm20'`.first(gid)
Test.post("/juego", {"accion": "elegir_emboscada", "rowId": rowM20["id"].toString})
  .status(302)

g = Game.find(gid)
Test.assert(g.fase == "listo", "elegir cierra la fase de emboscada")
Test.assert(g.escudo == 5, "solo cobra la emboscada elegida: Escudo −1")
Test.assert(g.energia == 6, "la emboscada no elegida no cobra: Energía queda en 6")
Test.assert(Game.count(gid, "mesa") == 3, "la mesa sigue con 3 cartas después de elegir")
Test.assert(Game.lastLogs(gid, 6).map { |l| l["text"] }.join(" ").contains("Emboscada inicial: El banco de tiburones"), "la elección queda en la bitácora")

Test.get("/juego")
  .status(200)
  .textContains("ya resuelto")

// --- Una sola emboscada: cobra automáticamente ---

Fixture.mesa(gid, ["m20", "m01", "m02"])
Fixture.reset(gid)
Game.enterInitial(gid)

g = Game.find(gid)
Test.assert(g.fase == "listo", "con una sola emboscada no hay fase de elección")
Test.assert(g.escudo == 5 && g.energia == 6, "la única emboscada cobra al entrar")

// No se vuelve a cobrar al recargar ni al iniciar el turno.
Test.get("/juego").status(200)
Test.assert(Game.find(gid).escudo == 5, "una emboscada ya en la mesa no vuelve a cobrar al recargar")

// --- Limpieza: dejar la sesión sin partida para el resto de la suite ---

Test.post("/juego", {"accion": "reiniciar"}).status(302)
Test.assert(Game.find(gid) == null, "reiniciar borra la partida de prueba")
