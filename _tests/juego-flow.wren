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
Test.assert(Game.count(gid, "mesa") == 3, "la mesa arranca con 3 Misterios")
Test.assert(Game.count(gid, "mano") == 3, "la mano arranca con 3 cartas")

Test.get("/juego")
  .status(200)
  .textContains("La fosa del Megalodón")
  .textContains("Energía")
  .contains("Mazos y descartes")
  .contains("dorso-misterio-thumb.png")
  .contains("data-moves=")
  .contains("&quot;kind&quot;:&quot;draw&quot;")

// --- Elegir un Misterio y resolver con dados de la mesa ---

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

Test.get("/juego")
  .status(200)
  .contains('data-moves="[]"')

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
Test.assert(g.fase == "listo", "el turno nuevo arranca listo")
Test.assert(g.resueltas == 0, "el turno nuevo no arrastra un Misterio resuelto")
Test.assert(!g.tirado, "el turno nuevo arranca sin tirada")
Test.assert(Game.count(gid, "mesa") == 3, "la mesa vuelve a 3 Misterios")
Test.assert(Game.count(gid, "mano") == 3, "la mano se repone a 3")
Test.assert(Game.count(gid, "descarteJuego") == 1, "la carta resuelta va al descarte del Juego")
Test.assert(Game.count(gid, "descarteEquipo") == 3, "la mano vieja va al descarte de Equipo")

// --- La derrota exige Energía y Escudo en 0 a la vez ---

Test.post("/juego", {"accion": "nueva", "modo": "experto"})
  .status(302)
gid = `SELECT MAX(id) AS id FROM games`.first["id"].toNum
Flow.normalize(gid)
Flow.safeOnTop(gid)

`UPDATE games SET fase = 'resuelto', resultado = 'ganada', energia = 0, escudo = 3 WHERE id = ?`.query(gid)
Test.post("/juego", {"accion": "terminar"}).status(302)
var gCero = Game.find(gid)
Test.assert(gCero.status == "activa", "cero Energía solo no termina la partida")
Test.assert(gCero.turno == 2, "el turno avanza con la Energía en 0")

`UPDATE games SET fase = 'resuelto', resultado = 'ganada', energia = 3, escudo = 0 WHERE id = ?`.query(gid)
Test.post("/juego", {"accion": "terminar"}).status(302)
gCero = Game.find(gid)
Test.assert(gCero.status == "activa", "cero Escudo solo no termina la partida")

`UPDATE games SET fase = 'resuelto', resultado = 'ganada', energia = 0, escudo = 0 WHERE id = ?`.query(gid)
Test.post("/juego", {"accion": "terminar"}).status(302)
Test.assert(Game.find(gid).status == "derrota", "con Energía y Escudo en 0 la partida termina")

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
