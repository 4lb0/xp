// Marca: la cabecera declara favicon, íconos de app y metadatos sociales.
// Los assets estáticos se sirven desde /img; acá se verifica que el layout
// los referencie y que la insignia aparezca en la portada.

Test.get("/")
  .status(200)
  .contains("favicon.ico")
  .contains("favicon-32.png")
  .contains("apple-touch-icon.png")
  .contains("logo-xp-mark.png")
  .contains("/img/og-xp.jpg")
  .contains("hero-brand")
  .textContains("Equipo eXPedición")

Test.get("/juego")
  .status(200)
  .contains("apple-touch-icon.png")
  .contains("logo-xp-mark.png")
