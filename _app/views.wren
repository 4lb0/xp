import "/_app/template" for Layout

// Componentes de vista compartidos. Cada método devuelve un solo HtmlNode, así
// que se interpola con {{ Views.algo(...) }} sin escapado doble.
class Views {
  static cardArt(card) { <span class="card-art"><span class="card-emoji" aria-hidden="true">{{ card.emoji }}</span></span> }

  static cardFamily(card, familyLabel, withIcon) { <span class="card-family">{{ withIcon && Layout.icon(card.typeIcon) }} {{ familyLabel }} · <span class="card-id">{{ card.id }}</span></span> }

  static cardTitle(card) { <h3>{{ card.name }}</h3> }

  static cardBadge(card) { <span class="use-badge {{ card.useClass }}" title="{{ card.useHint }}">{{ Layout.icon(card.useIcon) }} {{ card.useLabel }}</span> }

  static cardChips(card) { <div class="effect-chips">
    {{ card.helpChips.map{|h| <span class="chip {{ h["cls"] }}" title="{{ h["title"] }}" aria-label="{{ h["title"] }}">{{ Layout.icon(h["icon"]) }} {{ h["text"] }}</span>} }}
  </div> }

  static cardText(card) { <section class="card-text">{{ card.body }}</section> }

  // Los tres contadores de la mesa. `extra` agrega una clase (por ejemplo la
  // variante del panel de final).
  static gauges(g, extra) { <section class="gauges-board {{ extra }}" aria-label="Contadores de la expedición">
    <article class="counter">
      {{ Layout.die(g.energia, "die-teal") }}
      <span class="counter-body">
        <span class="counter-label">Energía</span>
        <span class="counter-value">{{ g.energia }}</span>
      </span>
    </article>
    <article class="counter">
      {{ Layout.die(g.escudo, "die-gold") }}
      <span class="counter-body">
        <span class="counter-label">Escudo</span>
        <span class="counter-value">{{ g.escudo }}</span>
      </span>
    </article>
    <article class="counter">
      {{ Layout.die(g.pistas, "die-coral") }}
      <span class="counter-body">
        <span class="counter-label">Pistas</span>
        <span class="counter-value">{{ g.pistas }}</span>
      </span>
    </article>
  </section> }

  // Contadores compactos del rail móvil.
  static railState(g) { <div class="rail-state">
    <span class="rail-stat rail-energia" title="Energía {{ g.energia }}"><b>{{ g.energia }}</b><small>⚡</small></span>
    <span class="rail-stat rail-escudo" title="Escudo {{ g.escudo }}"><b>{{ g.escudo }}</b><small>🛡️</small></span>
    <span class="rail-stat rail-pistas" title="Pistas {{ g.pistas }}"><b>{{ g.pistas }}</b><small>🔍</small></span>
  </div> }

  // Opciones del selector de modo, compartidas por la portada y el arranque.
  static modeOptions(selected) { [
    <option value="experto" {{ selected == "experto" ? "selected" : "" }}>Experto — 6 y 6, sin apoyos</option>,
    <option value="casual" {{ selected == "casual" ? "selected" : "" }}>Normal — 6 y 6 + Kit en la mano</option>,
    <option value="facil" {{ selected == "facil" ? "selected" : "" }}>Asistido — 6 y 6 + Carga en la mano</option>
  ] }

  // Selector de un dado de 1 a 6.
  static dieSelect(name, label) { <label class="die-select">{{ label }}<select name="{{ name }}">
      {{ [1, 2, 3, 4, 5, 6].map{|n| <option value="{{ n }}">{{ n }}</option>} }}
    </select></label> }
}
