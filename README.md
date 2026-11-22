# XP: En busca del Megalodón — prototipo web

Versión jugable en el navegador del juego de mesa cooperativo **XP (Equipo eXPedición)**, Edición 1. Sirve para probar el mazo, los contadores y las pruebas de dados antes de imprimir cartas.

- Se puede jugar solo o en equipo: un solo dispositivo, una mesa, el equipo XP contra el juego.
- La expedición busca la prueba de que el Megalodón existe: para el mundo es un mito, como el monstruo del lago Ness.
- Partidas de 10 a 20 minutos.
- 40 cartas de Misterio (una o dos opciones cada una) + 44 cartas de Equipo (incluye 2 de apoyo), todas editables como archivos Markdown.
- Arte provisorio: un emoji grande por carta, hasta que lleguen las ilustraciones.
- Tirada digital desde la app **o** carga manual de lo que salió en los dados de la mesa.
- Hecho con [Bialet](https://bialet.dev): Wren, SQLite y HTML server-rendered, sin frameworks ni build step.

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

## Rutas

| Ruta | Qué hace |
|---|---|
| `/` | Portada, pitch del juego y preparación de la mesa. |
| `/juego` | La partida: contadores, cartas activas, mano, herramientas, dados y bitácora. |
| `/reglas` | Manual de bolsillo completo. |
| `/cartas` | Las 80 cartas del mazo, leídas desde Markdown. |

El estado de la partida se guarda en SQLite y se ata a la sesión del navegador. Se puede recargar o cerrar la pestaña sin perder nada.

## Cómo se juega en la app

1. Elegís el modo (experto 5/5, casual 5/5 + 1 apoyo o fácil 6/6 + 2 apoyos) y arranca la expedición. No hay que elegir cantidad de jugadores: se juega solo o en equipo.
2. La app reparte 3 cartas de Equipo y revela **siempre 3 cartas de Misterio**, sin importar cuántos jueguen. La cantidad de jugadores no cambia nada: las decisiones son del equipo.
3. En cada ciclo: roban 2 cartas de Equipo, pueden jugar 1 carta, eligen una carta de Misterio y una de sus opciones. Al final del ciclo te quedan 3 cartas: el resto se descarta al azar, sin elección.
4. La prueba de dados se puede resolver de dos formas:
   - **Tirar en la app**: el servidor genera los D6.
   - **Ya tiré en la mesa**: elegís en pantalla lo que salió en cada dado físico.
5. Todas las Maniobras se juegan **antes** de tirar (Turbo, Giro, Focos, Suerte, Cebo, Ahorro, Blindaje): se comprometen a ciegas. Giro invierte el dado y Focos lo relanza si la prueba falla.
6. Al resolver, la app aplica los efectos de la opción y controla victoria/derrota. La prueba da exactamente lo que dice la carta: no hay tirada extra.
7. Al terminar el ciclo el submarino consume **1 Energía**, siempre. La Energía es el reloj: cada ciclo hay que decidir entre buscar Pistas o recargar.

Los contadores son los tres dados del juego: **Energía** (6 → 0, derrota), **Escudo** (6 → 0, derrota) y **Pistas** (0 → 6, victoria).

**El reloj:** cada ciclo cuesta 1 Energía. Las Baterías de Respaldo (+2, seis en el mazo), el Generador Auxiliar y Ahorro de Oxígeno son la forma de sostenerlo. Si el equipo se queda quieto, pierde; si solo recarga, el misterio no avanza.

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
fallo: energia-1
```

El pulso llega cada nueve segundos...
````

La guía completa de formato, pruebas, efectos y reglas de estilo está en [`cartas/LEEME.md`](cartas/LEEME.md).

El motor (`_app/cards.wren`) lee el bloque desde el HTML que devuelve `Markdown.file`, arma las opciones, calcula la etiqueta de la prueba y los efectos, y renderiza la narrativa como HTML seguro. **No hay caché**: cada partida nueva lee los archivos tal como están en disco.

Se pueden agregar cartas hasta `m60` y `e30` sin tocar código. La app saltea los archivos que no existen.

## Estructura

```
xp/
├── index.wren              Portada
├── juego.wren              Tablero y todas las acciones (POST/redirect/GET)
├── reglas.wren             Manual
├── cartas.wren             Visor del mazo completo
├── _migration.wren         Tablas SQLite (se aplican al arrancar)
├── _app/
│   ├── template.wren       Layout, navegación y componente de dado
│   ├── cards.wren          Parser de cartas Markdown + motor de pruebas/etiquetas
│   └── game.wren           Estado de partida, mazos, dados y efectos
├── cartas/
│   ├── LEEME.md            Cómo editar cartas
│   ├── misterio/01..40.md  40 cartas de Misterio
│   └── equipo/01..16.md    16 cartas de Equipo (40 copias)
├── css/style.css           Identidad visual del prototipo
├── BRANDING.md             Manual de marca de la franquicia XP
└── _db.sqlite3             Base de datos (se crea sola)
```

## Modelo de datos

| Tabla | Qué guarda |
|---|---|
| `games` | Una fila por partida: contadores, ciclo, fase, prueba pendiente, banderas de maniobras. |
| `game_cards` | Cada copia física del mazo con su zona: `misterio`, `equipo`, `mesa`, `mano`, `herramientas`, `descarte`. |
| `game_log` | Bitácora narrativa de la partida. |

El mazo se mezcla con `ORDER BY RANDOM()` de SQLite. Las tiradas digitales también salen de SQLite (`ABS(RANDOM()) % 6 + 1`), así que no hace falta ningún generador extra.

## Decisiones de este prototipo

- **Solo o en equipo.** El equipo comparte la mano y decide junto. También se puede jugar una sola persona. Al final del ciclo quedan 3 cartas; el resto se descarta al azar.
- **La cantidad de jugadores no cambia la mesa.** Siempre 3 cartas de Misterio, siempre 2 de robo, siempre 6 Pistas. Se puede jugar solo o en equipo.
- **Tres modos.** Experto (5 y 5), Casual (5 y 5 + 1 carta de apoyo) y Muy fácil (6 y 6 + 2 cartas de apoyo).
- **Cartas de apoyo.** Kit de emergencia (+1 Energía o +1 Escudo) y Carga de emergencia (+2 Energía o +2 Escudo). En Experto se mezclan en el mazo; en Casual el Kit va al área de ayuda; en Muy fácil van las dos. Las cartas del área se usan una vez, en cualquier momento, sin gastar la carta del ciclo.
- **Un misterio por ciclo, una carta jugada por ciclo.** La app lo hace cumplir; si intentás saltearlo, te avisa.
- **Dados físicos primero.** La app no obliga a tirar: el ingreso manual es de primera clase, no un modo oculto.
- **La mesa se repone al terminar el ciclo**, no al resolver, para que el resultado quede visible mientras se discute.
- **Nada de JavaScript.** Todo es HTML, CSS y formularios. El único movimiento es el `prefers-reduced-motion`.
- **Una o dos opciones por carta, sin A/B/C.** Se muestran como acciones; las letras quedan solo como separadores internos del Markdown. Las emboscadas muestran una sola.
- **Maniobras a ciegas.** Se juegan antes de tirar. Ver el dado y después decidir convertía cada prueba en una decisión sin riesgo.
- **Consumo fijo.** −1 Energía por ciclo: el juego se juega contra el reloj, no contra la suerte de una sola tirada.
- **Emboscadas.** Algunas cartas de Peligro (7 de las 40) cuestan 1 Energía, 1 Escudo o 1 Pista al entrar a la mesa. Tienen una sola opción. Golpean al equipo justo cuando repone la mesa.
- **La Energía es solo el reloj.** Las cartas de Misterio pegan al Escudo o a las Pistas; la Energía baja 1 por ciclo y se recupera únicamente con Batería (+2, ×6) y Generador Auxiliar. Soldadura cura 1 de Escudo (×4): parece una gran cura, pero es de las cartas trampa.

## Sobre la marca

`BRANDING.md` fija la identidad de la franquicia: paleta, logo, tipografías, sistema de cartas, iconografía, voz y tono, prompt maestro para las 80 ilustraciones y checklist de calidad. El CSS del prototipo traduce esa paleta a la pantalla.

## Próximos pasos

- Modo cooperativo con roles opcionales, si el grupo lo pide.
- Ilustraciones definitivas (una por carta) con el prompt maestro de `BRANDING.md`.
- Modo “solo dados”: tirar D6 sin partida, para probar cartas impresas.
- Balance del mazo: el motor ya registra cada tirada, así que se puede medir la tasa de éxito por prueba.
- Exportar una partida a Markdown para seguir la narrativa después de jugar.
