class Layout {
  // Subir al cambiar css/style.css para romper la caché de Cloudflare.
  static assetVersion { "2026-11-24-1" }
  static printVersion { "2026-11-23-1" }
  static description { "XP — Equipo eXPedición. LCG cooperativo de aventura y misterio para toda la familia. Mazos fijos, partidas de 10 a 20 minutos." }

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
        <meta name="description" content="{{ Layout.description }}" />
        <meta name="theme-color" content="#071a2e" />
        <script>
          (function () {
            try {
              var d = document.documentElement;
              var m = localStorage.getItem("xp-motion");
              if (m === null) m = matchMedia("(prefers-reduced-motion: reduce)").matches ? "off" : "on";
              d.dataset.motion = m;
              var s = localStorage.getItem("xp-sound");
              d.dataset.sound = s === null ? "on" : s;
            } catch (e) {}
          })();
        </script>
        <meta name="application-name" content="XP" />
        <meta name="apple-mobile-web-app-title" content="XP" />
        <link rel="canonical" href="{{ Request.baseUrl }}{{ Request.uri }}" />
        <link rel="icon" href="/favicon.ico" sizes="any" />
        <link rel="icon" type="image/png" sizes="32x32" href="/img/favicon-32.png" />
        <link rel="icon" type="image/png" sizes="16x16" href="/img/favicon-16.png" />
        <link rel="apple-touch-icon" sizes="180x180" href="/img/apple-touch-icon.png" />
        <meta property="og:type" content="website" />
        <meta property="og:locale" content="es_AR" />
        <meta property="og:site_name" content="XP · Equipo eXPedición" />
        <meta property="og:title" content="{{ title }}" />
        <meta property="og:description" content="{{ Layout.description }}" />
        <meta property="og:url" content="{{ Request.baseUrl }}{{ Request.uri }}" />
        <meta property="og:image" content="{{ Request.baseUrl }}/img/og-xp.jpg" />
        <meta property="og:image:width" content="1200" />
        <meta property="og:image:height" content="630" />
        <meta property="og:image:alt" content="Insignia circular de XP, Equipo eXPedición" />
        <meta name="twitter:card" content="summary_large_image" />
        <meta name="twitter:title" content="{{ title }}" />
        <meta name="twitter:description" content="{{ Layout.description }}" />
        <meta name="twitter:image" content="{{ Request.baseUrl }}/img/og-xp.jpg" />
        <link rel="preload" href="/css/fonts/archivo-latin.woff2" as="font" type="font/woff2" crossorigin />
        <link rel="preload" href="/css/fonts/source-sans-3-latin.woff2" as="font" type="font/woff2" crossorigin />
        <link rel="stylesheet" href="/css/style.css?v={{ Layout.assetVersion }}" />
      </head>
      <body>
        <a class="skip-link" href="#contenido">Saltar al contenido</a>
        {{ !hideHeader && <header class="site-header">
          <nav class="nav wrap" aria-label="Principal">
            <a class="brand" href="/" aria-label="XP, Equipo eXPedición, inicio">
              <img class="brand-mark" src="/img/logo-xp-mark.png" width="48" height="48" alt="" />
              <span class="brand-text">
                <strong>Equipo eXPedición</strong>
                <small>En busca del Megalodón</small>
              </span>
            </a>
            <ul class="nav-links">
              <li><a href="/" class="{{ Request.uri == "/" ? "active" : "" }}" aria-current="{{ Request.uri == "/" ? "page" : "false" }}">Inicio</a></li>
              <li><a href="/juego" class="{{ Request.uri.startsWith("/juego") ? "active" : "" }}" aria-current="{{ Request.uri.startsWith("/juego") ? "page" : "false" }}">Expedición</a></li>
              <li><a href="/como-jugar" class="{{ Request.uri == "/como-jugar" ? "active" : "" }}" aria-current="{{ Request.uri == "/como-jugar" ? "page" : "false" }}">Guía</a></li>
              <li><a href="/reglas" class="{{ Request.uri == "/reglas" ? "active" : "" }}" aria-current="{{ Request.uri == "/reglas" ? "page" : "false" }}">Reglas</a></li>
              <li><a href="/cartas" class="{{ Request.uri == "/cartas" ? "active" : "" }}" aria-current="{{ Request.uri == "/cartas" ? "page" : "false" }}">Cartas</a></li>
            </ul>
          </nav>
        </header> }}

        <div class="wrap" id="contenido">
          {{ content }}
        </div>

        <footer class="site-footer">
          <div class="wrap footer-inner">
            <p class="footer-brand">
              <img src="/img/logo-xp-mark.png" width="28" height="28" alt="" />
              <span><strong>XP</strong> · Equipo eXPedición — Edición 01: <em>En busca del Megalodón</em></span>
            </p>
            <p class="muted">Hecho con <a href="https://bialet.dev" target="_blank" rel="noopener">Bialet</a></p>
          </div>
        </footer>
        <script src="/js/game.js?v={{ Layout.assetVersion }}" defer></script>
      </body>
    </html> }
}
