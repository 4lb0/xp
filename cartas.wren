import "_app/template" for Layout
import "_app/cards" for Card

var misterio = []
for (i in 1..60) {
  var c = Card.get("m" + Util.lpad(i.toString, 2, "0"))
  if (c != null) misterio.add(c)
}

var equipo = []
for (i in 1..30) {
  var c = Card.get("e" + Util.lpad(i.toString, 2, "0"))
  if (c != null) equipo.add(c)
}

var exploracion = misterio.where { |c| c.family == "exploracion" }.toList
var peligro = misterio.where { |c| c.family == "peligro" }.toList
var dilema = misterio.where { |c| c.family == "dilema" }.toList
var herramientas = equipo.where { |c| c.type == "herramienta" }.toList
var maniobras = equipo.where { |c| c.type == "maniobra" && !c.isSupport }.toList
var apoyos = equipo.where { |c| c.isSupport }.toList

return Layout.render(<main>
  <header class="board-head">
    <div>
      <p class="eyebrow">Mazo completo</p>
      <h1>El mazo completo</h1>
    </div>
    <p class="pill">{{ misterio.count }} de Misterio · {{ equipo.count }} de Equipo</p>
  </header>

  <nav class="toc" aria-label="Secciones del mazo">
    <a class="pill" href="#exploracion">Exploración ({{ exploracion.count }})</a>
    <a class="pill" href="#peligro">Peligro ({{ peligro.count }})</a>
    <a class="pill" href="#dilema">Dilema ({{ dilema.count }})</a>
    <a class="pill" href="#herramientas">Herramientas ({{ herramientas.count }})</a>
    <a class="pill" href="#maniobras">Maniobras ({{ maniobras.count }})</a>
    <a class="pill pill-support" href="#apoyos">Maniobras de apoyo ({{ apoyos.count }})</a>
  </nav>

  <p class="hint">Cada carta es un archivo markdown en <code>cartas/</code>. El emoji es el arte provisorio hasta que llegue la ilustración. Editá el texto, los dados o los efectos y la próxima partida ya usa la versión nueva. <a href="/editar-cartas">Cómo editar una carta</a>.</p>

  <p class="hint"><strong>Proxies para imprimir:</strong> <a href="/pdf/xp-proxies-bw.pdf?v={{ Layout.printVersion }}">descargar el PDF B&amp;N</a> · 84 cartas + 3 referencias · 60 × 86 mm · 9 por hoja A4 · con líneas de corte.</p>

  <section class="deck-section" id="exploracion">
    <div class="section-head"><h2>Exploración y pistas</h2><p>Investigar, descifrar, descubrir.</p></div>
    <div class="deck-grid">
      {{ exploracion.map{|c| <article class="mini-card" data-family="exploracion">
        <span class="card-art"><span class="card-emoji" aria-hidden="true">{{ c.emoji }}</span></span>
        <span class="card-family">Exploración · <span class="card-id">{{ c.id }}</span></span>
        <h3>{{ c.name }}</h3>
        <section class="card-text">{{ c.body }}</section>
        <ul>
          {{ c.options.map{|o| <li>{{ o["texto"] }} — <span class="test-badge test-{{ o["tipoPrueba"] }}">{{ o["pruebaLabel"] }}</span><br/><span class="option-effects">
  <span class="chip-label">Éxito</span>
  {{ o["exitoChips"].map{|c| <span class="chip {{ c["cls"] }}" title="{{ c["title"] }}" aria-label="{{ c["title"] }}">{{ c["icon"] }} {{ c["text"] }}</span>} }}
  <span class="chip-label">Fallo</span>
  {{ o["falloChips"].map{|c| <span class="chip {{ c["cls"] }}" title="{{ c["title"] }}" aria-label="{{ c["title"] }}">{{ c["icon"] }} {{ c["text"] }}</span>} }}
</span></li>} }}
        </ul>
      </article>} }}
    </div>
  </section>

  <section class="deck-section" id="peligro">
    <div class="section-head"><h2>Peligro y encuentros</h2><p>El Megalodón casi nunca se ve. Eso es lo que asusta.</p></div>
    <div class="deck-grid">
      {{ peligro.map{|c| <article class="mini-card" data-family="peligro">
        <span class="card-art"><span class="card-emoji" aria-hidden="true">{{ c.emoji }}</span></span>
        <span class="card-family">Peligro{{ c.entry != "" ? " · Emboscada" : "" }} · <span class="card-id">{{ c.id }}</span></span>
        <h3>{{ c.name }}</h3>
        {{ c.entry != "" && <p class="entry-badge">Al entrar
          {{ c.entryChips.map{|c| <span class="chip {{ c["cls"] }}" title="{{ c["title"] }}" aria-label="{{ c["title"] }}">{{ c["icon"] }} {{ c["text"] }}</span>} }}
        </p> }}
        <section class="card-text">{{ c.body }}</section>
        <ul>
          {{ c.options.map{|o| <li>{{ o["texto"] }} — <span class="test-badge test-{{ o["tipoPrueba"] }}">{{ o["pruebaLabel"] }}</span><br/><span class="option-effects">
  <span class="chip-label">Éxito</span>
  {{ o["exitoChips"].map{|c| <span class="chip {{ c["cls"] }}" title="{{ c["title"] }}" aria-label="{{ c["title"] }}">{{ c["icon"] }} {{ c["text"] }}</span>} }}
  <span class="chip-label">Fallo</span>
  {{ o["falloChips"].map{|c| <span class="chip {{ c["cls"] }}" title="{{ c["title"] }}" aria-label="{{ c["title"] }}">{{ c["icon"] }} {{ c["text"] }}</span>} }}
</span></li>} }}
        </ul>
      </article>} }}
    </div>
  </section>

  <section class="deck-section" id="dilema">
    <div class="section-head"><h2>Dilemas y recursos</h2><p>Elegir también cuesta: solo mueven Energía y Escudo.</p></div>
    <div class="deck-grid">
      {{ dilema.map{|c| <article class="mini-card" data-family="dilema">
        <span class="card-art"><span class="card-emoji" aria-hidden="true">{{ c.emoji }}</span></span>
        <span class="card-family">Dilema · <span class="card-id">{{ c.id }}</span></span>
        <h3>{{ c.name }}</h3>
        <section class="card-text">{{ c.body }}</section>
        <ul>
          {{ c.options.map{|o| <li>{{ o["texto"] }} — <span class="test-badge test-{{ o["tipoPrueba"] }}">{{ o["pruebaLabel"] }}</span><br/><span class="option-effects">
  <span class="chip-label">Éxito</span>
  {{ o["exitoChips"].map{|c| <span class="chip {{ c["cls"] }}" title="{{ c["title"] }}" aria-label="{{ c["title"] }}">{{ c["icon"] }} {{ c["text"] }}</span>} }}
  <span class="chip-label">Fallo</span>
  {{ o["falloChips"].map{|c| <span class="chip {{ c["cls"] }}" title="{{ c["title"] }}" aria-label="{{ c["title"] }}">{{ c["icon"] }} {{ c["text"] }}</span>} }}
</span></li>} }}
        </ul>
      </article>} }}
    </div>
  </section>

  <section class="deck-section" id="herramientas">
    <div class="section-head"><h2>Herramientas</h2><p>Permanentes. Una sola activa por equipo.</p></div>
    <div class="deck-grid">
      {{ herramientas.map{|c| <article class="mini-card" data-family="herramienta">
        <span class="card-art"><span class="card-emoji" aria-hidden="true">{{ c.emoji }}</span></span>
        <span class="card-family">Herramienta · x{{ c.copies }} · <span class="card-id">{{ c.id }}</span></span>
        <h3>{{ c.name }}</h3>
        <section class="card-text">{{ c.body }}</section>
      </article>} }}
    </div>
  </section>

  <section class="deck-section" id="maniobras">
    <div class="section-head"><h2>Maniobras</h2><p>Se usan una vez y van al descarte.</p></div>
    <div class="deck-grid">
      {{ maniobras.map{|c| <article class="mini-card" data-family="maniobra">
        <span class="card-art"><span class="card-emoji" aria-hidden="true">{{ c.emoji }}</span></span>
        <span class="card-family">Maniobra · x{{ c.copies }} · <span class="card-id">{{ c.id }}</span></span>
        <h3>{{ c.name }}</h3>
        <section class="card-text">{{ c.body }}</section>
      </article>} }}
    </div>
  </section>

  <section class="deck-section" id="apoyos">
    <div class="section-head"><h2>Maniobras de apoyo</h2><p>Las cartas para encontrar rápido: se usan una vez, van al descarte y eligen Energía o Escudo.</p></div>
    <div class="deck-grid">
      {{ apoyos.map{|c| <article class="mini-card" data-family="apoyo">
        <span class="card-ribbon">Apoyo</span>
        <span class="card-art"><span class="card-emoji" aria-hidden="true">{{ c.emoji }}</span></span>
        <span class="card-family">Maniobra de apoyo · x{{ c.copies }} · <span class="card-id">{{ c.id }}</span></span>
        <h3>{{ c.name }}</h3>
        <section class="card-text">{{ c.body }}</section>
      </article>} }}
    </div>
  </section>
</main>)
