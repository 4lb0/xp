import "_app/template" for Layout

return Layout.render(<main>
  <header class="board-head">
    <div>
      <p class="eyebrow">Para quien edita</p>
      <h1>Cómo editar las cartas</h1>
    </div>
    <a class="btn btn-ghost btn-small" href="/cartas">Volver al mazo</a>
  </header>
  <section class="panel doc">
    {{ Markdown.file("cartas/LEEME.md") }}
  </section>
</main>, "Editar cartas · XP")
