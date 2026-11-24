class Layout {
  // Subir al cambiar css/style.css para romper la caché de Cloudflare.
  static assetVersion { "2026-11-24-9" }
  static printVersion { "2026-11-23-1" }
  static description { "XP — Equipo eXPedición. LCG cooperativo de aventura y misterio para toda la familia. Mazos fijos, partidas de 10 a 20 minutos." }

  static render(content) { Layout.render(content, "XP · Equipo eXPedición", false) }

  // Emoji del contenido → ícono de línea. Los emojis de ilustración de carta
  // no pasan por acá: son arte provisorio, no iconografía de interfaz.
  static iconName(glyph) {
    var names = {
      "⚡": "bolt", "🛡": "shield", "🛡️": "shield", "🔍": "mag", "🎲": "dice",
      "🃏": "card", "🂠": "deck", "🔧": "wrench", "🎒": "pack", "📖": "book",
      "🏠": "home", "🎁": "gift", "👀": "eye", "🔊": "sound", "✨": "sparkle",
      "👆": "pointer", "♾": "infinity", "♾️": "infinity", "🔁": "reroll",
      "🔋": "battery", "🫧": "bubble", "🌊": "wave", "🔄": "refresh",
      "🔀": "shuffle", "🚀": "play", "🖐": "hand", "🖐️": "hand"
    }
    return names.containsKey(glyph) ? names[glyph] : "dot"
  }

  static icon(glyph) { <svg class="ico" aria-hidden="true" focusable="false"><use href="#ico-{{ Layout.iconName(glyph) }}"/></svg> }

  static die(value) { Layout.die(value, "") }

  // De 1 a 6, puntos. De 7 a 12, la cifra dentro de la cara: una cara de seis
  // puntos no puede valer 9, así que arriba de 6 manda el número.
  static die(value, extra) { <span class="die {{ value > 6 ? "die-number" : "" }} {{ extra }}" data-value="{{ value }}" aria-hidden="true"><span class="die-num">{{ value > 6 ? value : "" }}</span><span class="p p1"></span><span class="p p2"></span><span class="p p3"></span><span class="p p4"></span><span class="p p5"></span><span class="p p6"></span><span class="p p7"></span><span class="p p8"></span><span class="p p9"></span></span> }

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
        <link rel="icon" type="image/png" sizes="48x48" href="/img/favicon-48.png" />
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
  <svg class="svg-defs" aria-hidden="true" focusable="false">
    <defs>
      <symbol id="ico-card" viewBox="0 0 48 48">
        <g fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round">
          <rect x="9" y="6" width="26" height="36" rx="4"/>
          <path d="M15 15h14M15 21h14M15 27h9"/>
        </g>
      </symbol>
      <symbol id="ico-cards" viewBox="0 0 48 48">
        <g fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round">
          <rect x="5" y="10" width="24" height="31" rx="3"/>
          <rect x="15" y="5" width="24" height="31" rx="3"/>
          <path d="M21 14h12M21 20h12M21 26h8"/>
        </g>
      </symbol>
      <symbol id="ico-play" viewBox="0 0 48 48">
        <g fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round">
          <rect x="8" y="7" width="26" height="34" rx="4"/>
          <path d="M18 18 L30 24 L18 30 Z" fill="currentColor" stroke="none"/>
        </g>
      </symbol>
      <symbol id="ico-mystery" viewBox="0 0 48 48">
        <g fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round">
          <rect x="4" y="13" width="17" height="24" rx="3"/>
          <rect x="15" y="8" width="18" height="29" rx="3"/>
          <rect x="27" y="13" width="17" height="24" rx="3"/>
          <circle cx="24" cy="23" r="2.5" fill="currentColor" stroke="none"/>
        </g>
      </symbol>
      <symbol id="ico-dice" viewBox="0 0 48 48">
        <g fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round">
          <rect x="8" y="8" width="32" height="32" rx="7"/>
          <circle cx="17" cy="17" r="2.2" fill="currentColor" stroke="none"/>
          <circle cx="31" cy="17" r="2.2" fill="currentColor" stroke="none"/>
          <circle cx="24" cy="24" r="2.2" fill="currentColor" stroke="none"/>
          <circle cx="17" cy="31" r="2.2" fill="currentColor" stroke="none"/>
          <circle cx="31" cy="31" r="2.2" fill="currentColor" stroke="none"/>
        </g>
      </symbol>
      <symbol id="ico-deck" viewBox="0 0 48 48">
        <g fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round">
          <rect x="7" y="11" width="24" height="29" rx="3"/>
          <rect x="14" y="6" width="24" height="29" rx="3"/>
          <path d="M20 14h12M20 20h12M20 26h8"/>
        </g>
      </symbol>
      <symbol id="ico-bolt" viewBox="0 0 48 48">
        <path d="M27 4 L12 28 H23 L21 44 L36 20 H25 Z" fill="currentColor"/>
      </symbol>
      <symbol id="ico-shield" viewBox="0 0 48 48">
        <g fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round">
          <path d="M24 5 L41 12 V23 C41 34 33 42 24 45 C15 42 7 34 7 23 V12 Z"/>
        </g>
      </symbol>
      <symbol id="ico-mag" viewBox="0 0 48 48">
        <g fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round">
          <circle cx="21" cy="21" r="12"/>
          <path d="M30 30 L43 43"/>
        </g>
      </symbol>
      <symbol id="ico-trophy" viewBox="0 0 48 48">
        <g fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round">
          <path d="M15 7h18v7c0 8-4 13-9 15-5-2-9-7-9-15Z"/>
          <path d="M15 11H8v4c0 5 3 8 8 8M33 11h7v4c0 5-3 8-8 8"/>
          <path d="M24 29v7M17 41h14"/>
        </g>
      </symbol>
      <symbol id="ico-broken" viewBox="0 0 48 48">
        <g fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round">
          <path d="M24 5 L41 12 V23 C41 34 33 42 24 45 C15 42 7 34 7 23 V12 Z"/>
          <path d="M24 9 L20 22 L28 26 L22 40"/>
        </g>
      </symbol>
      <symbol id="ico-eye" viewBox="0 0 48 48">
        <g fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round">
          <path d="M4 24 C10 14 17 10 24 10 C31 10 38 14 44 24 C38 34 31 38 24 38 C17 38 10 34 4 24 Z"/>
          <circle cx="24" cy="24" r="6"/>
        </g>
      </symbol>
      <symbol id="die1" viewBox="0 0 64 64">
        <rect x="4" y="4" width="56" height="56" rx="10" fill="#F4F1EA"/>
        <circle cx="32" cy="32" r="6" fill="#0B2239"/>
      </symbol>
      <symbol id="die2" viewBox="0 0 64 64">
        <rect x="4" y="4" width="56" height="56" rx="10" fill="#F4F1EA"/>
        <circle cx="20" cy="20" r="6" fill="#0B2239"/>
        <circle cx="44" cy="44" r="6" fill="#0B2239"/>
      </symbol>
      <symbol id="die3" viewBox="0 0 64 64">
        <rect x="4" y="4" width="56" height="56" rx="10" fill="#F4F1EA"/>
        <circle cx="20" cy="20" r="6" fill="#0B2239"/>
        <circle cx="32" cy="32" r="6" fill="#0B2239"/>
        <circle cx="44" cy="44" r="6" fill="#0B2239"/>
      </symbol>
      <symbol id="die4" viewBox="0 0 64 64">
        <rect x="4" y="4" width="56" height="56" rx="10" fill="#F4F1EA"/>
        <circle cx="20" cy="20" r="6" fill="#0B2239"/>
        <circle cx="44" cy="20" r="6" fill="#0B2239"/>
        <circle cx="20" cy="44" r="6" fill="#0B2239"/>
        <circle cx="44" cy="44" r="6" fill="#0B2239"/>
      </symbol>
      <symbol id="die5" viewBox="0 0 64 64">
        <rect x="4" y="4" width="56" height="56" rx="10" fill="#F4F1EA"/>
        <circle cx="20" cy="20" r="6" fill="#0B2239"/>
        <circle cx="44" cy="20" r="6" fill="#0B2239"/>
        <circle cx="32" cy="32" r="6" fill="#0B2239"/>
        <circle cx="20" cy="44" r="6" fill="#0B2239"/>
        <circle cx="44" cy="44" r="6" fill="#0B2239"/>
      </symbol>
      <symbol id="die6" viewBox="0 0 64 64">
        <rect x="4" y="4" width="56" height="56" rx="10" fill="#F4F1EA"/>
        <circle cx="20" cy="20" r="6" fill="#0B2239"/>
        <circle cx="44" cy="20" r="6" fill="#0B2239"/>
        <circle cx="20" cy="32" r="6" fill="#0B2239"/>
        <circle cx="44" cy="32" r="6" fill="#0B2239"/>
        <circle cx="20" cy="44" r="6" fill="#0B2239"/>
        <circle cx="44" cy="44" r="6" fill="#0B2239"/>
      </symbol>
      <symbol id="ico-hand" viewBox="0 0 48 48">
        <g fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round">
          <path d="M15 26V14a3 3 0 0 1 6 0v10"/>
          <path d="M21 24V11a3 3 0 0 1 6 0v13"/>
          <path d="M27 24V14a3 3 0 0 1 6 0v14"/>
          <path d="M33 28v-6a3 3 0 0 1 6 0v10c0 6-5 10-11 10h-4c-6 0-10-4-10-10l-3-6a3 3 0 0 1 5-3l3 4"/>
        </g>
      </symbol>
      <symbol id="ico-wrench" viewBox="0 0 48 48">
        <g fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round">
          <path d="M30 8a10 10 0 0 0-8 16L10 36a3 3 0 0 0 4 4l12-12A10 10 0 0 0 40 18l-6 2-4-4 2-8z"/>
        </g>
      </symbol>
      <symbol id="ico-pack" viewBox="0 0 48 48">
        <g fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round">
          <path d="M16 16v-3a4 4 0 0 1 4-4h8a4 4 0 0 1 4 4v3"/>
          <rect x="9" y="16" width="30" height="24" rx="5"/>
          <path d="M9 26h30M22 26v6"/>
        </g>
      </symbol>
      <symbol id="ico-book" viewBox="0 0 48 48">
        <g fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round">
          <path d="M24 13c-3-3-8-4-13-4v26c5 0 10 1 13 4 3-3 8-4 13-4V9c-5 0-10 1-13 4z"/>
          <path d="M24 13v26"/>
        </g>
      </symbol>
      <symbol id="ico-home" viewBox="0 0 48 48">
        <g fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round">
          <path d="M8 22 24 8l16 14"/>
          <path d="M12 20v18h24V20"/>
          <path d="M21 38v-9h6v9"/>
        </g>
      </symbol>
      <symbol id="ico-gift" viewBox="0 0 48 48">
        <g fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round">
          <rect x="8" y="18" width="32" height="22" rx="3"/>
          <path d="M8 26h32M24 18v22"/>
          <path d="M24 18c-6 0-11-2-11-6a4 4 0 0 1 8-1c1 2 3 4 3 7zm0 0c6 0 11-2 11-6a4 4 0 0 0-8-1c-1 2-3 4-3 7z"/>
        </g>
      </symbol>
      <symbol id="ico-sound" viewBox="0 0 48 48">
        <g fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round">
          <path d="M8 20h8l10-8v24l-10-8H8z"/>
          <path d="M32 18a8 8 0 0 1 0 12M37 13a14 14 0 0 1 0 22"/>
        </g>
      </symbol>
      <symbol id="ico-sparkle" viewBox="0 0 48 48">
        <g fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round">
          <path d="M24 6c1 8 4 12 12 14-8 2-11 6-12 14-1-8-4-12-12-14 8-2 11-6 12-14z"/>
          <path d="M37 30l1 4 4 1-4 1-1 4-1-4-4-1 4-1z"/>
        </g>
      </symbol>
      <symbol id="ico-pointer" viewBox="0 0 48 48">
        <g fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round">
          <path d="M20 26V10a3 3 0 0 1 6 0v14"/>
          <path d="M26 24V16a3 3 0 0 1 6 0v12l3-2a3 3 0 0 1 4 3l-4 9a10 10 0 0 1-9 6c-6 0-9-3-12-8l-3-5a3 3 0 0 1 5-3l4 4"/>
        </g>
      </symbol>
      <symbol id="ico-infinity" viewBox="0 0 48 48">
        <g fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round">
          <path d="M24 24c-4-5-6-7-10-7a7 7 0 0 0 0 14c4 0 6-2 10-7 4-5 6-7 10-7a7 7 0 0 1 0 14c-4 0-6-2-10-7z"/>
        </g>
      </symbol>
      <symbol id="ico-reroll" viewBox="0 0 48 48">
        <g fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round">
          <path d="M12 20a14 14 0 0 1 24-4"/>
          <path d="M36 8v8h-8"/>
          <path d="M36 28a14 14 0 0 1-24 4"/>
          <path d="M12 40v-8h8"/>
        </g>
      </symbol>
      <symbol id="ico-battery" viewBox="0 0 48 48">
        <g fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round">
          <rect x="6" y="15" width="30" height="18" rx="4"/>
          <path d="M41 21v6"/>
          <path d="M14 21v6M20 21v6M26 21v6"/>
        </g>
      </symbol>
      <symbol id="ico-bubble" viewBox="0 0 48 48">
        <g fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round">
          <circle cx="20" cy="28" r="10"/>
          <circle cx="34" cy="15" r="5"/>
          <path d="M15 22a8 8 0 0 1 4-3"/>
        </g>
      </symbol>
      <symbol id="ico-wave" viewBox="0 0 48 48">
        <g fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round">
          <path d="M4 18c5-6 9-6 14 0s9 6 14 0 9-6 12 0"/>
          <path d="M4 31c5-6 9-6 14 0s9 6 14 0 9-6 12 0"/>
        </g>
      </symbol>
      <symbol id="ico-refresh" viewBox="0 0 48 48">
        <g fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round">
          <path d="M38 24a14 14 0 1 1-5-10.7"/>
          <path d="M38 8v9h-9"/>
        </g>
      </symbol>
      <symbol id="ico-shuffle" viewBox="0 0 48 48">
        <g fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round">
          <path d="M6 14h6c10 0 12 20 22 20h8M6 34h6c10 0 12-20 22-20h8"/>
          <path d="M36 9l6 5-6 5M36 29l6 5-6 5"/>
        </g>
      </symbol>
      <symbol id="ico-dot" viewBox="0 0 48 48">
        <circle cx="24" cy="24" r="4" fill="currentColor"/>
      </symbol>
    </defs>
  </svg>
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
            <p class="muted">Hecho con <a href="https://iz.ar" target="_blank" rel="noopener">iz.ar</a></p>
          </div>
        </footer>
        <script src="/js/game.js?v={{ Layout.assetVersion }}" defer></script>
      </body>
    </html> }
}
