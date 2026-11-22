import "_app/template" for Layout

return Layout.render(<main>
  <header class="board-head">
    <div>
      <p class="eyebrow">Manual de bolsillo</p>
      <h1>Reglas de XP</h1>
    </div>
    <p class="pill">2 a 6 jugadores · 10 a 20 minutos</p>
  </header>

  <section>
    <div class="split">
      <div>
        <h2>La idea</h2>
        <p>Son un equipo de expedición, no jugadores rivales. El submarino baja hacia una fosa sin cartografiar en busca de seis Pistas sobre el Megalodón. Nadie gana solo y nadie pierde solo.</p>
        <ul>
          <li><strong>Ganan</strong> si reúnen 6 Pistas.</li>
          <li><strong>Pierden</strong> si la Energía llega a 0 (se quedan sin aire) o el Escudo llega a 0 (el casco cede).</li>
        </ul>
        <p class="hint">En la app, el equipo comparte una sola mano y decide entre todos. Es el modo mesa compartida: el dispositivo se pasa de jugador en jugador.</p>
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
      <li><span class="num">1</span><span><strong>Repartan una carta de Equipo a cada jugador</strong>Con niños de 5 años conviene jugar con las cartas visibles y leer las opciones en voz alta.</span></li>
      <li><span class="num">2</span><span><strong>Revelen las cartas de Misterio</strong>2 jugadores: 2 cartas. 3 o 4: 3 cartas. 5 o 6: 4 cartas.</span></li>
      <li><span class="num">3</span><span><strong>Pongan los contadores</strong>Energía 6, Escudo 6, Pistas 0. La app lo hace sola y guarda la partida.</span></li>
    </ol>
  </section>

  <section>
    <div class="section-head">
      <h2>El turno, paso a paso</h2>
      <p>Juegan en sentido horario.</p>
    </div>
    <ol class="steps">
      <li><span class="num">1</span><span><strong>Robá 2 cartas de Equipo</strong>Límite de mano: 3 cartas. Si te pasás, descartá hasta quedar en 3 antes de seguir.</span></li>
      <li><span class="num">2</span><span><strong>Jugá 1 carta (opcional)</strong>Herramienta: queda en la mesa toda la partida. Máximo 4 en mesa; la quinta reemplaza a una. Maniobra: se resuelve y va al descarte.</span></li>
      <li><span class="num">3</span><span><strong>Resolvé un Misterio</strong>Elegí una carta activa, lean la situación, debatan y elijan una de sus opciones. Después viene la prueba de dados.</span></li>
      <li><span class="num">4</span><span><strong>Reponé la mesa y pasá el turno</strong>La carta resuelta va al descarte, se revela una nueva y juega la persona de la izquierda.</span></li>
    </ol>
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
    <p class="hint">Las Maniobras pueden cambiar un dado, sumar al total o repetir la tirada. Se usan después de tirar y antes de resolver.</p>
  </section>

  <section>
    <div class="split">
      <div>
        <div class="section-head"><h2>Herramientas</h2></div>
        <p class="muted">Quedan boca arriba frente al equipo. Máximo 4.</p>
        <table>
          <thead><tr><th>Carta</th><th>Efecto</th></tr></thead>
          <tbody>
            <tr><td>Sonar de Alta Frecuencia</td><td>Una vez por turno, mirá la carta de arriba del Mazo del Juego.</td></tr>
            <tr><td>Focos Abisales</td><td>Relanzá un dado en pruebas de Cara o Seca.</td></tr>
            <tr><td>Generador Auxiliar</td><td>Si la Energía está en 3 o menos al empezar el turno, sube 1.</td></tr>
            <tr><td>Blindaje de Titanio</td><td>Una vez por turno, reducí 1 el daño al Escudo.</td></tr>
            <tr><td>Brazo Robótico</td><td>Si ganás Pistas y algún dado muestra 6, ganás 1 Pista más.</td></tr>
            <tr><td>Arpón Rastreador</td><td>Gastá 2 de Energía y tirá un dado. Si sale Cara, +1 Pista y se descarta.</td></tr>
            <tr><td>Estabilizadores</td><td>Sumá 1 al total en todas las pruebas de 2 dados.</td></tr>
          </tbody>
        </table>
      </div>
      <div>
        <div class="section-head"><h2>Maniobras</h2></div>
        <p class="muted">Se usan una vez y van al descarte.</p>
        <table>
          <thead><tr><th>Carta</th><th>Efecto</th></tr></thead>
          <tbody>
            <tr><td>Giro Brusco</td><td>Antes de tirar: el dado de Cara o Seca se invierte.</td></tr>
            <tr><td>Turbo de Emergencia</td><td>Antes de tirar: sumá 2 al total de la prueba.</td></tr>
            <tr><td>Suerte del Principiante</td><td>Antes de tirar: si la prueba falla, se vuelve a tirar una vez.</td></tr>
            <tr><td>Soldadura Submarina</td><td>Recuperá 1 de Escudo.</td></tr>
            <tr><td>Batería de Respaldo</td><td>Recuperá 2 de Energía. Hay 4 en el mazo.</td></tr>
            <tr><td>Análisis Rápido</td><td>Gastá 1 de Energía y ganá 1 Pista directa.</td></tr>
            <tr><td>Señuelo Luminoso</td><td>Cambiá una carta activa por otra sin resolverla.</td></tr>
            <tr><td>Lanzar Cebo</td><td>Cancelá una pérdida de Escudo en este turno.</td></tr>
            <tr><td>Ahorro de Oxígeno</td><td>Este turno no pierden Energía: ni por consumo, ni por cartas.</td></tr>
          </tbody>
        </table>
      </div>
    </div>
  </section>

  <section class="panel">
    <h2>El reloj: consumo y empujón</h2>
    <p><strong>Consumo:</strong> al terminar cada turno, el submarino pierde <strong>1 Energía</strong>, hayan ganado o no una Pista. La Energía es el reloj de la partida: no se puede quedar quieto.</p>
    <p><strong>Recarga:</strong> la Batería de Respaldo devuelve 2 de Energía y hay 4 en el mazo. El Generador Auxiliar recarga 1 al empezar el turno si están en 3 o menos. Ahorro de Oxígeno saltea todo gasto de Energía durante un turno, incluido el consumo.</p>
    <p><strong>Empujón:</strong> cuando una prueba sale bien, el equipo elige entre asegurar la Pista o arriesgar una tirada aparte de 2 dados (8+). Si sale, +1 Pista; si falla, −2 Escudo. Nadie está obligado a empujar.</p>
    <p><strong>Emboscadas:</strong> algunas cartas de Peligro cuestan 1 Energía o 1 Escudo apenas entran a la mesa, y tienen una sola opción. No se elige cómo enfrentarlas: se resuelve la prueba y se sigue.</p>
  </section>

  <section class="panel">
    <h2>Dados de la app y dados de la mesa</h2>
    <p>La app puede tirar los dados por ustedes: es cómodo cuando no hay lugar en la mesa. Pero el juego está pensado para tirar dados de verdad.</p>
    <p>Por eso, en cada prueba pueden elegir <strong>“Ya tiré en la mesa”</strong> e ingresar lo que salió en cada dado. La app aplica el resultado igual, con las mismas reglas y los mismos efectos.</p>
    <p class="muted">Trampa permitida: nadie va a revisar el dado. Es un juego cooperativo, la única persona a la que le pueden hacer trampa es al equipo.</p>
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

  <section class="panel">
    <p class="eyebrow">Para quien diseña</p>
    <h2>Las cartas son archivos markdown</h2>
    <p>El mazo completo vive en <code>cartas/</code>, un archivo por carta, con un bloque de mecánicas y la narrativa en markdown. Se pueden editar a mano y la app los lee en cada partida nueva.</p>
    <a class="btn btn-ghost btn-small" href="/cartas">Ver el mazo completo</a>
  </section>
</main>)
