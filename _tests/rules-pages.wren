// Las páginas públicas se renderizan con las reglas nuevas y el nombre Misión.

Test.get("/")
  .status(200)
  .textContains("Resolvé una Misión")
  .contains("Antes de elegir la Misión")

Test.get("/reglas")
  .status(200)
  .textContains("El turno, paso a paso")
  .textContains("antes de elegir la Misión")
  .textContains("Ningún contador baja de 0 ni pasa de 12")
  .textContains("en cualquier momento")
  .textContains("Orden de una tirada")
  .textContains("Mazo de Misiones")

Test.get("/como-jugar")
  .status(200)
  .textContains("Tu primer turno")
  .textContains("Cartas de Misión")
  .textContains("Tu estado")
  .textContains("antes de elegir la Misión")

Test.get("/cartas")
  .status(200)
  .textContains("40 Misiones")
