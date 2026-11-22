class Layout {
  static render(content) { Layout.render(content, "Tu herramienta") }

  static render(content, title) { <!doctype html>
    <html lang="es" data-theme="light">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title>{{ title }}</title>
        <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/beakcss/dist/beak.contained.min.css" />
        <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/beakcss/dist/themes/cyan.css" />
      </head>
      <body>
        <main>
          {{ content }}
        </main>
        <footer>
          <small><a href="https://iz.ar">Creado en iz.ar</a></small>
        </footer>
      </body>
    </html> }
}
