// Resolución de una prueba: éxito, fallo, re-tiradas, victoria y protección.
import "/_app/game" for Game

class ResolveFixture {
  static fresh() {
    var id = Game.create(1, "experto")
    `UPDATE games SET energia = 6, escudo = 6, pistas = 0, pistasTurno = 0,
       fase = 'listo', status = 'activa', turno = 1, jugador = 1,
       pruebaCarta = NULL, pruebaOpcion = NULL, dado1 = 0, dado2 = 0,
       tirado = 0, bonus = 0, cebo = 0, ahorro = 0, giro = 0, suerte = 0,
       blindajeM = 0, blindajeUsado = 0, focosM = 0, jugadas = 0,
       resueltas = 0, resultado = NULL, ultimo = NULL
       WHERE id = ?`.query(id)
    `UPDATE game_cards SET zone = 'descarteEquipo' WHERE gameId = ? AND zone = 'herramientas'`.query(id)
    return id
  }

  // Deja una carta concreta en la mesa y una prueba ya tirada.
  static pending(id, cardId, label, d1, d2, tirado) {
    var row = `SELECT id FROM game_cards WHERE gameId = ? AND cardId = ?`.first(id, cardId)
    `UPDATE game_cards SET zone = 'misterio' WHERE gameId = ? AND zone = 'mesa' AND cardId != ?`.query(id, cardId)
    if (row == null) {
      `INSERT INTO game_cards (gameId, cardId, zone, ord) VALUES (?, ?, 'mesa', 0)`.query(id, cardId)
    } else {
      `UPDATE game_cards SET zone = 'mesa' WHERE id = ?`.query(row["id"])
    }
    `UPDATE games SET fase = 'prueba', pruebaCarta = ?, pruebaOpcion = ?,
       dado1 = ?, dado2 = ?, tirado = ?, bonus = 0, jugadas = 0 WHERE id = ?`.query([cardId, label, d1, d2, tirado, id])
  }

  static equip(id, cardId) {
    `INSERT INTO game_cards (gameId, cardId, zone, ord) VALUES (?, ?, 'herramientas', 0)`.query(id, cardId)
  }
}

// --- Errores de flujo ---

Test.assert(Game.resolve(999999)["error"].contains("No hay una partida"), "resolver sin partida avisa")
var id = ResolveFixture.fresh()
Test.assert(Game.resolve(id)["error"].contains("No hay una prueba"), "resolver sin prueba pendiente avisa")
Game.destroy(id)

id = ResolveFixture.fresh()
ResolveFixture.pending(id, "m01", "A", 0, 0, 0)
Test.assert(Game.resolve(id)["error"].contains("tirar los dados"), "resolver sin tirar avisa")
Game.destroy(id)

// --- Éxito ---

id = ResolveFixture.fresh()
ResolveFixture.pending(id, "m01", "A", 2, 0, 1)
var res = Game.resolve(id)
Test.assert(res["ok"] == true, "par con 2 supera la prueba")
Test.assert(res["error"] == "", "una resolución válida no devuelve error")
Test.assert(res["status"] == "activa", "con 1 Pista la partida sigue activa")
Test.assert(res["texto"].contains("Prueba superada"), "el texto avisa que se superó")
Test.assert(res["texto"].contains("Señales en la oscuridad"), "el texto nombra la carta")
var g = Game.find(id)
Test.assert(g.pistas == 1, "el éxito aplica pistas+1")
Test.assert(g.fase == "resuelto", "la fase queda resuelta")
Test.assert(g.resultado == "ganada", "el resultado queda como ganada")
Test.assert(g.resueltas == 1, "se marca una Misión resuelta en el turno")
Test.assert(!g.tirado, "la tirada se limpia al resolver")
Test.assert(g.dado1 == 2, "el dado queda guardado para mostrarlo")
Test.assert(g.ultimo != null && g.ultimo.contains("Prueba superada"), "ultimo guarda el texto")
Test.assert(Game.count(id, "mesa") == 0, "la carta resuelta sale de la mesa")
Test.assert(Game.ids(id, "descarteJuego").contains("m01"), "la carta resuelta va al descarte")
Test.assert(Game.lastLogs(id, 1)[0]["text"].contains("Prueba superada"), "la bitácora registra el resultado")
Game.destroy(id)

// --- Fallo ---

id = ResolveFixture.fresh()
ResolveFixture.pending(id, "m01", "A", 1, 0, 1)
res = Game.resolve(id)
Test.assert(res["ok"] == false, "par con 1 falla la prueba")
Test.assert(res["texto"].contains("Prueba fallida"), "el texto avisa que falló")
g = Game.find(id)
Test.assert(g.escudo == 5, "el fallo aplica escudo-1")
Test.assert(g.pistas == 0, "el fallo no suma Pistas")
Test.assert(g.resultado == "perdida", "el resultado queda como perdida")
Test.assert(Game.ids(id, "descarteJuego").contains("m01"), "la carta fallada también va al descarte")
Game.destroy(id)

// --- Suerte del Principiante: re-tirada ---

id = ResolveFixture.fresh()
ResolveFixture.pending(id, "m01", "A", 1, 0, 1)
`UPDATE games SET suerte = 1 WHERE id = ?`.query(id)
res = Game.resolve(id)
Test.assert(res["reroll"] == true, "Suerte frena la resolución y pide re-tirar")
Test.assert(res["error"] == "", "la re-tirada no es un error")
Test.assert(res["texto"] == "", "la re-tirada no aplica texto de resultado")
g = Game.find(id)
Test.assert(g.fase == "reroll", "la fase pasa a reroll")
Test.assert(g.escudo == 6, "no se aplica el daño antes de re-tirar")
Test.assert(g.pistas == 0, "no se gana Pista antes de re-tirar")
Test.assert(Game.count(id, "mesa") == 1, "la carta sigue en la mesa")
Test.assert(Game.lastLogs(id, 1)[0]["text"].contains("Suerte del Principiante"), "la bitácora avisa la re-tirada")

// La segunda tirada sale bien: recién ahí se aplica el éxito.
`UPDATE games SET dado1 = 2, tirado = 1, fase = 'prueba', suerte = 0 WHERE id = ?`.query(id)
res = Game.resolve(id)
Test.assert(res["ok"] == true, "la segunda tirada puede superar la prueba")
Test.assert(Game.find(id).pistas == 1, "el éxito se aplica después de la re-tirada")
Test.assert(!Game.find(id).suerte, "Suerte se consume")
Game.destroy(id)

// --- Focos Abisales: relanza un dado ---

id = ResolveFixture.fresh()
ResolveFixture.pending(id, "m01", "A", 1, 0, 1)
`UPDATE games SET focosM = 1 WHERE id = ?`.query(id)
res = Game.resolve(id)
Test.assert(res["reroll"] == true, "Focos también frena la resolución")
Test.assert(Game.find(id).fase == "reroll", "Focos lleva a la fase reroll")
Test.assert(Game.lastLogs(id, 1)[0]["text"].contains("Focos Abisales"), "la bitácora nombra Focos")
Game.destroy(id)

// --- Victoria ---

id = ResolveFixture.fresh()
`UPDATE games SET pistas = 5 WHERE id = ?`.query(id)
ResolveFixture.pending(id, "m01", "A", 2, 0, 1)
res = Game.resolve(id)
Test.assert(res["ok"] == true, "la prueba que da la sexta Pista se resuelve")
Test.assert(res["status"] == "victoria", "seis Pistas devuelven victoria")
g = Game.find(id)
Test.assert(g.status == "victoria", "la victoria queda guardada")
Test.assert(g.pistas == 6, "las Pistas llegan a 6")
Test.assert(Game.lastLogs(id, 1)[0]["text"].contains("Seis Pistas"), "la bitácora anuncia la victoria")
Game.destroy(id)

// --- Brazo Robótico ve el dado real ---

id = ResolveFixture.fresh()
ResolveFixture.equip(id, "e05")
ResolveFixture.pending(id, "m01", "A", 6, 0, 1)
res = Game.resolve(id)
Test.assert(res["ok"] == true, "un 6 en par supera la prueba")
Test.assert(Game.find(id).pistas == 2, "Brazo suma la Pista extra al resolver")
Test.assert(res["texto"].contains("Brazo Robótico"), "el texto incluye la nota del Brazo")
Game.destroy(id)

// --- Ahorro de Oxígeno durante la resolución ---

id = ResolveFixture.fresh()
`UPDATE games SET ahorro = 1 WHERE id = ?`.query(id)
ResolveFixture.pending(id, "m04", "B", 1, 0, 1)
res = Game.resolve(id)
Test.assert(res["ok"] == false, "1 no llega al 4+ de m04")
Test.assert(Game.find(id).energia == 6, "Ahorro evita el energia-1 del fallo")
Test.assert(res["texto"].contains("Ahorro"), "el texto menciona el Ahorro")
Game.destroy(id)

// Sin Ahorro, el mismo fallo cuesta Energía.
id = ResolveFixture.fresh()
ResolveFixture.pending(id, "m04", "B", 1, 0, 1)
Game.resolve(id)
Test.assert(Game.find(id).energia == 5, "sin Ahorro el fallo cuesta 1 Energía")
Game.destroy(id)

// --- Cebo y Blindaje durante la resolución ---

id = ResolveFixture.fresh()
`UPDATE games SET cebo = 1 WHERE id = ?`.query(id)
ResolveFixture.pending(id, "m01", "A", 1, 0, 1)
Game.resolve(id)
Test.assert(Game.find(id).escudo == 6, "Cebo cancela el escudo-1 del fallo")
Game.destroy(id)

id = ResolveFixture.fresh()
`UPDATE games SET blindajeM = 1 WHERE id = ?`.query(id)
ResolveFixture.pending(id, "m01", "A", 1, 0, 1)
Game.resolve(id)
g = Game.find(id)
Test.assert(g.escudo == 6, "Blindaje absorbe el golpe de 1: 6 - 1 + 1")
Test.assert(g.blindajeUsado, "Blindaje queda usado")
Test.assert(!g.blindajeM, "Blindaje preparado se consume")
Game.destroy(id)
