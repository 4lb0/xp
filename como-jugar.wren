import "_app/template" for Layout

return Layout.render(<main class="quick">
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
        <rect x="4" y="4" width="56" height="56" rx="10" fill="#eaf6f8"/>
        <circle cx="32" cy="32" r="6" fill="#0a2239"/>
      </symbol>
      <symbol id="die2" viewBox="0 0 64 64">
        <rect x="4" y="4" width="56" height="56" rx="10" fill="#eaf6f8"/>
        <circle cx="20" cy="20" r="6" fill="#0a2239"/>
        <circle cx="44" cy="44" r="6" fill="#0a2239"/>
      </symbol>
      <symbol id="die3" viewBox="0 0 64 64">
        <rect x="4" y="4" width="56" height="56" rx="10" fill="#eaf6f8"/>
        <circle cx="20" cy="20" r="6" fill="#0a2239"/>
        <circle cx="32" cy="32" r="6" fill="#0a2239"/>
        <circle cx="44" cy="44" r="6" fill="#0a2239"/>
      </symbol>
      <symbol id="die4" viewBox="0 0 64 64">
        <rect x="4" y="4" width="56" height="56" rx="10" fill="#eaf6f8"/>
        <circle cx="20" cy="20" r="6" fill="#0a2239"/>
        <circle cx="44" cy="20" r="6" fill="#0a2239"/>
        <circle cx="20" cy="44" r="6" fill="#0a2239"/>
        <circle cx="44" cy="44" r="6" fill="#0a2239"/>
      </symbol>
      <symbol id="die5" viewBox="0 0 64 64">
        <rect x="4" y="4" width="56" height="56" rx="10" fill="#eaf6f8"/>
        <circle cx="20" cy="20" r="6" fill="#0a2239"/>
        <circle cx="44" cy="20" r="6" fill="#0a2239"/>
        <circle cx="32" cy="32" r="6" fill="#0a2239"/>
        <circle cx="20" cy="44" r="6" fill="#0a2239"/>
        <circle cx="44" cy="44" r="6" fill="#0a2239"/>
      </symbol>
      <symbol id="die6" viewBox="0 0 64 64">
        <rect x="4" y="4" width="56" height="56" rx="10" fill="#eaf6f8"/>
        <circle cx="20" cy="20" r="6" fill="#0a2239"/>
        <circle cx="44" cy="20" r="6" fill="#0a2239"/>
        <circle cx="20" cy="32" r="6" fill="#0a2239"/>
        <circle cx="44" cy="32" r="6" fill="#0a2239"/>
        <circle cx="20" cy="44" r="6" fill="#0a2239"/>
        <circle cx="44" cy="44" r="6" fill="#0a2239"/>
      </symbol>
    </defs>
  </svg>

  <header class="board-head">
    <div>
      <p class="eyebrow">Guía visual</p>
      <h1>Cómo jugar</h1>
    </div>
    <p class="pill">LCG · mazos fijos · 10 a 20 minutos · solo o en cooperativo</p>
  </header>

  <section class="quick-goal panel">
    <div>
      <p class="eyebrow">El objetivo</p>
      <h2>Encontrá al Megalodón con 6 Pistas.</h2>
      <p>
        La <strong>Energía</strong> es el aire. El <strong>Escudo</strong> es el casco.
        Pueden superar 6. Si al cerrar un turno ambos están en 0 a la vez, la expedición termina.
        Si las Pistas llegan a 6, ganan en ese momento. Es un <strong>LCG</strong>: mazos fijos, sin sobres.
      </p>
    </div>
    <div class="quick-gauges" aria-label="Los tres contadores">
      <div class="quick-gauge">
        <svg aria-hidden="true"><use href="#ico-bolt"/></svg>
        <strong>6</strong>
        <span>Energía</span>
      </div>
      <div class="quick-gauge">
        <svg aria-hidden="true"><use href="#ico-shield"/></svg>
        <strong>6</strong>
        <span>Escudo</span>
      </div>
      <div class="quick-gauge">
        <svg aria-hidden="true"><use href="#ico-mag"/></svg>
        <strong>0 → 6</strong>
        <span>Pistas</span>
      </div>
    </div>
  </section>

  <section class="quick-section">
    <div class="quick-section-head">
      <h2>La mesa</h2>
      <p>Esto es todo lo que necesitás tener a la vista.</p>
    </div>
    <div class="quick-map">
      <article class="quick-zone">
        <p class="eyebrow">3 Misterios</p>
        <div class="quick-card-row">
          <svg class="quick-card coral" aria-hidden="true"><use href="#ico-card"/></svg>
          <svg class="quick-card green" aria-hidden="true"><use href="#ico-card"/></svg>
          <svg class="quick-card cyan" aria-hidden="true"><use href="#ico-card"/></svg>
        </div>
        <p>Siempre 3 boca arriba. Elegís uno por turno.</p>
      </article>

      <article class="quick-zone">
        <p class="eyebrow">Tu mano</p>
        <div class="quick-card-row">
          <svg class="quick-card gold" aria-hidden="true"><use href="#ico-card"/></svg>
          <svg class="quick-card purple" aria-hidden="true"><use href="#ico-card"/></svg>
          <svg class="quick-card gold" aria-hidden="true"><use href="#ico-card"/></svg>
        </div>
        <p>Compartida. Arrancás con 3; se repone a 3 cada turno.</p>
      </article>

      <article class="quick-zone">
        <p class="eyebrow">Herramienta</p>
        <div class="quick-card-row">
          <svg class="quick-card gold" aria-hidden="true"><use href="#ico-card"/></svg>
        </div>
        <p>Una sola activa. La nueva pisa la anterior.</p>
      </article>

      <article class="quick-zone">
        <p class="eyebrow">Mazos</p>
        <div class="quick-decks">
          <div class="quick-deck">
            <svg aria-hidden="true"><use href="#ico-deck"/></svg>
            <small>Juego</small>
          </div>
          <div class="quick-deck">
            <svg aria-hidden="true"><use href="#ico-deck"/></svg>
            <small>Equipo</small>
          </div>
        </div>
        <p>Los topes están ocultos. El Sonar revela el del Mazo del Juego.</p>
      </article>
    </div>
  </section>

  <section class="quick-section quick-first">
    <div class="quick-section-head">
      <h2>Tu primer turno</h2>
      <p>Estos 4 pasos se repiten en cada turno.</p>
    </div>
    <p class="quick-note"><strong>Antes de empezar:</strong> 3 cartas de Equipo y 3 de Misterio. Todos: 6 de Energía y 6 de Escudo. Diferencia: Experto sin apoyos · Normal +1 · Asistido +2.</p>
    <ol class="quick-steps">
      <li>
        <span class="quick-step-num">1</span>
        <svg class="quick-icon" aria-hidden="true"><use href="#ico-play"/></svg>
        <div>
          <strong>Jugá 1 carta (o no)</strong>
          <p>Arrancás con 3. Podés jugarla antes o después de elegir el Misterio, siempre antes de tirar. Herramienta queda; Maniobra se gasta.</p>
        </div>
      </li>
      <li>
        <span class="quick-step-num">2</span>
        <svg class="quick-icon" aria-hidden="true"><use href="#ico-mystery"/></svg>
        <div>
          <strong>Elegí un Misterio</strong>
          <p>Hay 3 boca arriba. Lean la carta y elijan una de sus opciones.</p>
        </div>
      </li>
      <li>
        <span class="quick-step-num">3</span>
        <svg class="quick-icon" aria-hidden="true"><use href="#ico-dice"/></svg>
        <div>
          <strong>Tirá y resolvé</strong>
          <p>Aplicá éxito o fallo. La carta resuelta va al descarte.</p>
        </div>
      </li>
      <li>
        <span class="quick-step-num">4</span>
        <svg class="quick-icon" aria-hidden="true"><use href="#ico-deck"/></svg>
        <div>
          <strong>Cerrá el turno</strong>
          <p>Descartá toda la mano, robá 1 del Mazo del Juego, reponé la mano a 3 y pagá ⚡ 1.</p>
        </div>
      </li>
    </ol>
    <div class="quick-example">
      <span class="eyebrow">Primer turno, en concreto</span>
      <p>
        Tenés 3 cartas. Jugás <strong>Soldadura</strong> (🛡️ +1, va al descarte).
        Elegís <strong>El nido</strong>. Tirás <strong>Cara</strong>: éxito, ⚡ +2.
        La carta va al descarte, entra la próxima; descartás toda la mano,
        robás 1 del Mazo del Juego, reponés la mano a 3 y el submarino paga <strong>⚡ 1</strong>.
      </p>
    </div>
  </section>

  <section class="quick-section">
    <div class="quick-section-head">
      <h2>Cómo leer una carta de Equipo</h2>
      <p>Los íconos dicen qué es, cuándo se usa y qué hace. No hace falta leer el texto.</p>
    </div>
    <div class="quick-key">
      <article class="fake-card gold">
        <span class="fake-emoji">🔋</span>
        <small>🔧 Herramienta · queda</small>
        <strong>Generador</strong>
        <span class="use-badge use-always">♾️ Siempre</span>
        <span class="chip chip-energia">⚡ +1</span>
        <small>si está en 4 o menos</small>
      </article>
      <article class="fake-card purple">
        <span class="fake-emoji">⚡</span>
        <small>🃏 Maniobra · una vez</small>
        <strong>Batería</strong>
        <span class="use-badge use-now">👆 Ahora</span>
        <span class="chip chip-energia">⚡ +2</span>
        <small>se juega y listo</small>
      </article>
      <article class="fake-card purple">
        <span class="fake-emoji">🚀</span>
        <small>🃏 Maniobra · una vez</small>
        <strong>Turbo</strong>
        <span class="use-badge use-before">🎲 Antes de tirar</span>
        <span class="chip chip-dado">🎲 +2</span>
        <small>se prepara antes de la prueba</small>
      </article>
    </div>
    <div class="quick-rules">
      <span><strong>🔧 Herramienta:</strong> queda en la mesa</span>
      <span><strong>🃏 Maniobra:</strong> una vez y al descarte</span>
      <span><strong>👆 Ahora:</strong> se resuelve enseguida</span>
      <span><strong>🎲 Antes de tirar:</strong> se prepara para la prueba</span>
      <span><strong>♾️ Siempre:</strong> funciona sola en la mesa</span>
    </div>
  </section>

  <section class="quick-section">
    <div class="quick-section-head">
      <h2>La tirada</h2>
      <p>La carta dice qué prueba toca. Siempre con dados de seis caras.</p>
    </div>
    <div class="quick-dice">
      <div>
        <svg class="quick-die" aria-hidden="true"><use href="#die2"/></svg>
        <strong>CARA</strong><span>sale par</span>
      </div>
      <div>
        <svg class="quick-die" aria-hidden="true"><use href="#die3"/></svg>
        <strong>SECA</strong><span>sale impar</span>
      </div>
      <div>
        <svg class="quick-die" aria-hidden="true"><use href="#die5"/></svg>
        <span class="quick-plus">+</span>
        <svg class="quick-die" aria-hidden="true"><use href="#die3"/></svg>
        <strong>SUMA</strong><span>5 + 3 = 8</span>
      </div>
      <div>
        <svg class="quick-die" aria-hidden="true"><use href="#die4"/></svg>
        <svg class="quick-die" aria-hidden="true"><use href="#die4"/></svg>
        <strong>DOBLES</strong><span>iguales</span>
      </div>
      <div>
        <svg class="quick-die" aria-hidden="true"><use href="#die2"/></svg>
        <svg class="quick-die" aria-hidden="true"><use href="#die5"/></svg>
        <strong>SIN 1 NI 6</strong><span>ninguno 1 ni 6</span>
      </div>
      <div>
        <svg class="quick-die" aria-hidden="true"><use href="#die4"/></svg>
        <strong>1 DADO 4+</strong><span>4, 5 o 6</span>
      </div>
    </div>
  </section>

  <section class="quick-section">
    <div class="quick-rules">
      <span><strong>1</strong> carta por turno</span>
      <span><strong>1</strong> Herramienta activa</span>
      <span><strong>3</strong> al empezar</span>
      <span><strong>Emboscada:</strong> −1 ⚡, 🛡️ o Pista al entrar</span>
      <span><strong>Modos:</strong> todos 6/6 · Experto sin apoyos · Normal +1 · Asistido +2</span>
    </div>
  </section>

  <section class="quick-end">
    <article class="quick-end-card win">
      <svg aria-hidden="true"><use href="#ico-trophy"/></svg>
      <div>
        <p class="eyebrow">Ganás</p>
        <h2>6 Pistas</h2>
        <p>El Megalodón existe. El mundo puede seguir creyendo que es un mito.</p>
      </div>
    </article>
    <article class="quick-end-card lose">
      <svg aria-hidden="true"><use href="#ico-broken"/></svg>
      <div>
        <p class="eyebrow">Perdés</p>
        <h2>0 Energía y 0 Escudo al cerrar un turno</h2>
        <p>No es inmediato: si al terminar el turno siguen ambos en 0, la expedición termina.</p>
      </div>
    </article>
  </section>

  <div class="quick-actions">
    <a class="btn btn-primary" href="/juego">Iniciar expedición</a>
    <a class="btn btn-ghost" href="/reglas">Reglas completas</a>
  </div>
</main>, "Cómo jugar · XP")
