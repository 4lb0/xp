// El turno nuevo: la carta se juega antes de elegir la Misión, la mano se
// descarta al elegirla y las Maniobras que piden un dado usan la mesa de dados.
import "/_app/game" for Game
import "/_app/cards" for Card

class Turno {
  static normalizar(id) {
    `UPDATE games SET energia = 6, escudo = 6, pistas = 0, pistasTurno = 0,
       fase = 'listo', status = 'activa', turno = 1, jugador = 1,
       pruebaCarta = NULL, pruebaOpcion = NULL, dado1 = 0, dado2 = 0,
       tirado = 0, bonus = 0, cebo = 0, ahorro = 0, giro = 0, suerte = 0,
       blindajeM = 0, blindajeUsado = 0, focosM = 0, jugadas = 0,
       resueltas = 0, resultado = NULL, ultimo = NULL, maniobraRow = NULL
       WHERE id = ?`.query(id)
  }

  static nueva() {
    Test.post("/juego", {"accion": "nueva", "modo": "experto"}).withCsrf().status(302)
    var id = `SELECT MAX(id) AS id FROM games`.first["id"].toNum
    Turno.normalizar(id)
    return id
  }

  // Deja exactamente esas cartas en la mano (una copia de cada una).
  static mano(id, cardIds) {
    `UPDATE game_cards SET zone = 'equipo' WHERE gameId = ? AND zone = 'mano'`.query(id)
    for (cid in cardIds) {
      var row = `SELECT id FROM game_cards WHERE gameId = ? AND cardId = ? ORDER BY id`.first(id, cid)
      if (row != null) `UPDATE game_cards SET zone = 'mano' WHERE id = ?`.query(row["id"])
    }
  }

  // Deja una copia concreta en la mano y devuelve la fila.
  static aLaMano(id, cardId) {
    var row = `SELECT id FROM game_cards WHERE gameId = ? AND cardId = ? ORDER BY id`.first(id, cardId)
    `UPDATE game_cards SET zone = 'mano' WHERE id = ?`.query(row["id"])
    return row["id"]
  }

  // Deja una Misión de Cara en la mesa y devuelve su fila.
  static misionCara(id) {
    var row = `SELECT id FROM game_cards WHERE gameId = ? AND cardId = 'm01'`.first(id)
    `UPDATE game_cards SET zone = 'misterio' WHERE gameId = ? AND zone = 'mesa'`.query(id)
    `UPDATE game_cards SET zone = 'mesa' WHERE id = ?`.query(row["id"])
    return row["id"]
  }
}

// --- La Maniobra con dados usa la misma mesa que las pruebas ---

var gid = Turno.nueva()
var arpon = Turno.aLaMano(gid, "e06")
Test.post("/juego", {"accion": "jugar", "rowId": arpon.toString}).withCsrf().status(302)
var g = Game.find(gid)
Test.assert(g.fase == "maniobra", "el Arpón deja una tirada de Maniobra pendiente")
Test.assert(g.energia == 4, "el Arpón gasta 2 Energía al jugarse")
Test.assert(g.jugadas == 1, "el Arpón consume la carta del turno")
Test.assert(g.maniobraRow != null, "queda guardada la Maniobra pendiente")

Test.get("/juego").status(200).textContains("Tirá un dado")

Test.post("/juego", {"accion": "tirar_maniobra", "origen": "mesa", "d1": "2"}).withCsrf().status(302)
g = Game.find(gid)
Test.assert(g.energia == 4, "la tirada no vuelve a cobrar Energía")
Test.assert(g.pistas == 1, "un 2 en el Arpón es Cara: +1 Pista")
Test.assert(g.fase == "listo", "la Maniobra vuelve a la fase de Maniobras")
Test.assert(g.maniobraRow == null, "la Maniobra pendiente se limpia")
Test.assert(Game.ids(gid, "descarteEquipo").contains("e06"), "el Arpón va al descarte")
Test.assert(Game.lastLogs(gid, 1)[0]["text"].contains("CARA"), "la bitácora registra el dado")

// Con Seca no hay Pista.
gid = Turno.nueva()
arpon = Turno.aLaMano(gid, "e06")
Test.post("/juego", {"accion": "jugar", "rowId": arpon.toString}).withCsrf().status(302)
Test.post("/juego", {"accion": "tirar_maniobra", "origen": "mesa", "d1": "3"}).withCsrf().status(302)
Test.assert(Game.find(gid).pistas == 0, "un 3 en el Arpón es Seca: sin Pista")

// --- Elegir la Misión no descarta la mano ---

gid = Turno.nueva()
Test.assert(Game.count(gid, "mano") == 3, "la partida arranca con 3 en la mano")
var mision = Turno.misionCara(gid)
Test.post("/juego", {"accion": "elegir", "rowId": mision.toString, "opt": "A"}).withCsrf().status(302)
g = Game.find(gid)
Test.assert(g.fase == "prueba", "elegir deja la prueba preparada")
Test.assert(Game.count(gid, "mano") == 3, "elegir la Misión no descarta la mano")

// Volver a elegir tampoco toca la mano.
Test.post("/juego", {"accion": "cancelar"}).withCsrf().status(302)
g = Game.find(gid)
Test.assert(g.fase == "listo", "cancelar vuelve a la fase de Maniobras")
Test.assert(Game.count(gid, "mano") == 3, "cancelar no toca la mano")

// --- Una Maniobra no se puede jugar con la prueba ya elegida ---

gid = Turno.nueva()
mision = Turno.misionCara(gid)
var turbo = Turno.aLaMano(gid, "e09")
Test.post("/juego", {"accion": "elegir", "rowId": mision.toString, "opt": "A"}).withCsrf().status(302)
Test.post("/juego", {"accion": "maniobra", "rowId": turbo.toString}).withCsrf().status(302)
g = Game.find(gid)
Test.assert(g.bonus == 0, "la Maniobra jugada después de elegir no se aplica")
Test.assert(Game.ids(gid, "mano").contains("e09"), "la carta sigue en la mano")

// --- Cerrar con una carta jugada: roban 1 y la mano queda en 3 ---

gid = Turno.nueva()
Turno.mano(gid, ["e12", "e11", "e01"])
var bateria = `SELECT id FROM game_cards WHERE gameId = ? AND cardId = 'e12' AND zone = 'mano'`.first(gid)
Test.post("/juego", {"accion": "jugar", "rowId": bateria["id"].toString}).withCsrf().status(302)
Test.assert(Game.count(gid, "mano") == 2, "jugar una carta deja 2 en la mano")
mision = Turno.misionCara(gid)
Test.post("/juego", {"accion": "elegir", "rowId": mision.toString, "opt": "A"}).withCsrf().status(302)
Test.post("/juego", {"accion": "mesa", "d1": "2", "d2": "0"}).withCsrf().status(302)
Test.post("/juego", {"accion": "terminar"}).withCsrf().status(302)
g = Game.find(gid)
Test.assert(g.turno == 2, "el turno avanza")
Test.assert(Game.count(gid, "mano") == 3, "roban 1 y la mano vuelve a 3 sin descartar")
Test.assert(g.fase == "listo", "con 3 cartas el turno arranca directo")

// --- Tirada con suma y re-tirada: las sumas se vuelven a aplicar ---

gid = Turno.nueva()
mision = Turno.misionCara(gid)
Test.post("/juego", {"accion": "elegir", "rowId": mision.toString, "opt": "A"}).withCsrf().status(302)
`UPDATE games SET bonus = 2, suerte = 1 WHERE id = ?`.query(gid)
// Cara con 1 falla; con la Suma no cambia la paridad, pero Suerte pide repetir.
Test.post("/juego", {"accion": "mesa", "d1": "1", "d2": "0"}).withCsrf().status(302)
g = Game.find(gid)
Test.assert(g.fase == "reroll", "la Suerte frena la resolución")
Test.assert(g.escudo == 6, "no se aplica el fallo antes de repetir")
Test.get("/juego").status(200).textContains("La prueba falló")
Test.post("/juego", {"accion": "reroll", "origen": "mesa", "d1": "4"}).withCsrf().status(302)
g = Game.find(gid)
Test.assert(g.fase == "resuelto", "la segunda tirada resuelve la prueba")
Test.assert(g.resultado == "ganada", "un 4 es Cara: la prueba se gana")
Test.assert(g.bonus == 0, "las sumas se limpian al cerrar la prueba")

// --- Una carta de apoyo se juega desde la mano y gasta la carta del turno ---

gid = Turno.nueva()
Turno.mano(gid, ["e17", "e12", "e11"])
var kit = `SELECT id FROM game_cards WHERE gameId = ? AND cardId = 'e17' AND zone = 'mano'`.first(gid)
Test.post("/juego", {"accion": "jugar", "rowId": kit["id"].toString}).withCsrf().status(302)
g = Game.find(gid)
Test.assert(g.energia == 7, "el Kit da +1 Energía")
Test.assert(g.escudo == 7, "el Kit también da +1 Escudo")
Test.assert(g.jugadas == 1, "el apoyo consume la carta del turno")
Test.assert(g.fase == "listo", "el apoyo se resuelve en el momento")
Test.assert(Game.ids(gid, "descarteEquipo").contains("e17"), "el apoyo va al descarte")
var bateria2 = `SELECT id FROM game_cards WHERE gameId = ? AND cardId = 'e12' AND zone = 'mano'`.first(gid)
Test.post("/juego", {"accion": "jugar", "rowId": bateria2["id"].toString}).withCsrf().status(302)
Test.assert(Game.find(gid).energia == 7, "no se puede jugar una segunda carta en el turno")

// --- La Maniobra del turno queda a la vista hasta resolver ---

gid = Turno.nueva()
Turno.mano(gid, ["e09", "e12", "e11"])
var turboFila = `SELECT id FROM game_cards WHERE gameId = ? AND cardId = 'e09' AND zone = 'mano'`.first(gid)
Test.post("/juego", {"accion": "maniobra", "rowId": turboFila["id"].toString}).withCsrf().status(302)
Test.assert(Game.ids(gid, "preparada").contains("e09"), "la Maniobra preparada queda a la vista")
Test.get("/juego").status(200).textContains("Maniobra del turno")
mision = Turno.misionCara(gid)
Test.post("/juego", {"accion": "elegir", "rowId": mision.toString, "opt": "A"}).withCsrf().status(302)
Test.post("/juego", {"accion": "mesa", "d1": "2", "d2": "0"}).withCsrf().status(302)
Test.assert(Game.ids(gid, "preparada").isEmpty, "al resolver, la Maniobra sale de la mesa")
Test.assert(Game.ids(gid, "descarteEquipo").contains("e09"), "al resolver, la Maniobra va al descarte")

// --- Un POST sin token CSRF no ejecuta la acción ---

var partidasAntes = `SELECT COUNT(*) AS n FROM games`.first["n"].toNum
Test.post("/juego", {"accion": "nueva", "modo": "experto"}).status(302)
Test.assert(`SELECT COUNT(*) AS n FROM games`.first["n"].toNum == partidasAntes, "sin CSRF no se crea una partida")
