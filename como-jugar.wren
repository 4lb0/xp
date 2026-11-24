import "_app/template" for Layout

return Layout.render(<main class="quick">

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
        Pueden superar 6, hasta 12. Si al cerrar un turno la Energía o el Escudo quedan en 0, la expedición termina.
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
        <p class="eyebrow">3 Misiones</p>
        <div class="quick-card-row">
          <svg class="quick-card coral" aria-hidden="true"><use href="#ico-card"/></svg>
          <svg class="quick-card green" aria-hidden="true"><use href="#ico-card"/></svg>
          <svg class="quick-card cyan" aria-hidden="true"><use href="#ico-card"/></svg>
        </div>
        <p>Siempre 3 boca arriba. Elegís una por turno.</p>
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
        <p>Los topes están ocultos. El Sonar revela el del Mazo de Misiones.</p>
      </article>
    </div>
  </section>

  <section class="quick-section quick-first">
    <div class="quick-section-head">
      <h2>Tu primer turno</h2>
      <p>Estos 4 pasos se repiten en cada turno.</p>
    </div>
    <p class="quick-note"><strong>Antes de empezar:</strong> 3 cartas de Equipo y 3 de Misión. Todos: 6 de Energía y 6 de Escudo. Diferencia: Experto sin apoyos · Normal +1 · Asistido +2.</p>
    <ol class="quick-steps">
      <li>
        <span class="quick-step-num">1</span>
        <svg class="quick-icon" aria-hidden="true"><use href="#ico-play"/></svg>
        <div>
          <strong>Jugá 1 carta (o no)</strong>
          <p>Arrancás con 3. Se juega antes de elegir la Misión. Herramienta queda; Maniobra se gasta. Al elegir la Misión se descarta lo que quedó en la mano.</p>
        </div>
      </li>
      <li>
        <span class="quick-step-num">2</span>
        <svg class="quick-icon" aria-hidden="true"><use href="#ico-mystery"/></svg>
        <div>
          <strong>Elegí una Misión</strong>
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
          <p>La carta resuelta va al descarte, entra 1 del Mazo de Misiones y el submarino paga ⚡ 1.</p>
        </div>
      </li>
    </ol>
    <div class="quick-example">
      <span class="eyebrow">Primer turno, en concreto</span>
      <p>
        Tenés 3 cartas. Jugás <strong>Soldadura</strong> (🛡️ +1, va al descarte).
        Elegís <strong>El nido</strong>. Tirás <strong>Cara</strong>: éxito, ⚡ +2.
        La carta va al descarte, entra la próxima; descartás toda la mano,
        entra 1 del Mazo de Misiones y el submarino paga <strong>⚡ 1</strong>.
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
        <span class="use-badge use-always">{{ Layout.icon("♾️") }} Siempre</span>
        <span class="chip chip-energia">{{ Layout.icon("⚡") }} +1</span>
        <small>si está en 4 o menos</small>
      </article>
      <article class="fake-card purple">
        <span class="fake-emoji">⚡</span>
        <small>🃏 Maniobra · una vez</small>
        <strong>Batería</strong>
        <span class="use-badge use-now">{{ Layout.icon("👆") }} Ahora</span>
        <span class="chip chip-energia">{{ Layout.icon("⚡") }} +2</span>
        <small>se juega y listo</small>
      </article>
      <article class="fake-card purple">
        <span class="fake-emoji">🚀</span>
        <small>🃏 Maniobra · una vez</small>
        <strong>Turbo</strong>
        <span class="use-badge use-before">{{ Layout.icon("🎲") }} Antes de tirar</span>
        <span class="chip chip-dado">{{ Layout.icon("🎲") }} +2</span>
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
        <h2>0 de Energía o 0 de Escudo al cerrar un turno</h2>
        <p>No es inmediato: se evalúa al cerrar el turno. Basta con que la Energía o el Escudo lleguen a 0.</p>
      </div>
    </article>
  </section>

  <div class="quick-actions">
    <a class="btn btn-primary" href="/juego">Iniciar expedición</a>
    <a class="btn btn-ghost" href="/reglas">Reglas completas</a>
  </div>
</main>, "Cómo jugar · XP")
