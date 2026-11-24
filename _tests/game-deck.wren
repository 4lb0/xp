// Estado de la partida y mazos: creación, modos, robo, reciclado y consultas.
import "/_app/game" for Game

class Fixture {
  // Crea una partida y neutraliza la emboscada inicial (aleatoria) para que
  // las aserciones no dependan de las cartas que salieron en la mesa.
  static fresh(modo) {
    var id = Game.create(1, modo)
    `UPDATE games SET energia = 6, escudo = 6, pistas = 0, pistasTurno = 0,
       fase = 'listo', status = 'activa', turno = 1, jugador = 1,
       pruebaCarta = NULL, pruebaOpcion = NULL, dado1 = 0, dado2 = 0,
       tirado = 0, bonus = 0, cebo = 0, ahorro = 0, giro = 0, suerte = 0,
       blindajeM = 0, blindajeUsado = 0, focosM = 0, jugadas = 0,
       resueltas = 0, resultado = NULL, ultimo = NULL
       WHERE id = ?`.query(id)
    return id
  }
}

// --- Creación y modos ---

var id = Fixture.fresh("casual")
var g = Game.find(id)
Test.assert(g != null, "Game.create deja una partida encontrable")
Test.assert(g.id == id, "find() devuelve la misma partida")
Test.assert(g.modo == "casual", "create() guarda el modo")
Test.assert(g.players == 1, "create() guarda los jugadores")
Test.assert(g.energia == 6 && g.escudo == 6, "Energía y Escudo arrancan en 6")
Test.assert(g.pistas == 0, "Pistas arranca en 0")
Test.assert(g.turno == 1, "el turno arranca en 1")
Test.assert(g.status == "activa", "la partida arranca activa")
Test.assert(g.fase == "listo", "la partida arranca lista para elegir")
Test.assert(Game.count(id, "mesa") == 3, "hay 3 Misiones en la mesa")
Test.assert(Game.count(id, "mano") == 3, "la mano arranca con 3 cartas")
Test.assert(Game.count(id, "misterio") == 37, "quedan 37 Misiones en el mazo")
Test.assert(Game.count(id, "equipo") == 41, "quedan 41 cartas de Equipo en el mazo")
Test.assert(Game.count(id, "ayuda") == 0, "el área de Apoyo ya no se usa")
Test.assert(Game.ids(id, "mano").contains("e17"), "el apoyo del modo normal arranca en la mano")
Test.assert(Game.count(id, "herramientas") == 0, "no hay Herramienta activa al empezar")

// Las 40 cartas de Misión y las 44 copias de Equipo están siempre.
var totalMisiones = Game.count(id, "misterio") + Game.count(id, "mesa") + Game.count(id, "descarteJuego")
Test.assert(totalMisiones == 40, "el Mazo del Juego tiene 40 cartas en total")
var totalEquipo = Game.count(id, "equipo") + Game.count(id, "mano") + Game.count(id, "descarteEquipo") + Game.count(id, "herramientas")
Test.assert(totalEquipo == 44, "el Mazo del Equipo tiene 44 copias en total")

// Cada partida tiene su propio mazo.
var otra = Fixture.fresh("casual")
Test.assert(otra != id, "dos partidas tienen ids distintos")
Test.assert(Game.count(id, "mesa") == 3 && Game.count(otra, "mesa") == 3, "cada partida reparte su propia mesa")
Game.destroy(otra)

var experto = Fixture.fresh("experto")
Test.assert(Game.count(experto, "ayuda") == 0, "el modo experto no tiene apoyos")
Test.assert(Game.count(experto, "mano") == 3, "en experto la mano son 3 cartas robadas")
Test.assert(!Game.ids(experto, "mano").contains("e17"), "en experto no hay apoyos en la mano")
Game.destroy(experto)

var facil = Fixture.fresh("facil")
Test.assert(Game.count(facil, "mano") == 3, "asistido arranca con 3 cartas en la mano")
Test.assert(Game.ids(facil, "mano").contains("e17"), "asistido incluye el Kit")
Test.assert(Game.ids(facil, "mano").contains("e18"), "asistido incluye la Carga")
Test.assert(Game.count(facil, "equipo") == 41, "los apoyos de la mano no quedan en el mazo")
Game.destroy(facil)

// --- find ---

Test.assert(Game.find(null) == null, "find(null) no rompe")
Test.assert(Game.find(999999) == null, "find() de una partida inexistente devuelve null")

// --- Robo y reciclado ---

var deck = Fixture.fresh("experto")
var top = Game.topCard(deck)
Test.assert(top != null, "topCard() muestra la próxima carta del Mazo del Juego")
var mesaAntes = Game.count(deck, "mesa")
var drawn = Game.draw(deck, "misterio", "mesa", 1)
Test.assert(drawn == top.id, "draw() saca la misma carta que topCard()")
Test.assert(Game.count(deck, "mesa") == mesaAntes + 1, "draw() suma una carta a la mesa")
Test.assert(Game.count(deck, "misterio") == 36, "draw() resta una carta al mazo")
Game.destroy(deck)

// Si el mazo de Equipo se agota, el descarte se mezcla y se sigue robando.
deck = Fixture.fresh("experto")
`UPDATE game_cards SET zone = 'descarteEquipo' WHERE gameId = ? AND cardId LIKE 'e%'`.query(deck)
Test.assert(Game.count(deck, "equipo") == 0, "vaciamos el mazo de Equipo")
var robada = Game.draw(deck, "equipo", "mano", 3)
Test.assert(robada != null, "draw() recicla el descarte cuando el mazo está vacío")
Test.assert(Game.count(deck, "mano") == 3, "la mano queda en 3 tras reciclar")
Test.assert(Game.count(deck, "equipo") == 41, "el descarte reciclado vuelve al mazo")
Test.assert(Game.count(deck, "descarteEquipo") == 0, "el descarte de Equipo queda vacío")
Test.assert(Game.lastLogs(deck, 5).map { |l| l["text"] }.join(" ").contains("Se mezcla el descarte del Mazo de Equipo"), "el reciclado queda en la bitácora")
Game.destroy(deck)

// Un mazo vacío sin descarte no roba nada.
deck = Fixture.fresh("experto")
Test.assert(Game.recycleDiscard(deck, "misterio") == false, "sin descarte no hay nada que reciclar")
Test.assert(Game.draw(deck, "misterio", "mesa", 1) != null, "el mazo lleno sigue robando")
`UPDATE game_cards SET zone = 'descarteJuego' WHERE gameId = ? AND cardId LIKE 'm%'`.query(deck)
Test.assert(Game.count(deck, "misterio") == 0, "vaciamos el Mazo del Juego")
Test.assert(Game.draw(deck, "misterio", "mesa", 1) != null, "robar de un mazo vacío recicla el descarte de Misión")
Game.destroy(deck)

// Reciclar un mazo no toca el descarte del otro.
deck = Fixture.fresh("experto")
`UPDATE game_cards SET zone = 'descarteJuego' WHERE gameId = ? AND cardId LIKE 'm%'`.query(deck)
var unaEquipo = `SELECT id FROM game_cards WHERE gameId = ? AND cardId LIKE 'e%'`.first(deck)
Game.move(unaEquipo["id"], "descarteEquipo")
Test.assert(Game.recycleDiscard(deck, "misterio") == true, "reciclar Misión informa que hubo cartas")
Test.assert(Game.count(deck, "misterio") == 40, "todo el descarte de Misión vuelve al mazo")
Test.assert(Game.count(deck, "descarteEquipo") == 1, "el descarte de Equipo queda intacto")
Test.assert(Game.recycleDiscard(deck, "equipo") == true, "reciclar Equipo informa que hubo cartas")
Test.assert(Game.count(deck, "descarteEquipo") == 0, "el descarte de Equipo se vacía")
Game.destroy(deck)

// --- Consultas de cartas ---

deck = Fixture.fresh("casual")
Test.assert(Game.rows(deck, "mesa").count == 3, "rows() devuelve una fila por carta")
Test.assert(Game.ids(deck, "mesa").count == 3, "ids() devuelve los cardId de la zona")
var inMesa = Game.cardsIn(deck, "mesa")
Test.assert(inMesa.count == 3, "cardsIn() arma una entrada por carta")
Test.assert(inMesa[0]["rowId"] != null, "cardsIn() incluye el rowId")
Test.assert(inMesa[0]["card"] != null, "cardsIn() incluye la carta parseada")

var filaMesa = Game.rows(deck, "mesa")[0]
Game.move(filaMesa["id"], "descarteJuego")
Test.assert(Game.count(deck, "mesa") == 2, "move() saca la carta de su zona")
Test.assert(Game.count(deck, "descarteJuego") == 1, "move() pone la carta en la zona nueva")

// --- Herramientas y efectos ---

Test.assert(Game.hasEffect(["e04"], "reduce_damage"), "hasEffect encuentra el Blindaje")
Test.assert(!Game.hasEffect(["e01"], "reduce_damage"), "hasEffect no confunde cartas")
Test.assert(!Game.hasEffect(["no-existe"], "reduce_damage"), "hasEffect tolera ids inválidos")

var filaBlindaje = `SELECT id FROM game_cards WHERE gameId = ? AND cardId = 'e04'`.first(deck)
Game.move(filaBlindaje["id"], "herramientas")
Test.assert(Game.hasTool(deck, "reduce_damage"), "hasTool ve el Blindaje equipado")
Game.move(filaBlindaje["id"], "descarteEquipo")
Test.assert(!Game.hasTool(deck, "reduce_damage"), "hasTool deja de verlo al descartarlo")

// --- Bitácora ---

Game.log(deck, "Prueba de bitácora")
Test.assert(Game.lastLogs(deck, 1).count == 1, "lastLogs respeta el límite")
Test.assert(Game.lastLogs(deck, 1)[0]["text"] == "Prueba de bitácora", "lastLogs devuelve lo último primero")
Test.assert(Game.lastLogs(deck, 100).count > 1, "lastLogs devuelve el historial")

// --- Destruir ---

Game.destroy(deck)
Test.assert(Game.find(deck) == null, "destroy() borra la partida")
Test.assert(Game.count(deck, "mesa") == 0, "destroy() borra las cartas de la partida")
Test.assert(Game.lastLogs(deck, 10).isEmpty, "destroy() borra la bitácora")
