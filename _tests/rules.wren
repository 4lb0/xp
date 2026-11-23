// Reglas puras del motor: efectos, pruebas de dados, límites y tiradas.
import "/_app/game" for Game

// --- parseEffects ---

var p = Game.parseEffects("pistas+1")
Test.assert(p["pistas"] == 1, "pistas+1 suma una pista")
Test.assert(p["energia"] == 0 && p["escudo"] == 0, "los contadores no tocados quedan en 0")

p = Game.parseEffects("energia-2")
Test.assert(p["energia"] == -2, "energia-2 resta dos")

p = Game.parseEffects("escudo+1, pistas-1")
Test.assert(p["escudo"] == 1, "parsea el primer efecto")
Test.assert(p["pistas"] == -1, "parsea el segundo efecto con signo negativo")

p = Game.parseEffects(" pistas + 2 , escudo - 1 ")
Test.assert(p["pistas"] == 2, "tolera espacios alrededor de la clave y del valor")
Test.assert(p["escudo"] == -1, "tolera espacios en el efecto negativo")

p = Game.parseEffects("")
Test.assert(p["pistas"] == 0 && p["energia"] == 0 && p["escudo"] == 0, "vacío no cambia nada")

p = Game.parseEffects(null)
Test.assert(p["pistas"] == 0 && p["energia"] == 0 && p["escudo"] == 0, "null no rompe parseEffects")

p = Game.parseEffects("suerte+1")
Test.assert(p["suerte"] == null, "una clave desconocida no se agrega")
Test.assert(p["pistas"] == 0, "una clave desconocida no contamina las conocidas")

p = Game.parseEffects("pistas")
Test.assert(p["pistas"] == 0, "un efecto sin signo se ignora")

p = Game.parseEffects("+1")
Test.assert(p["pistas"] == 0 && p["energia"] == 0 && p["escudo"] == 0, "un signo sin clave se ignora")

// --- evalTest ---

Test.assert(Game.evalTest("cara", 0, 2, 0, 0, false), "cara pasa con 2")
Test.assert(Game.evalTest("cara", 0, 4, 0, 0, false), "cara pasa con 4")
Test.assert(Game.evalTest("cara", 0, 6, 0, 0, false), "cara pasa con 6")
Test.assert(!Game.evalTest("cara", 0, 1, 0, 0, false), "cara falla con 1")
Test.assert(!Game.evalTest("cara", 0, 5, 0, 0, false), "cara falla con 5")
Test.assert(Game.evalTest("cara", 0, 2, 1, 0, false), "cara solo mira el primer dado")

Test.assert(Game.evalTest("seca", 0, 1, 0, 0, false), "seca pasa con 1")
Test.assert(Game.evalTest("seca", 0, 5, 0, 0, false), "seca pasa con 5")
Test.assert(!Game.evalTest("seca", 0, 2, 0, 0, false), "seca falla con 2")
Test.assert(!Game.evalTest("seca", 0, 6, 0, 0, false), "seca falla con 6")

Test.assert(Game.evalTest("dobles", 0, 3, 3, 0, false), "dobles pasa con 3 y 3")
Test.assert(Game.evalTest("dobles", 0, 6, 6, 0, false), "dobles pasa con 6 y 6")
Test.assert(!Game.evalTest("dobles", 0, 3, 4, 0, false), "dobles falla con dados distintos")

Test.assert(Game.evalTest("sin1", 0, 2, 5, 0, false), "sin1 pasa sin 1 ni 6")
Test.assert(!Game.evalTest("sin1", 0, 1, 5, 0, false), "sin1 falla si el primer dado es 1")
Test.assert(!Game.evalTest("sin1", 0, 5, 6, 0, false), "sin1 falla si el segundo dado es 6")
Test.assert(!Game.evalTest("sin1", 0, 6, 6, 0, false), "sin1 falla con dos 6")

Test.assert(Game.evalTest("suma", 7, 3, 4, 0, false), "suma exacta pasa (7)")
Test.assert(!Game.evalTest("suma", 7, 3, 3, 0, false), "suma por debajo falla (6 < 7)")
Test.assert(Game.evalTest("suma", 9, 4, 5, 0, false), "suma exacta 9 pasa")
Test.assert(!Game.evalTest("suma", 9, 3, 5, 0, false), "suma 8 no llega a 9")
Test.assert(Game.evalTest("suma", 9, 3, 4, 2, false), "el bono de Turbo suma al total")
Test.assert(Game.evalTest("suma", 9, 3, 4, 2, false), "con +2 de Turbo llega a 9")
Test.assert(Game.evalTest("suma", 9, 3, 4, 1, true), "con +1 y Estabilizadores llega a 9")
Test.assert(!Game.evalTest("suma", 9, 3, 4, 0, false), "sin bono ni estabilizadores no llega a 9")
Test.assert(Game.evalTest("suma", 10, 4, 5, 0, true), "Estabilizadores suma 1 al total")
Test.assert(!Game.evalTest("suma", 10, 4, 5, 0, false), "sin Estabilizadores no llega a 10")

Test.assert(Game.evalTest("dado", 6, 6, 0, 0, false), "1 dado 6+ pasa con 6")
Test.assert(!Game.evalTest("dado", 6, 5, 0, 0, false), "1 dado 6+ falla con 5")
Test.assert(Game.evalTest("dado", 4, 3, 0, 1, false), "el bono aplica a 1 dado")
Test.assert(!Game.evalTest("dado", 4, 3, 0, 0, false), "1 dado 4+ falla con 3")

// --- clamp y roll ---

Test.assert(Game.clamp(5, 0, 6) == 5, "clamp deja el valor dentro del rango")
Test.assert(Game.clamp(-1, 0, 6) == 0, "clamp sube al mínimo")
Test.assert(Game.clamp(9, 0, 6) == 6, "clamp baja al máximo")
Test.assert(Game.clamp(0, 0, 6) == 0, "clamp acepta el mínimo")
Test.assert(Game.clamp(6, 0, 6) == 6, "clamp acepta el máximo")

var rolls = Game.roll(60)
Test.assert(rolls.count == 60, "roll(n) devuelve n dados")
var validos = true
for (d in rolls) {
  if (d < 1 || d > 6 || d != d.floor) validos = false
}
Test.assert(validos, "cada dado está entre 1 y 6 y es entero")
