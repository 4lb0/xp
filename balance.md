# Balance — XP: En busca del Megalodón

Registro de ideas y decisiones de balance. Nada de esto está aplicado: cada entrada queda como propuesta hasta probarla en mesa. Los reportes de playtest siguen en `feedback.md`.

---

## 23/11/2026 — Cartas que no interactúan con Pistas (12/40)

- **Problema:** 12 de las 40 cartas del Mazo del Juego no otorgan ni quitan Pistas en ninguna opción: m04 (El pecio del Santa Elena), m18 (Persecución entre rocas) y las 10 de Dilema (m31–m40).
- **Por qué importa:** la victoria depende de juntar 6 Pistas, así que un 30% del mazo no empuja la condición de victoria. En una mesa de 6–8 turnos, salir de Exploración/Peligro corta el ritmo.
- **Contexto:** los Dilemas por regla solo mueven Energía y Escudo. m04 y m18 tampoco tocan Pistas pese a ser Exploración y Peligro.
- **Decisión:** hay que **bajar** la cantidad de cartas sin Pistas, no llevarlas a 0. Algunas tienen que quedar como cartas de respiro entre cartas que empujan la victoria.
- **Objetivo propuesto:** pasar de 12 a **6** (15% del mazo). A confirmar; 8 también sirve si la mesa necesita más respiro.
- **Camino propuesto (objetivo 6):**
  - m04 y m18 pasan a dar Pista (en una opción o en el fallo, según lo que pida la narrativa) → quedan 10.
  - 4 de los 10 Dilemas se reconvierten a Exploración/Peligro con Pista → quedan 6.
  - Los 6 Dilemas restantes siguen sin Pistas como cartas de respiro.
- **Nota de diseño:** reconvertir Dilemas implica cambiarles la `familia`, porque por regla actual los Dilemas no otorgan ni quitan Pistas. La alternativa es dejar los 10 Dilemas intactos y solo tocar m04/m18, pero eso baja apenas a 10.
- **Estado:** dirección decidida (bajar, no eliminar); número objetivo y cartas a tocar, pendientes.

---

## 23/11/2026 — Generadores automáticos demasiado fuertes (e03 y e19)

- **Cartas:** Generador Auxiliar (e03, `energy_start`) y Generador de Escudo (e19, `shield_start`).
- **Actual:** cada una tiene 2 copias y al empezar el turno suma +1 si el recurso está en 4 o menos (ver `juego.wren:374–381`).
- **Problema:** con dos copias de cada uno, la mesa puede encadenar recuperación automática casi todos los turnos. Son herramientas que no gastan la carta del turno ni requieren decisión: el jugador no elige cuándo usarlas, así que se vuelven un piso de recursos demasiado alto.
- **Propuesta:** una sola copia de cada uno (`copias: 1`) y bajar el umbral de 4 a 2 (sumar solo cuando el recurso está en 2 o menos).
- **Efecto esperado:** los generadores pasan de sostener la partida a rescatar de una situación crítica. Quedan relevantes, pero dejan de compensar el desgaste normal.
- **Ojo con el mazo:** hoy las `copias` del Mazo de Equipo suman 44 (regla en `cartas/LEEME.md`). Sacar una copia de cada generador deja el mazo en 40: hay que decidir dónde van esas 4 copias antes de aplicar el cambio.
- **Estado:** idea, sin decidir.

---

## 23/11/2026 — Giro Brusco pasa a “ganar una Cara o Seca” (e08)

- **Texto actual:** “Prepará el giro antes de tirar. En una prueba de Cara o Seca, el dado se invierte (Cara ↔ Seca).”
- **Cómo funciona hoy:** `flip_parity` marca `giro = 1` y, al tirar, el motor hace `d1 = 7 - d1` (`juego.wren:168` y `186`). Cambia la cara del dado, no el tipo de prueba.
- **Problema 1 (regla):** no hace ganar el tiro: invierte el resultado. Un 2 en prueba de Cara pasa a 5 (falla) y un 3 pasa a 4 (gana). Como la Maniobra se juega a ciegas, antes de tirar, la probabilidad queda igual (3 caras ganan antes y 3 después): hoy la carta no hace nada.
- **Problema 2 (texto):** el imperativo “Prepará el giro...” suena a efecto obligatorio y a que mejora el tiro. Falta el “podés” y falta aclarar el alcance.
- **Decisión:** reemplazar el efecto por uno que **garantice ganar la próxima prueba de Cara o Seca**, con **una sola copia**.
- **Contexto:** hay **21 opciones de Cara/Seca en 20 de las 40 cartas** (la mitad del Mazo del Juego). El poder es alto por uso, pero con 1 copia entre 44 cartas del Mazo de Equipo la frecuencia lo acota.
- **Wording propuesto (recomendado):**
  > Podés jugarla antes de tirar: en una prueba de Cara o Seca, el resultado se resuelve a tu favor.
- **Alternativas:**
  - “Podés jugarla antes de tirar en una prueba de Cara o Seca. Esa prueba se gana.”
  - “Antes de tirar, elegí una prueba de Cara o Seca: se resuelve como ganada.”
- **Nombre:** “Giro Brusco” puede quedar; el giro ahora es narrativo y el resultado se resuelve a favor.
- **Implementación pendiente:**
  - Nuevo efecto (por ejemplo `auto_win_parity`): al jugarla antes de tirar, resolver la prueba como ganada; avisar si la prueba no es de Cara o Seca.
  - Bajar `copias` de 2 a 1 y sumar 1 copia en otra carta para mantener el Mazo de Equipo en 44.
- **Estado:** dirección y wording decididos; falta aplicar la carta y el motor.

---

## Notas sueltas

- `shield_start` (e19) no aparece en la tabla de efectos de `cartas/LEEME.md`; la tabla solo documenta `energy_start`.
- Focos Abisales (e02) también usa imperativo (“Prepará los focos...”), pero su efecto sí hace algo: si la prueba falla, relanza el dado.
