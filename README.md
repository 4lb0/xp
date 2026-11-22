# XP: En busca del Megalodón — prototipo web

Versión jugable en el navegador del juego de mesa cooperativo **XP (Equipo eXPedición)**, Edición 1. Sirve para probar el mazo, los contadores y las pruebas de dados antes de imprimir cartas.

- 2 a 6 jugadores, un solo dispositivo que se pasa de mano en mano.
- Partidas de 10 a 20 minutos.
- 40 cartas de Misterio (una o dos opciones cada una) + 40 cartas de Equipo, todas editables como archivos Markdown.
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

1. Elegís cuántos jugadores son y el modo (normal 5/5 o fácil 6/6) y arranca la expedición.
2. La app reparte 3 cartas de Equipo y revela **siempre 3 cartas de Misterio**, sin importar cuántos jueguen. La cantidad de jugadores solo cambia el orden de las tiradas: las decisiones son del equipo.
3. En cada turno: roban 2 cartas de Equipo, pueden jugar 1 carta, eligen una carta de Misterio y una de sus opciones. El descarte hasta 3 se hace al final, antes de pasar el turno.
4. La prueba de dados se puede resolver de dos formas:
   - **Tirar en la app**: el servidor genera los D6.
   - **Ya tiré en la mesa**: elegís en pantalla lo que salió en cada dado físico.
5. Las Maniobras se juegan **antes** de tirar (Turbo, Giro, Suerte, Cebo, Ahorro): se comprometen a ciegas. Los Focos Abisales son la excepción de Herramienta, porque relanzan un dado ya tirado.
6. Al resolver, la app aplica los efectos y controla victoria/derrota. Si la prueba salió bien, el equipo elige entre **asegurar la Pista** o **empujar**: una tirada aparte de 2 dados (8+) por +1 Pista, con −1 Escudo si falla.
7. Al terminar el turno el submarino consume **1 Energía**, siempre. La Energía es el reloj: cada turno hay que decidir entre buscar Pistas, recargar o **reparar el casco** (1 Energía → 2 Escudo, una vez por turno).

Los contadores son los tres dados del juego: **Energía** (6 → 0, derrota), **Escudo** (6 → 0, derrota) y **Pistas** (0 → 6, victoria).

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
| `games` | Una fila por partida: contadores, turno, jugador activo, fase, prueba pendiente, banderas de maniobras. |
| `game_cards` | Cada copia física del mazo con su zona: `misterio`, `equipo`, `mesa`, `mano`, `herramientas`, `descarte`. |
| `game_log` | Bitácora narrativa de la partida. |

El mazo se mezcla con `ORDER BY RANDOM()` de SQLite. Las tiradas digitales también salen de SQLite (`ABS(RANDOM()) % 6 + 1`), así que no hace falta ningún generador extra.

## Decisiones de este prototipo

- **Mano compartida.** El GDD reparte cartas por jugador. Acá el equipo comparte una mano de 3 para que un solo dispositivo alcance y para que los más chicos participen sin gestionar su propio mazo. El turno rota igual entre jugadores.
- **La cantidad de jugadores no cambia la mesa.** Siempre 3 cartas de Misterio, siempre 2 de robo, siempre 6 Pistas. Solo cambia a quién le toca tirar.
- **Dos modos.** Normal (5 y 5) y fácil (6 y 6) para los más chicos.
- **Un misterio por turno, una carta jugada por turno.** La app lo hace cumplir; si intentás saltearlo, te avisa.
- **Dados físicos primero.** La app no obliga a tirar: el ingreso manual es de primera clase, no un modo oculto.
- **La mesa se repone al terminar el turno**, no al resolver, para que el resultado quede visible mientras se discute.
- **Nada de JavaScript.** Todo es HTML, CSS y formularios. El único movimiento es el `prefers-reduced-motion`.
- **Una o dos opciones por carta, sin A/B/C.** Se muestran como acciones; las letras quedan solo como separadores internos del Markdown. Las emboscadas muestran una sola.
- **Maniobras a ciegas.** Se juegan antes de tirar. Ver el dado y después decidir convertía cada prueba en una decisión sin riesgo.
- **Consumo fijo y empujón.** −1 Energía por turno y la opción de arriesgar una Pista extra: el juego se juega contra el reloj, no contra la suerte de una sola tirada.
- **Emboscadas.** Algunas cartas de Peligro (7 de las 40) cuestan 1 Escudo o 1 Pista al entrar a la mesa, o hacen perder un turno. Tienen una sola opción. Golpean al equipo justo cuando repone la mesa.
- **La Energía es solo el reloj.** Las cartas de Misterio pegan al Escudo o a las Pistas; la Energía baja 1 por turno y se recupera únicamente con Batería (+2, ×6) y Generador Auxiliar. Soldadura cura 3 de Escudo (×4).

## Sobre la marca

`BRANDING.md` fija la identidad de la franquicia: paleta, logo, tipografías, sistema de cartas, iconografía, voz y tono, prompt maestro para las 80 ilustraciones y checklist de calidad. El CSS del prototipo traduce esa paleta a la pantalla.

## Próximos pasos

- Repartir mano por jugador y pantalla de “pasá el dispositivo”.
- Ilustraciones definitivas (una por carta) con el prompt maestro de `BRANDING.md`.
- Modo “solo dados”: tirar D6 sin partida, para probar cartas impresas.
- Balance del mazo: el motor ya registra cada tirada, así que se puede medir la tasa de éxito por prueba.
- Exportar una partida a Markdown para seguir la narrativa después de jugar.
