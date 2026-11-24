# XP — Sistema de diseño de la app

Este documento describe **cómo se ve y cómo se construye la interfaz** de la app
de XP. El manual de marca (`BRANDING.md`) define la identidad; acá está la
traducción a pantalla: tokens, componentes, estados y las reglas que no se
negocian.

Es un documento vivo: si un token cambia en `css/style.css`, cambia acá. La
paleta de imprenta y sus cuaternas CMYK viven en `BRANDING.md` §5; este archivo
las repite sólo para tenerlas a mano.

---

## 1. Principios

1. **Es una mesa, no un tablero de control.** Los contadores se leen como dados,
   las cartas se leen como cartas. Un panel nuevo se justifica si ayuda a jugar,
   no si muestra datos.
2. **Nadie queda afuera.** Texto grande, contraste alto, targets táctiles de
   44 px y ningún dato que dependa sólo del color: cada familia suma ícono,
   franja y palabra.
3. **Todo se puede imprimir.** Cada color de la edición tiene cuaterna CMYK de
   proceso. Si un color de pantalla no se puede imprimir, no entra.
4. **La ficción manda el tono.** Rioplatense, segunda persona, expedición. Nada
   de "usuario", "recurso" o "ítem" cuando se puede decir equipo, Pista o
   Escudo.
5. **Sin frameworks ni build.** HTML server-rendered, un CSS, un JS liviano.
   Si algo necesita un paso de compilación, no va.

---

## 2. Tokens

Viven en `css/style.css`, bloque `:root`. **Usá siempre el token**, nunca el HEX:
los reemplazos globales y la imprenta dependen de eso.

### Color

| Token | HEX | CMYK | Rol |
|---|---|---|---|
| `--abyss` | `#071A2E` | 89/73/33/63 | Fondo de la app |
| `--deep` | `#0B2239` | 91/71/28/57 | Superficies, dorso de Equipo |
| `--navy` | `#14547F` | 91/55/11/17 | Controles, degradados |
| `--navy-2` | `#1A6396` | 88/50/6/8 | Degradados, hover |
| `--burgundy` | `#4A1B24` | 36/87/60/56 | Dorso del Juego, aire de misterio |
| `--teal` | `#1B6B72` | 85/30/38/21 | Petróleo, acentos de ambiente |
| `--turquoise` | `#0FA8A2` | 75/5/35/2 | Exploración, highlights |
| `--turquoise-soft` | `#A5D7D2` | 33/1/14/0 | Texto de apoyo en turquesa |
| `--cyan` | `#33BBCC` | 66/1/14/0 | Maniobras, enlaces, foco |
| `--cyan-soft` | `#9BD7E1` | 35/1/7/0 | Texto de apoyo en cian |
| `--gold` | `#F2B33D` | 1/29/87/2 | Faro: acción principal, Herramientas |
| `--gold-soft` | `#F5DA8C` | 4/11/50/0 | Latón: texto y detalles |
| `--coral` | `#E06550` | 2/71/69/1 | Peligro, pérdidas |
| `--coral-soft` | `#F0BEB4` | 2/27/19/0 | Texto de apoyo en coral |
| `--green` | `#12A05F` | 79/3/80/3 | Dilema, victoria |
| `--support` | `#C02F70` | 7/92/12/8 | Apoyo (Anémona) |
| `--support-soft` | `#F0CDD7` | 4/21/3/0 | Texto de apoyo, títulos de zona |
| `--paper` | `#F4F1EA` | 4/4/5/0 | Texto principal, Espuma |
| `--paper-soft` | `#D9D5CC` | 13/11/14/0 | Texto corrido sobre superficies |
| `--muted` | `#8FA6B3` | 43/23/16/0 | Metadatos, texto secundario |
| `--ink` | `#0A0A0A` | K100 | Placas e íconos |
| `--bone-soft` | `#B9C2C6` | — | Texto corrido atenuado |
| `--line` | `rgba(244,241,234,.16)` | — | Filetes y separadores |
| `--line-strong` | `rgba(244,241,234,.34)` | — | Filetes de estructura |
| `--card` | `rgba(11,34,57,.6)` | — | Superficie de carta |
| `--panel` | `rgba(11,34,57,.5)` | — | Paneles y placas |

Reglas de color:

- **Anémona no va como texto chico** (3,6:1). Va como fondo, borde o etiqueta
  con Espuma encima. Para texto, `--support-soft`.
- Los acentos de familia usados como texto sobre Abismo dan 5:1 o más.
- El dorado nunca va como texto pequeño sobre cian ni sobre turquesa.
- Los fondos profundos no pasan de 260 % de TAC.

### Tipografía

| Token | Familia | Uso |
|---|---|---|
| `--font-display` | Archivo (variable 100–900 / 62–125) | Títulos, cifras, botones |
| `--font-body` | Source Sans 3 (variable 200–900) | Todo el texto corrido |

Autoalojadas en `css/fonts/` (WOFF2, latin y latin-ext). Sin pedidos a Google.

| Nivel | Regla | Tamaño |
|---|---|---|
| h1 | Archivo 900, ancho 112 % | `clamp(2.05rem, 5vw, 3.3rem)` |
| h2 | Archivo 900, ancho 106 % | `clamp(1.4rem, 3vw, 1.9rem)` |
| h3 | Archivo 800, ancho 108 % | 1.12rem |
| Cuerpo | Source Sans 3 400 | 1rem / 1.5 |
| Texto de carta | Source Sans 3 400 | 0.92rem |
| Familia de carta | Source Sans 3 700, versalitas +14 % | 0.72rem |
| ID de carta | Source Sans 3 600, tabular | 0.72rem, 72 % opacidad |
| Etiqueta de zona | Source Sans 3 700, versalitas | 0.66–0.72rem |

Cifras y contadores: Archivo 800 con `font-variant-numeric: tabular-nums`.
Máximo dos pesos por carta. Sin sombras de texto ni tracking negativo.

### Forma y movimiento

| Token | Valor |
|---|---|
| `--radius` | 3px — todo: paneles, cartas, botones, fichas |
| `--radius-sm` | 2px — sellos y etiquetas |
| Sombra | fuera de la mesa, sólo los dados. En la mesa, las cartas y las pilas proyectan sombra de contacto (ver §3, Mesa) |
| Grano | `body::before`, ruido SVG al 5 % sobre el campo plano |
| Duración de hover | 150ms |
| Robo de carta | 680ms (dorso → revelado) |
| Descarte | 540ms |
| Dados | 300ms de shake antes del resultado |

`prefers-reduced-motion` y el toggle **Animaciones** apagan todo esto
(`[data-motion="off"]`). El sonido tiene su propio toggle.

---

## 3. Componentes

### Cabecera y navegación

`.site-header` sticky, **campo plano** (sin blur ni transparencia), borde inferior
`--line`. Cinco rutas: Inicio, Expedición, Guía, Reglas, Cartas, en versalitas
con `letter-spacing`, sin píldoras: la ruta activa lleva subrayado dorado de 2px,
`class="active"` **y** `aria-current="page"`.

En `/juego` la cabecera del sitio se oculta. La mesa tiene su propia placa
(`.board-head`) con el nombre de la expedición, el modo, los accesos a Reglas e
Inicio y los dos toggles. En móvil los accesos viven en el rail inferior.

### Etiquetas

No hay *eyebrow* de landing. `.eyebrow` es un **sello de documento**: una
etiqueta con filete y versalitas que nombra el panel o la sección, igual que un
campo de formulario impreso. Nunca flota como kicker arriba de un título.

### Botones

| Clase | Uso | Color |
|---|---|---|
| `.btn-primary` | Acción principal de la pantalla | Fondo `--gold`, texto `#3A2A06`, filete de tinta |
| `.btn-ghost` | Acción secundaria | Borde `--line-strong`, texto `--paper` |
| `.btn-small` | Acciones dentro de cartas | Igual, padding menor |
| `.pill` / `.pill-btn` | Metadatos y abrir el diálogo de mazos | Borde `--line`, texto `--muted` |

Una sola acción primaria por zona. En táctil, todos los botones, pills y
toggles miden 44 px de alto mínimo.

### Mesa

La partida **no es una página con secciones: es una mesa con objetos**. Todo lo
de `/juego` vive dentro de `.felt`, una superficie con luz desde arriba
(degradados radiales), viñeta y un filete claro en el borde superior. Adentro,
las zonas tienen lugar fijo y no se reacomodan:

| Zona | Contenido | Regla |
|---|---|---|
| `.zone-encounter` | 3 Misiones + pilas | Arriba de todo; siempre 3 lugares, ocupados o no |
| `.zone-own` | Herramienta y Maniobra del turno | Arriba, junto a las Misiones; la Maniobra queda hasta resolver |
| `.felt-top` | Contadores, fase y turno | En el medio, como banda; en móvil los contadores pasan al rail |
| `.zone-hand` | Mano | Abajo; se mantiene entre turnos: robás 1 y descartás hasta 3 |

**Orden de la mesa.** De arriba abajo: las cartas de Misión (son del juego, se
comparten), tu Herramienta y la Maniobra del turno, tu estado, la bandeja de
resolución y tu mano. La Maniobra del turno se queda a la vista hasta que la
Misión se resuelve, para no perder de vista el efecto; recién ahí va al
descarte. El estado va en el medio porque en papel es el centro de la mesa; en
pantalla se maneja solo y en móvil vive en el rail.

- **Geometría fija.** Cada carta tiene `aspect-ratio: 63/88` (la proporción de
  impresión) y no crece con su texto. La única pieza que cede espacio es
  `.card-text`; nada más se comprime.
- **Lugares vacíos.** Una Misión resuelta deja su lugar: `.card-slot` con
  borde punteado y el rótulo del lugar. Nunca se colapsa la grilla.
- **Pilas a la vista.** Los dos mazos y los dos descartes se dibujan como
  objetos (`.pile`, dorso real, canto de varias cartas con `box-shadow` y
  contador en placa). La pila abre el diálogo de mazos: no hay un botón
  escondido en la cabecera.
- **Bandejas.** Los estados de resolución (`.tray`) aparecen sobre la mesa, con
  el dado a la derecha y las acciones abajo. Las cartas siguen en su lugar
  mientras se resuelve una prueba; la que está en juego lleva `.is-pending`.
- **Bitácora plegada.** `.log-box` es un `<details>` de una línea con la última
  entrada. El registro completo se abre a demanda.

### Cartas

Anatomía, de arriba abajo: franja de familia → ilustración (emoji provisorio)
→ línea de tipo con familia e ID → título → caja de texto → opciones o acciones.

La carta es un **objeto físico**: radio de 7px, filete de 1px, degradado
vertical apenas visible, sombra de contacto y una luz interna en el borde
superior. La ilustración ocupa el 30 % de la altura y lleva la trama de agua. La
caja de texto tiene fondo propio, filete y una trama de imprenta al 2 %: cuando
la carta tiene poco texto, el espacio libre se lee como caja y no como hueco.

La franja de color lleva la trama de la familia y no se rellena con halos. En
pantallas de menos de 900px la carta pierde la proporción fija, se limita a
470px de ancho y la ilustración pasa a 16:9 para que el texto se lea.

| Familia | Franja (§5) | Color |
|---|---|---|
| Exploración | Onda | `--turquoise` |
| Peligro | Dentada | `--coral` |
| Dilema | Doble | `--green` |
| Herramientas | Sólida gruesa (6px) | `--gold` |
| Maniobras | Fina (2px) | `--cyan` |
| Apoyo | Punteada | `--support` |

La franja se dibuja con `::before` sobre `.card` y `.mini-card`; las variantes
de trama usan máscaras SVG para la onda y la dentada. **No se agrega una familia
sin su trama.**

### Fichas de efecto

`.chip` para costos y beneficios (⚡ Energía, 🛡️ Escudo, 🔍 Pistas, 🎲 dados).
Cada ficha tiene su modificador de color y su `title`/`aria-label`. Los textos
largos van en `.chip-label`, en versalitas y `--muted`.

### Dados

`.die` con `data-value` (0–6). Variantes `.die-teal` (Energía), `.die-gold`
(Escudo), `.die-coral` (Pistas), `.die-large` (tirada). Los pips son
`aria-hidden`; el valor siempre se acompaña de texto.

Los contadores que pueden pasar de 6 muestran la cifra dibujada dentro de la
cara (7–12) y la cifra real al lado: el dado nunca miente. El tope es 12.

### Bandejas de resolución

`.tray` es la bandeja de estado: prueba, tirada fallida, resultado, apoyo.
Grilla de dos columnas (contenido + dado) y una fila de acciones a lo ancho; en
móvil se apila. La emboscada inicial no usa bandeja: se elige sobre la misma
carta de la mesa, con el botón `.ambush-action` que sólo aparece en esa fase.

La bandeja no repite el sello de fase: eso vive en `.felt-prompt`, la línea que
dice qué hay que hacer ahora. El resultado de una prueba es `role="status"` y
recibe foco al cargar.

### Bitácora

`.log-box` plegado con la última entrada a la vista. Adentro, `.log` con hora
corta local (`19:43`), `datetime` completo y el texto en segunda persona. Nunca
timestamps crudos.

### Rail de la expedición

- **≥1000px**: no se muestra. Los contadores están en la mesa y los accesos en
  la placa de la mesa.
- **<1000px**: barra fija abajo, con los tres contadores y los accesos, con
  etiquetas cortas (`.rail-label-short`) y targets de 44px. Los contadores de la
  mesa se ocultan para no duplicar el dato.

### Diálogo de mazos

`<dialog>` nativo, `aria-labelledby`. Cada mazo lleva el campo de su dorso:
borgoña para el Juego, azul para el Equipo. Las miniaturas son de 168×235
(2× del uso), no los PNG de 900×1260.

### Contadores (HUD)

`.gauges-board` vive en `.felt-top`, como tres dados apoyados en la mesa: dado
de 2,5rem, rótulo en versalitas y cifra. En móvil no se muestran acá: el dato
está en el rail inferior.

---

## 4. Estados

| Estado | Regla |
|---|---|
| Sin partida | Formulario de inicio con modo preseleccionado y enlace a reglas |
| Mesa vacía | Texto que explica cómo reponerla, nunca un espacio en blanco |
| Lugar vacío | `.card-slot` punteado con el ícono y el nombre del lugar |
| Carta bloqueada | `.is-locked` (62 % de opacidad, desaturada) + texto de por qué |
| Carta en juego | `.is-pending`: filete y halo dorado, la carta no sale de la mesa |
| Carta jugable | `.is-actionable`: se levanta 5px al pasar el puntero o al enfocar |
| Resultado | `role="status"`, foco en el `h2`, dados visibles y fichas del efecto |
| Victoria | `.ending.victoria`: glow dorado, fuegos suaves detrás del contenido, dados reales del final |
| Derrota | `.ending.derrota`: glow coral, dados reales del final |
| Movimiento nuevo | `.is-new` (outline dorado) o animación de dorso |

Todo estado vacío se escribe. No hay placeholders del tipo "Sin datos".

---

## 5. Accesibilidad

- Contraste mínimo 4.5:1 para texto; 3:1 para texto grande y bordes de foco.
- Targets táctiles de 44×44 px en `@media (pointer: coarse)`.
- Foco visible siempre; el anillo usa `--cyan`.
- `aria-live` en avisos, resultados y toast de movimientos.
- Los emojis decorativos van `aria-hidden`; el dato va en texto.
- Los dados exponen el número, no la cara.
- El movimiento y el sonido se pueden apagar y la preferencia persiste.

---

## 6. Assets

| Recurso | Archivo | Regla |
|---|---|---|
| Insignia completa | `img/logo-xp.png` | Placa blanca, sólo sobre fondo oscuro |
| Monograma | `img/logo-xp-mark.png` | Placa negra, cabecera y pie |
| Favicon / app | `img/favicon-16.png`, `favicon-32.png`, `favicon-48.png`, `favicon.ico` | **Versión simplificada**: placa negra + XP, sin órbita ni estrellas |
| Íconos de app | `img/apple-touch-icon.png`, `icon-192.png`, `icon-512.png` | Mismo ícono simplificado |
| Dorsos | `img/dorso-equipo.png`, `dorso-mision.png` | 900×1260 para cualquier uso grande |
| Miniaturas | `img/dorso-*-thumb.png` | 168×235, para diálogo y animación |
| Fuentes | `css/fonts/*.woff2` | Archivo y Source Sans 3 variables |

Regla de placas: **negativo sobre oscuro, positivo sobre claro**. No hay una
tercera variante.

Al cambiar cualquier asset cacheado, subir `Layout.assetVersion` en
`_app/template.wren` (Cloudflare cachea el CSS 4 horas).

---

## 7. Imprenta

La app es el prototipo de un juego que se imprime. Por eso:

- Todo color sale de los tokens, y todo token tiene cuaterna CMYK.
- Los archivos `-print.png` van a 300 dpi con el tamaño físico correcto
  (63,5 × 88,9 mm) y sangrado de 2 mm.
- Los proxies en blanco y negro se regeneran con `python3 tools/make_proxies.py`.
- Ninguna pieza final depende de un degradado, una sombra o una transparencia
  para leerse.

---

## 8. Deuda conocida

- **Iconografía mixta**: la guía visual usa SVG de línea y el resto de la app
  usa emoji. Los emojis de ilustración son provisorios hasta que lleguen las
  cartas ilustradas; los íconos de interfaz deberían converger a SVG.
- **Ícono de familia**: §5 pide ícono además de franja y palabra. Hoy hay
  franja y palabra; falta el set de seis íconos.
- **Logo vectorial**: la insignia es PNG de 1000px. Falta el SVG.
- **MIME de fuentes**: los `.woff2` se sirven como `application/octet-stream`;
  conviene `font/woff2` desde el servidor.
