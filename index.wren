import "_app/template" for Layout

var session = Session.new()
var modoGuardado = session.get("modo")
var modoInicial = (modoGuardado == "experto" || modoGuardado == "casual" || modoGuardado == "facil") ? modoGuardado : "casual"

return Layout.render(<main>
  <section class="hero">
    <div class="hero-grid">
      <div>
        <div class="hero-brand">
          <img src="/img/logo-xp.png" width="124" height="124" alt="Insignia XP, Equipo eXPedición" />
          <p class="eyebrow">LCG de aventura y misterio</p>
        </div>
        <h1>XP <span>En busca del Megalodón</span></h1>
        <p class="lead">
          Podés jugar solo o en cooperativo con amigos. El submarino baja hacia una fosa que nadie
          cartografió. Para el mundo, el Megalodón es un mito, como el monstruo del lago Ness.
          Ustedes van a comprobar si existe. Es un <strong>LCG</strong>: mazos fijos, sin sobres aleatorios.
        </p>
        <p class="lead">
          <strong>La misión:</strong> reunir 6 Pistas que confirmen al Megalodón antes de quedarse
          sin Energía o sin Escudo. La mesa es una sola: las decisiones se comparten.
        </p>
        <div class="hero-actions">
          <a class="btn btn-primary" href="/juego">Iniciar expedición</a>
          <a class="btn btn-ghost" href="/como-jugar">Cómo jugar</a>
        </div>
      </div>
      <aside class="console" aria-label="Estado inicial de la expedición">
        <h2>Tablero de la mesa</h2>
        <div class="gauges">
          <div class="gauge">
            {{ Layout.die(6, "die-teal") }}
            <span class="gauge-name">Energía</span>
          </div>
          <div class="gauge">
            {{ Layout.die(6, "die-gold") }}
            <span class="gauge-name">Escudo</span>
          </div>
          <div class="gauge">
            {{ Layout.die(0, "die-coral") }}
            <span class="gauge-name">Pistas</span>
          </div>
        </div>
        <p class="hint" style="margin: 1rem 0 0">
          Tres dados D6 quedan a la vista de todos. Energía y Escudo pueden superar 6, con tope 12 y piso 0. Si al empezar el cierre del turno la Energía o el Escudo están en 0, la expedición termina. Si las Pistas llegan a 6, en cualquier momento, la expedición gana.
        </p>
      </aside>
    </div>
  </section>

  <section>
    <div class="section-head">
      <h2>Cómo se juega</h2>
      <p>Cuatro pasos por turno. Sin tablero.</p>
    </div>
    <ol class="steps">
      <li>
        <span class="num">1</span>
        <span><strong>Arrancá con 3 cartas de Equipo</strong>En Normal y Asistido, los apoyos ya vienen en la mano. La mano se mantiene: al cerrar robás 1 carta y descartás hasta 3.</span>
      </li>
      <li>
        <span class="num">2</span>
        <span><strong>Jugá 1 carta (opcional)</strong>Antes de elegir la Misión. Herramienta: queda en la mesa. Maniobra: se usa una vez y va al descarte. La mano no se descarta.</span>
      </li>
      <li>
        <span class="num">3</span>
        <span><strong>Resolvé una Misión</strong>Elegí una de las cartas de la mesa, lean la situación entre todos y elijan una de sus opciones. Después, la prueba de dados.</span>
      </li>
      <li>
        <span class="num">4</span>
        <span><strong>Cerrá el turno</strong>Se revela una nueva Misión. El submarino consume 1 Energía y robás 1 carta; si la mano pasa de 3, descartás hasta quedar con 3.</span>
      </li>
    </ol>
  </section>

  <section>
    <div class="split">
      <div>
        <div class="section-head">
          <h2>Prepará la mesa</h2>
        </div>
        <p class="muted">Podés jugar solo o en cooperativo con amigos: la mesa es una. Siempre hay 3 cartas de Misión y la mano se mantiene en 3.</p>
        <form method="get" action="/juego" class="panel">
          <label for="modo"><strong>Modo</strong></label>
          <p style="margin: 0.4rem 0 0.9rem">
            <select id="modo" name="modo" style="font: inherit; padding: 0.5rem 0.7rem; border-radius: 8px; background: var(--navy); color: inherit; border: 1px solid rgba(51,187,204,.35)">
              <option value="experto" {{ modoInicial == "experto" ? "selected" : "" }}>Experto — 6 y 6, sin apoyos</option>
              <option value="casual" {{ modoInicial == "casual" ? "selected" : "" }}>Normal — 6 y 6 + Kit en la mano</option>
              <option value="facil" {{ modoInicial == "facil" ? "selected" : "" }}>Asistido — 6 y 6 + Kit y Carga en la mano</option>
            </select>
          </p>
          <button class="btn btn-primary">Empezar</button>
        </form>
      </div>
      <div>
        <div class="section-head">
          <h2>Lo que hay en la caja</h2>
        </div>
        <table class="table-stack">
          <caption>Componentes del prototipo</caption>
          <thead>
            <tr><th>Componente</th><th>Cantidad</th></tr>
          </thead>
          <tbody>
            <tr><td>Cartas de Misión</td><td>40</td></tr>
            <tr><td>Cartas de Equipo</td><td>44 (10 Herramientas + 34 Maniobras, 2 de apoyo)</td></tr>
            <tr><td>Dados de estado</td><td>3 D6</td></tr>
            <tr><td>Dados de prueba</td><td>2 a 4 D6</td></tr>
          </tbody>
        </table>
      </div>
    </div>
  </section>

  <section class="panel" style="text-align:center">
    <h2>Se explica en una ronda y se juega en una mesa chica</h2>
    <p class="muted">10 a 20 minutos. Solo o en cooperativo. Desde los 5 años, con las cartas a la vista.</p>
    <a class="btn btn-primary" href="/juego">Probar la expedición</a>
  </section>
</main>, "XP · En busca del Megalodón")
