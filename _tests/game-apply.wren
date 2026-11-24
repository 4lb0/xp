// Aplicación de efectos sobre los contadores: topes, maniobras y victoria.
import "/_app/game" for Game

class Fixture {
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

  static equip(id, cardId) {
    `INSERT INTO game_cards (gameId, cardId, zone, ord) VALUES (?, ?, 'herramientas', 0)`.query(id, cardId)
  }
}

// --- Sumas y restas normales ---

var id = Fixture.fresh()
var res = Game.apply(id, Game.find(id), Game.parseEffects("pistas+2"), true, [])
Test.assert(res["pistas"] == 2, "apply suma 2 Pistas")
Test.assert(Game.find(id).pistas == 2, "las Pistas quedan guardadas")

res = Game.apply(id, Game.find(id), Game.parseEffects("energia-2"), true, [])
Test.assert(res["energia"] == 4, "apply resta 2 Energía")
Test.assert(Game.find(id).energia == 4, "la Energía queda guardada")

res = Game.apply(id, Game.find(id), Game.parseEffects("escudo+1"), true, [])
Test.assert(res["escudo"] == 7, "el Escudo puede superar 6")
Test.assert(res["status"] == "activa", "sumar Escudo no gana la partida")
Game.destroy(id)

// --- Topes en cero ---

id = Fixture.fresh()
`UPDATE games SET energia = 1, escudo = 1, pistas = 0 WHERE id = ?`.query(id)
res = Game.apply(id, Game.find(id), Game.parseEffects("energia-3, escudo-3, pistas-2"), true, [])
Test.assert(res["energia"] == 0, "la Energía no baja de 0")
Test.assert(res["escudo"] == 0, "el Escudo no baja de 0")
Test.assert(res["pistas"] == 0, "las Pistas no bajan de 0")
var g = Game.find(id)
Test.assert(g.energia == 0 && g.escudo == 0 && g.pistas == 0, "los topes se guardan en la partida")
Test.assert(g.status == "derrota", "llegar a 0 en Energía o Escudo pierde en el momento")
Game.destroy(id)

// --- Tope de 12 ---

id = Fixture.fresh()
`UPDATE games SET energia = 11, escudo = 11, pistas = 4 WHERE id = ?`.query(id)
res = Game.apply(id, Game.find(id), Game.parseEffects("energia+3, escudo+3, pistas+1"), true, [])
Test.assert(res["energia"] == 12, "la Energía no pasa de 12")
Test.assert(res["escudo"] == 12, "el Escudo no pasa de 12")
Test.assert(res["pistas"] == 5, "las Pistas suman normal por debajo del tope")
Test.assert(res["notas"].join(" ").contains("tope de 12"), "el tope deja una nota en la bitácora")
var gTope = Game.find(id)
Test.assert(gTope.energia == 12 && gTope.escudo == 12, "el tope se guarda en la partida")
Game.destroy(id)

// --- Ahorro de Oxígeno ---

id = Fixture.fresh()
`UPDATE games SET ahorro = 1 WHERE id = ?`.query(id)
res = Game.apply(id, Game.find(id), Game.parseEffects("energia-2"), true, [])
Test.assert(res["energia"] == 6, "Ahorro evita el gasto de Energía")
Test.assert(res["notas"].count == 1 && res["notas"][0].contains("Ahorro"), "Ahorro deja una nota")
Test.assert(Game.find(id).ahorro, "el Ahorro sigue armado hasta cerrar el turno")
Game.destroy(id)

// --- Lanzar Cebo ---

id = Fixture.fresh()
`UPDATE games SET cebo = 1 WHERE id = ?`.query(id)
res = Game.apply(id, Game.find(id), Game.parseEffects("escudo-2"), true, [])
Test.assert(res["escudo"] == 6, "Cebo cancela todo el daño al Escudo")
Test.assert(res["notas"].count == 1 && res["notas"][0].contains("Cebo"), "Cebo deja una nota")
Test.assert(!Game.find(id).cebo, "Cebo se consume")
Game.destroy(id)

// --- Blindaje de Titanio (Maniobra) ---

id = Fixture.fresh()
`UPDATE games SET blindajeM = 1 WHERE id = ?`.query(id)
res = Game.apply(id, Game.find(id), Game.parseEffects("escudo-2"), true, [])
Test.assert(res["escudo"] == 5, "Blindaje reduce 1 el daño: 6 - 2 + 1")
Test.assert(res["notas"].count == 1 && res["notas"][0].contains("Blindaje"), "Blindaje deja una nota")
g = Game.find(id)
Test.assert(g.blindajeUsado, "Blindaje queda marcado como usado")
Test.assert(!g.blindajeM, "Blindaje preparado se consume")
res = Game.apply(id, g, Game.parseEffects("escudo-2"), true, [])
Test.assert(res["escudo"] == 3, "Blindaje no se aplica dos veces en el turno")
Game.destroy(id)

// --- Blindaje de Titanio (Herramienta activa) ---

id = Fixture.fresh()
Fixture.equip(id, "e04")
res = Game.apply(id, Game.find(id), Game.parseEffects("escudo-2"), true, Game.ids(id, "herramientas"))
Test.assert(res["escudo"] == 5, "el Blindaje equipado reduce 1 el daño")
Test.assert(Game.find(id).blindajeUsado, "el Blindaje equipado también se marca usado")
// Sin la carta equipada no hay reducción.
Game.destroy(id)

id = Fixture.fresh()
res = Game.apply(id, Game.find(id), Game.parseEffects("escudo-2"), true, [])
Test.assert(res["escudo"] == 4, "sin Blindaje el Escudo pierde 2")
Game.destroy(id)

// --- Brazo Robótico: Pista extra con un 6 ---

id = Fixture.fresh()
Fixture.equip(id, "e05")
`UPDATE games SET dado1 = 6, dado2 = 2 WHERE id = ?`.query(id)
res = Game.apply(id, Game.find(id), Game.parseEffects("pistas+1"), true, Game.ids(id, "herramientas"))
Test.assert(res["pistas"] == 2, "Brazo Robótico suma 1 Pista si sale un 6")
Test.assert(res["notas"].count == 1 && res["notas"][0].contains("Brazo"), "Brazo deja una nota")
Game.destroy(id)

// Con un 6 pero prueba fallida no suma.
id = Fixture.fresh()
Fixture.equip(id, "e05")
`UPDATE games SET dado1 = 6, dado2 = 2 WHERE id = ?`.query(id)
res = Game.apply(id, Game.find(id), Game.parseEffects("pistas+1"), false, Game.ids(id, "herramientas"))
Test.assert(res["pistas"] == 1, "Brazo no suma si la prueba falla")
Game.destroy(id)

// Sin ningún 6 no suma.
id = Fixture.fresh()
Fixture.equip(id, "e05")
`UPDATE games SET dado1 = 3, dado2 = 2 WHERE id = ?`.query(id)
res = Game.apply(id, Game.find(id), Game.parseEffects("pistas+1"), true, Game.ids(id, "herramientas"))
Test.assert(res["pistas"] == 1, "Brazo solo suma cuando un dado muestra 6")
Game.destroy(id)

// --- Victoria y Pistas del turno ---

id = Fixture.fresh()
`UPDATE games SET pistas = 5 WHERE id = ?`.query(id)
res = Game.apply(id, Game.find(id), Game.parseEffects("pistas+1"), true, [])
Test.assert(res["pistas"] == 6, "la sexta Pista queda registrada")
Test.assert(res["status"] == "victoria", "seis Pistas ganan en el momento")

// Si en el mismo efecto llegan a 6 Pistas y a 0 Energía, gana la victoria.
id = Fixture.fresh()
`UPDATE games SET pistas = 5, energia = 1 WHERE id = ?`.query(id)
res = Game.apply(id, Game.find(id), Game.parseEffects("pistas+1, energia-1"), true, [])
Test.assert(res["energia"] == 0, "la Energía llega a 0 en el mismo efecto")
Test.assert(res["status"] == "victoria", "la sexta Pista gana antes que la derrota")
Test.assert(Game.find(id).status == "victoria", "la victoria se guarda")
Game.destroy(id)

id = Fixture.fresh()
Game.apply(id, Game.find(id), Game.parseEffects("pistas+2"), true, [])
res = Game.apply(id, Game.find(id), Game.parseEffects("pistas-1"), true, [])
Test.assert(res["pistas"] == 1, "una pérdida de Pista resta")
g = Game.find(id)
Test.assert(g.pistasTurno == 2, "solo las Pistas ganadas cuentan para pistasTurno")
Game.destroy(id)
