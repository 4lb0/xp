import "_app/template" for Layout

return Layout.render(<main>
  <header class="board-head">
    <div>
      <p class="eyebrow">Manual de bolsillo</p>
      <h1>Reglas de XP</h1>
    </div>
    <div class="board-meta">
      <p class="pill">Solo o en cooperativo · 10 a 20 minutos</p>
      <a class="btn btn-ghost btn-small" href="/como-jugar">Guía visual</a>
    </div>
  </header>

  <nav class="toc" aria-label="Secciones de las reglas">
    <a class="pill" href="#idea">La idea</a>
    <a class="pill" href="#preparacion">Preparación</a>
    <a class="pill" href="#turno">El turno</a>
    <a class="pill" href="#pruebas">Pruebas</a>
    <a class="pill" href="#equipo">Cartas</a>
    <a class="pill" href="#reloj">Energía</a>
    <a class="pill" href="#final">Final</a>
  </nav>

  <section id="idea">
    <div class="split">
      <div>
        <h2>La idea</h2>
        <p>Podés jugar solo o en cooperativo con amigos. El submarino baja hacia una fosa sin cartografiar en busca de seis Pistas que confirmen que el Megalodón existe. Para el resto del mundo es una leyenda, como el monstruo del lago Ness.</p>
        <p class="hint">Es un <strong>LCG</strong>: los mazos son fijos, no hay sobres aleatorios ni cartas coleccionables.</p>
        <ul>
          <li><strong>Ganan</strong> en cuanto reúnen 6 Pistas, en cualquier momento de la partida.</li>
          <li><strong>Pierden</strong> si al empezar el cierre de un turno la Energía o el Escudo están en 0.</li>
        </ul>
        <p class="hint">En la app, la mano es una sola y las decisiones se comparten. Podés jugar solo o en cooperativo con amigos: la mesa es la misma.</p>
        <p class="hint">Las cartas de Dilema no dan ni quitan Pistas: solo mueven Energía y Escudo.</p>
      </div>
      <div class="console">
        <h2>Los tres contadores</h2>
        <div class="gauges">
          <div class="gauge">{{ Layout.die(6, "die-teal") }}<span class="gauge-name">Energía</span></div>
          <div class="gauge">{{ Layout.die(6, "die-gold") }}<span class="gauge-name">Escudo</span></div>
          <div class="gauge">{{ Layout.die(0, "die-coral") }}<span class="gauge-name">Pistas</span></div>
        </div>
        <p class="hint" style="margin: 0.9rem 0 0">Arrancan en 6, 6 y 0. Ningún contador baja de 0 ni pasa de 12: la mesa se topea en los dos extremos. Las Pistas llegan a 6 y ganan.</p>
      </div>
    </div>
  </section>

  <section id="preparacion">
    <div class="section-head">
      <h2>Preparación</h2>
    </div>
    <ol class="steps">
      <li><span class="num">1</span><span><strong>Arranquen con 3 cartas de Equipo</strong>La mano es compartida. Con niños de 5 años conviene leer las opciones en voz alta.</span></li>
      <li><span class="num">2</span><span><strong>Revelen siempre 3 cartas de Misión</strong>Sin importar cuántos jueguen. La mesa no cambia: cambia a quién le toca tirar.</span></li>
      <li><span class="num">3</span><span><strong>Pongan los contadores</strong>Todos: 6 de Energía y 6 de Escudo. Pistas 0. Experto: sin apoyos. Normal: +1 Maniobra de apoyo en el área. Asistido: +2 Maniobras de apoyo.</span></li>
    </ol>
  </section>

  <section id="turno">
    <div class="section-head">
      <h2>El turno, paso a paso</h2>
      <p>Se juega un turno por vez, solo o en cooperativo.</p>
    </div>
    <ol class="steps">
      <li><span class="num">1</span><span><strong>Comienzo del turno</strong>Se resuelven las acciones que dependen del comienzo de cada Misión (Generador Auxiliar, Generador de Escudo) y roban la mano: 3 cartas de Equipo.</span></li>
      <li><span class="num">2</span><span><strong>Maniobras</strong>Juegan <strong>1 carta</strong> de la mano, o ninguna: una Herramienta (queda en la mesa, una sola activa), una Maniobra (se resuelve y va al descarte) o una Maniobra de apoyo del área (no gasta la carta del turno). Al cerrar esta fase, las cartas que quedaron en la mano van al descarte.</span></li>
      <li><span class="num">3</span><span><strong>Elijan una Misión</strong>Elegí una de las cartas de la mesa, lean la situación, debatan y elijan una de sus opciones. Después viene la prueba de dados y se aplica el resultado: suman o restan. Ningún contador baja de 0 ni pasa de 12.</span></li>
      <li><span class="num">4</span><span><strong>Cierren el turno</strong>La carta resuelta ya está en el descarte: se revela una nueva en su lugar. El submarino consume <strong>1 Energía</strong> y el turno pasa al equipo. Al empezar el próximo turno vuelven a correr los Generadores y se roba la mano.</span></li>
    </ol>
    <p class="hint">Si se agota un mazo, mezclá su descarte y seguí robando.</p>
  </section>

  <section class="panel legend">
    <p class="eyebrow">Fichas de efectos</p>
    <p><span class="chip chip-energia">{{ Layout.icon("⚡") }} +1</span> Energía · <span class="chip chip-escudo">{{ Layout.icon("🛡️") }} +2</span> Escudo · <span class="chip chip-pista">{{ Layout.icon("🔍") }} +1</span> Pistas</p>
    <p class="hint">El ícono dice qué recurso cambia y el número, cuánto. La ficha con borde rojo es una pérdida.</p>
  </section>

  <section id="pruebas">
    <div class="section-head">
      <h2>Pruebas de dados</h2>
      <p>Cara o Seca siempre se tira con un solo dado. Todas las Misiones se resuelven con un D6 o dos.</p>
    </div>
    <p><strong>Orden de una tirada:</strong></p>
    <ol class="steps">
      <li><span class="num">1</span><span><strong>Tiren</strong>En la app o con los dados de la mesa.</span></li>
      <li><span class="num">2</span><span><strong>Apliquen las sumas</strong>Turbo de Emergencia (+2 al total) y Estabilizadores (+1 en pruebas de 2 dados) se suman al resultado.</span></li>
      <li><span class="num">3</span><span><strong>Apliquen las re-tiradas</strong>Si la prueba falla, Suerte del Principiante vuelve a tirar todos los dados y Focos Abisales relanza un dado.</span></li>
      <li><span class="num">4</span><span><strong>Elijan qué dado repetir</strong>Si el efecto es de un solo dado, se quedan con uno y relanzan el otro.</span></li>
      <li><span class="num">5</span><span><strong>Vuelvan a aplicar las sumas</strong>Cada tirada nueva pasa otra vez por los efectos de sumar. Se repite hasta que no queden efectos de volver a tirar.</span></li>
    </ol>
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
    <p class="hint">Giro Brusco invierte el dado de Cara o Seca antes de las sumas. Las Maniobras de prueba se preparan antes de elegir la Misión: si la opción que eligen no es de Cara o Seca, el Giro y los Focos se pierden.</p>
  </section>

  <section id="equipo">
    <div class="split">
      <div>
        <div class="section-head"><h2>Herramientas</h2></div>
        <p class="muted">Solo una activa: si juegan otra, la anterior va al descarte.</p>
        <table>
          <thead><tr><th>Carta</th><th>Efecto</th></tr></thead>
          <tbody>
            <tr><td>Sonar de Alta Frecuencia</td><td>Una vez por Misión, mirá la carta de arriba del Mazo de Misiones con todo su contenido.</td></tr>
                        <tr><td>Generador Auxiliar</td><td>Si la Energía está en 4 o menos al empezar cada Misión, sube 1.</td></tr>
            <tr><td>Generador de Escudo</td><td>Si el Escudo está en 4 o menos al empezar cada Misión, sube 1.</td></tr>
                        <tr><td>Brazo Robótico</td><td>Si ganás Pistas y algún dado muestra 6, ganás 1 Pista más.</td></tr>
                        <tr><td>Estabilizadores</td><td>Sumá 1 al total en todas las pruebas de 2 dados.</td></tr>
          </tbody>
        </table>
      </div>
      <div>
        <div class="section-head"><h2>Maniobras</h2></div>
        <p class="muted">Se juegan antes de elegir la Misión, una vez, y van al descarte.</p>
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
            <tr><td>Lanzar Cebo</td><td>Cancelá una pérdida de Escudo en esta Misión.</td></tr>
            <tr><td>Ahorro de Oxígeno</td><td>En esta Misión no pierden Energía: ni por consumo, ni por cartas.</td></tr>
          </tbody>
        </table>
      </div>
    </div>
  </section>

  <section class="panel support-panel" id="apoyo">
    <h2>Maniobras de apoyo</h2>
    <p>Dos Maniobras del equipo: <strong>Kit de emergencia</strong> (<span class="chip chip-energia">{{ Layout.icon("⚡") }} +1</span> o <span class="chip chip-escudo">{{ Layout.icon("🛡️") }} +1</span>) y <strong>Carga de emergencia</strong> (<span class="chip chip-energia">{{ Layout.icon("⚡") }} +2</span> o <span class="chip chip-escudo">{{ Layout.icon("🛡️") }} +2</span>).</p>
    <p>En <strong>Experto</strong> se mezclan en el mazo. En <strong>Normal</strong>, el Kit se busca y queda en el área de Apoyo. En <strong>Asistido</strong>, las dos quedan en el área. Se juegan en la fase de Maniobras, una vez, y van al descarte. Si están en el área de Apoyo no gastan la carta del turno: se pueden jugar además de la carta de la mano.</p>
  </section>

  <section class="panel" id="reloj">
    <h2>El reloj: consumo de Energía</h2>
    <p><strong>Consumo:</strong> al cerrar cada turno, el submarino pierde <strong>1 Energía</strong>, hayan ganado o no una Pista. La Energía es el reloj de la partida y no se recupera con las cartas de Misión.</p>
    <p><strong>Derrota:</strong> se evalúa al principio del cierre. Si la Energía o el Escudo están en 0, la expedición termina antes del consumo y de reponer la mesa. Si el consumo deja la Energía en 0, el equipo juega un turno más para recuperarla: si no lo hace, el cierre siguiente termina la partida.</p>
    <p><strong>Recarga:</strong> solo con Equipo. La Batería de Respaldo devuelve 2 de Energía y hay 6 en el mazo. El Generador Auxiliar recarga 1 al empezar cada Misión si están en 4 o menos. El Generador de Escudo hace lo mismo con el casco. Ahorro de Oxígeno saltea el consumo de un turno.</p>
    <p><strong>Emboscadas:</strong> diez cartas de Misión cuestan <strong>1 Energía</strong>, <strong>1 Escudo</strong> o <strong>1 Pista</strong> apenas entran a la mesa, y tienen una sola opción. Si entran varias a la vez (por ejemplo, en el reparto inicial), el equipo elige cuál sufrir: solo esa se aplica y las demás no cobran. Si todas cuestan lo mismo, no hay nada que elegir: se aplica una al azar. Una emboscada que ya está en la mesa no vuelve a cobrar. Las cartas de Misión nunca te sacan Energía: la Energía la baja el reloj y la recupera el Equipo.</p>
  </section>

  <section class="panel" id="dados">
    <h2>Dados de la app y dados de la mesa</h2>
    <p>La app puede tirar los dados por ustedes: es cómodo cuando no hay lugar en la mesa. Pero el juego está pensado para tirar dados de verdad.</p>
    <p>Por eso, en cada tirada pueden elegir <strong>“Ya tiré en la mesa”</strong> e ingresar lo que salió en cada dado. La misma mesa de dados sirve para la prueba, para las re-tiradas y para las Maniobras que piden un dado. La app aplica el resultado igual, con las mismas reglas y los mismos efectos.</p>
    <p class="muted">Trampa permitida: nadie va a revisar el dado. No es un juego competitivo: la única persona a la que le pueden hacer trampa es al equipo.</p>
  </section>

  <section id="final">
    <div class="section-head">
      <h2>Final de la partida</h2>
    </div>
    <table>
      <thead><tr><th>Condición</th><th>Qué pasa</th></tr></thead>
      <tbody>
        <tr><td>Pistas llega a 6</td><td><strong>Victoria.</strong> En ese momento, en cualquier parte de la partida: no hace falta esperar al cierre.</td></tr>
        <tr><td>Energía o Escudo en 0 al empezar el cierre</td><td><strong>Derrota.</strong> Se evalúa antes del consumo y de reponer la mesa. Con cualquiera de los dos en 0, la expedición termina.</td></tr>
      </tbody>
    </table>
  </section>

</main>, "Reglas · XP")
