Cada carta es un archivo Markdown. No hay base de datos de cartas ni paso de compilación: la app lee los archivos cada vez que empieza una partida.

## Dónde están

```
cartas/
  misterio/   01.md … 40.md   (Mazo del Juego)
  equipo/     01.md … 16.md   (Mazo de los Jugadores)
```

El número del archivo es el identificador de la carta: `cartas/misterio/07.md` es la carta `m07`. Se pueden agregar cartas nuevas hasta `60.md` (misterio) y `30.md` (equipo) sin tocar código: el motor recorre esos números y saltea los que no existen.

## Anatomía de una carta de Misterio

Primero va el bloque de mecánicas:

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
[B]
texto: Seguir el pulso en silencio
prueba: 1 dado, 4+
exito: pistas+1
fallo: energia-1, escudo-1
```

Debajo, la narrativa en Markdown normal:

```markdown
El pulso llega cada nueve segundos. Ustedes lo escuchan dos veces más antes de decidir.
```

- El bloque ` ```xp ` es la ficha técnica. **No cambies el orden de las claves ni el formato.**
- Lo que está debajo del bloque es la narrativa: Markdown normal (párrafos, **negritas**, listas). Se muestra en la carta y en la mesa.
- `familia` es `exploracion`, `peligro` o `dilema`. Define el color de la carta.
- `emoji` es el arte provisorio de la carta: se muestra grande en la mesa y en el visor. Cuando exista la ilustración definitiva, este campo desaparece y se reemplaza por la imagen.
- `entrada` es opcional: el costo que se paga cuando la carta se revela en la mesa. Ejemplos: `energia-1`, `escudo-1`, `pistas-1`. Las cartas con `entrada` son **emboscadas** y llevan una sola opción. La app aplica el costo al repartir la mesa, al reponerla al final del ciclo y al cambiarla con Señuelo Luminoso.
- Casi todas las cartas tienen **dos opciones**, `[A]` y `[B]`. Las emboscadas tienen **una sola opción**, `[A]`.
- Las letras son solo marcadores internos para separar los bloques: la app no las muestra. En la mesa se ven botones con la acción, sin numeración.
- Cada opción necesita las cuatro claves: `texto`, `prueba`, `exito`, `fallo`.

## Pruebas disponibles

| Escribí | Significa |
|---|---|
| `cara` | 1 dado. Gana si sale par (2, 4, 6). |
| `seca` | 1 dado. Gana si sale impar (1, 3, 5). |
| `1 dado, 4+` | 1 dado. Gana con 4 o más. |
| `2 dados, 8+` | 2 dados. Gana si la suma llega a 8. |
| `dobles` | 2 dados. Gana si salen iguales. |
| `sin 1 ni 6` | 2 dados. Gana si ninguno muestra 1 ni 6. |

Los números son libres: `1 dado, 3+`, `1 dado, 5+`, `2 dados, 7+`, `2 dados, 9+`. El motor detecta si la prueba usa uno o dos dados automáticamente. Una carta puede tener dos opciones con pruebas distintas: esa es la decisión de la mesa.

## Efectos disponibles

Se escriben separados por coma, con signo:

```
exito: pistas+1
fallo: energia-2, escudo-1
```

| Efecto | Qué hace |
|---|---|
| `pistas+1` / `pistas+2` | Suma Pistas (máximo 6). |
| `energia+1` / `energia+2` | Recupera Energía (máximo 6). |
| `energia-1` / `energia-2` | Gasta Energía. A 0, derrota. |
| `escudo+1` / `escudo+2` | Recupera Escudo (máximo 6). |
| `escudo-1` / `escudo-2` | Daña el Escudo. A 0, derrota. |

Las Pistas se pueden perder (`pistas-1`), pero es raro y fuerte: usalo solo en fallos o entradas muy malas. En las cartas de Misterio, la Energía no se toca: los golpes van al Escudo o a las Pistas. Si una carta no debe tener efecto, escribí `nada` o dejá el campo vacío.

## Anatomía de una carta de Equipo

```xp
id: e01
nombre: Sonar de Alta Frecuencia
emoji: 📡
tipo: herramienta
copias: 2
efecto: peek
```

Debajo, el texto de la carta (Markdown normal):

```markdown
Una vez por ciclo, mirá la carta de arriba del Mazo del Juego antes de elegir.
```

- `emoji`: arte provisorio, igual que en las cartas de Misterio.
- `tipo`: `herramienta` (queda en la mesa) o `maniobra` (se descarta).
- `copias`: cuántas veces entra esta carta en el mazo. La suma de todas las `copias` tiene que dar 44.
- `efecto`: el identificador que usa el motor.
- `valor` (solo cartas de apoyo): cuánto cura la elección (+1 o +2).

### Cartas de apoyo

`tipo: apoyo` con `valor: 1` o `2`. Al usarlas, el jugador elige **+valor Energía o +valor Escudo**. En Experto se mezclan en el mazo; en Normal una va al área de ayuda; en Asistido las dos. Las del área se usan una vez, en cualquier momento.

### Efectos que el motor ya implementa

| `efecto` | Qué hace |
|---|---|
| `peek` | Muestra la próxima carta del mazo mientras la Herramienta esté en la mesa. |
| `reroll_parity` | Antes de tirar en una prueba de Cara o Seca: si falla, relanza el dado una vez (1 vez por ciclo). |
| `energy_start` | Al empezar el ciclo, si la Energía está en 4 o menos, sube 1. |
| `reduce_damage` | Antes de tirar: reduce 1 el daño al Escudo (1 vez por ciclo). |
| `extra_clue_six` | Si ganan Pistas y un dado muestra 6, suma 1 Pista extra. |
| `harpoon` | Habilita el botón del Arpón: 2 Energía, tira 1 dado, con Cara gana 1 Pista y se descarta. |
| `plus_one_sum` | Suma 1 al total de las pruebas de 2 dados. |
| `heal_shield` | Maniobra instantánea: +2 Escudo. |
| `heal_energy` | Maniobra instantánea: +2 Energía. |
| `clue_for_energy` | Maniobra instantánea: −1 Energía, +1 Pista. |
| `discard_active` | Maniobra instantánea: cambia una carta activa por otra. |
| `plus_two` | Suma +2 al total, después de tirar. |
| `flip_parity` | Después de tirar: invierte el dado de una prueba de Cara o Seca. |
| `reroll_all` | Vuelve a tirar todos los dados. |
| `cancel_shield_loss` | Cancela una pérdida de Escudo en el ciclo. |
| `no_energy_cost` | Evita el gasto de Energía en el ciclo. |

Agregar un efecto nuevo requiere tocar `_app/game.wren` o `juego.wren`: el bloque markdown define los datos, no la lógica.

## Reglas de estilo para escribir cartas

- Español rioplatense neutro, segunda persona plural: “el equipo”, “ustedes”.
- Frases cortas. Nada de terror explícito, sangre ni violencia gráfica.
- El Megalodón se sugiere, no se muestra de frente.
- Apto para leer en voz alta a un nene de 5 años.
- Sin comillas dobles ni los caracteres `<` `>` dentro del bloque `xp`.
- Los textos de las opciones arrancan con un verbo: “Encender”, “Huir”, “Esperar”.

## Después de editar

1. Guardá el archivo.
2. Empezá una expedición nueva desde la app (`/juego` → “Nueva expedición” o “Abandonar y empezar de nuevo”).
3. Revisá el mazo completo en `/cartas` para confirmar que la carta se lee bien.

La app no cachea las cartas entre partidas. Si el archivo tiene un error de formato, la carta no aparece en el mazo y el resto sigue funcionando.
