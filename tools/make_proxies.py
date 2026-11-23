#!/usr/bin/env python3
"""Genera un PDF de proxies B&N para XP.

Lee las cartas Markdown de cartas/misterio y cartas/equipo, repite las copias
del mazo de Equipo y arma hojas A4 con 9 cartas de 60 x 86 mm (unos mm menos
que una carta TCG estándar de 63 x 88 mm), con líneas de corte. Al final agrega
3 cartas de referencia (Energía, Pistas y Escudo) con dibujos.

Uso:
    python3 tools/make_proxies.py

Requiere reportlab:
    python3 -m pip install reportlab
"""

from __future__ import annotations

import re
import textwrap
from pathlib import Path

from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.pdfmetrics import stringWidth
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen import canvas
from reportlab.lib.styles import ParagraphStyle
from reportlab.platypus import Paragraph

ROOT = Path(__file__).resolve().parents[1]
CARD_W = 60 * mm
CARD_H = 86 * mm
GAP_X = 0
GAP_Y = 0
MARGIN_X = (A4[0] - 3 * CARD_W) / 2
MARGIN_Y = (A4[1] - 3 * CARD_H) / 2
COLS = 3
ROWS = 3
OUT = ROOT / "pdf" / "xp-proxies-bw.pdf"
EMOJI_FONT = ROOT / "tools" / "fonts" / "NotoEmoji.ttf"

if not EMOJI_FONT.exists():
    raise SystemExit("Falta tools/fonts/NotoEmoji.ttf (ver README).")
pdfmetrics.registerFont(TTFont("NotoEmoji", str(EMOJI_FONT)))


def clean(text: str) -> str:
    """Deja texto imprimible en las fuentes estándar de PDF (WinAnsi)."""
    if text is None:
        return ""
    text = text.replace("**", "").replace("__", "").replace("`", "")
    text = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", text)
    text = text.replace("<br>", "\n").replace("<br/>", "\n")
    text = re.sub(r"<[^>]+>", "", text)
    text = text.replace("−", "-").replace("–", "-").replace("—", "-")
    text = text.replace("→", "->").replace("↔", "<->").replace("…", "...")
    text = text.replace("“", '"').replace("”", '"').replace("‘", "'").replace("’", "'")
    text = text.replace("⚡", "ENERGIA").replace("🛡️", "ESCUDO").replace("🛡", "ESCUDO")
    text = text.replace("🔍", "PISTA").replace("·", "-")
    text = "".join(ch for ch in text if ord(ch) < 256 or ch in "áéíóúÁÉÍÓÚñÑüÜ¿¡")
    text = re.sub(r"[ \t]+", " ", text)
    return text.strip()


def parse_card(path: Path) -> dict:
    raw = path.read_text(encoding="utf-8")
    start = raw.index("```xp") + len("```xp")
    end = raw.index("```", start)
    block = raw[start:end].strip().splitlines()
    body = raw[end + 3 :].strip()
    meta: dict[str, str] = {}
    options: list[dict[str, str]] = []
    current: dict[str, str] | None = None
    for line in block:
        line = line.strip()
        if not line:
            continue
        match = re.fullmatch(r"\[([^\]]+)\]", line)
        if match:
            current = {"label": match.group(1)}
            options.append(current)
            continue
        if ":" in line:
            key, value = line.split(":", 1)
            key, value = key.strip(), value.strip()
            if current is not None:
                current[key] = value
            else:
                meta[key] = value
    meta["options"] = options
    meta["body"] = body
    meta["file"] = path.name
    return meta


def effect_text(raw: str) -> str:
    if not raw:
        return ""
    names = {"pistas": "Pistas", "energia": "Energía", "escudo": "Escudo"}
    parts = []
    for piece in raw.split(","):
        piece = piece.strip()
        if not piece:
            continue
        match = re.match(r"([a-záéíóúñ]+)\s*([+-])\s*(\d+)", piece)
        if not match:
            parts.append(clean(piece))
            continue
        key, sign, value = match.groups()
        parts.append(f"{names.get(key, key.title())} {sign}{value}")
    return " · ".join(parts)


def test_text(raw: str) -> str:
    if not raw:
        return ""
    raw = raw.strip().lower()
    if raw == "cara":
        return "CARA · SALE PAR"
    if raw == "seca":
        return "SECA · SALE IMPAR"
    if raw == "dobles":
        return "2 DADOS · DOBLES"
    if raw.startswith("sin 1"):
        return "2 DADOS · SIN 1 NI 6"
    return clean(raw.upper().replace(",", " ·"))


def parse_effects(raw: str) -> list[tuple[str, str, str]]:
    out: list[tuple[str, str, str]] = []
    if not raw:
        return out
    for piece in raw.split(","):
        match = re.match(r"\s*(pistas|energia|escudo)\s*([+-])\s*(\d+)", piece)
        if match:
            out.append(match.groups())
    return out


def draw_chips(c: canvas.Canvas, effects: list[tuple[str, str, str]], x: float, y: float) -> float:
    """Dibuja chips tipo app: icono emoji + valor. Devuelve el ancho usado."""
    icons = {"energia": "⚡", "escudo": "🛡️", "pistas": "🔍"}
    start = x
    for key, sign, value in effects:
        icon = icons.get(key, "•")
        c.setFont("NotoEmoji", 6.2)
        iw = stringWidth(icon, "NotoEmoji", 6.2)
        c.setFont("Helvetica-Bold", 5.4)
        tw = stringWidth(f"{sign}{value}", "Helvetica-Bold", 5.4)
        chip_w = iw + tw + 2.8 * mm
        c.setFillGray(0.90)
        c.roundRect(x, y, chip_w, 4.5 * mm, 1.4 * mm, stroke=0, fill=1)
        c.setFillGray(0)
        c.setFont("NotoEmoji", 6.2)
        c.drawString(x + 1.1 * mm, y + 1.15 * mm, icon)
        c.setFont("Helvetica-Bold", 5.4)
        c.drawString(x + 1.1 * mm + iw + 0.45 * mm, y + 1.25 * mm, f"{sign}{value}")
        x += chip_w + 0.8 * mm
    return x - start


def draw_effects_row(
    c: canvas.Canvas, label: str, effects: list[tuple[str, str, str]], x: float, y: float
) -> None:
    c.setFillGray(0.20)
    c.setFont("Helvetica-Bold", 4.4)
    c.drawString(x, y + 1.3 * mm, label)
    if effects:
        draw_chips(c, effects, x + 11.0 * mm, y)
    else:
        c.setFont("Helvetica", 5.0)
        c.drawString(x + 11.0 * mm, y + 1.3 * mm, "—")


def team_type(card: dict) -> str:
    if (card.get("subtipo") or "").strip().lower() == "apoyo" or (card.get("tipo") or "").lower() == "apoyo":
        return "MANIOBRA DE APOYO · UNA VEZ"
    if (card.get("tipo") or "").lower() == "herramienta":
        return "HERRAMIENTA · QUEDA"
    return "MANIOBRA · UNA VEZ"


def team_help(card: dict) -> dict:
    """Ayuda visual de una carta de Equipo: cuándo se usa y qué hace."""
    effect = (card.get("efecto") or "").strip()
    value = (card.get("valor") or "1").strip()
    support = (card.get("subtipo") or "").strip().lower() == "apoyo"
    help = {"use_icon": "👆", "use_label": "AHORA", "chips": []}

    def before() -> None:
        help["use_icon"], help["use_label"] = "🎲", "ANTES DE TIRAR"

    def always() -> None:
        help["use_icon"], help["use_label"] = "♾️", "SIEMPRE"

    if effect == "peek":
        always()
        help["chips"] = [("👀", "Próxima carta")]
    elif effect == "reroll_parity":
        before()
        help["chips"] = [("🔁", "1 dado")]
    elif effect == "energy_start":
        always()
        help["chips"] = [("⚡", "+1"), ("", "4 o menos")]
    elif effect == "reduce_damage":
        before()
        help["chips"] = [("🛡️", "-1 daño")]
    elif effect == "extra_clue_six":
        always()
        help["chips"] = [("🔍", "+1"), ("🎲", "sale 6")]
    elif effect == "harpoon":
        help["chips"] = [("⚡", "-2"), ("🎲", "Cara"), ("🔍", "+1")]
    elif effect == "plus_one_sum":
        always()
        help["chips"] = [("🎲", "+1"), ("", "2 dados")]
    elif effect == "flip_parity":
        before()
        help["chips"] = [("🔄", "Cara / Seca")]
    elif effect == "plus_two":
        before()
        help["chips"] = [("🎲", "+2")]
    elif effect == "reroll_all":
        before()
        help["chips"] = [("🎲", "todos"), ("🔁", "si falla")]
    elif effect == "heal_shield":
        help["chips"] = [("🛡️", "+1")]
    elif effect == "heal_energy":
        help["chips"] = [("⚡", "+2")]
    elif effect == "clue_for_energy":
        help["chips"] = [("⚡", "-1"), ("🔍", "+1")]
    elif effect == "discard_active":
        help["chips"] = [("🔀", "Misterio nuevo")]
    elif effect == "cancel_shield_loss":
        before()
        help["chips"] = [("🛡️", "no pierdas")]
    elif effect == "no_energy_cost":
        before()
        help["chips"] = [("⚡", "gratis")]
    elif effect == "shield_start":
        always()
        help["chips"] = [("🛡️", "+1"), ("", "4 o menos")]
    elif support:
        help["chips"] = [("⚡", f"+{value}"), ("", "o"), ("🛡️", f"+{value}")]
    return help


def draw_use_badge(c: canvas.Canvas, icon: str, label: str, x: float, y: float) -> None:
    """Pastilla con el momento de uso: 👆 AHORA, 🎲 ANTES DE TIRAR, ♾️ SIEMPRE."""
    c.setFont("NotoEmoji", 6.6)
    iw = stringWidth(icon, "NotoEmoji", 6.6) if icon else 0
    c.setFont("Helvetica-Bold", 5.4)
    tw = stringWidth(label, "Helvetica-Bold", 5.4)
    w = iw + tw + 3.0 * mm
    c.setFillGray(0.90)
    c.roundRect(x, y, w, 4.7 * mm, 2.2 * mm, stroke=0, fill=1)
    if icon:
        c.setFillGray(0.05)
        c.setFont("NotoEmoji", 6.6)
        c.drawString(x + 1.2 * mm, y + 1.3 * mm, icon)
    c.setFillGray(0.05)
    c.setFont("Helvetica-Bold", 5.4)
    c.drawString(x + 1.2 * mm + iw + (0.5 * mm if icon else 0), y + 1.45 * mm, label)


def draw_text_chips(c: canvas.Canvas, chips: list[tuple[str, str]], x: float, y: float) -> float:
    """Fichas de efecto con icono y texto corto. Devuelve el ancho usado."""
    start = x
    for icon, text in chips:
        clean_text = clean(text)
        icon_w = stringWidth(icon, "NotoEmoji", 6.8) if icon else 0
        text_w = stringWidth(clean_text, "Helvetica-Bold", 5.4)
        chip_w = icon_w + text_w + 2.8 * mm
        c.setFillGray(0.90)
        c.roundRect(x, y, chip_w, 5.0 * mm, 1.8 * mm, stroke=0, fill=1)
        c.setFillGray(0.05)
        if icon:
            c.setFont("NotoEmoji", 6.8)
            c.drawString(x + 1.0 * mm, y + 1.25 * mm, icon)
        c.setFont("Helvetica-Bold", 5.4)
        c.drawString(x + 1.0 * mm + icon_w + (0.4 * mm if icon else 0), y + 1.45 * mm, clean_text)
        x += chip_w + 0.7 * mm
    return x - start


def mystery_family(card: dict) -> str:
    family = (card.get("familia") or "exploracion").lower()
    return {"exploracion": "EXPLORACIÓN", "peligro": "PELIGRO", "dilema": "DILEMA"}.get(family, family.upper())


def draw_card(c: canvas.Canvas, card: dict, x: float, y: float) -> None:
    kind = "misterio" if card.get("id", "").startswith("m") else "equipo"
    c.saveState()

    inset = 2.6 * mm
    header_h = 6.0 * mm
    is_support = (card.get("subtipo") or "").lower() == "apoyo" or (card.get("tipo") or "").lower() == "apoyo"
    if kind == "misterio":
        # Misterio: cabecera arriba, pie de marca abajo.
        header_y = y + CARD_H - inset - header_h
        content_top = header_y - 1.8 * mm
        footer_y = y + 3.8 * mm
    else:
        # Equipo: la cabecera con id y mazo va abajo; la marca XP queda justo arriba.
        header_y = y + inset
        content_top = y + CARD_H - inset - 1.8 * mm
        footer_y = y + inset + header_h + 1.8 * mm

    if is_support:
        # Borde negro superior: las Maniobras de apoyo se encuentran de inmediato.
        support_bar = 2.8 * mm
        c.setFillGray(0)
        c.rect(x, y + CARD_H - support_bar, CARD_W, support_bar, stroke=0, fill=1)
        c.setFillGray(1)
        c.setFont("Helvetica-Bold", 4.4)
        c.drawCentredString(x + CARD_W / 2, y + CARD_H - 1.9 * mm, "APOYO")
        content_top = y + CARD_H - support_bar - 1.2 * mm

    # Cabecera gris con id y mazo.
    c.setFillGray(0.90 if kind == "misterio" else 0.84)
    c.rect(x + inset, header_y, CARD_W - 2 * inset, header_h, stroke=0, fill=1)
    c.setFillGray(0)
    c.setFont("Helvetica-Bold", 5.6)
    c.drawString(x + inset + 1.5 * mm, header_y + 1.8 * mm, clean(card.get("id", "")).upper())
    c.setFont("Helvetica-Bold" if kind == "equipo" else "Helvetica", 4.8)
    deck = "MAZO DEL JUEGO" if kind == "misterio" else "MAZO DEL EQUIPO"
    c.drawRightString(x + CARD_W - inset - 1.5 * mm, header_y + 1.8 * mm, deck)

    left = x + inset
    width = CARD_W - 2 * inset
    top = content_top

    # Nombre.
    name_style = ParagraphStyle(
        "name", fontName="Helvetica-Bold", fontSize=9.5, leading=10.3, textColor=(0, 0, 0), spaceAfter=0
    )
    name = Paragraph(clean(card.get("nombre", "Sin nombre")), name_style)
    _, name_h = name.wrap(width, 20 * mm)
    name.drawOn(c, left, top - name_h)
    top -= name_h + 1.0 * mm

    # Tipo / familia.
    sub = mystery_family(card) if kind == "misterio" else team_type(card)
    c.setFont("Helvetica-Bold", 5.2)
    c.setFillGray(0.25)
    if kind == "misterio":
        c.drawString(left, top - 4.0 * mm, sub)
    else:
        type_icon = "🎁" if is_support else ("🔧" if (card.get("tipo") or "").lower() == "herramienta" else "🃏")
        c.setFont("NotoEmoji", 6.4)
        c.setFillGray(0.20)
        c.drawString(left, top - 4.0 * mm, type_icon)
        icon_w = stringWidth(type_icon, "NotoEmoji", 6.4)
        c.setFont("Helvetica-Bold", 5.0)
        c.drawString(left + icon_w + 1.0 * mm, top - 4.0 * mm, sub)
    emoji = (card.get("emoji") or "").strip()
    if emoji:
        c.setFont("NotoEmoji", 7.2)
        c.setFillGray(0.20)
        c.drawRightString(left + width, top - 4.0 * mm, emoji)
    top -= 5.0 * mm

    if kind == "equipo":
        help = team_help(card)
        top -= 1.3 * mm
        draw_use_badge(c, help["use_icon"], help["use_label"], left, top - 4.7 * mm)
        top -= 5.8 * mm
        if help["chips"]:
            draw_text_chips(c, help["chips"], left, top - 5.0 * mm)
            top -= 6.0 * mm

    if kind == "misterio":
        entry_effects = parse_effects(card.get("entrada", ""))
        if entry_effects:
            c.setFillGray(0.90)
            c.roundRect(left, top - 5.6 * mm, width, 5.6 * mm, 1.4 * mm, stroke=0, fill=1)
            c.setFillGray(0.15)
            c.setFont("Helvetica-Bold", 4.6)
            entry_label = "AL ENTRAR"
            c.drawString(left + 1.4 * mm, top - 3.8 * mm, entry_label)
            entry_label_w = stringWidth(entry_label, "Helvetica-Bold", 4.6)
            draw_chips(c, entry_effects, left + 1.4 * mm + entry_label_w + 2.5 * mm, top - 5.0 * mm)
            top -= 6.6 * mm

        title_style = ParagraphStyle(
            "option_title", fontName="Helvetica-Bold", fontSize=6.3, leading=7.3,
            textColor=(0.05, 0.05, 0.05), spaceAfter=0
        )
        for idx, opt in enumerate(card.get("options", [])):
            label = opt.get("label", chr(65 + idx))
            c.setFillGray(1)
            c.setStrokeGray(0)
            c.setLineWidth(0.5)
            c.circle(left + 2.0 * mm, top - 2.1 * mm, 2.0 * mm, stroke=1, fill=1)
            c.setFillGray(0)
            c.setFont("Helvetica-Bold", 5.3)
            c.drawCentredString(left + 2.0 * mm, top - 3.5 * mm, clean(label))

            title = clean(opt.get("texto", ""))
            prueba = test_text(opt.get("prueba", ""))
            text_width = width - 5.2 * mm
            tp = Paragraph(title, title_style)
            _, th = tp.wrap(text_width, 20 * mm)
            tp.drawOn(c, left + 5.2 * mm, top - th)
            y = top - th - 1.0 * mm

            # Prueba: pill gris.
            if prueba:
                c.setFont("Helvetica-Bold", 4.9)
                tw = stringWidth(prueba, "Helvetica-Bold", 4.9)
                c.setFillGray(0.90)
                c.roundRect(left + 5.2 * mm, y - 4.3 * mm, tw + 2.6 * mm, 4.3 * mm, 1.4 * mm, stroke=0, fill=1)
                c.setFillGray(0.15)
                c.drawString(left + 6.5 * mm, y - 3.0 * mm, prueba)
                y -= 5.2 * mm

            draw_effects_row(c, "ÉXITO", parse_effects(opt.get("exito", "")), left + 5.2 * mm, y - 4.5 * mm)
            y -= 5.0 * mm
            draw_effects_row(c, "FALLO", parse_effects(opt.get("fallo", "")), left + 5.2 * mm, y - 4.5 * mm)
            y -= 5.2 * mm
            top = y - 0.6 * mm

        # Un fragmento de narrativa al pie, para que la carta no quede vacía.
        flavor = clean(card.get("body", ""))
        if flavor:
            flavor = textwrap.shorten(flavor, width=235, placeholder="…")
            flavor = "\n".join(textwrap.wrap(flavor, width=76)[:4])
            flavor_style = ParagraphStyle(
                "flavor", fontName="Helvetica-Oblique", fontSize=5.0, leading=6.0,
                textColor=(0.42, 0.42, 0.42), spaceAfter=0
            )
            fp = Paragraph(flavor, flavor_style)
            _, fh = fp.wrap(width, 20 * mm)
            fy = y + 8.0 * mm
            if fy + fh < top - 2.0 * mm:
                c.setStrokeGray(0.75)
                c.setLineWidth(0.3)
                c.line(left, fy + fh + 1.0 * mm, left + width, fy + fh + 1.0 * mm)
                fp.drawOn(c, left, fy)
    else:
        body = clean(card.get("body", ""))
        body_style = ParagraphStyle(
            "body", fontName="Helvetica", fontSize=8.2, leading=10.0, textColor=(0.08, 0.08, 0.08), spaceAfter=0
        )
        p = Paragraph(body, body_style)
        _, body_h = p.wrap(width, 48 * mm)
        p.drawOn(c, left, top - body_h)

    # Pie de carta.
    c.setFillGray(0.35)
    c.setFont("Helvetica", 4.3)
    c.drawCentredString(x + CARD_W / 2, footer_y, "XP: En busca del Megalodón")

    c.restoreState()


def draw_cut_lines(c: canvas.Canvas, cards: list[dict]) -> None:
    vertical = set()
    horizontal = set()
    for i, _card in enumerate(cards):
        row, col = divmod(i, COLS)
        x = MARGIN_X + col * CARD_W
        y = A4[1] - MARGIN_Y - CARD_H - row * CARD_H
        vertical.add((round(x, 3), round(y, 3), round(y + CARD_H, 3)))
        vertical.add((round(x + CARD_W, 3), round(y, 3), round(y + CARD_H, 3)))
        horizontal.add((round(y, 3), round(x, 3), round(x + CARD_W, 3)))
        horizontal.add((round(y + CARD_H, 3), round(x, 3), round(x + CARD_W, 3)))

    c.saveState()
    c.setStrokeGray(0.58)
    c.setLineWidth(0.3)
    c.setDash(2, 2)
    for x, y0, y1 in sorted(vertical):
        c.line(x, y0, x, y1)
    for y, x0, x1 in sorted(horizontal):
        c.line(x0, y, x1, y)
    c.restoreState()


def reference_cards() -> list[dict]:
    return [
        {
            "id": "R1",
            "kind": "referencia",
            "name": "ENERGÍA",
            "eyebrow": "EL RELOJ",
            "range": "6+",
            "text": "Se gasta 1 por ciclo. Puede superar 6. No pierde sola: la derrota es al cerrar un turno con Energía y Escudo en 0.",
            "icon": "energia",
        },
        {
            "id": "R2",
            "kind": "referencia",
            "name": "PISTAS",
            "eyebrow": "LA MISIÓN",
            "range": "0 A 6",
            "text": "Reuní 6 Pistas para encontrar al Megalodón.",
            "icon": "pistas",
        },
        {
            "id": "R3",
            "kind": "referencia",
            "name": "ESCUDO",
            "eyebrow": "EL CASCO",
            "range": "6+",
            "text": "Puede superar 6. No pierde solo: la derrota es al cerrar un turno con Energía y Escudo en 0.",
            "icon": "escudo",
        },
    ]


def draw_resource_icon(c: canvas.Canvas, icon: str, cx: float, cy: float, size: float) -> None:
    c.saveState()
    c.translate(cx - size / 2, cy - size / 2)
    c.scale(size / 100.0, size / 100.0)
    c.setStrokeGray(0)
    c.setFillGray(0)
    c.setLineWidth(7)
    c.setLineCap(1)
    c.setLineJoin(1)
    if icon == "energia":
        p = c.beginPath()
        p.moveTo(58, 4)
        p.lineTo(22, 54)
        p.lineTo(45, 54)
        p.lineTo(38, 96)
        p.lineTo(78, 42)
        p.lineTo(52, 42)
        p.close()
        c.drawPath(p, fill=1, stroke=0)
    elif icon == "pistas":
        c.setFillGray(1)
        c.circle(42, 58, 27, stroke=1, fill=1)
        c.setFillGray(1)
        c.setLineWidth(9)
        c.line(62, 38, 91, 9)
    else:
        p = c.beginPath()
        p.moveTo(50, 4)
        p.lineTo(90, 18)
        p.lineTo(90, 48)
        p.curveTo(90, 74, 72, 89, 50, 96)
        p.curveTo(28, 89, 10, 74, 10, 48)
        p.lineTo(10, 18)
        p.close()
        c.drawPath(p, fill=0, stroke=1)
    c.restoreState()


def draw_reference_card(c: canvas.Canvas, card: dict, x: float, y: float) -> None:
    inset = 2.6 * mm
    header_h = 6.0 * mm
    header_y = y + CARD_H - inset - header_h
    c.saveState()

    # Cabecera gris con la etiqueta de referencia.
    c.setFillGray(0.90)
    c.rect(x + inset, header_y, CARD_W - 2 * inset, header_h, stroke=0, fill=1)
    c.setFillGray(0)
    c.setFont("Helvetica-Bold", 5.0)
    c.drawString(x + inset + 1.5 * mm, header_y + 1.8 * mm, "REFERENCIA")
    c.setFont("Helvetica", 4.8)
    c.drawRightString(x + CARD_W - inset - 1.5 * mm, header_y + 1.8 * mm, card.get("id", ""))

    # Dibujo grande.
    draw_resource_icon(c, card.get("icon", "energia"), x + CARD_W / 2, y + 54 * mm, 29 * mm)

    # Nombre, subtítulo y regla.
    c.setFillGray(0)
    c.setFont("Helvetica-Bold", 14)
    c.drawCentredString(x + CARD_W / 2, y + 31 * mm, card.get("name", ""))
    c.setFillGray(0.30)
    c.setFont("Helvetica-Bold", 5.6)
    c.drawCentredString(x + CARD_W / 2, y + 25.5 * mm, card.get("eyebrow", ""))
    c.setFillGray(0)
    c.setFont("Helvetica-Bold", 9.0)
    c.drawCentredString(x + CARD_W / 2, y + 18.5 * mm, card.get("range", ""))

    text_style = ParagraphStyle(
        "ref_text", fontName="Helvetica", fontSize=6.4, leading=8.0,
        textColor=(0.15, 0.15, 0.15), alignment=1, spaceAfter=0
    )
    p = Paragraph(clean(card.get("text", "")), text_style)
    _, th = p.wrap(CARD_W - 2 * inset - 6 * mm, 18 * mm)
    p.drawOn(c, x + inset + 3 * mm, y + 15 * mm - th)

    c.setFillGray(0.35)
    c.setFont("Helvetica", 4.3)
    c.drawCentredString(x + CARD_W / 2, y + 3.8 * mm, "XP: En busca del Megalodón")
    c.restoreState()


def build() -> None:
    misterio = [parse_card(p) for p in sorted((ROOT / "cartas" / "misterio").glob("*.md"))]
    equipo_unique = [parse_card(p) for p in sorted((ROOT / "cartas" / "equipo").glob("*.md"))]
    equipo = []
    for card in equipo_unique:
        copies = int(card.get("copias") or 1)
        for _ in range(copies):
            equipo.append(card)

    cards = misterio + equipo
    refs = reference_cards()
    per_page = COLS * ROWS
    chunks = [cards[i : i + per_page] for i in range(0, len(cards), per_page)]
    # Las referencias van al final de la última hoja, si hay lugar.
    for ref in refs:
        if not chunks or len(chunks[-1]) >= per_page:
            chunks.append([])
        chunks[-1].append(ref)
    OUT.parent.mkdir(parents=True, exist_ok=True)

    c = canvas.Canvas(str(OUT), pagesize=A4)
    c.setTitle("XP - Proxies B&N")
    c.setAuthor("XP - Equipo eXPedición")
    c.setSubject("Proxies para imprimir en blanco y negro")
    c.setCreator("tools/make_proxies.py")

    for chunk in chunks:
        for i, card in enumerate(chunk):
            row, col = divmod(i, COLS)
            x = MARGIN_X + col * CARD_W
            y = A4[1] - MARGIN_Y - CARD_H - row * CARD_H
            if card.get("kind") == "referencia":
                draw_reference_card(c, card, x, y)
            else:
                draw_card(c, card, x, y)
        draw_cut_lines(c, chunk)
        c.showPage()

    c.save()
    print(f"{len(cards)} cartas + {len(refs)} referencias · {len(chunks)} páginas · {OUT}")


if __name__ == "__main__":
    build()
