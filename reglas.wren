import "_app/template" for Layout

return Layout.render(<main>
  <header class="board-head">
    <div>
      <p class="eyebrow">Manual de bolsillo</p>
      <h1>Reglas de XP</h1>
    </div>
    <p class="pill">Solo o en cooperativo · 10 a 20 minutos</p>
  </header>

  <section>
    <div class="split">
      <div>
        <h2>La idea</h2>
        <p>Podés jugar solo o en cooperativo con amigos. El submarino baja hacia una fosa sin cartografiar en busca de seis Pistas que confirmen que el Megalodón existe. Para el resto del mundo es una leyenda, como el monstruo del lago Ness.</p>
        <ul>
          <li><strong>Ganan</strong> si reúnen 6 Pistas.</li>
          <li><strong>Pierden</strong> si la Energía llega a 0 (se quedan sin aire) o el Escudo llega a 0 (el casco cede).</li>
        </ul>
        <p class="hint">En la app, la mano es una sola y las decisiones se comparten. Podés jugar solo o en cooperativo con amigos: la mesa es la misma.</p>
        <p class="hint">Se juega con el <strong>tope revelado</strong>: la próxima carta del Mazo del Juego y la del Mazo del Equipo están a la vista, con su contenido.</p>
        <p class="hint">Las cartas de Dilema no dan ni quitan Pistas: solo mueven Energía y Escudo.</p>
      </div>
      <div class="console">
        <h2>Los tres contadores</h2>
        <div class="gauges">
          <div class="gauge">{{ Layout.die(6, "die-teal") }}<span class="gauge-name">Energía</span></div>
          <div class="gauge">{{ Layout.die(6, "die-gold") }}<span class="gauge-name">Escudo</span></div>
          <div class="gauge">{{ Layout.die(0, "die-coral") }}<span class="gauge-name">Pistas</span></div>
        </div>
        <p class="hint" style="margin: 0.9rem 0 0">Arrancan en 6, 6 y 0. Se mueven entre 0 y 6, nunca más.</p>
      </div>
    </div>
  </section>

  <section>
    <div class="section-head">
      <h2>Preparación</h2>
    </div>
    <ol class="steps">
      <li><span class="num">1</span><span><strong>Arranquen con 3 cartas de Equipo</strong>La mano es compartida. Con niños de 5 años conviene leer las opciones en voz alta.</span></li>
      <li><span class="num">2</span><span><strong>Revelen siempre 3 cartas de Misterio</strong>Sin importar cuántos jueguen. La mesa no cambia: cambia a quién le toca tirar.</span></li>
      <li><span class="num">3</span><span><strong>Pongan los contadores</strong>Experto: 5 y 5. Normal: 5 y 5 + 1 Maniobra de apoyo en el área. Asistido: 6 y 6 + 2 Maniobras de apoyo. Pistas 0 en todos.</span></li>
    </ol>
  </section>

  <section>
    <div class="section-head">
      <h2>El ciclo, paso a paso</h2>
      <p>Se juega un ciclo por vez, solo o en cooperativo.</p>
    </div>
    <ol class="steps">
      <li><span class="num">1</span><span><strong>Robá 2 cartas de Equipo</strong>Robás 2 por ciclo y jugás con las cartas que tengas. Al final del ciclo te quedan 3: el resto se descarta al azar.</span></li>
      <li><span class="num">2</span><span><strong>Jugá 1 carta (opcional)</strong>Herramienta: queda en la mesa toda la partida. Una sola en mesa; la nueva reemplaza a la anterior. Maniobra: se resuelve y va al descarte.</span></li>
      <li><span class="num">3</span><span><strong>Resolvé un Misterio</strong>Elegí una carta activa, lean la situación, debatan y elijan una de sus opciones. Después viene la prueba de dados.</span></li>
      <li><span class="num">4</span><span><strong>Reponé la mesa y pasá el ciclo</strong>La carta resuelta va al descarte, se revela una nueva y pasan al siguiente ciclo. Al final, las cartas que sobren de 3 se descartan al azar.</span></li>
    </ol>
  </section>

  <section class="panel legend">
    <p class="eyebrow">Fichas de efectos</p>
    <p><span class="chip chip-energia">⚡ +1</span> Energía · <span class="chip chip-escudo">🛡️ +2</span> Escudo · <span class="chip chip-pista">🔍 +1</span> Pistas</p>
    <p class="hint">El ícono dice qué recurso cambia y el número, cuánto. La ficha con borde rojo es una pérdida.</p>
  </section>

  <section>
    <div class="section-head">
      <h2>Pruebas de dados</h2>
      <p>Todas las cartas de Misterio se resuelven con un D6 o dos.</p>
    </div>
    <table>
      <caption>Tipos de prueba que aparecen en las cartas</caption>
      <thead>
        <tr><th>Prueba</th><th>Cómo se lee</th><th>Ejemplo</th></tr>
      </thead>
      <tbody>
        <tr><td><strong>CARA</strong></td><td>Sale par: 2, 4 o 6.</td><td>Igual que en Pokémon TCG: cara es par, seca es impar.</td></tr>
        <tr><td><strong>SECA</strong></td><td>Sale impar: 1, 3 o 5.</td><td>El dado muestra un número impar.</td></tr>
        <tr><td><strong>1 dado, 4+</strong></td><td>El dado alcanza el número o más.</td><td>Sale 4, 5 o 6.</td></tr>
        <tr><td><strong>2 dados, 8+</strong></td><td>La suma de los dos dados alcanza el número.</td><td>5 + 3, 6 + 4.</td></tr>
        <tr><td><strong>Dobles</strong></td><td>Los dos dados muestran lo mismo.</td><td>3 y 3.</td></tr>
        <tr><td><strong>Sin 1 ni 6</strong></td><td>Ninguno de los dos dados muestra 1 ni 6.</td><td>2 y 5 sirven; 1 y 3 no.</td></tr>
      </tbody>
    </table>
    <p class="hint">Las Maniobras se juegan antes de tirar: pueden cambiar un dado, sumar al total o repetir la tirada si falla.</p>
  </section>

  <section>
    <div class="split">
      <div>
        <div class="section-head"><h2>Herramientas</h2></div>
        <p class="muted">Solo una activa: si juegan otra, la anterior va al descarte.</p>
        <table>
          <thead><tr><th>Carta</th><th>Efecto</th></tr></thead>
          <tbody>
            <tr><td>Sonar de Alta Frecuencia</td><td>Una vez por misterio, mirá la segunda carta del Mazo del Juego.</td></tr>
                        <tr><td>Generador Auxiliar</td><td>Si la Energía está en 4 o menos al empezar cada misterio, sube 1.</td></tr>
            <tr><td>Generador de Escudo</td><td>Si el Escudo está en 4 o menos al empezar cada misterio, sube 1.</td></tr>
                        <tr><td>Brazo Robótico</td><td>Si ganás Pistas y algún dado muestra 6, ganás 1 Pista más.</td></tr>
                        <tr><td>Estabilizadores</td><td>Sumá 1 al total en todas las pruebas de 2 dados.</td></tr>
          </tbody>
        </table>
      </div>
      <div>
        <div class="section-head"><h2>Maniobras</h2></div>
        <p class="muted">Se juegan antes de tirar, una vez, y van al descarte.</p>
        <table>
          <thead><tr><th>Carta</th><th>Efecto</th></tr></thead>
          <tbody>
            <tr><td>Giro Brusco</td><td>Antes de tirar: invertí el dado de Cara o Seca (Cara ↔ Seca).</td></tr>
            <tr><td>Focos Abisales</td><td>Antes de tirar: si la prueba de Cara o Seca falla, relanzá el dado una vez.</td></tr>
            <tr><td>Blindaje de Titanio</td><td>Antes de resolver: reducí 1 el daño al Escudo.</td></tr>
            <tr><td>Arpón Rastreador</td><td>Gastá 2 de Energía y tirá un dado. Si sale Cara, +1 Pista.</td></tr>
            <tr><td>Turbo de Emergencia</td><td>Antes de tirar: sumá 2 al total de la prueba.</td></tr>
            <tr><td>Suerte del Principiante</td><td>Antes de tirar: si la prueba falla, se vuelve a tirar una vez.</td></tr>
            <tr><td>Soldadura Submarina</td><td>Recuperá 1 de Escudo. Hay 4 en el mazo.</td></tr>
            <tr><td>Batería de Respaldo</td><td>Recuperá 2 de Energía. Hay 6 en el mazo.</td></tr>
            <tr><td>Análisis Rápido</td><td>Gastá 1 de Energía y ganá 1 Pista directa.</td></tr>
            <tr><td>Señuelo Luminoso</td><td>Cambiá una carta activa por otra sin resolverla.</td></tr>
            <tr><td>Lanzar Cebo</td><td>Cancelá una pérdida de Escudo en este misterio.</td></tr>
            <tr><td>Ahorro de Oxígeno</td><td>En este misterio no pierden Energía: ni por consumo, ni por cartas.</td></tr>
          </tbody>
        </table>
      </div>
    </div>
  </section>

  <section class="panel">
    <h2>Maniobras de apoyo</h2>
    <p>Dos Maniobras del equipo: <strong>Kit de emergencia</strong> (<span class="chip chip-energia">⚡ +1</span> o <span class="chip chip-escudo">🛡️ +1</span>) y <strong>Carga de emergencia</strong> (<span class="chip chip-energia">⚡ +2</span> o <span class="chip chip-escudo">🛡️ +2</span>).</p>
    <p>En <strong>Experto</strong> se mezclan en el mazo. En <strong>Normal</strong>, el Kit se busca y queda en el área de ayuda. En <strong>Asistido</strong>, las dos quedan en el área. Se usan una vez, van al descarte como cualquier Maniobra y, si están en el área de ayuda, no gastan la carta del ciclo.</p>
  </section>

  <section class="panel">
    <h2>El reloj: consumo de Energía</h2>
    <p><strong>Consumo:</strong> al terminar cada ciclo, el submarino pierde <strong>1 Energía</strong>, hayan ganado o no una Pista. La Energía es el reloj de la partida y no se recupera con las cartas de Misterio.</p>
    <p><strong>Recarga:</strong> solo con Equipo. La Batería de Respaldo devuelve 2 de Energía y hay 6 en el mazo. El Generador Auxiliar recarga 1 al empezar cada misterio si están en 4 o menos. El Generador de Escudo hace lo mismo con el casco. Ahorro de Oxígeno saltea el consumo de un ciclo.</p>
    <p><strong>Emboscadas:</strong> diez cartas de Misterio cuestan <strong>1 Energía</strong>, <strong>1 Escudo</strong> o <strong>1 Pista</strong> apenas entran a la mesa, y tienen una sola opción. Al empezar la partida, si hay más de una entre las 3 cartas iniciales, el equipo elige cuál sufrir: solo una emboscada inicial se aplica. Las cartas de Misterio nunca te sacan Energía: la Energía la baja el reloj y la recupera el Equipo.</p>
  </section>

  <section class="panel">
    <h2>Dados de la app y dados de la mesa</h2>
    <p>La app puede tirar los dados por ustedes: es cómodo cuando no hay lugar en la mesa. Pero el juego está pensado para tirar dados de verdad.</p>
    <p>Por eso, en cada prueba pueden elegir <strong>“Ya tiré en la mesa”</strong> e ingresar lo que salió en cada dado. La app aplica el resultado igual, con las mismas reglas y los mismos efectos.</p>
    <p class="muted">Trampa permitida: nadie va a revisar el dado. No es un juego competitivo: la única persona a la que le pueden hacer trampa es al equipo.</p>
  </section>

  <section>
    <div class="section-head">
      <h2>Final de la partida</h2>
    </div>
    <table>
      <thead><tr><th>Condición</th><th>Qué pasa</th></tr></thead>
      <tbody>
        <tr><td>Pistas llega a 6</td><td><strong>Victoria.</strong> Resuelven el misterio. El desenlace cambia según la Energía y el Escudo con los que lleguen.</td></tr>
        <tr><td>Energía llega a 0</td><td><strong>Derrota.</strong> Se quedan sin aire en la oscuridad.</td></tr>
        <tr><td>Escudo llega a 0</td><td><strong>Derrota.</strong> El vehículo no resiste la presión.</td></tr>
      </tbody>
    </table>
  </section>

</main>)
