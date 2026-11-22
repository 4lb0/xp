import "_app/template" for Layout

return Layout.render(<main class="howto">
  <header class="board-head">
    <div>
      <p class="eyebrow">Guía visual</p>
      <h1>Cómo jugar</h1>
    </div>
    <p class="pill">Solo o en cooperativo · 10 a 20 minutos</p>
  </header>

  <section class="howto-hero panel">
    <div>
      <p class="eyebrow">La idea en una frase</p>
      <h2>Reuní 6 Pistas antes de quedarte sin Energía o sin Escudo.</h2>
      <p>
        Son una expedición en un submarino. Cada ciclo eligen un Misterio, tiran dados
        y aguantan el desgaste. La <strong>Energía</strong> es el reloj; el
        <strong>Escudo</strong>, el casco. Las <strong>Pistas</strong> son la victoria.
      </p>
      <div class="hero-actions">
        <a class="btn btn-primary" href="/juego">Iniciar expedición</a>
        <a class="btn btn-ghost" href="/reglas">Reglas completas</a>
      </div>
    </div>
    <div class="howto-gauges" aria-label="Los tres contadores">
      <div class="gauge">
        {{ Layout.die(6, "die-teal") }}
        <span class="gauge-name">Energía</span>
        <small>El reloj. Si llega a 0, se quedan sin aire.</small>
      </div>
      <div class="gauge">
        {{ Layout.die(6, "die-gold") }}
        <span class="gauge-name">Escudo</span>
        <small>El casco. Si llega a 0, la presión gana.</small>
      </div>
      <div class="gauge">
        {{ Layout.die(3, "die-coral") }}
        <span class="gauge-name">Pistas</span>
        <small>La misión. Con 6, encuentran al Megalodón.</small>
      </div>
    </div>
  </section>

  <section>
    <div class="section-head">
      <h2>La mesa</h2>
      <p>Siempre hay 3 Misterios a la vista y una mano compartida.</p>
    </div>
    <div class="table-map">
      <article class="map-zone">
        <p class="eyebrow">Mazo del Juego</p>
        <div class="fake-row">
          <div class="fake-card coral">
            <span class="fake-emoji" aria-hidden="true">🦈</span>
            <strong>La sombra enorme</strong>
            <small>Peligro · emboscada</small>
            <span class="chip chip-escudo chip-loss">🛡️ −1</span>
          </div>
          <div class="fake-card green">
            <span class="fake-emoji" aria-hidden="true">🥚</span>
            <strong>El nido</strong>
            <small>Dilema</small>
          </div>
          <div class="fake-card cyan">
            <span class="fake-emoji" aria-hidden="true">🫧</span>
            <strong>El túnel</strong>
            <small>Exploración</small>
          </div>
        </div>
        <p class="muted">3 cartas de Misterio siempre. El Sonar puede revelar la próxima carta del mazo con todo su contenido.</p>
      </article>

      <article class="map-zone">
        <p class="eyebrow">Mazo del Equipo</p>
        <div class="fake-row">
          <div class="fake-card gold">
            <span class="fake-emoji" aria-hidden="true">📡</span>
            <strong>Sonar</strong>
            <small>Herramienta · 1 activa</small>
          </div>
          <div class="fake-card purple">
            <span class="fake-emoji" aria-hidden="true">🔧</span>
            <strong>Soldadura</strong>
            <small>Maniobra · al descarte</small>
          </div>
        </div>
        <p class="muted">La mano es una sola. Una Herramienta activa por equipo. Las Maniobras se gastan.</p>
      </article>

      <article class="map-zone map-counters">
        <p class="eyebrow">Contadores</p>
        <div class="counter-chips">
          <span class="chip chip-energia">⚡ Energía</span>
          <span class="chip chip-escudo">🛡️ Escudo</span>
          <span class="chip chip-pistas">🔍 Pistas</span>
        </div>
        <p class="muted">Energía y Escudo arrancan en 5 o 6 según el modo. Las Pistas siempre en 0.</p>
      </article>
    </div>
  </section>

  <section class="panel howto-cycle">
    <div class="section-head">
      <h2>Un ciclo, 4 pasos</h2>
      <p>Se repite hasta que haya 6 Pistas o el submarino ceda.</p>
    </div>
    <ol class="cycle">
      <li>
        <span class="cycle-num">1</span>
        <div>
          <strong>Robá 2 de Equipo</strong>
          <p>Al final del ciclo te quedan 3 cartas: el resto se descarta al azar.</p>
        </div>
      </li>
      <li>
        <span class="cycle-num">2</span>
        <div>
          <strong>Jugá 1 carta (opcional)</strong>
          <p>Herramienta: queda activa. Maniobra: se usa antes de tirar y va al descarte.</p>
        </div>
      </li>
      <li>
        <span class="cycle-num">3</span>
        <div>
          <strong>Elegí un Misterio</strong>
          <p>Lean la carta, elijan una opción y hagan la prueba de dados.</p>
        </div>
      </li>
      <li>
        <span class="cycle-num">4</span>
        <div>
          <strong>Reponé y pagá 1 Energía</strong>
          <p>La carta resuelta va al descarte, entra la próxima del mazo y el submarino consume 1 Energía.</p>
        </div>
      </li>
    </ol>
  </section>

  <section>
    <div class="section-head">
      <h2>La prueba de dados</h2>
      <p>La carta dice qué prueba toca. Siempre se resuelve con dados de seis caras.</p>
    </div>
    <div class="dice-guide">
      <article class="dice-card">
        <p class="eyebrow">CARA</p>
        <div class="dice-row">{{ Layout.die(2) }}{{ Layout.die(4) }}{{ Layout.die(6) }}</div>
        <p>Sale par.</p>
      </article>
      <article class="dice-card">
        <p class="eyebrow">SECA</p>
        <div class="dice-row">{{ Layout.die(1) }}{{ Layout.die(3) }}{{ Layout.die(5) }}</div>
        <p>Sale impar.</p>
      </article>
      <article class="dice-card">
        <p class="eyebrow">SUMA</p>
        <div class="dice-row">{{ Layout.die(5) }}<span class="dice-plus">+</span>{{ Layout.die(3) }}</div>
        <p>La suma llega al número. Ejemplo: 8+.</p>
      </article>
      <article class="dice-card">
        <p class="eyebrow">DOBLES</p>
        <div class="dice-row">{{ Layout.die(3) }}{{ Layout.die(3) }}</div>
        <p>Los dos dados muestran lo mismo.</p>
      </article>
      <article class="dice-card">
        <p class="eyebrow">SIN 1 NI 6</p>
        <div class="dice-row">{{ Layout.die(2) }}{{ Layout.die(5) }}</div>
        <p>Ninguno muestra 1 ni 6.</p>
      </article>
      <article class="dice-card">
        <p class="eyebrow">1 DADO, 4+</p>
        <div class="dice-row">{{ Layout.die(4) }}</div>
        <p>Sale 4, 5 o 6.</p>
      </article>
    </div>
  </section>

  <section>
    <div class="section-head">
      <h2>Qué hace cada carta</h2>
      <p>Todo el Equipo se juega distinto. La carta lo dice arriba.</p>
    </div>
    <div class="card-grid">
      <article class="mini-card howto-card" data-family="herramienta">
        <span class="card-family">Herramienta</span>
        <h3>Queda en la mesa</h3>
        <p class="card-text">Solo una activa por equipo. Si juegan otra, la anterior va al descarte. Suman su efecto mientras estén en juego.</p>
      </article>
      <article class="mini-card howto-card" data-family="maniobra">
        <span class="card-family">Maniobra</span>
        <h3>Se usa una vez</h3>
        <p class="card-text">Se juega antes de tirar, se resuelve y va al descarte. Turbo, Suerte, Cebo, Ahorro, Blindaje, Giro y Focos.</p>
      </article>
      <article class="mini-card howto-card" data-family="apoyo">
        <span class="card-family">Maniobra de apoyo</span>
        <h3>También es Maniobra</h3>
        <p class="card-text">Se usa una vez y va al descarte. Elige ⚡ Energía o 🛡️ Escudo. En Normal/Asistido puede esperar en el área de ayuda.</p>
      </article>
    </div>
  </section>

  <section class="panel howto-alert">
    <p class="eyebrow">Ojo con las emboscadas</p>
    <h2>Algunas cartas golpean al entrar.</h2>
    <p>
      Si el Misterio trae un costo de entrada, se paga apenas llega a la mesa:
      <span class="chip chip-energia chip-loss">⚡ −1</span>
      <span class="chip chip-escudo chip-loss">🛡️ −1</span>
      <span class="chip chip-pistas chip-loss">🔍 −1</span>.
      Al empezar la partida, si hay más de una entre las 3 cartas iniciales, el equipo elige cuál sufrir.
    </p>
  </section>

  <section>
    <div class="section-head">
      <h2>Elegí dificultad</h2>
      <p>Cambia el aguante inicial y las ayudas. La mesa es siempre la misma.</p>
    </div>
    <div class="mode-grid">
      <article class="mode-card">
        <p class="eyebrow">Experto</p>
        <h3>5 ⚡ · 5 🛡️</h3>
        <p>Sin ayudas extra. Las dos Maniobras de apoyo se mezclan en el mazo.</p>
      </article>
      <article class="mode-card">
        <p class="eyebrow">Normal</p>
        <h3>5 ⚡ · 5 🛡️</h3>
        <p>El Kit de emergencia espera en el área de ayuda. Se usa sin gastar la carta del ciclo.</p>
      </article>
      <article class="mode-card mode-card-easy">
        <p class="eyebrow">Asistido</p>
        <h3>6 ⚡ · 6 🛡️</h3>
        <p>Las dos Maniobras de apoyo en el área. Es el modo recomendado para la primera partida.</p>
      </article>
    </div>
  </section>

  <section class="split">
    <article class="panel outcome outcome-win">
      <p class="eyebrow">Ganás si…</p>
      <h2>Llegan a 6 Pistas</h2>
      <p>El Megalodón existe. El mundo puede seguir creyendo que es un mito: ustedes ya lo vieron.</p>
    </article>
    <article class="panel outcome outcome-lose">
      <p class="eyebrow">Pierden si…</p>
      <h2>Energía o Escudo llegan a 0</h2>
      <p>Sin aire no hay expedición. Sin casco, la fosa se queda con el secreto.</p>
    </article>
  </section>

  <section class="panel howto-cta">
    <p class="eyebrow">¿Listo?</p>
    <h2>La fosa no se va a explorar sola.</h2>
    <p class="muted">Podés jugar solo o compartir las decisiones con amigos.</p>
    <div class="hero-actions">
      <a class="btn btn-primary" href="/juego">Iniciar expedición</a>
      <a class="btn btn-ghost" href="/reglas">Leer el manual completo</a>
    </div>
  </section>
</main>, "Cómo jugar · XP")
