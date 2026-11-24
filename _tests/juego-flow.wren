// Flujo HTTP completo: crear partida, elegir, tirar, resolver y cerrar turno.
import "/_app/game" for Game
import "/_app/cards" for Card

class Flow {
  // La emboscada inicial es aleatoria. La neutralizamos para que el flujo sea
  // determinista y la prueba mida lo que tiene que medir.
  static normalize(id) {
    `UPDATE games SET energia = 6, escudo = 6, pistas = 0, pistasTurno = 0,
       fase = 'listo', status = 'activa', turno = 1, jugador = 1,
       pruebaCarta = NULL, pruebaOpcion = NULL, dado1 = 0, dado2 = 0,
       tirado = 0, bonus = 0, cebo = 0, ahorro = 0, giro = 0, suerte = 0,
       blindajeM = 0, blindajeUsado = 0, focosM = 0, jugadas = 0,
       resueltas = 0, resultado = NULL, ultimo = NULL
       WHERE id = ?`.query(id)
  }

  // Deja m01 en la mesa sin cambiar la cantidad de cartas de la mesa.
  static putM01(id) {
    var row = `SELECT id, zone FROM game_cards WHERE gameId = ? AND cardId = 'm01'`.first(id)
    if (row["zone"] != "mesa") {
      var victima = `SELECT id FROM game_cards WHERE gameId = ? AND zone = 'mesa' ORDER BY id`.first(id)
      if (victima != null) Game.move(victima["id"], "misterio")
      `UPDATE game_cards SET zone = 'mesa' WHERE id = ?`.query(row["id"])
    }
    return `SELECT id FROM game_cards WHERE gameId = ? AND cardId = 'm01'`.first(id)["id"]
  }

  // Deja arriba una carta sin emboscada para que cerrar el turno no mueva
  // contadores por sorpresa.
  // Arranca una partida limpia y la deja visible para las pruebas.
  static nuevaPartida() {
    Test.post("/juego", {"accion": "nueva", "modo": "experto"}).status(302)
    var id = `SELECT MAX(id) AS id FROM games`.first["id"].toNum
    Flow.normalize(id)
    Flow.safeOnTop(id)
    return id
  }

  static safeOnTop(id) {
    var deck = `SELECT id, cardId FROM game_cards WHERE gameId = ? AND zone = 'misterio'`.fetch(id)
    for (r in deck) {
      var c = Card.get(r["cardId"])
      if (c != null && c.entry == "") {
        // RANDOM() puede dar negativos: -1 no garantiza quedar arriba.
        `UPDATE game_cards SET ord = -9223372036854775808 WHERE id = ?`.query(r["id"])
        return c.id
      }
    }
    return null
  }
}

// --- Entrada sin partida ---

Test.get("/juego")
  .status(200)
  .textContains("Prepará la expedición")

// --- Crear una partida desde el formulario ---

Test.post("/juego", {"accion": "nueva", "modo": "casual"})
  .status(302)
  .header("Location", "/juego")

var gid = `SELECT MAX(id) AS id FROM games`.first["id"].toNum
Test.assert(gid != null && gid > 0, "el POST de nueva crea una partida")
var g = Game.find(gid)
Test.assert(g.modo == "casual", "la partida arranca en el modo elegido")
// La emboscada inicial puede golpear un contador (nunca más de 1 punto).
Test.assert(g.energia == 6 || g.energia == 5, "la Energía arranca en 6 o en 5 por una emboscada")
Test.assert(g.escudo == 6 || g.escudo == 5, "el Escudo arranca en 6 o en 5 por una emboscada")
Test.assert(g.pistas == 0, "las Pistas arrancan en 0")
Test.assert(Game.count(gid, "mesa") == 3, "la mesa arranca con 3 Misiones")
Test.assert(Game.count(gid, "mano") == 3, "la mano arranca con 3 cartas")

Test.get("/juego")
  .status(200)
  .textContains("La fosa del Megalodón")
  .textContains("Energía")
  .contains("Mazos y descartes")
  .contains("dorso-mision-thumb.png")
  .contains("data-moves=")
  .contains("&quot;kind&quot;:&quot;draw&quot;")

// --- Elegir una Misión y resolver con dados de la mesa ---

Flow.normalize(gid)
var rowId = Flow.putM01(gid)
// Consumir los movimientos que hizo el fixture antes de medir la acción real.
Test.get("/juego").status(200)
Test.post("/juego", {"accion": "elegir", "rowId": rowId.toString, "opt": "A"})
  .status(302)
g = Game.find(gid)
Test.assert(g.fase == "prueba", "elegir deja la prueba preparada")
Test.assert(g.pruebaCarta == "m01", "elegir guarda la carta")
Test.assert(g.pruebaOpcion == "A", "elegir guarda la opción")

// La mano se mantiene: elegir la Misión no descarta nada.
Test.get("/juego")
  .status(200)
  .contains('data-moves="[]"')
Test.assert(Game.count(gid, "mano") == 3, "elegir la Misión no descarta la mano")

Test.post("/juego", {"accion": "mesa", "d1": "2", "d2": "0"})
  .status(302)
  .header("Location", "/juego?anim=dados")
g = Game.find(gid)
Test.assert(g.fase == "resuelto", "tirar resuelve la prueba")
Test.assert(g.resultado == "ganada", "2 en cara supera m01")
Test.assert(g.pistas == 1, "el éxito de m01 suma 1 Pista")
Test.assert(g.dado1 == 2, "la app guarda el dado de la mesa")
Test.assert(Game.count(gid, "mesa") == 2, "la carta resuelta sale de la mesa")

Test.get("/juego")
  .status(200)
  .textContains("Prueba superada")
  .contains("&quot;kind&quot;:&quot;discard&quot;")
  .contains("&quot;to&quot;:&quot;descarteJuego&quot;")

// --- Cerrar el turno: descarte, consumo y reposición ---

Flow.safeOnTop(gid)
var pistasAntes = g.pistas
Test.post("/juego", {"accion": "terminar"})
  .status(302)
g = Game.find(gid)
Test.assert(g.turno == 2, "cerrar el turno avanza el contador")
Test.assert(g.energia == 5, "cerrar el turno consume 1 Energía")
Test.assert(g.pistas == pistasAntes, "cerrar el turno no toca las Pistas")
Test.assert(g.resueltas == 0, "el turno nuevo no arrastra una Misión resuelta")
Test.assert(!g.tirado, "el turno nuevo arranca sin tirada")
Test.assert(Game.count(gid, "mesa") == 3, "la mesa vuelve a 3 Misiones")
Test.assert(Game.count(gid, "mano") == 4, "roban 1 y la mano pasa a 4")
Test.assert(g.fase == "descarte", "con 4 cartas hay que descartar antes de empezar")
Test.assert(Game.count(gid, "descarteJuego") == 1, "la carta resuelta va al descarte del Juego")
var sobra = Game.cardsIn(gid, "mano")[0]
Test.post("/juego", {"accion": "descartar_mano", "rowId": sobra["rowId"].toString}).status(302)
g = Game.find(gid)
Test.assert(Game.count(gid, "mano") == 3, "descartar deja la mano en 3")
Test.assert(g.fase == "listo", "con 3 cartas el turno arranca")
Test.assert(Game.count(gid, "descarteEquipo") == 1, "la carta descartada va al descarte de Equipo")

// --- La derrota llega con cualquiera de los dos contadores en 0 ---

var gDerrota = Flow.nuevaPartida()
`UPDATE games SET fase = 'resuelto', resultado = 'ganada', energia = 0, escudo = 3 WHERE id = ?`.query(gDerrota)
Test.post("/juego", {"accion": "terminar"}).status(302)
var gCero = Game.find(gDerrota)
Test.assert(gCero.status == "derrota", "cero Energía al cerrar el turno termina la partida")
Test.assert(gCero.turno == 1, "la partida perdida no avanza de turno")

gDerrota = Flow.nuevaPartida()
`UPDATE games SET fase = 'resuelto', resultado = 'ganada', energia = 3, escudo = 0 WHERE id = ?`.query(gDerrota)
Test.post("/juego", {"accion": "terminar"}).status(302)
Test.assert(Game.find(gDerrota).status == "derrota", "cero Escudo al cerrar el turno termina la partida")

gDerrota = Flow.nuevaPartida()
`UPDATE games SET fase = 'resuelto', resultado = 'ganada', energia = 0, escudo = 0 WHERE id = ?`.query(gDerrota)
Test.post("/juego", {"accion": "terminar"}).status(302)
Test.assert(Game.find(gDerrota).status == "derrota", "los dos en 0 también terminan la partida")

// --- Cerrar con 1 Energía no derrota: el consumo deja 0 y hay un turno para recuperarla ---

var gGracia = Flow.nuevaPartida()
`UPDATE games SET fase = 'resuelto', resultado = 'ganada', energia = 1, escudo = 3 WHERE id = ?`.query(gGracia)
Test.post("/juego", {"accion": "terminar"}).status(302)
var gSig = Game.find(gGracia)
Test.assert(gSig.status == "activa", "cerrar con 1 Energía no termina la partida en ese momento")
Test.assert(gSig.energia == 0, "el consumo deja la Energía en 0")
Test.assert(gSig.turno == 2, "el turno avanza igual")
`UPDATE games SET fase = 'resuelto', resultado = 'ganada' WHERE id = ?`.query(gGracia)
Test.post("/juego", {"accion": "terminar"}).status(302)
Test.assert(Game.find(gGracia).status == "derrota", "el cierre siguiente con 0 Energía termina la partida")

// --- La sexta Pista gana en el momento, sin esperar al cierre ---

var gVictoria = Flow.nuevaPartida()
`UPDATE games SET pistas = 5 WHERE id = ?`.query(gVictoria)
var misionVictoria = Flow.putM01(gVictoria)
Test.post("/juego", {"accion": "elegir", "rowId": misionVictoria.toString, "opt": "A"}).status(302)
Test.post("/juego", {"accion": "mesa", "d1": "2", "d2": "0"}).status(302)
Test.assert(Game.find(gVictoria).status == "victoria", "la sexta Pista gana al resolver, en cualquier momento")

// --- Modo inválido: el servidor cae en Normal ---

Test.post("/juego", {"accion": "nueva", "modo": "inventado"})
  .status(302)
var nuevo = `SELECT MAX(id) AS id FROM games`.first["id"].toNum
Test.assert(nuevo != gid, "una nueva partida reemplaza a la anterior")
Test.assert(Game.find(gid) == null, "la partida anterior se destruye al empezar otra")
Test.assert(Game.find(nuevo).modo == "casual", "un modo inválido cae en Normal")

// --- Reiniciar deja la sesión sin partida ---

Test.post("/juego", {"accion": "reiniciar"})
  .status(302)
Test.assert(Game.find(nuevo) == null, "reiniciar destruye la partida")
Test.get("/juego")
  .status(200)
  .textContains("Prepará la expedición")
