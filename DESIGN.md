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
| `--line` | `rgba(51,187,204,.18)` | — | Bordes y separadores |
| `--card` | `rgba(11,34,57,.86)` | — | Superficie de carta |

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
| `--radius` | 16px — paneles y cartas |
| `--radius-sm` | 10px — fichas, mini-cartas, inputs |
| `--shadow` | `0 18px 40px rgba(0,0,0,.35)` |
| Duración de hover | 150ms |
| Robo de carta | 680ms (dorso → revelado) |
| Descarte | 540ms |
| Dados | 300ms de shake antes del resultado |

`prefers-reduced-motion` y el toggle **Animaciones** apagan todo esto
(`[data-motion="off"]`). El sonido tiene su propio toggle.

---

## 3. Componentes

### Cabecera y navegación

`.site-header` sticky, fondo `rgba(7,26,46,.7)` con blur, borde inferior
`--line`. Cinco rutas: Inicio, Expedición, Guía, Reglas, Cartas. La ruta activa
lleva `class="active"` **y** `aria-current="page"`; el resto `aria-current="false"`.

En `/juego` la cabecera se oculta y la navegación vive en el rail.

### Botones

| Clase | Uso | Color |
|---|---|---|
| `.btn-primary` | Acción principal de la pantalla | Fondo `--gold`, texto `#3A2A06` |
| `.btn-ghost` | Acción secundaria | Borde `--line`, texto `--paper` |
| `.btn-small` | Acciones dentro de cartas | Igual, padding menor |
| `.pill` / `.pill-btn` | Metadatos y abrir el diálogo de mazos | Borde `--line`, texto `--muted` |

Una sola acción primaria por zona. En táctil, todos los botones, pills y
toggles miden 44 px de alto mínimo.

### Cartas

Estructura: franja de familia → ilustración (emoji provisorio) → familia + ID →
título → texto → opciones o acciones.

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

### Paneles

`.panel` base; `.test-panel` (prueba en curso), `.result-panel` (resultado),
`.push-panel` (empujón), `.ambush-choice` (emboscada), `.support-choice`
(apoyo), `.help-zone` (apoyo en mesa), `.quick-*` para la guía.

Cada panel de estado abre con `.eyebrow` en versalitas y un `h2` que dice qué
está pasando. El resultado de una prueba es `role="status"` y recibe foco al
cargar.

### Bitácora

`.log` con hora corta local (`19:43`), `datetime` completo y el texto en
segunda persona. Nunca timestamps crudos.

### Rail de la expedición

- **≥1000px**: columna fija de 190px a la derecha, con los tres contadores, el
  turno y los accesos.
- **<1000px**: deja de flotar. Pasa a ser una grilla 3×2 sobre la mesa, con
  etiquetas cortas (`.rail-label-short`) y targets de 44px. Los contadores se
  muestran una sola vez, en `.gauges-board`.

### Diálogo de mazos

`<dialog>` nativo, `aria-labelledby`. Cada mazo lleva el campo de su dorso:
borgoña para el Juego, azul para el Equipo. Las miniaturas son de 168×235
(2× del uso), no los PNG de 900×1260.

### Contadores (HUD)

`.gauges-board` es una grilla de tres columnas **también en móvil**: apilados
empujaban la acción fuera de pantalla. En pantallas de menos de 380px el dado
se achica y el contador pasa a vertical.

---

## 4. Estados

| Estado | Regla |
|---|---|
| Sin partida | Formulario de inicio con modo preseleccionado y enlace a reglas |
| Mesa vacía | Texto que explica cómo reponerla, nunca un espacio en blanco |
| Carta bloqueada | `.is-locked` (55 % de opacidad) + texto de por qué |
| Resultado | `role="status"`, foco en el `h2`, dados visibles y fichas del efecto |
| Victoria | `.ending.victoria`: glow dorado, dados reales del final |
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
| Dorsos | `img/dorso-equipo.png`, `dorso-misterio.png` | 900×1260 para cualquier uso grande |
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
