class Layout {
  // Subir al cambiar css/style.css para romper la caché de Cloudflare.
  static assetVersion { "2026-11-22-2" }
  static printVersion { "2026-11-22-2" }

  static render(content) { Layout.render(content, "XP · Equipo eXPedición", false) }

  static die(value) { Layout.die(value, "") }

  static die(value, extra) { <span class="die {{ extra }}" data-value="{{ value }}" aria-hidden="true"><span class="p p1"></span><span class="p p2"></span><span class="p p3"></span><span class="p p4"></span><span class="p p5"></span><span class="p p6"></span><span class="p p7"></span><span class="p p8"></span><span class="p p9"></span></span> }

  static render(content, title) { Layout.render(content, title, false) }

  static render(content, title, hideHeader) { <!doctype html>
    <html lang="es">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title>{{ title }}</title>
        <meta name="description" content="XP: En busca del Megalodón. Juego de mesa de aventura y misterio para toda la familia. Solo o en cooperativo." />
        <meta name="theme-color" content="#061423" />
        <link rel="stylesheet" href="/css/style.css?v={{ Layout.assetVersion }}" />
      </head>
      <body>
        <a class="skip-link" href="#contenido">Saltar al contenido</a>
        {{ !hideHeader && <header class="site-header">
          <nav class="nav wrap" aria-label="Principal">
            <a class="brand" href="/" aria-label="XP, inicio">
              <span class="brand-mark" aria-hidden="true">XP</span>
              <span class="brand-text">
                <strong>Equipo eXPedición</strong>
                <small>En busca del Megalodón</small>
              </span>
            </a>
            <ul class="nav-links">
              <li><a href="/" class="{{ Request.uri == "/" ? "active" : "" }}">Inicio</a></li>
              <li><a href="/juego" class="{{ Request.uri.startsWith("/juego") ? "active" : "" }}">Expedición</a></li>
              <li><a href="/como-jugar" class="{{ Request.uri == "/como-jugar" ? "active" : "" }}">Guía</a></li>
              <li><a href="/reglas" class="{{ Request.uri == "/reglas" ? "active" : "" }}">Reglas</a></li>
              <li><a href="/cartas" class="{{ Request.uri == "/cartas" ? "active" : "" }}">Cartas</a></li>
            </ul>
          </nav>
        </header> }}

        <div class="wrap" id="contenido">
          {{ content }}
        </div>

        <footer class="site-footer">
          <div class="wrap footer-inner">
            <p><strong>XP</strong> · Equipo eXPedición — Edición 1: <em>En busca del Megalodón</em></p>
            <p class="muted">Creado con <a href="https://iz.ar" target="_blank">iz.ar</a></p>
          </div>
        </footer>
      </body>
    </html> }
}
