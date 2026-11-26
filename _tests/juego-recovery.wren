// Recuperación de una partida cuando el navegador perdió la cookie de sesión
// (en Android, el sistema puede descartar el navegador y con él la cookie).
// La cookie persistente xpGame devuelve la partida y la vuelve a atar a la
// sesión nueva.
import "/_app/game" for Game

// Un token que ya no existe no rompe la página: muestra la preparación.
Test.get("/juego")
  .setHeader("Cookie", "xpGame=0000000000000000000000000000000000000000")
  .status(200)
  .textContains("Prepará la expedición")

// Con el token real, la partida vuelve aunque no haya cookie de sesión.
var id = Game.create(1, "experto")
var token = Game.ensureToken(id)
Test.get("/juego")
  .setHeader("Cookie", "xpGame=" + token)
  .status(200)
  .textContains("La fosa del Megalodón")

// La sesión nueva quedó atada a la partida: ya no hace falta la cookie.
Test.get("/juego")
  .status(200)
  .textContains("La fosa del Megalodón")
