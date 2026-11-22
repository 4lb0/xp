import "_app/template" for Layout

return Layout.render(<main>
  <section class="hero">
    <div class="hero-grid">
      <div>
        <p class="eyebrow">Juego cooperativo de aventura y misterio</p>
        <h1>XP <span>En busca del Megalodón</span></h1>
        <p class="lead">
          Son un solo equipo. Bajan en un submarino hacia una fosa que nadie cartografió.
          Cada carta es una decisión, cada tirada puede acercarlos al descubrimiento
          o apagar las luces para siempre.
        </p>
        <p class="lead">
          <strong>La misión:</strong> reunir 6 Pistas antes de quedarse sin Energía o sin Escudo.
          Nadie gana solo. Nadie pierde solo.
        </p>
        <div class="hero-actions">
          <a class="btn btn-primary" href="/juego">Iniciar expedición</a>
          <a class="btn btn-ghost" href="/reglas">Leer las reglas</a>
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
          Tres dados D6 quedan a la vista de todos. Si Energía o Escudo llegan a 0,
          la expedición termina. Si Pistas llega a 6, el misterio queda resuelto.
        </p>
      </aside>
    </div>
  </section>

  <section>
    <div class="section-head">
      <h2>Tres ideas, un juego</h2>
      <p>Para jugar en una mesa chica, en un restaurante, en diez minutos.</p>
    </div>
    <div class="card-grid">
      <article class="card" data-family="exploracion">
        <span class="card-family">Cooperativo</span>
        <h3>El equipo es uno</h3>
        <p>No hay roles secretos ni traidores. Se debate, se elige entre todos y se tira una sola vez. La derrota también es compartida.</p>
      </article>
      <article class="card" data-family="peligro">
        <span class="card-family">Misterio</span>
        <h3>El Megalodón casi no se ve</h3>
        <p>Una sombra enorme, un ojo, una estela. El peligro se intuye antes de aparecer: eso es lo que da miedo bonito, no sustos.</p>
      </article>
      <article class="card" data-family="herramienta">
        <span class="card-family">Azar y estrategia</span>
        <h3>La mitad se decide con dados</h3>
        <p>Cara o Seca, suma de dos dados, dobles, evitar el 1. Las Herramientas y Maniobras existen para torcer la suerte a tiempo.</p>
      </article>
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
        <span><strong>Robá 2 cartas de Equipo</strong>Al final del turno te quedan 3 cartas: el resto se descarta al azar.</span>
      </li>
      <li>
        <span class="num">2</span>
        <span><strong>Jugá 1 carta (opcional)</strong>Una Herramienta queda en la mesa toda la partida. Una Maniobra se usa una vez y va al descarte.</span>
      </li>
      <li>
        <span class="num">3</span>
        <span><strong>Resolvé un Misterio</strong>Elegí una de las cartas activas, lean la situación entre todos y elijan una de sus opciones. Después, la prueba de dados.</span>
      </li>
      <li>
        <span class="num">4</span>
        <span><strong>Reponé la mesa</strong>Descarten la carta resuelta, revelen una nueva y pase el dispositivo. Al final se descartan al azar hasta 3.</span>
      </li>
    </ol>
  </section>

  <section>
    <div class="split">
      <div>
        <div class="section-head">
          <h2>Prepará la mesa</h2>
        </div>
        <p class="muted">Se puede jugar solo o en equipo: la mesa es una. Siempre hay 3 cartas de Misterio y se roban 2 de Equipo por turno.</p>
        <form method="get" action="/juego" class="panel">
          <label for="modo"><strong>Modo</strong></label>
          <p style="margin: 0.4rem 0 0.9rem">
            <select id="modo" name="modo" style="font: inherit; padding: 0.5rem 0.7rem; border-radius: 8px; background: #0b2a44; color: inherit; border: 1px solid rgba(127,230,242,.3)">
              <option value="normal" selected>Normal — 5 y 5</option>
              <option value="facil">Fácil — 6 y 6 (chicos) + Batería de apoyo</option>
            </select>
          </p>
          <button class="btn btn-primary">Empezar</button>
        </form>
      </div>
      <div>
        <div class="section-head">
          <h2>Lo que hay en la caja</h2>
        </div>
        <table>
          <caption>Componentes del prototipo</caption>
          <thead>
            <tr><th>Componente</th><th>Cantidad</th></tr>
          </thead>
          <tbody>
            <tr><td>Cartas de Misterio</td><td>40</td></tr>
            <tr><td>Cartas de Equipo</td><td>40 (14 Herramientas + 26 Maniobras)</td></tr>
            <tr><td>Dados de estado</td><td>3 D6</td></tr>
            <tr><td>Dados de prueba</td><td>2 a 4 D6</td></tr>
          </tbody>
        </table>
      </div>
    </div>
  </section>

  <section class="panel" style="text-align:center">
    <p class="eyebrow">Modo restaurante</p>
    <h2>Se explica en una ronda y se juega en una mesa chica</h2>
    <p class="muted">10 a 20 minutos. Solo o en equipo. Desde los 5 años, con las cartas a la vista.</p>
    <a class="btn btn-primary" href="/juego">Probar la expedición</a>
  </section>
</main>)
