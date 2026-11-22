#!/usr/bin/env python3
"""Genera un PDF de proxies B&N para XP.

Lee las cartas Markdown de cartas/misterio y cartas/equipo, repite las copias
del mazo de Equipo y arma hojas A4 con 9 cartas de 60 x 86 mm (unos mm menos
que una carta TCG estándar de 63 x 88 mm), con líneas de corte.

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
from reportlab.pdfbase.pdfmetrics import stringWidth
from reportlab.pdfgen import canvas
from reportlab.lib.styles import ParagraphStyle
from reportlab.platypus import Paragraph

ROOT = Path(__file__).resolve().parents[1]
CARD_W = 60 * mm
CARD_H = 86 * mm
GAP_X = 4 * mm
GAP_Y = 3 * mm
MARGIN_X = 11 * mm
MARGIN_BOTTOM = 16 * mm
COLS = 3
ROWS = 3
OUT = ROOT / "pdf" / "xp-proxies-bw.pdf"


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
        return "CARA (par)"
    if raw == "seca":
        return "SECA (impar)"
    if raw == "dobles":
        return "DOBLES"
    if raw.startswith("sin 1"):
        return "SIN 1 NI 6"
    return clean(raw.upper())


def team_type(card: dict) -> str:
    if (card.get("subtipo") or "").strip().lower() == "apoyo" or (card.get("tipo") or "").lower() == "apoyo":
        return "MANIOBRA DE APOYO"
    if (card.get("tipo") or "").lower() == "herramienta":
        return "HERRAMIENTA"
    return "MANIOBRA"


def mystery_family(card: dict) -> str:
    family = (card.get("familia") or "exploracion").lower()
    return {"exploracion": "EXPLORACIÓN", "peligro": "PELIGRO", "dilema": "DILEMA"}.get(family, family.upper())


def draw_crop_marks(c: canvas.Canvas, x: float, y: float, w: float, h: float) -> None:
    c.saveState()
    c.setStrokeGray(0.15)
    c.setLineWidth(0.3)
    m = 2.2 * mm
    for cx, cy, dx, dy in (
        (x, y, -1, -1),
        (x + w, y, 1, -1),
        (x, y + h, -1, 1),
        (x + w, y + h, 1, 1),
    ):
        c.line(cx, cy, cx + dx * m, cy)
        c.line(cx, cy, cx, cy + dy * m)
    c.restoreState()


def draw_card(c: canvas.Canvas, card: dict, x: float, y: float) -> None:
    kind = "misterio" if card.get("id", "").startswith("m") else "equipo"
    c.saveState()

    # Línea de corte + marcas de esquina.
    c.setStrokeGray(0.62)
    c.setLineWidth(0.3)
    c.setDash(2, 2)
    c.rect(x, y, CARD_W, CARD_H, stroke=1, fill=0)
    c.setDash()
    draw_crop_marks(c, x, y, CARD_W, CARD_H)

    inset = 1.3 * mm
    c.setStrokeGray(0)
    c.setLineWidth(0.55)
    c.rect(x + inset, y + inset, CARD_W - 2 * inset, CARD_H - 2 * inset, stroke=1, fill=0)

    # Marca de agua muy clara para llenar el espacio y ayudar a separar tipos.
    if kind == "misterio":
        mark = mystery_family(card)[0]
    elif (card.get("subtipo") or "").lower() == "apoyo" or (card.get("tipo") or "").lower() == "apoyo":
        mark = "A"
    elif (card.get("tipo") or "").lower() == "herramienta":
        mark = "H"
    else:
        mark = "M"
    c.setFillGray(0.92)
    c.setFont("Helvetica-Bold", 58)
    c.drawCentredString(x + CARD_W / 2, y + 22 * mm, mark)

    # Cabecera gris con id y mazo.
    header_h = 6.0 * mm
    header_y = y + CARD_H - inset - header_h
    c.setFillGray(0.88)
    c.rect(x + inset, header_y, CARD_W - 2 * inset, header_h, stroke=0, fill=1)
    c.setFillGray(0)
    c.setFont("Helvetica-Bold", 5.6)
    c.drawString(x + inset + 2.0 * mm, header_y + 1.8 * mm, clean(card.get("id", "")).upper())
    c.setFont("Helvetica", 4.8)
    deck = "MAZO DEL JUEGO" if kind == "misterio" else "MAZO DEL EQUIPO"
    c.drawRightString(x + CARD_W - inset - 2.0 * mm, header_y + 1.8 * mm, deck)

    left = x + inset + 2.0 * mm
    width = CARD_W - 2 * inset - 4.0 * mm
    top = header_y - 1.8 * mm

    # Nombre.
    name_style = ParagraphStyle(
        "name", fontName="Helvetica-Bold", fontSize=9.0, leading=9.8, textColor=(0, 0, 0), spaceAfter=0
    )
    name = Paragraph(clean(card.get("nombre", "Sin nombre")), name_style)
    _, name_h = name.wrap(width, 20 * mm)
    name.drawOn(c, left, top - name_h)
    top -= name_h + 1.0 * mm

    # Tipo / familia.
    sub = mystery_family(card) if kind == "misterio" else team_type(card)
    c.setFont("Helvetica-Bold", 5.2)
    c.setFillGray(0.25)
    c.drawString(left, top - 4.0 * mm, sub)
    top -= 5.0 * mm

    if kind == "misterio":
        entry = effect_text(card.get("entrada", ""))
        if entry:
            badge_w = width
            c.setFillGray(0)
            c.rect(left, top - 4.6 * mm, badge_w, 4.6 * mm, stroke=0, fill=1)
            c.setFillGray(1)
            c.setFont("Helvetica-Bold", 4.9)
            c.drawString(left + 1.2 * mm, top - 3.3 * mm, f"EMBOSCADA · Al entrar: {entry}")
            c.setFillGray(0)
            top -= 6.0 * mm

        option_style = ParagraphStyle(
            "option", fontName="Helvetica", fontSize=5.25, leading=6.15, textColor=(0.08, 0.08, 0.08), spaceAfter=0
        )
        for idx, opt in enumerate(card.get("options", [])):
            label = opt.get("label", chr(65 + idx))
            # círculo con la opción
            c.setFillGray(0)
            c.circle(left + 2.0 * mm, top - 2.1 * mm, 2.0 * mm, stroke=0, fill=1)
            c.setFillGray(1)
            c.setFont("Helvetica-Bold", 5.3)
            c.drawCentredString(left + 2.0 * mm, top - 3.5 * mm, clean(label))
            c.setFillGray(0)

            title = clean(opt.get("texto", ""))
            prueba = test_text(opt.get("prueba", ""))
            exito = effect_text(opt.get("exito", ""))
            fallo = effect_text(opt.get("fallo", ""))
            lines = [f"<b>{title}</b>"]
            if prueba:
                lines.append(f"Prueba: {prueba}")
            if exito:
                lines.append(f"Éxito: {exito}")
            if fallo:
                lines.append(f"Fallo: {fallo}")
            p = Paragraph("<br/>".join(lines), option_style)
            text_width = width - 5.2 * mm
            _, option_h = p.wrap(text_width, 40 * mm)
            p.drawOn(c, left + 5.2 * mm, top - option_h)
            top -= max(option_h, 5.0 * mm) + 2.0 * mm

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
            fy = y + inset + 7.0 * mm
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
        top -= body_h + 3.0 * mm

        # Recordatorio de uso según el tipo de carta.
        if (card.get("subtipo") or "").lower() == "apoyo" or (card.get("tipo") or "").lower() == "apoyo":
            usage = "Se usa una vez y va al descarte. Elegí Energía o Escudo."
        elif (card.get("tipo") or "").lower() == "herramienta":
            usage = "Queda en la mesa. Solo una Herramienta activa por equipo."
        else:
            usage = "Se juega antes de tirar. Después va al descarte."
        usage_style = ParagraphStyle(
            "usage", fontName="Helvetica", fontSize=5.6, leading=6.8,
            textColor=(0.35, 0.35, 0.35), spaceAfter=0
        )
        up = Paragraph(f"<b>CÓMO SE USA:</b> {usage}", usage_style)
        _, uh = up.wrap(width, 18 * mm)
        up.drawOn(c, left, top - uh)

    # Marca de proxy.
    c.setFillGray(0.55)
    c.setFont("Helvetica", 4.2)
    c.drawRightString(x + CARD_W - inset - 2 * mm, y + inset + 2.0 * mm, "PROXY B&N")

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
    per_page = COLS * ROWS
    pages = (len(cards) + per_page - 1) // per_page
    OUT.parent.mkdir(parents=True, exist_ok=True)

    c = canvas.Canvas(str(OUT), pagesize=A4)
    c.setTitle("XP - Proxies B&N")
    c.setAuthor("XP - Equipo eXPedición")
    c.setSubject("Proxies para imprimir en blanco y negro")
    c.setCreator("tools/make_proxies.py")

    for page in range(pages):
        # Encabezado de página.
        c.setFillGray(0)
        c.setFont("Helvetica-Bold", 6.2)
        c.drawString(MARGIN_X, A4[1] - 9 * mm, "XP · EQUIPO EXPEDICIÓN · PROXIES B&N")
        c.setFont("Helvetica", 5.4)
        c.drawRightString(A4[0] - MARGIN_X, A4[1] - 9 * mm, "60 × 86 mm · IMPRIMIR AL 100% · SIN ESCALAR")

        chunk = cards[page * per_page : (page + 1) * per_page]
        for i, card in enumerate(chunk):
            row, col = divmod(i, COLS)
            x = MARGIN_X + col * (CARD_W + GAP_X)
            y = A4[1] - MARGIN_BOTTOM - CARD_H - row * (CARD_H + GAP_Y)
            draw_card(c, card, x, y)

        # Pie de página.
        c.setFillGray(0.25)
        c.setFont("Helvetica", 5.0)
        c.drawString(MARGIN_X, 9 * mm, "Cortá por las líneas y meté cada carta en un folio. Si imprimís desde Preview, elegí “Tamaño real”.")
        c.drawRightString(A4[0] - MARGIN_X, 9 * mm, f"pág. {page + 1}/{pages}")

        # Regla de calibración de 50 mm.
        c.setStrokeGray(0.2)
        c.setLineWidth(0.35)
        c.line(MARGIN_X, 5.2 * mm, MARGIN_X + 50 * mm, 5.2 * mm)
        c.setFillGray(0.25)
        c.setFont("Helvetica", 4.6)
        c.drawString(MARGIN_X + 51.5 * mm, 4.5 * mm, "50 mm")

        c.showPage()

    c.save()
    print(f"{len(cards)} cartas · {pages} páginas · {OUT}")


if __name__ == "__main__":
    build()
