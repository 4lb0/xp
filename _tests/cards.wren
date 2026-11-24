// Motor de cartas: lectura del Markdown, opciones y etiquetas de prueba.
// No toca la base: todo sale de cartas/ y de las funciones puras de Card.
import "/_app/cards" for Card

// --- Lectura de los archivos ---

var m01 = Card.get("m01")
Test.assert(m01 != null, "m01 debería leerse desde cartas/misterio/01.md")
Test.assert(m01.id == "m01", "m01 conserva su id")
Test.assert(m01.name == "Señales en la oscuridad", "m01 conserva su nombre")
Test.assert(m01.family == "exploracion", "m01 conserva su familia")
Test.assert(m01.options.count == 2, "m01 debería tener dos opciones")
Test.assert(m01.options[0]["label"] == "A", "la primera opción es A")
Test.assert(m01.options[1]["label"] == "B", "la segunda opción es B")
Test.assert(m01.option("B")["texto"] == "Sintonizar el pulso exacto", "option(B) devuelve la opción B")
Test.assert(m01.option("Z")["label"] == "A", "una etiqueta desconocida cae en la primera opción")

var e12 = Card.get("e12")
Test.assert(e12 != null, "e12 debería leerse desde cartas/equipo/12.md")
Test.assert(e12.copies == 6, "e12 tiene 6 copias")
Test.assert(e12.value == 1, "el valor por defecto es 1")
Test.assert(!e12.isTool, "e12 no es Herramienta")
Test.assert(e12.isManeuver, "e12 es Maniobra")
Test.assert(!e12.isSupport, "e12 no es apoyo")

var e18 = Card.get("e18")
Test.assert(e18.isSupport, "e18 es Maniobra de apoyo")
Test.assert(e18.value == 2, "e18 cura 2")

var tool = Card.get("e01")
Test.assert(tool.isTool, "e01 es Herramienta")
Test.assert(tool.effect == "peek", "e01 tiene el efecto peek")
Test.assert(tool.options.isEmpty, "las Herramientas no tienen opciones de prueba")
Test.assert(tool.option("A") == null, "option() devuelve null sin opciones")

// --- Identificadores inválidos ---

Test.assert(Card.get(null) == null, "un id null no es una carta")
Test.assert(Card.get("m1") == null, "un id corto no es una carta")
Test.assert(Card.get("m99") == null, "una carta inexistente devuelve null")
Test.assert(Card.get("e99") == null, "una carta de equipo inexistente devuelve null")

// --- Cuándo se puede jugar cada carta ---

Test.assert(tool.playNow, "una Herramienta se juega desde la mano")
Test.assert(e18.playNow, "un apoyo se juega desde la mano")
Test.assert(Card.get("e11").playNow, "Soldadura (heal_shield) se juega desde la mano")
Test.assert(Card.get("e12").playNow, "Batería (heal_energy) se juega desde la mano")
Test.assert(Card.get("e13").playNow, "Análisis Rápido (clue_for_energy) se juega desde la mano")
Test.assert(Card.get("e14").playNow, "Señuelo (discard_active) se juega desde la mano")
Test.assert(Card.get("e06").playNow, "Arpón se juega desde la mano")

Test.assert(!Card.get("e09").playNow, "Turbo no se juega desde la mano")
Test.assert(Card.get("e09").isPrep, "Turbo se prepara antes de tirar")
Test.assert(Card.get("e10").isPrep, "Suerte se prepara antes de tirar")
Test.assert(Card.get("e15").isPrep, "Cebo se prepara antes de tirar")
Test.assert(Card.get("e16").isPrep, "Ahorro se prepara antes de tirar")
Test.assert(Card.get("e04").isPrep, "Blindaje se prepara antes de tirar")
Test.assert(!Card.get("e02").isPrep, "Focos depende de una prueba Cara o Seca, no es prep genérica")
Test.assert(!Card.get("e08").isPrep, "Giro depende de una prueba Cara o Seca, no es prep genérica")

// --- Etiquetas de las opciones ---

Test.assert(m01.options[0]["tipoPrueba"] == "cara", "cara se decora como tipo cara")
Test.assert(m01.options[0]["dados"] == 1, "cara usa un dado")
Test.assert(m01.options[0]["pruebaLabel"] == "CARA · sale par", "etiqueta de cara")
Test.assert(m01.options[0]["exitoChips"][0]["text"] == "+1", "el éxito de m01 muestra +1")

var seca = {"prueba": "seca", "exito": "pistas+1", "fallo": "escudo-1"}
Card.decorate(seca)
Test.assert(seca["tipoPrueba"] == "seca", "seca se decora como tipo seca")
Test.assert(seca["pruebaLabel"] == "SECA · sale impar", "etiqueta de seca")

var dobles = {"prueba": "dobles", "exito": "pistas+2", "fallo": "escudo-1"}
Card.decorate(dobles)
Test.assert(dobles["tipoPrueba"] == "dobles", "dobles se decora como tipo dobles")
Test.assert(dobles["dados"] == 2, "dobles usa dos dados")

var sin1 = {"prueba": "sin 1 ni 6", "exito": "pistas+1", "fallo": "escudo-1"}
Card.decorate(sin1)
Test.assert(sin1["tipoPrueba"] == "sin1", "sin 1 ni 6 se decora como tipo sin1")
Test.assert(sin1["dados"] == 2, "sin1 usa dos dados")
Test.assert(sin1["pruebaLabel"] == "2 dados · sin 1 ni 6", "etiqueta de sin1")

var suma = {"prueba": "2 dados, 8+", "exito": "pistas+1", "fallo": "escudo-1"}
Card.decorate(suma)
Test.assert(suma["tipoPrueba"] == "suma", "2 dados se decora como suma")
Test.assert(suma["objetivo"] == 8, "suma extrae el objetivo 8")
Test.assert(suma["dados"] == 2, "suma usa dos dados")
Test.assert(suma["pruebaLabel"] == "2 dados · 8+", "etiqueta de suma")

var dado = {"prueba": "1 dado, 6+", "exito": "pistas+2", "fallo": "escudo-1"}
Card.decorate(dado)
Test.assert(dado["tipoPrueba"] == "dado", "1 dado se decora como dado")
Test.assert(dado["objetivo"] == 6, "dado extrae el objetivo 6")
Test.assert(dado["dados"] == 1, "dado usa un dado")
Test.assert(dado["pruebaLabel"] == "1 dado · 6+", "etiqueta de dado")

var sinPrueba = {"exito": "pistas+1", "fallo": "escudo-1"}
Card.decorate(sinPrueba)
Test.assert(sinPrueba["tipoPrueba"] == "cara", "sin prueba se asume cara")

// --- targetOf ---

Test.assert(Card.targetOf("2 dados, 8+") == 8, "targetOf ignora lo anterior a la coma")
Test.assert(Card.targetOf("1 dado, 6+") == 6, "targetOf lee el 6")
Test.assert(Card.targetOf("9 dados, 3+") == 3, "targetOf no toma los dados como objetivo")
Test.assert(Card.targetOf("sin números") == 0, "targetOf devuelve 0 sin dígitos")

// --- Etiquetas de efectos ---

Test.assert(Card.effectsLabel("pistas+1") == "Pistas +1", "effectsLabel de pistas")
Test.assert(Card.effectsLabel("escudo-1") == "Escudo −1", "effectsLabel usa el signo menos visual")
Test.assert(Card.effectsLabel("pistas+1, escudo-1") == "Pistas +1 · Escudo −1", "effectsLabel une varios efectos")
Test.assert(Card.effectsLabel("energia+2") == "Energía +2", "effectsLabel de energía")
Test.assert(Card.effectsLabel("") == "sin efecto", "sin texto no hay efecto")
Test.assert(Card.effectsLabel(null) == "sin efecto", "null no rompe effectsLabel")

// --- Fichas de efecto ---

var chips = Card.chips("pistas+1, energia-2, escudo+1")
Test.assert(chips.count == 3, "chips separa cada efecto")
Test.assert(chips[0]["icon"] == "🔍", "pistas usa la lupa")
Test.assert(chips[0]["cls"] == "chip-pistas", "pistas usa chip-pistas")
Test.assert(chips[1]["icon"] == "⚡", "energía usa el rayo")
Test.assert(chips[1]["text"] == "−2", "energía negativa usa el signo visual")
Test.assert(chips[1]["cls"].contains("chip-loss"), "una pérdida se marca chip-loss")
Test.assert(chips[2]["cls"] == "chip-escudo", "escudo usa chip-escudo")

var vacio = Card.chips("")
Test.assert(vacio.count == 1, "sin efectos hay una ficha")
Test.assert(vacio[0]["cls"] == "chip-none", "la ficha vacía es chip-none")
Test.assert(vacio[0]["text"] == "—", "la ficha vacía muestra una raya")

var raro = Card.chips("foo+1")
Test.assert(raro[0]["icon"] == "·", "un efecto desconocido usa el punto")
Test.assert(raro[0]["cls"] == "chip-foo", "un efecto desconocido conserva su clave")

// --- Ayuda visual ---

var misterio = Card.visualFor({"id": "m01"})
Test.assert(misterio["typeIcon"] == "🌊", "un Misterio usa el ícono de ola")
Test.assert(misterio["typeLabel"] == "Misterio", "un Misterio se rotula Misterio")

var peek = Card.visualFor({"id": "e01", "tipo": "herramienta", "efecto": "peek"})
Test.assert(peek["typeIcon"] == "🔧", "una Herramienta usa la llave")
Test.assert(peek["useClass"] == "use-always", "peek es Siempre")
Test.assert(peek["useLabel"] == "Siempre", "peek se rotula Siempre")
Test.assert(peek["chips"][0]["text"] == "Próximo Misterio", "peek muestra el próximo Misterio")

var turbo = Card.visualFor({"id": "e09", "tipo": "maniobra", "efecto": "plus_two"})
Test.assert(turbo["useClass"] == "use-before", "Turbo se prepara antes de tirar")
Test.assert(turbo["chips"][0]["text"] == "+2", "Turbo muestra +2")

var bateria = Card.visualFor({"id": "e12", "tipo": "maniobra", "efecto": "heal_energy"})
Test.assert(bateria["chips"][0]["text"] == "+2", "Batería muestra +2")
Test.assert(bateria["chips"][0]["cls"] == "chip-energia", "Batería usa chip-energia")

var arpon = Card.visualFor({"id": "e06", "tipo": "maniobra", "efecto": "harpoon"})
Test.assert(arpon["chips"].count == 3, "Arpón muestra gasto, prueba y pista")

var estabilizadores = Card.visualFor({"id": "e07", "tipo": "herramienta", "efecto": "plus_one_sum"})
Test.assert(estabilizadores["useClass"] == "use-always", "Estabilizadores funcionan siempre")
Test.assert(estabilizadores["chips"][0]["cls"] == "chip-dado", "Estabilizadores suman al dado")

var apoyo = Card.visualFor({"id": "e18", "tipo": "maniobra", "subtipo": "apoyo", "efecto": "apoyo", "valor": "2"})
Test.assert(apoyo["typeIcon"] == "🎁", "un apoyo usa el regalo")
Test.assert(apoyo["typeLabel"].contains("apoyo"), "un apoyo se rotula como apoyo")
Test.assert(apoyo["chips"].count == 3, "un apoyo ofrece Energía o Escudo")
Test.assert(apoyo["chips"][0]["text"] == "+2", "el apoyo usa su valor 2")

var desconocido = Card.visualFor({"id": "e99", "tipo": "maniobra", "efecto": "desconocido"})
Test.assert(desconocido["typeLabel"] == "Maniobra · una vez", "una Maniobra se rotula como tal")
Test.assert(desconocido["chips"][0]["cls"] == "chip-none", "un efecto sin ayuda cae en chip-none")
