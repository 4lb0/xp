// Motor de cartas: cada carta es un .md en cartas/ con un bloque ```xp
// de mecánicas y narrativa en markdown. Ver cartas/LEEME.md.
class Card {
  construct new(meta, body, options) {
    _id = meta["id"]
    _name = meta["nombre"] || "Carta sin nombre"
    _family = meta["familia"] || meta["tipo"] || "exploracion"
    _type = meta["tipo"] || ""
    _copies = Num.fromString(meta["copias"] || "1")
    _effect = meta["efecto"] || ""
    _emoji = meta["emoji"] || "🫧"
    _entry = meta["entrada"] || ""
    _entryLabel = meta["entradaLabel"] || ""
    _body = body
    _options = options
  }

  id { _id }
  name { _name }
  family { _family }
  type { _type }
  copies { _copies }
  effect { _effect }
  emoji { _emoji }
  entry { _entry }
  entryLabel { _entryLabel }
  body { _body }
  options { _options }

  option(label) {
    for (o in _options) {
      if (o["label"] == label) return o
    }
    return _options.isEmpty ? null : _options[0]
  }

  isTool { _type == "herramienta" }
  isManeuver { _type == "maniobra" }

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
    for (o in opts) Card.decorate(o)
    return Card.new(meta, body, opts)
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
    } else if (p == "sin 1") {
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
      if (key == "turno") name = "Turno"
      parts.add(name + " " + sign + val)
    }
    return parts.isEmpty ? "sin efecto" : parts.join(" · ")
  }
}
