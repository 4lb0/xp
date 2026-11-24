// Motor de cartas: cada carta es un .md en cartas/ con un bloque ```xp
// de mecánicas y narrativa en markdown. Ver cartas/LEEME.md.
class Card {
  construct new(meta, body, options) {
    _id = meta["id"]
    _name = meta["nombre"] || "Carta sin nombre"
    _family = meta["familia"] || meta["tipo"] || "exploracion"
    _type = meta["tipo"] || ""
    _subtype = meta["subtipo"] || ""
    _copies = Num.fromString(meta["copias"] || "1")
    _value = Num.fromString(meta["valor"] || "1")
    _effect = meta["efecto"] || ""
    _emoji = meta["emoji"] || "🫧"
    _entry = meta["entrada"] || ""
    _entryLabel = meta["entradaLabel"] || ""
    _entryChips = meta["entradaChips"] || []
    _body = body
    _options = options
    _visual = Card.visualFor(meta)
  }

  id { _id }
  name { _name }
  family { _family }
  type { _type }
  subtype { _subtype }
  copies { _copies }
  value { _value }
  effect { _effect }
  emoji { _emoji }
  entry { _entry }
  entryLabel { _entryLabel }
  entryChips { _entryChips }
  body { _body }
  options { _options }

  // Ayuda visual de las cartas de Equipo. Sale del efecto, así que editar
  // el Markdown de la carta no obliga a repetir los iconos.
  typeIcon { _visual["typeIcon"] }
  typeLabel { _visual["typeLabel"] }
  typeHint { _visual["typeHint"] }
  useIcon { _visual["useIcon"] }
  useLabel { _visual["useLabel"] }
  useHint { _visual["useHint"] }
  useClass { _visual["useClass"] }
  helpChips { _visual["chips"] }

  option(label) {
    for (o in _options) {
      if (o["label"] == label) return o
    }
    return _options.isEmpty ? null : _options[0]
  }

  isTool { _type == "herramienta" }
  isManeuver { _type == "maniobra" }
  isSupport { _type == "apoyo" || _subtype == "apoyo" }

  // Las cartas que se resuelven en el momento se pueden jugar desde la mano.
  // Las demás (Turbo, Giro, Focos, Suerte, Blindaje...) se preparan en la
  // pantalla de la prueba, siempre antes de tirar.
  playNow {
    return isTool || isSupport || ["heal_shield", "heal_energy", "clue_for_energy", "harpoon", "discard_active"].contains(_effect)
  }

  // Maniobras genéricas que se pueden preparar desde la mano, antes de
  // elegir el Misterio. El efecto queda armado para la próxima prueba.
  isPrep {
    return ["plus_two", "reroll_all", "cancel_shield_loss", "no_energy_cost", "reduce_damage"].contains(_effect)
  }

  static get(id) {
    if (id == null || id.count < 3) return null
    var kind = id[0] == "m" ? "misterio" : "equipo"
    var path = "cartas/" + kind + "/" + id[1..2] + ".md"
    var html = Markdown.file(path)
    if (html == false) return null
    var raw = html.toString
    var parts = raw.split("<pre><code>")
    if (parts.count < 2) return null
    var chunks = parts[1].split("</code></pre>")
    if (chunks.count < 2) return null
    var metaRaw = chunks[0]
    var body = chunks[1].raw
    var meta = {}
    var opts = []
    var cur = null
    for (line in metaRaw.split("\n")) {
      var t = line.trim
      if (t == "") continue
      if (t[0] == "[") {
        var lb = t.split("[")[1].split("]")[0]
        cur = {"label": lb}
        opts.add(cur)
      } else {
        var kv = t.split(":")
        if (kv.count >= 2) {
          var k = kv[0].trim
          var v = kv[1..kv.count - 1].join(":").trim
          if (cur != null) {
            cur[k] = v
          } else {
            meta[k] = v
          }
        }
      }
    }
    meta["id"] = id
    meta["entradaLabel"] = meta["entrada"] == null ? "" : Card.effectsLabel(meta["entrada"])
    meta["entradaChips"] = Card.chips(meta["entrada"] || "")
    for (o in opts) Card.decorate(o)
    return Card.new(meta, body, opts)
  }

  static hchip(icon, text, cls, title) {
    return {"icon": icon, "text": text, "cls": cls, "title": title}
  }

  // Traduce el identificador de efecto a la ayuda visual que ve la mesa:
  // qué tipo de carta es, cuándo se juega y qué hace, con iconos y cifras.
  // Un nene de 5 años tiene que poder usarla sin leer el texto.
  static visualFor(meta) {
    var effect = meta["efecto"] || ""
    var value = Num.fromString(meta["valor"] || "1")
    var isSupport = meta["subtipo"] == "apoyo" || meta["tipo"] == "apoyo"
    var isTool = meta["tipo"] == "herramienta"
    var isMystery = (meta["id"] || "").startsWith("m")
    var v = {
      "typeIcon": isMystery ? "🌊" : (isSupport ? "🎁" : (isTool ? "🔧" : "🃏")),
      "typeLabel": isMystery ? "Misterio" : (isSupport ? "Maniobra de apoyo · una vez" : (isTool ? "Herramienta · queda" : "Maniobra · una vez")),
      "typeHint": isMystery ? "" : (isSupport ? "Se usa una vez, va al descarte y elegís Energía o Escudo." : (isTool ? "Queda en la mesa hasta que jueguen otra Herramienta." : "Se usa una vez y va al descarte.")),
      "useIcon": "👆",
      "useLabel": "Ahora",
      "useHint": "Se juega y se resuelve en el momento.",
      "useClass": "use-now",
      "chips": [Card.hchip("·", "—", "chip-none", "Sin efecto")]
    }

    if (effect == "peek") {
      v["useIcon"] = "♾️"
      v["useLabel"] = "Siempre"
      v["useHint"] = "Funciona sola mientras esté en la mesa."
      v["useClass"] = "use-always"
      v["chips"] = [Card.hchip("👀", "Próximo Misterio", "chip-neutral", "Mirá el próximo Misterio del Mazo")]
    } else if (effect == "reroll_parity") {
      v["useIcon"] = "🎲"
      v["useLabel"] = "Antes de tirar"
      v["useHint"] = "Se prepara antes de la prueba, en Cara o Seca."
      v["useClass"] = "use-before"
      v["chips"] = [Card.hchip("🔁", "1 dado", "chip-dado", "Si la prueba falla, relanzá 1 dado")]
    } else if (effect == "energy_start") {
      v["useIcon"] = "♾️"
      v["useLabel"] = "Siempre"
      v["useHint"] = "Funciona sola al empezar cada Misterio."
      v["useClass"] = "use-always"
      v["chips"] = [Card.hchip("⚡", "+1", "chip-energia", "Si la Energía está en 4 o menos, sube 1"), Card.hchip("", "4 o menos", "chip-neutral", "Solo si la Energía está en 4 o menos")]
    } else if (effect == "reduce_damage") {
      v["useIcon"] = "🎲"
      v["useLabel"] = "Antes de tirar"
      v["useHint"] = "Se prepara antes de la prueba que va a golpear el Escudo."
      v["useClass"] = "use-before"
      v["chips"] = [Card.hchip("🛡️", "−1 daño", "chip-escudo", "Reduce 1 el daño al Escudo de esa prueba")]
    } else if (effect == "extra_clue_six") {
      v["useIcon"] = "♾️"
      v["useLabel"] = "Siempre"
      v["useHint"] = "Funciona sola cada vez que ganan Pistas."
      v["useClass"] = "use-always"
      v["chips"] = [Card.hchip("🔍", "+1", "chip-pista", "Ganás 1 Pista extra si un dado muestra 6"), Card.hchip("🎲", "sale 6", "chip-dado", "Solo si un dado muestra 6")]
    } else if (effect == "harpoon") {
      v["chips"] = [Card.hchip("⚡", "−2", "chip-energia chip-loss", "Gastá 2 de Energía"), Card.hchip("🎲", "Cara", "chip-dado", "Tirá 1 dado: gana si sale Cara"), Card.hchip("🔍", "+1", "chip-pista", "Si sale Cara, ganás 1 Pista")]
    } else if (effect == "plus_one_sum") {
      v["useIcon"] = "♾️"
      v["useLabel"] = "Siempre"
      v["useHint"] = "Funciona sola en las pruebas de 2 dados."
      v["useClass"] = "use-always"
      v["chips"] = [Card.hchip("🎲", "+1", "chip-dado", "Sumá 1 al total de la prueba"), Card.hchip("", "2 dados", "chip-neutral", "Solo en pruebas de 2 dados")]
    } else if (effect == "flip_parity") {
      v["useIcon"] = "🎲"
      v["useLabel"] = "Antes de tirar"
      v["useHint"] = "Se prepara antes de una prueba de Cara o Seca."
      v["useClass"] = "use-before"
      v["chips"] = [Card.hchip("🔄", "Cara ↔ Seca", "chip-dado", "El dado se invierte: Cara pasa a Seca y Seca a Cara")]
    } else if (effect == "plus_two") {
      v["useIcon"] = "🎲"
      v["useLabel"] = "Antes de tirar"
      v["useHint"] = "Se prepara antes de la prueba."
      v["useClass"] = "use-before"
      v["chips"] = [Card.hchip("🎲", "+2", "chip-dado", "Sumá 2 al total de la prueba")]
    } else if (effect == "reroll_all") {
      v["useIcon"] = "🎲"
      v["useLabel"] = "Antes de tirar"
      v["useHint"] = "Se prepara antes de la prueba."
      v["useClass"] = "use-before"
      v["chips"] = [Card.hchip("🎲", "todos", "chip-dado", "Volvé a tirar todos los dados"), Card.hchip("🔁", "si falla", "chip-dado", "Solo si la prueba falla")]
    } else if (effect == "heal_shield") {
      v["chips"] = [Card.hchip("🛡️", "+1", "chip-escudo", "Recuperás 1 de Escudo")]
    } else if (effect == "heal_energy") {
      v["chips"] = [Card.hchip("⚡", "+2", "chip-energia", "Recuperás 2 de Energía")]
    } else if (effect == "clue_for_energy") {
      v["chips"] = [Card.hchip("⚡", "−1", "chip-energia chip-loss", "Gastá 1 de Energía"), Card.hchip("🔍", "+1", "chip-pista", "Ganás 1 Pista enseguida")]
    } else if (effect == "discard_active") {
      v["chips"] = [Card.hchip("🔀", "Misterio nuevo", "chip-neutral", "Descartá una carta activa y sacá otra en su lugar")]
    } else if (effect == "cancel_shield_loss") {
      v["useIcon"] = "🎲"
      v["useLabel"] = "Antes de tirar"
      v["useHint"] = "Se prepara antes de la prueba que puede dañar el Escudo."
      v["useClass"] = "use-before"
      v["chips"] = [Card.hchip("🛡️", "no pierdas", "chip-escudo", "En este Misterio no perdés Escudo por una carta o un evento")]
    } else if (effect == "no_energy_cost") {
      v["useIcon"] = "🎲"
      v["useLabel"] = "Antes de tirar"
      v["useHint"] = "Se prepara antes de la prueba."
      v["useClass"] = "use-before"
      v["chips"] = [Card.hchip("⚡", "gratis", "chip-energia", "En este Misterio no pierden Energía: ni por consumo ni por cartas")]
    } else if (effect == "shield_start") {
      v["useIcon"] = "♾️"
      v["useLabel"] = "Siempre"
      v["useHint"] = "Funciona sola al empezar cada Misterio."
      v["useClass"] = "use-always"
      v["chips"] = [Card.hchip("🛡️", "+1", "chip-escudo", "Si el Escudo está en 4 o menos, sube 1"), Card.hchip("", "4 o menos", "chip-neutral", "Solo si el Escudo está en 4 o menos")]
    } else if (isSupport) {
      v["chips"] = [Card.hchip("⚡", "+" + value.toString, "chip-energia", "Sumá " + value.toString + " de Energía"), Card.hchip("", "o", "chip-or", "Elegí Energía o Escudo"), Card.hchip("🛡️", "+" + value.toString, "chip-escudo", "Sumá " + value.toString + " de Escudo")]
    }
    return v
  }

  static chips(text) {
    var out = []
    if (text != null) {
      for (piece in text.split(",")) {
        var t = piece.trim
        if (t == "") continue
        var i = t.indexOf("+")
        var sign = "+"
        if (i == -1) {
          i = t.indexOf("-")
          sign = "−"
        }
        if (i < 1) continue
        var key = t[0...i].trim
        var val = t[i + 1..t.count - 1].trim
        var icon = "·"
        var name = key
        if (key == "pistas") {
          icon = "🔍"
          name = "Pistas"
        }
        if (key == "energia") {
          icon = "⚡"
          name = "Energía"
        }
        if (key == "escudo") {
          icon = "🛡️"
          name = "Escudo"
        }
        var cls = "chip-" + key
        if (sign == "−") cls = cls + " chip-loss"
        out.add({"icon": icon, "text": sign + val, "cls": cls, "title": name + " " + sign + val})
      }
    }
    if (out.isEmpty) out.add({"icon": "·", "text": "—", "cls": "chip-none", "title": "Sin efecto"})
    return out
  }

  static decorate(o) {
    var p = (o["prueba"] || "cara").trim
    var kind = "cara"
    var target = 0
    if (p == "cara") {
      kind = "cara"
    } else if (p == "seca") {
      kind = "seca"
    } else if (p == "dobles") {
      kind = "dobles"
    } else if (p.startsWith("sin 1")) {
      kind = "sin1"
    } else if (p.contains("2 dados")) {
      kind = "suma"
      target = Card.targetOf(p)
    } else {
      kind = "dado"
      target = Card.targetOf(p)
    }
    o["tipoPrueba"] = kind
    o["objetivo"] = target
    o["dados"] = (kind == "suma" || kind == "dobles" || kind == "sin1") ? 2 : 1
    var label = ""
    if (kind == "cara") {
      label = "CARA · sale par"
    } else if (kind == "seca") {
      label = "SECA · sale impar"
    } else if (kind == "dobles") {
      label = "2 dados · dobles"
    } else if (kind == "sin1") {
      label = "2 dados · sin 1 ni 6"
    } else if (kind == "suma") {
      label = "2 dados · " + target.toString + "+"
    } else {
      label = "1 dado · " + target.toString + "+"
    }
    o["pruebaLabel"] = label
    o["exitoLabel"] = Card.effectsLabel(o["exito"])
    o["falloLabel"] = Card.effectsLabel(o["fallo"])
    o["exitoChips"] = Card.chips(o["exito"])
    o["falloChips"] = Card.chips(o["fallo"])
  }

  static targetOf(text) {
    var rest = text
    var c = text.indexOf(",")
    if (c > -1) rest = text[c + 1..text.count - 1]
    var digits = ""
    for (ch in rest) {
      if ("0123456789".contains(ch)) digits = digits + ch
    }
    return digits == "" ? 0 : Num.fromString(digits)
  }

  static effectsLabel(text) {
    if (text == null || text.trim == "") return "sin efecto"
    var parts = []
    for (piece in text.split(",")) {
      var t = piece.trim
      if (t == "") continue
      var i = t.indexOf("+")
      var sign = "+"
      if (i == -1) {
        i = t.indexOf("-")
        sign = "−"
      }
      if (i < 1) continue
      var key = t[0...i].trim
      var val = t[i + 1..t.count - 1].trim
      var name = key
      if (key == "pistas") name = "Pistas"
      if (key == "energia") name = "Energía"
      if (key == "escudo") name = "Escudo"
      parts.add(name + " " + sign + val)
    }
    return parts.isEmpty ? "sin efecto" : parts.join(" · ")
  }
}
