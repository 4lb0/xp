# XP: En busca del Megalodón — prototipo web

Versión jugable en el navegador del **LCG** de aventura y misterio **XP (Equipo eXPedición)**, Edición 1. Mazos fijos, sin sobres aleatorios. Pensado para jugar solo, o en cooperativo con amigos. Sirve para probar el mazo, los contadores y las pruebas de dados antes de imprimir cartas.

- Se puede jugar solo o en cooperativo con amigos: un solo dispositivo, una mesa, el equipo XP contra el juego.
- La expedición busca la prueba de que el Megalodón existe: para el mundo es un mito, como el monstruo del lago Ness.
- Partidas de 10 a 20 minutos.
- 40 cartas de Misterio (una o dos opciones cada una) + 44 cartas de Equipo (10 Herramientas + 34 Maniobras, 2 de ellas de apoyo), todas editables como archivos Markdown.
- Arte provisorio: un emoji grande por carta, hasta que lleguen las ilustraciones. Las cartas de Equipo suman ícono de tipo, cuándo se usan y fichas de efecto para poder jugarlas sin leer.
- Tirada digital desde la app **o** carga manual de lo que salió en los dados de la mesa.
- Hecho con [Bialet](https://bialet.dev): Wren, SQLite y HTML server-rendered, sin frameworks ni build step.

## Proxies para imprimir

`pdf/xp-proxies-bw.pdf` contiene las **84 cartas** (40 de Misterio + 44 de Equipo,
incluidas las copias) en blanco y negro, a **60 × 86 mm** —unos milímetros menos
que una carta TCG estándar—, con **9 cartas por hoja A4** y líneas de corte.
Las cartas de Equipo muestran el tipo, cuándo se usan y las fichas de efecto con
iconos para poder jugarlas sin leer. Al final agrega **3 cartas de referencia**
con dibujos: Energía, Pistas y Escudo.
Imprimilo al **100% / tamaño real**, sin “ajustar a la página”.

Para regenerarlo:

```bash
python3 -m pip install reportlab
python3 tools/make_proxies.py
```

Los iconos usan **Noto Emoji** (OFL) en `tools/fonts/`.

## Marca

El manual completo está en [`BRANDING.md`](BRANDING.md). El sistema de diseño de
la interfaz —tokens, componentes, estados y reglas de accesibilidad— está en
[`DESIGN.md`](DESIGN.md). Los archivos listos para usar viven en `img/`:

| Archivo | Uso |
|---|---|
| `assets/logo-xp-original.jpg` | Original de la insignia. Fuente para regenerar todo |
| `img/logo-xp.png` | Insignia completa, 1000 × 1000, fondo blanco |
| `img/logo-xp-mark.png` | Monograma XP, 512 × 512, transparente |
| `favicon.ico` + `img/favicon-16.png`, `img/favicon-32.png`, `img/favicon-48.png` | Favicon de la pestaña: monograma simplificado (placa negra + XP, sin órbita ni estrellas) para que se lea a 16 px |
| `img/apple-touch-icon.png`, `img/icon-192.png`, `img/icon-512.png` | Íconos de app |
| `img/og-xp.jpg` | Tarjeta social de 1200 × 630 |
| `assets/card-backs/dorso-equipo.svg` | Dorso TCG del Mazo de Equipo (azul) |
| `assets/card-backs/dorso-misterio.svg` | Dorso TCG del Mazo del Juego (borgoña) |
| `img/dorso-equipo.png`, `img/dorso-misterio.png` | Vistas previas de los dorsos |
| `img/dorso-equipo-thumb.png`, `img/dorso-misterio-thumb.png` | Miniaturas de los dorsos, 168 × 235 (2× del uso de 84 × 118) |

La cabecera usa el monograma y la portada la insignia completa. Los favicons se
cachean fuerte en los navegadores: si cambia la insignia, conviene renombrar los
archivos además de subir `Layout.assetVersion`.

> **Ojo con `/favicon.ico`:** Bialet responde esa ruta con su propio ícono e
> ignora el archivo del proyecto, así que la app declara los PNG de 16, 32 y 48
> px. El `.ico` queda en el repo para hostings estáticos. Ver `feedback.md`.

La tipografía también se autoaloja: `css/fonts/` trae **Archivo** (wght 100–900,
wdth 62–125) y **Source Sans 3** (wght 200–900) en WOFF2, en latin y latin-ext.
No hay pedidos a Google en tiempo de ejecución. Si se reemplazan los archivos,
subí `Layout.assetVersion`.

## Caché de CSS

Cloudflare cachea `/css/style.css` durante 4 horas. Al cambiar el CSS, subí
`Layout.assetVersion` en `_app/template.wren` para que el HTML pida una URL
nueva (`/css/style.css?v=…`).

## Animaciones y sonido

Las acciones siguen recargando la página. Al volver a `/juego`, el servidor
compara las zonas con el estado anterior y deja en el HTML solo los movimientos
nuevos; un módulo de JavaScript liviano (`js/game.js`) los usa para:

- resaltar las cartas que acaban de entrar en mano, mesa, herramientas o apoyo;
- en los robos, ocultar la carta destino, hacer volar el **dorso** desde el
  mazo hasta su lugar y recién ahí revelar la carta con un pequeño pop;
- en los descartes, hacer volar la carta desde la mesa/mano hasta el descarte;
- mostrar un aviso breve con cuántas cartas se robaron o descartaron.

La carta fantasma está posicionada en coordenadas del documento, no de la
ventana: si seguís el movimiento con el scroll, la animación viaja con la página.
Los robos duran unos 680 ms y los descartes 540 ms.

En una tirada, los dados grandes hacen un shake leve y cambian de cara durante
unos 300 ms antes de quedar en el resultado. Al ganar, el panel final entra con
un glow dorado; al perder, con un glow coral y un pequeño sacudón. Los sonidos
también son distintos: rattle de dados, arpegio ascendente al ganar y descenso
grave al perder.

Los dos botones de la cabecera, **Animaciones** y **Sonido**, se guardan en
`localStorage` (`xp-motion` y `xp-sound`). Si el sistema pide
`prefers-reduced-motion`, las animaciones arrancan apagadas. El sonido es
sintetizado con Web Audio: no hay archivos de audio.

**Mazos y descartes** abre un modal con las cartas que quedan en cada mazo, las
que hay en cada descarte y la lista de cartas descartadas, separadas por mazo.

## Arrancar

```bash
cd xp
bialet dev
```

Abre `http://127.0.0.1:7001`. `dev` activa live reload y muestra los errores en el navegador.

Sin live reload:

```bash
bialet .
```

Para empezar de cero, borrá `_db.sqlite3` y volvé a levantar el servidor.

## Tests

El motor (`_app/cards.wren` y `_app/game.wren`) tiene una suite en `_tests/`:

```bash
bialet -T       # todos los tests
bialet -T -q    # salida mínima para CI
```

Los tests corren sobre una base SQLite temporal: no tocan `_db.sqlite3`. Cubren
la lectura y decoración de cartas, las pruebas de dados, los efectos (Ahorro,
Cebo, Blindaje, Brazo Robótico), el robo y reciclado de mazos, la resolución de
un Misterio y el flujo HTTP completo de `/juego` (crear, elegir, tirar,
resolver y cerrar turno).

## Rutas

| Ruta | Qué hace |
|---|---|
| `/` | Portada, pitch del juego y preparación de la mesa. |
| `/juego` | La partida: contadores, cartas activas, mano, herramientas, dados y bitácora. |
| `/reglas` | Manual de bolsillo completo. |
| `/como-jugar` | Guía visual para entender el juego en pocos minutos. |
| `/cartas` | Las 84 cartas del mazo, leídas desde Markdown. |

El estado de la partida se guarda en SQLite y se ata a la sesión del navegador. Se puede recargar o cerrar la pestaña sin perder nada.

## Cómo se juega en la app

1. Elegís el modo (todos arrancan 6/6: Experto sin apoyos, Normal +1 o Asistido +2) y arranca la expedición. No hay que elegir cantidad de jugadores: se juega solo o en cooperativo con amigos.
2. La app reparte 3 cartas de Equipo y revela **siempre 3 cartas de Misterio**, sin importar cuántos jueguen. La cantidad de jugadores no cambia nada: las decisiones son del equipo.
3. En cada turno arrancan con 3 cartas de Equipo, pueden jugar 1 carta antes o después de elegir el Misterio, y resuelven una de sus opciones. Al cerrar el turno descartan toda la mano, roban 1 del Mazo del Juego y reponen la mano a 3.
4. La prueba de dados se puede resolver de dos formas:
   - **Tirar en la app**: el servidor genera los D6.
   - **Ya tiré en la mesa**: elegís en pantalla lo que salió en cada dado físico.
5. Todas las Maniobras se juegan **antes** de tirar (Turbo, Giro, Focos, Suerte, Cebo, Ahorro, Blindaje): se comprometen a ciegas. Giro invierte el dado y Focos lo relanza si la prueba falla.
6. Al resolver, la app aplica los efectos de la opción y controla victoria/derrota. La prueba da exactamente lo que dice la carta: no hay tirada extra.
7. Al terminar el turno el submarino consume **1 Energía**, siempre. La Energía es el reloj: cada turno hay que decidir entre buscar Pistas o recargar.

Los contadores son los tres dados del juego: **Energía** y **Escudo** arrancan en 6, pueden superar 6 hasta un tope de 12 y no se pierde por separado. **Pistas** arranca en 0 y con 6 se gana en el momento. La derrota llega solo si un turno termina con Energía y Escudo en 0 a la vez.

**El reloj:** cada turno cuesta 1 Energía. Las Baterías de Respaldo (+2, seis en el mazo), el Generador Auxiliar y Ahorro de Oxígeno son la forma de sostenerlo. Si el equipo se queda quieto, pierde; si solo recarga, el misterio no avanza.

## Las cartas son Markdown

Cada carta es un archivo en `cartas/` con un bloque ```` ```xp ```` de mecánicas, un emoji como arte provisorio y narrativa en Markdown debajo:

````markdown
```xp
id: m01
nombre: Señales en la oscuridad
familia: exploracion
emoji: 📡
[A]
texto: Encender el sonar
prueba: cara
exito: pistas+1
fallo: escudo-1
```

El pulso llega cada nueve segundos...
````

La guía completa de formato, pruebas, efectos y reglas de estilo está en [`cartas/LEEME.md`](cartas/LEEME.md).

El motor (`_app/cards.wren`) lee el bloque desde el HTML que devuelve `Markdown.file`, arma las opciones, calcula la etiqueta de la prueba y los efectos, y renderiza la narrativa como HTML seguro. **No hay caché**: cada partida nueva lee los archivos tal como están en disco.

Se pueden agregar cartas hasta `m60` y `e30` sin tocar código. La app saltea los archivos que no existen.

## Para quien diseña

El mazo completo vive en `cartas/`, un archivo por carta, con un bloque de mecánicas y la narrativa en Markdown. Se pueden editar a mano y la app los lee en cada partida nueva. La guía de formato está en [`cartas/LEEME.md`](cartas/LEEME.md) y el visor completo en la ruta `/cartas` de la app.

## Estructura

```
xp/
├── index.wren              Portada
├── juego.wren              Tablero y todas las acciones (POST/redirect/GET)
├── reglas.wren             Manual
├── como-jugar.wren         Guía visual
├── cartas.wren             Visor del mazo completo
├── _migration.wren         Tablas SQLite (se aplican al arrancar)
├── _app/
│   ├── template.wren       Layout, navegación y componente de dado
│   ├── cards.wren          Parser de cartas Markdown + motor de pruebas/etiquetas
│   └── game.wren           Estado de partida, mazos, dados y efectos
├── cartas/
│   ├── LEEME.md            Cómo editar cartas
│   ├── misterio/01..40.md  40 cartas de Misterio
│   └── equipo/01..19.md    19 cartas de Equipo (44 copias)
├── css/style.css           Identidad visual del prototipo
├── BRANDING.md             Manual de marca de la franquicia XP
└── _db.sqlite3             Base de datos (se crea sola)
```

## Modelo de datos

| Tabla | Qué guarda |
|---|---|
| `games` | Una fila por partida: contadores, turno, fase, prueba pendiente, banderas de maniobras. |
| `game_cards` | Cada copia física del mazo con su zona: `misterio`, `equipo`, `mesa`, `mano`, `herramientas`, `ayuda`, `descarteJuego`, `descarteEquipo`. |
| `game_log` | Bitácora narrativa de la partida. |

El mazo se mezcla con `ORDER BY RANDOM()` de SQLite. Las tiradas digitales también salen de SQLite (`ABS(RANDOM()) % 6 + 1`), así que no hace falta ningún generador extra.

## Decisiones de este prototipo

- **Solo o en cooperativo.** Podés jugar una sola persona o compartir la mano y las decisiones con amigos. Al cerrar el turno descartás toda la mano y robás 3 cartas nuevas.
- **La cantidad de jugadores no cambia la mesa.** Siempre 3 cartas de Misterio, mano de 3 y siempre 6 Pistas. Se puede jugar solo o en cooperativo con amigos.
- **Tres modos.** Todos empiezan con 6 de Energía y 6 de Escudo. Experto no tiene apoyos; Normal suma 1 Maniobra de apoyo; Asistido suma 2.
- **Maniobras de apoyo.** Kit de emergencia (+1 Energía o +1 Escudo) y Carga de emergencia (+2 Energía o +2 Escudo) son Maniobras: se usan una vez y van al descarte. En Experto se mezclan en el mazo; en Normal el Kit va al área de Apoyo; en Asistido van las dos. Las del área se usan sin gastar la carta del turno. En la app se destacan en rosa con la etiqueta **Apoyo**.
- **Una sola Herramienta activa por equipo.** Si juegan otra, la anterior va al descarte.
- **Un misterio por turno, una carta jugada por turno.** La app lo hace cumplir; si intentás saltearlo, te avisa.
- **Dados físicos primero.** La app no obliga a tirar: el ingreso manual es de primera clase, no un modo oculto.
- **La mesa se repone al terminar el turno**, no al resolver, para que el resultado quede visible mientras se discute.
- **Nada de JavaScript.** Todo es HTML, CSS y formularios. El único movimiento es el `prefers-reduced-motion`.
- **Una o dos opciones por carta, sin A/B/C.** Se muestran como acciones; las letras quedan solo como separadores internos del Markdown. Las emboscadas muestran una sola.
- **Maniobras a ciegas.** Se juegan antes de tirar. Ver el dado y después decidir convertía cada prueba en una decisión sin riesgo.
- **Consumo fijo.** −1 Energía por turno: el juego se juega contra el reloj, no contra la suerte de una sola tirada.
- **Dilemas sin Pistas.** Las 10 cartas de Dilema no otorgan ni quitan Pistas: solo mueven Energía y Escudo. Las Pistas vienen de Exploración y Peligro.
- **Emboscadas.** Diez de las 40 cartas cuestan 1 Energía, 1 Escudo o 1 Pista al entrar a la mesa. Tienen una sola opción. Golpean al equipo justo cuando repone la mesa.
- **Emboscada inicial.** Si en el reparto inicial entran varias emboscadas a la vez, no se aplican todas: el equipo elige cuál sufrir y las demás no cobran. El costo de entrada se paga una sola vez; una emboscada que ya está en la mesa no vuelve a cobrar.
- **La Energía es solo el reloj.** La Energía baja 1 por turno y se recupera con Batería (+2, ×6), Generador Auxiliar y apoyos. Energía y Escudo pueden pasar de 6, con tope 12. Soldadura cura 1 de Escudo (×4): parece una gran cura, pero es de las cartas trampa.
- **Mazos fijos (LCG).** No hay sobres aleatorios: todas las cartas del juego están en los dos mazos. Si un mazo se agota, se mezcla su descarte y se sigue robando.

## Sobre la marca

`BRANDING.md` fija la identidad de la franquicia: paleta, logo, tipografías, sistema de cartas, iconografía, voz y tono, prompt maestro para las 80 ilustraciones y checklist de calidad. El CSS del prototipo traduce esa paleta a la pantalla.

## Próximos pasos

- Roles opcionales para jugar en cooperativo, si el grupo lo pide.
- Ilustraciones definitivas (una por carta) con el prompt maestro de `BRANDING.md`.
- Modo “solo dados”: tirar D6 sin partida, para probar cartas impresas.
- Balance del mazo: el motor ya registra cada tirada, así que se puede medir la tasa de éxito por prueba.
- Exportar una partida a Markdown para seguir la narrativa después de jugar.
