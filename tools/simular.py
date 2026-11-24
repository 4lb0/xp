#!/usr/bin/env python3
"""Simulación de partidas de XP (rama mano-continua).

Lee las cartas desde `cartas/` —la misma fuente que usa la app— e implementa
las reglas del prototipo: turno con carta antes de la Misión, mano de 3 que se
mantiene (robás 1, descartás hasta 3), dados con sumas y re-tiradas, derrota al
principio del cierre y victoria en cuanto llegan a 6 Pistas.

Corre varios arquetipos de jugador, muchas partidas por arquetipo y modo, y
escribe `reporte.html` con los resultados. No reemplaza un playtest: es una
herramienta para ver tendencias del mazo y de las decisiones.

Uso:
    python3 tools/simular.py                 # 3000 partidas por arquetipo y modo
    python3 tools/simular.py --games 5000
    python3 tools/simular.py --seed 7 --out reporte.html
"""

import argparse
import datetime as dt
import html
import random
import re
import statistics
import subprocess
import time
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MISIONES = ROOT / "cartas" / "misiones"
EQUIPO = ROOT / "cartas" / "equipo"


# --------------------------------------------------------------------------
# Cartas
# --------------------------------------------------------------------------

def parse_effects(text):
    eff = {"pistas": 0, "energia": 0, "escudo": 0}
    if not text:
        return eff
    for part in text.split(","):
        m = re.match(r"\s*([a-záéíóú]+)\s*([+-])\s*(\d+)", part)
        if not m:
            continue
        key = m.group(1)
        if key in eff:
            eff[key] = int(m.group(3)) * (1 if m.group(2) == "+" else -1)
    return eff


def parse_test(text):
    p = (text or "cara").strip().lower()
    if p == "cara":
        return "cara", 0, 1
    if p == "seca":
        return "seca", 0, 1
    if p == "dobles":
        return "dobles", 0, 2
    if p.startswith("sin 1"):
        return "sin1", 0, 2
    m = re.search(r"(\d+)\s*\+", p)
    target = int(m.group(1)) if m else 0
    if "2 dados" in p:
        return "suma", target, 2
    return "dado", target, 1


def parse_block(path):
    text = path.read_text(encoding="utf-8")
    m = re.search(r"```xp\n(.*?)```", text, re.S)
    if not m:
        return None, []
    meta, opts, cur = {}, [], None
    for line in m.group(1).splitlines():
        t = line.strip()
        if not t:
            continue
        if t.startswith("["):
            cur = {"label": t.strip("[]")}
            opts.append(cur)
        else:
            k, _, v = t.partition(":")
            if cur is not None:
                cur[k.strip()] = v.strip()
            else:
                meta[k.strip()] = v.strip()
    return meta, opts


def load_cards():
    missions, equipment = {}, {}
    for path in sorted(MISIONES.glob("*.md")):
        meta, opts = parse_block(path)
        if not meta or "id" not in meta:
            continue
        options = []
        for o in opts:
            kind, target, dice = parse_test(o.get("prueba", "cara"))
            options.append({
                "label": o.get("label", "A"),
                "kind": kind,
                "target": target,
                "dice": dice,
                "exito": parse_effects(o.get("exito", "")),
                "fallo": parse_effects(o.get("fallo", "")),
            })
        missions[meta["id"]] = {
            "id": meta["id"],
            "nombre": meta.get("nombre", meta["id"]),
            "familia": meta.get("familia", "exploracion"),
            "entrada": parse_effects(meta.get("entrada", "")),
            "entradaLabel": meta.get("entrada", ""),
            "options": options,
        }
    for path in sorted(EQUIPO.glob("*.md")):
        meta, _ = parse_block(path)
        if not meta or "id" not in meta:
            continue
        equipment[meta["id"]] = {
            "id": meta["id"],
            "nombre": meta.get("nombre", meta["id"]),
            "tipo": meta.get("tipo", "maniobra"),
            "subtipo": meta.get("subtipo", ""),
            "efecto": meta.get("efecto", ""),
            "copias": int(meta.get("copias", "1")),
            "valor": int(meta.get("valor", "1")),
        }
    return missions, equipment


# --------------------------------------------------------------------------
# Probabilidades de las pruebas
# --------------------------------------------------------------------------

@lru_cache(maxsize=None)
def chance(kind, target, bonus=0, estab=False):
    b = bonus + (1 if estab else 0)
    if kind in ("cara", "seca"):
        return 0.5
    if kind == "dobles":
        return 6 / 36
    if kind == "sin1":
        return 16 / 36
    if kind == "suma":
        ok = sum(1 for a in range(1, 7) for c in range(1, 7) if a + c + b >= target)
        return ok / 36
    if kind == "dado":
        ok = sum(1 for a in range(1, 7) if a + b >= target)
        return ok / 6
    return 0.5


def p_six(kind):
    if kind in ("suma", "dobles", "sin1"):
        return 1 - (5 / 6) ** 2
    return 1 / 6


def clamp(v):
    return max(0, min(12, v))


def playable(g, cid):
    eff = g.E[cid]["efecto"]
    if eff == "clue_for_energy":
        return g.energia >= 1
    if eff == "harpoon":
        return g.energia >= 2
    return True


# --------------------------------------------------------------------------
# Juego
# --------------------------------------------------------------------------

class Game:
    def __init__(self, mode, missions, equipment, rng, strategy):
        self.M = missions
        self.E = equipment
        self.rng = rng
        self.strategy = strategy
        self.mode = mode
        self.energia = 6
        self.escudo = 6
        self.pistas = 0
        self.turno = 1
        self.tool = None
        self.flags = {"bonus": 0, "giro": False, "suerte": False, "focos": False,
                      "blindaje": False, "blindajeUsado": False, "cebo": False, "ahorro": False}
        self.mission_deck = list(missions.keys())
        rng.shuffle(self.mission_deck)
        self.mission_disc = []
        self.equip_deck = []
        for cid, c in equipment.items():
            self.equip_deck.extend([cid] * c["copias"])
        rng.shuffle(self.equip_deck)
        self.equip_disc = []
        self.prepared = []
        self.mesa = [self.draw_mission() for _ in range(3)]
        self.hand = []
        if mode in ("normal", "asistido") and "e17" in self.equip_deck:
            self.equip_deck.remove("e17")
            self.hand.append("e17")
        if mode == "asistido" and "e18" in self.equip_deck:
            self.equip_deck.remove("e18")
            self.hand.append("e18")
        while len(self.hand) < 3:
            c = self.draw_equip()
            if c is None:
                break
            self.hand.append(c)
        entries = [m for m in self.mesa if any(self.M[m]["entrada"].values())]
        if len(entries) == 1:
            self.pay_entry(entries[0])
        elif len(entries) > 1:
            costos = {tuple(sorted(self.M[m]["entrada"].items())) for m in entries}
            if len(costos) == 1:
                self.pay_entry(rng.choice(entries))
            else:
                self.pay_entry(strategy.choose_ambush(self, entries))

    # --- mazos ---

    def draw_mission(self):
        if not self.mission_deck:
            if not self.mission_disc:
                return None
            self.mission_deck = self.mission_disc
            self.mission_disc = []
            self.rng.shuffle(self.mission_deck)
        return self.mission_deck.pop()

    def draw_equip(self):
        if not self.equip_deck:
            if not self.equip_disc:
                return None
            self.equip_deck = self.equip_disc
            self.equip_disc = []
            self.rng.shuffle(self.equip_deck)
        return self.equip_deck.pop()

    # --- efectos ---

    def apply(self, eff, ok=False, d1=0, d2=0):
        dp, de, ds = eff["pistas"], eff["energia"], eff["escudo"]
        if de < 0 and self.flags["ahorro"]:
            de = 0
        if ds < 0 and self.flags["cebo"]:
            ds = 0
            self.flags["cebo"] = False
        if ds < 0 and self.flags["blindaje"] and not self.flags["blindajeUsado"]:
            ds += 1
            self.flags["blindajeUsado"] = True
            self.flags["blindaje"] = False
        if ok and dp > 0 and self.tool == "e05" and (d1 == 6 or d2 == 6):
            dp += 1
        self.pistas = clamp(self.pistas + dp)
        self.energia = clamp(self.energia + de)
        self.escudo = clamp(self.escudo + ds)
        return dp, de, ds

    def pay_entry(self, mid):
        self.apply(self.M[mid]["entrada"], True, 0, 0)

    # --- resolución ---

    def roll(self, n):
        return [self.rng.randint(1, 6) for _ in range(n)]

    def test_ok(self, opt, d1, d2):
        kind, target = opt["kind"], opt["target"]
        bonus = self.flags["bonus"]
        estab = self.tool == "e07"
        if kind == "cara":
            return d1 % 2 == 0
        if kind == "seca":
            return d1 % 2 == 1
        if kind == "dobles":
            return d1 == d2
        if kind == "sin1":
            return d1 not in (1, 6) and d2 not in (1, 6)
        if kind == "suma":
            return d1 + d2 + bonus + (1 if estab else 0) >= target
        return d1 + bonus >= target

    def resolve(self, mid, opt_index):
        opt = self.M[mid]["options"][opt_index]
        dice = self.roll(opt["dice"])
        d1 = dice[0]
        d2 = dice[1] if len(dice) > 1 else 0
        if opt["kind"] in ("cara", "seca") and self.flags["giro"]:
            d1 = 7 - d1
            self.flags["giro"] = False
        ok = self.test_ok(opt, d1, d2)
        if not ok and (self.flags["suerte"] or self.flags["focos"]):
            if self.flags["suerte"]:
                nd = self.roll(opt["dice"])
                d1 = nd[0]
                d2 = nd[1] if len(nd) > 1 else 0
                self.flags["suerte"] = False
                ok = self.test_ok(opt, d1, d2)
            else:
                if opt["kind"] in ("cara", "seca"):
                    d1 = self.roll(1)[0]
                    ok = self.test_ok(opt, d1, d2)
                self.flags["focos"] = False
        self.apply(opt["exito"] if ok else opt["fallo"], ok, d1, d2)
        self.equip_disc.extend(self.prepared)
        self.prepared = []
        if mid in self.mesa:
            self.mesa.remove(mid)
            self.mission_disc.append(mid)
        return ok

    # --- jugar carta ---

    def play(self, cid, target_mid=None):
        card = self.E[cid]
        self.hand.remove(cid)
        eff = card["efecto"]
        if card["tipo"] == "herramienta":
            if self.tool is not None:
                self.equip_disc.append(self.tool)
            self.tool = cid
        elif eff == "heal_energy":
            self.apply({"pistas": 0, "energia": 2, "escudo": 0})
            self.equip_disc.append(cid)
        elif eff == "heal_shield":
            self.apply({"pistas": 0, "energia": 0, "escudo": 1})
            self.equip_disc.append(cid)
        elif eff == "clue_for_energy":
            self.apply({"pistas": 1, "energia": -1, "escudo": 0})
            self.equip_disc.append(cid)
        elif eff == "harpoon":
            self.apply({"pistas": 0, "energia": -2, "escudo": 0})
            if self.roll(1)[0] % 2 == 0:
                self.apply({"pistas": 1, "energia": 0, "escudo": 0})
            self.equip_disc.append(cid)
        elif eff == "apoyo":
            v = card["valor"]
            if self.energia <= self.escudo:
                self.apply({"pistas": 0, "energia": v, "escudo": 0})
            else:
                self.apply({"pistas": 0, "energia": 0, "escudo": v})
            self.equip_disc.append(cid)
        elif eff == "discard_active":
            victima = self.strategy.choose_señuelo(self, target_mid)
            if victima is not None:
                self.mesa.remove(victima)
                self.mission_disc.append(victima)
                nueva = self.draw_mission()
                if nueva is not None:
                    self.mesa.append(nueva)
                    self.pay_entry(nueva)
            self.equip_disc.append(cid)
        elif eff == "plus_two":
            self.prepared.append(cid)
            self.flags["bonus"] += 2
        elif eff == "flip_parity":
            self.prepared.append(cid)
            self.flags["giro"] = True
        elif eff == "reroll_parity":
            self.prepared.append(cid)
            self.flags["focos"] = True
        elif eff == "reroll_all":
            self.prepared.append(cid)
            self.flags["suerte"] = True
        elif eff == "reduce_damage":
            self.prepared.append(cid)
            self.flags["blindaje"] = True
        elif eff == "cancel_shield_loss":
            self.prepared.append(cid)
            self.flags["cebo"] = True
        elif eff == "no_energy_cost":
            self.prepared.append(cid)
            self.flags["ahorro"] = True

    def close(self):
        if self.energia < 1 or self.escudo < 1:
            return "derrota"
        if not self.flags["ahorro"]:
            self.energia = clamp(self.energia - 1)
        nueva = self.draw_mission()
        if nueva is not None:
            self.mesa.append(nueva)
            self.pay_entry(nueva)
        self.equip_disc.extend(self.prepared)
        self.prepared = []
        self.flags.update({"bonus": 0, "giro": False, "suerte": False, "focos": False,
                           "blindaje": False, "blindajeUsado": False, "cebo": False, "ahorro": False})
        if self.tool == "e03" and self.energia <= 4:
            self.energia = clamp(self.energia + 1)
        if self.tool == "e19" and self.escudo <= 4:
            self.escudo = clamp(self.escudo + 1)
        c = self.draw_equip()
        if c is not None:
            self.hand.append(c)
        while len(self.hand) > 3:
            self.equip_disc.append(self.hand.pop(self.strategy.choose_discard(self)))
        self.turno += 1
        return None


# --------------------------------------------------------------------------
# Arquetipos
# --------------------------------------------------------------------------

class Base:
    key = "base"
    nombre = "Base"
    wp = 2.0
    we = 1.0
    ws = 1.2

    def weights(self, g):
        we, ws = self.we, self.ws
        if g.energia <= 2:
            we *= 2.2
        elif g.energia <= 4:
            we *= 1.4
        elif g.energia >= 8:
            we *= 0.6
        if g.escudo <= 2:
            ws *= 2.4
        elif g.escudo <= 4:
            ws *= 1.4
        elif g.escudo >= 8:
            ws *= 0.6
        return self.wp, we, ws

    def value(self, g, eff):
        dp, de, ds = eff["pistas"], eff["energia"], eff["escudo"]
        if dp > 0 and g.pistas + dp >= 6:
            return 1000.0
        if de < 0 and g.energia + de < 1:
            return -1000.0
        if ds < 0 and g.escudo + ds < 1:
            return -1000.0
        wp, we, ws = self.weights(g)
        real_dp = max(-g.pistas, min(dp, 12 - g.pistas))
        u = wp * real_dp + we * de + ws * ds
        if g.energia + de <= 1:
            u -= 6.0
        if g.escudo + ds <= 1:
            u -= 6.0
        return u

    def option_ev(self, g, opt, bonus=None, reroll=False, estab=None):
        b = g.flags["bonus"] if bonus is None else bonus
        e = (g.tool == "e07") if estab is None else estab
        p = chance(opt["kind"], opt["target"], b, e)
        if reroll:
            p = 1 - (1 - p) ** 2
        return p * self.value(g, opt["exito"]) + (1 - p) * self.value(g, opt["fallo"])

    def choose_target(self, g):
        best = None
        for mid in list(g.mesa):
            m = g.M[mid]
            for i, opt in enumerate(m["options"]):
                ev = self.option_ev(g, opt)
                if m["familia"] == "dilema":
                    ev -= 0.6 * self.wp
                if best is None or ev > best[0]:
                    best = (ev, mid, i)
        return (best[1], best[2]) if best else (None, 0)

    def card_gain(self, g, target, cid):
        card = g.E[cid]
        eff = card["efecto"]
        mid, oi = target
        if mid is None or not playable(g, cid):
            return -1
        opt = g.M[mid]["options"][oi]
        base = self.option_ev(g, opt)
        if card["tipo"] == "herramienta":
            if g.tool == cid:
                return -1
            if eff == "energy_start":
                return self.value(g, {"pistas": 0, "energia": 1, "escudo": 0}) * 2 if g.energia <= 4 else -1
            if eff == "shield_start":
                return self.value(g, {"pistas": 0, "energia": 0, "escudo": 1}) * 2 if g.escudo <= 4 else -1
            if eff == "plus_one_sum":
                return self.option_ev(g, opt, estab=True) - base if opt["dice"] == 2 else -1
            if eff == "extra_clue_six":
                if opt["exito"]["pistas"] <= 0:
                    return -1
                return p_six(opt["kind"]) * self.value(g, {"pistas": 1, "energia": 0, "escudo": 0}) * 0.8
            if eff == "peek":
                return 0.7
            return -1
        if eff == "plus_two":
            return self.option_ev(g, opt, bonus=g.flags["bonus"] + 2) - base \
                if opt["kind"] in ("suma", "dado") else -1
        if eff == "reroll_all":
            return self.option_ev(g, opt, reroll=True) - base
        if eff == "reroll_parity":
            return self.option_ev(g, opt, reroll=True) - base \
                if opt["kind"] in ("cara", "seca") else -1
        if eff == "flip_parity":
            return -1  # no cambia la probabilidad
        if eff == "reduce_damage":
            return self.value(g, {"pistas": 0, "energia": 0, "escudo": 1}) * 0.9 \
                if opt["fallo"]["escudo"] < 0 else -1
        if eff == "cancel_shield_loss":
            return self.value(g, {"pistas": 0, "energia": 0, "escudo": -opt["fallo"]["escudo"]}) * 0.9 \
                if opt["fallo"]["escudo"] < 0 else -1
        if eff == "no_energy_cost":
            u = self.value(g, {"pistas": 0, "energia": 1, "escudo": 0})
            if opt["fallo"]["energia"] < 0:
                u += self.value(g, {"pistas": 0, "energia": -opt["fallo"]["energia"], "escudo": 0}) * 0.5
            return u
        if eff == "heal_energy":
            return self.value(g, {"pistas": 0, "energia": 2, "escudo": 0})
        if eff == "heal_shield":
            return self.value(g, {"pistas": 0, "energia": 0, "escudo": 1})
        if eff == "clue_for_energy":
            return self.value(g, {"pistas": 1, "energia": -1, "escudo": 0})
        if eff == "harpoon":
            return 0.5 * self.value(g, {"pistas": 1, "energia": 0, "escudo": 0}) + \
                self.value(g, {"pistas": 0, "energia": -2, "escudo": 0})
        if eff == "apoyo":
            v = card["valor"]
            return max(self.value(g, {"pistas": 0, "energia": v, "escudo": 0}),
                       self.value(g, {"pistas": 0, "energia": 0, "escudo": v}))
        return -1

    def choose_card(self, g, target):
        best, best_gain = None, 0.6
        for cid in set(g.hand):
            if not playable(g, cid):
                continue
            gain = self.card_gain(g, target, cid)
            if gain > best_gain:
                best, best_gain = cid, gain
        return best

    def choose_discard(self, g):
        target = self.choose_target(g)
        peor, peor_gain = 0, 1e9
        for i, cid in enumerate(g.hand):
            gain = self.card_gain(g, target, cid)
            if gain < peor_gain:
                peor, peor_gain = i, gain
        return peor

    def choose_ambush(self, g, entries):
        best, best_v = entries[0], 1e9
        for mid in entries:
            v = self.value(g, g.M[mid]["entrada"])
            if v < best_v:
                best, best_v = mid, v
        return best

    def choose_señuelo(self, g, target_mid):
        candidatas = [m for m in g.mesa if m != target_mid] or list(g.mesa)
        if not candidatas:
            return None
        return min(candidatas, key=lambda m: min(
            self.option_ev(g, o) for o in g.M[m]["options"]))


class Azar(Base):
    key = "azar"
    nombre = "Azar"

    def choose_target(self, g):
        if not g.mesa:
            return (None, 0)
        mid = g.rng.choice(g.mesa)
        return (mid, g.rng.randrange(len(g.M[mid]["options"])))

    def choose_card(self, g, target):
        if not g.hand or g.rng.random() < 0.3:
            return None
        jugables = [c for c in set(g.hand) if playable(g, c)]
        return g.rng.choice(jugables) if jugables else None

    def choose_discard(self, g):
        return g.rng.randrange(len(g.hand))

    def choose_ambush(self, g, entries):
        return g.rng.choice(entries)

    def choose_señuelo(self, g, target_mid):
        candidatas = [m for m in g.mesa if m != target_mid] or list(g.mesa)
        return g.rng.choice(candidatas) if candidatas else None


class Cauto(Base):
    key = "cauto"
    nombre = "Cauto"
    wp = 1.2
    we = 1.9
    ws = 2.1

    def choose_card(self, g, target):
        curaciones = [c for c in set(g.hand) if g.E[c]["efecto"] in ("heal_energy", "heal_shield", "apoyo")]
        if curaciones and (g.energia <= 4 or g.escudo <= 4):
            best = max(curaciones, key=lambda c: self.card_gain(g, target, c))
            if self.card_gain(g, target, best) > 1.2:
                return best
        return super().choose_card(g, target)


class Buscador(Base):
    key = "buscador"
    nombre = "Buscador"
    wp = 3.4
    we = 0.55
    ws = 0.65

    def choose_card(self, g, target):
        mid, oi = target
        if mid is not None:
            opt = g.M[mid]["options"][oi]
            if opt["exito"]["pistas"] > 0:
                cartas = [c for c in set(g.hand)
                          if g.E[c]["efecto"] in ("plus_two", "reroll_all", "reroll_parity",
                                                  "clue_for_energy", "harpoon")]
                if cartas:
                    best = max(cartas, key=lambda c: self.card_gain(g, target, c))
                    if self.card_gain(g, target, best) > 0.6:
                        return best
        return super().choose_card(g, target)


class Equilibrado(Base):
    key = "equilibrado"
    nombre = "Equilibrado"
    wp = 2.3
    we = 1.0
    ws = 1.2

    def choose_card(self, g, target):
        if g.energia <= 3 or g.escudo <= 2:
            cartas = [c for c in set(g.hand)
                      if g.E[c]["efecto"] in ("heal_energy", "heal_shield", "apoyo")]
            if cartas:
                best = max(cartas, key=lambda c: self.card_gain(g, target, c))
                if self.card_gain(g, target, best) > 1.2:
                    return best
        return super().choose_card(g, target)


ARCHETIPOS = [Azar, Cauto, Buscador, Equilibrado]
MODOS = [("experto", "Experto"), ("normal", "Normal"), ("asistido", "Asistido")]


# --------------------------------------------------------------------------
# Partida
# --------------------------------------------------------------------------

def play_game(strategy, mode, missions, equipment, rng):
    g = Game(mode, missions, equipment, rng, strategy)
    jugadas = []
    elegidas = []
    ofrecidas = []
    while True:
        turnos = g.turno
        mid, oi = strategy.choose_target(g)
        if mid is None:
            return ("derrota", turnos, jugadas, elegidas, ofrecidas)
        cid = strategy.choose_card(g, (mid, oi))
        if cid is not None:
            g.play(cid, mid)
            jugadas.append(cid)
            if cid == "e14":
                mid, oi = strategy.choose_target(g)
                if mid is None:
                    return ("derrota", turnos, jugadas, elegidas, ofrecidas)
        if g.pistas >= 6:
            return ("victoria", turnos, jugadas, elegidas, ofrecidas)
        ofrecidas.extend(g.mesa)
        elegidas.append(mid)
        g.resolve(mid, oi)
        if g.pistas >= 6:
            return ("victoria", turnos, jugadas, elegidas, ofrecidas)
        if g.close() == "derrota":
            return ("derrota", turnos, jugadas, elegidas, ofrecidas)


def simulate(games, seed, missions, equipment):
    results = []
    for ai, cls in enumerate(ARCHETIPOS):
        for mi, (mode, mode_name) in enumerate(MODOS):
            for i in range(games):
                rng = random.Random(seed + ai * 1000003 + mi * 10007 + i * 7919)
                res, turnos, jugadas, elegidas, ofrecidas = play_game(
                    cls(), mode, missions, equipment, rng)
                results.append({
                    "arquetipo": cls.key,
                    "arquetipoNombre": cls.nombre,
                    "modo": mode,
                    "modoNombre": mode_name,
                    "resultado": res,
                    "turnos": turnos,
                    "jugadas": jugadas,
                    "elegidas": elegidas,
                    "ofertadas": ofrecidas,
                })
    return results


# --------------------------------------------------------------------------
# Reporte HTML
# --------------------------------------------------------------------------

FAMILIA = {"exploracion": "Exploración", "peligro": "Peligro", "dilema": "Dilema"}


def pct(a, b):
    return 0.0 if not b else 100.0 * a / b


def fmt(n, dec=1):
    return f"{n:.{dec}f}".replace(".", ",")


def barra(valor, maximo, clase="bar"):
    w = 0 if maximo <= 0 else max(0.0, min(100.0, 100.0 * valor / maximo))
    return f'<span class="{clase}" style="width:{w:.1f}%"></span>'


def build_report(results, missions, equipment, games, seed, elapsed):
    hoy = dt.date.today().strftime("%d/%m/%Y")
    try:
        commit = subprocess.check_output(["git", "rev-parse", "--short", "HEAD"],
                                         cwd=ROOT, text=True).strip()
        branch = subprocess.check_output(["git", "branch", "--show-current"],
                                         cwd=ROOT, text=True).strip()
    except Exception:
        commit, branch = "?", "?"

    cel = {}
    plays, picks, offers = {}, {}, {}
    for r in results:
        k = (r["arquetipo"], r["modo"])
        c = cel.setdefault(k, {"n": 0, "w": 0, "turnos": [], "tw": [], "tl": []})
        c["n"] += 1
        c["turnos"].append(r["turnos"])
        if r["resultado"] == "victoria":
            c["w"] += 1
            c["tw"].append(r["turnos"])
        else:
            c["tl"].append(r["turnos"])
        for cid in r["jugadas"]:
            plays[(r["arquetipo"], cid)] = plays.get((r["arquetipo"], cid), 0) + 1
        for mid in r["elegidas"]:
            picks[(r["arquetipo"], mid)] = picks.get((r["arquetipo"], mid), 0) + 1
        for mid in r["ofertadas"]:
            offers[(r["arquetipo"], mid)] = offers.get((r["arquetipo"], mid), 0) + 1

    arqs = [(c.key, c.nombre) for c in ARCHETIPOS]
    total = len(results)
    victorias = sum(1 for r in results if r["resultado"] == "victoria")
    turnos = [r["turnos"] for r in results]
    games_arch = games * len(MODOS)
    total_partidas = games * len(MODOS) * len(arqs)

    # --- tabla resumen ---
    filas = []
    for key, nombre in arqs:
        fila = [f'<th scope="row">{html.escape(nombre)}</th>']
        for mode, _ in MODOS:
            c = cel[(key, mode)]
            fila.append(f'<td><strong>{fmt(pct(c["w"], c["n"]))}%</strong>'
                        f'<span class="sub">{fmt(statistics.mean(c["turnos"]))} turnos</span></td>')
        n = sum(cel[(key, m)]["n"] for m, _ in MODOS)
        w = sum(cel[(key, m)]["w"] for m, _ in MODOS)
        t = [x for m, _ in MODOS for x in cel[(key, m)]["turnos"]]
        fila.append(f'<td class="total"><strong>{fmt(pct(w, n))}%</strong>'
                    f'<span class="sub">{fmt(statistics.mean(t))} turnos</span></td>')
        filas.append(f'<tr>{"".join(fila)}</tr>')

    # --- detalle por jugador y modo ---
    detalle = []
    for key, nombre in arqs:
        for mode, mode_name in MODOS:
            c = cel[(key, mode)]
            derrotas = c["n"] - c["w"]
            detalle.append(
                f'<tr><td><strong>{html.escape(nombre)}</strong></td><td>{mode_name}</td>'
                f'<td class="num">{c["n"]}</td><td class="num">{c["w"]}</td>'
                f'<td class="num">{derrotas}</td>'
                f'<td class="num"><strong>{fmt(pct(c["w"], c["n"]))}%</strong></td>'
                f'<td class="num">{fmt(statistics.mean(c["turnos"]))}</td>'
                f'<td class="num">{fmt(statistics.mean(c["tw"])) if c["tw"] else "—"}</td>'
                f'<td class="num">{fmt(statistics.mean(c["tl"])) if c["tl"] else "—"}</td>'
                f'<td class="num">{fmt(statistics.median(c["turnos"]), 0)}</td></tr>')
    tabla_detalle = f"""<section class="block">
  <div class="block-head"><h2>Detalle: victorias, derrotas y turnos</h2>
  <p>Cada celda son {games} partidas. Turno promedio del total y separado por resultado.</p></div>
  <div class="table-wrap"><table>
    <thead><tr><th>Jugador</th><th>Modo</th><th class="num">Partidas</th>
    <th class="num">Ganadas</th><th class="num">Perdidas</th><th class="num">% victorias</th>
    <th class="num">Turno prom.</th><th class="num">Ganando</th><th class="num">Perdiendo</th>
    <th class="num">Mediana</th></tr></thead>
    <tbody>{''.join(detalle)}</tbody>
  </table></div>
</section>"""

    # --- equipo ---
    def tabla_equipo(rows, titulo, subtitulo):
        head_arq = "".join(f"<th class='num'>{html.escape(n)}</th>" for _, n in arqs)
        body = []
        max_n = max((r[0] for r in rows), default=1) or 1
        total_jugadas = sum(v for v in plays.values())
        for n, cid, card, por_arq in rows:
            tipo = "Herramienta" if card["tipo"] == "herramienta" else (
                "Apoyo" if card["subtipo"] == "apoyo" else "Maniobra")
            body.append(
                f'<tr><td><strong>{html.escape(card["nombre"])}</strong>'
                f'<span class="sub">{cid} · {tipo}</span></td>'
                f'<td class="num">{n}</td>'
                f'<td class="num">{fmt(n / total_partidas, 2)}</td>'
                f'<td class="barcell">{barra(n, max_n)}<span class="barval">{fmt(pct(n, total_jugadas))}%</span></td>'
                + "".join(f'<td class="num">{fmt(x / games_arch, 2)}</td>' for x in por_arq)
                + "</tr>")
        return f"""<section class="block">
  <div class="block-head"><h2>{titulo}</h2><p>{subtitulo}</p></div>
  <div class="table-wrap"><table>
    <thead><tr><th>Carta</th><th class="num">Jugadas</th><th class="num">Por partida</th><th>Peso</th>{head_arq}</tr></thead>
    <tbody>{''.join(body)}</tbody>
  </table></div>
</section>"""

    equip_rows = []
    for cid, card in equipment.items():
        n = sum(v for (a, c), v in plays.items() if c == cid)
        por_arq = [sum(v for (a, c), v in plays.items() if c == cid and a == key)
                   for key, _ in arqs]
        equip_rows.append((n, cid, card, por_arq))

    # --- misiones ---
    misiones_rows = []
    for mid, m in missions.items():
        n = sum(v for (a, c), v in picks.items() if c == mid)
        of = sum(v for (a, c), v in offers.items() if c == mid)
        misiones_rows.append((n, of, mid, m))
    max_tasa = max((pct(n, of) for n, of, _, _ in misiones_rows), default=1) or 1

    body = []
    head_arq = "".join(f"<th class='num'>{html.escape(n)}</th>" for _, n in arqs)
    for n, of, mid, m in sorted(misiones_rows, key=lambda r: -pct(r[0], r[1])):
        tasa = pct(n, of)
        body.append(
            f'<tr><td><strong>{html.escape(m["nombre"])}</strong>'
            f'<span class="sub">{mid} · {FAMILIA.get(m["familia"], m["familia"])}'
            f'{" · Emboscada" if m["entradaLabel"] else ""}</span></td>'
            f'<td class="num">{of}</td><td class="num">{n}</td>'
            f'<td class="barcell">{barra(tasa, max_tasa)}<span class="barval">{fmt(tasa)}%</span></td>'
            + "".join(
                f'<td class="num">{fmt(pct(picks.get((key, mid), 0), offers.get((key, mid), 0)))}%</td>'
                for key, _ in arqs)
            + "</tr>")
    tabla_misiones = f"""<section class="block">
  <div class="block-head"><h2>Misiones elegidas</h2>
  <p>Tasa = elegida / veces que estuvo en la mesa. Ordenado de más a menos elegida.</p></div>
  <div class="table-wrap"><table>
    <thead><tr><th>Misión</th><th class="num">En mesa</th><th class="num">Elegida</th><th>Tasa</th>{head_arq}</tr></thead>
    <tbody>{''.join(body)}</tbody>
  </table></div>
</section>"""

    # --- familias ---
    fam = {}
    for mid, m in missions.items():
        d = fam.setdefault(m["familia"], [0, 0])
        d[0] += sum(v for (a, c), v in offers.items() if c == mid)
        d[1] += sum(v for (a, c), v in picks.items() if c == mid)
    fam_rows = "".join(
        f'<tr><td><strong>{FAMILIA.get(k, k)}</strong></td>'
        f'<td class="num">{v[0]}</td><td class="num">{v[1]}</td>'
        f'<td class="barcell">{barra(pct(v[1], v[0]), 100)}<span class="barval">{fmt(pct(v[1], v[0]))}%</span></td></tr>'
        for k, v in sorted(fam.items(), key=lambda kv: -pct(kv[1][1], kv[1][0])))
    tabla_familias = f"""<section class="block">
  <div class="block-head"><h2>Familias</h2><p>Cuánto se eligen las Misiones según su familia.</p></div>
  <div class="table-wrap"><table>
    <thead><tr><th>Familia</th><th class="num">En mesa</th><th class="num">Elegida</th><th>Tasa</th></tr></thead>
    <tbody>{fam_rows}</tbody></table></div>
</section>"""

    # --- distribución ---
    buckets = [(1, 5), (6, 8), (9, 11), (12, 14), (15, 99)]
    dist = [(f"{lo}–{hi}" if hi < 99 else "15+", sum(1 for t in turnos if lo <= t <= hi))
            for lo, hi in buckets]
    maxd = max(n for _, n in dist) or 1
    dist_rows = "".join(
        f'<div class="dist-row"><span>{lab}</span><div class="dist-bar">{barra(n, maxd)}</div>'
        f'<b>{n}</b></div>' for lab, n in dist)

    # --- lectura ---
    orden_man = sorted(equip_rows, key=lambda r: -r[0])
    mas_man = orden_man[0][2]["nombre"]
    menos_man = orden_man[-1][2]["nombre"]
    orden_mis = sorted(misiones_rows, key=lambda r: -pct(r[0], r[1]))
    mas_mis = orden_mis[0][3]["nombre"]
    menos_mis = orden_mis[-1][3]["nombre"]
    tasa_pista = pct(fam.get("exploracion", [0, 0])[1] + fam.get("peligro", [0, 0])[1],
                     fam.get("exploracion", [0, 0])[0] + fam.get("peligro", [0, 0])[0])
    tasa_dilema = pct(fam.get("dilema", [0, 0])[1], fam.get("dilema", [0, 0])[0])
    win_cells = [pct(cel[(k, m)]["w"], cel[(k, m)]["n"]) for k, _ in arqs for m, _ in MODOS]
    mejor_arq = max(arqs, key=lambda a: sum(cel[(a[0], m)]["w"] for m, _ in MODOS))
    peor_arq = min(arqs, key=lambda a: sum(cel[(a[0], m)]["w"] for m, _ in MODOS))
    victorias_turnos = [r["turnos"] for r in results if r["resultado"] == "victoria"]
    derrotas_turnos = [r["turnos"] for r in results if r["resultado"] == "derrota"]

    html_out = f"""<!doctype html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Simulación de partidas · XP</title>
<style>
  :root {{
    --abyss:#071A2E; --deep:#0B2239; --cyan:#33BBCC; --gold:#F2B33D;
    --gold-soft:#F5DA8C; --coral:#E06550; --green:#12A05F; --turquoise:#0FA8A2;
    --paper:#F4F1EA; --paper-soft:#D9D5CC; --muted:#8FA6B3;
    --line:rgba(244,241,234,.16); --line-strong:rgba(244,241,234,.34);
    --font: "Archivo", system-ui, -apple-system, "Segoe UI", sans-serif;
  }}
  * {{ box-sizing: border-box; }}
  body {{
    margin:0; padding:0 0 4rem; color:var(--paper); font-family:var(--font); line-height:1.5;
    background:
      radial-gradient(120% 80% at 50% -10%, rgba(51,187,204,.12), transparent 60%),
      linear-gradient(180deg,#0a2136,#061525 60%,#05111d);
  }}
  .wrap {{ width:min(1180px, 100% - 2rem); margin:0 auto; }}
  header {{ padding:2.2rem 0 1.4rem; border-bottom:1px solid var(--line); }}
  .eyebrow {{ margin:0; color:var(--gold-soft); font-size:.72rem; font-weight:800;
    letter-spacing:.2em; text-transform:uppercase; }}
  h1 {{ margin:.35rem 0 .5rem; font-size:clamp(1.8rem,4vw,2.6rem); line-height:1.05;
    letter-spacing:-.02em; }}
  .lead {{ margin:0; max-width:68ch; color:var(--paper-soft); }}
  .meta {{ display:flex; flex-wrap:wrap; gap:.5rem; margin-top:1rem; }}
  .pill {{ border:1px solid var(--line-strong); border-radius:999px; padding:.3rem .75rem;
    color:var(--muted); font-size:.72rem; font-weight:700; letter-spacing:.08em;
    text-transform:uppercase; }}
  .summary {{ display:grid; grid-template-columns:repeat(auto-fit,minmax(170px,1fr));
    gap:.8rem; margin:1.6rem 0 .4rem; }}
  .stat {{ border:1px solid var(--line); border-radius:10px; padding:.9rem 1rem;
    background:linear-gradient(180deg,rgba(11,34,57,.72),rgba(7,26,46,.55)); }}
  .stat b {{ display:block; font-size:1.9rem; line-height:1.1; font-weight:900;
    font-variant-numeric:tabular-nums; }}
  .stat span {{ color:var(--muted); font-size:.72rem; font-weight:700;
    letter-spacing:.1em; text-transform:uppercase; }}
  .stat.gold b {{ color:var(--gold); }}
  .stat.cyan b {{ color:var(--cyan); }}
  .stat.coral b {{ color:var(--coral); }}
  .stat.green b {{ color:var(--green); }}
  .block {{ margin-top:2.2rem; }}
  .block-head {{ display:flex; align-items:baseline; justify-content:space-between;
    gap:1rem; flex-wrap:wrap; border-bottom:1px solid var(--line);
    padding-bottom:.45rem; margin-bottom:.8rem; }}
  .block-head h2 {{ margin:0; font-size:1.05rem; letter-spacing:.06em; text-transform:uppercase; }}
  .block-head p {{ margin:0; color:var(--muted); font-size:.8rem; max-width:70ch; }}
  .table-wrap {{ overflow-x:auto; border:1px solid var(--line); border-radius:10px; }}
  table {{ width:100%; border-collapse:collapse; min-width:720px; }}
  th, td {{ padding:.55rem .7rem; text-align:left; border-bottom:1px solid var(--line);
    font-size:.84rem; vertical-align:middle; }}
  thead th {{ color:var(--muted); font-size:.68rem; letter-spacing:.1em;
    text-transform:uppercase; font-weight:800; background:rgba(7,26,46,.6); }}
  tbody tr:last-child td {{ border-bottom:0; }}
  tbody tr:hover {{ background:rgba(51,187,204,.05); }}
  .num {{ text-align:right; font-variant-numeric:tabular-nums; white-space:nowrap; }}
  .sub {{ display:block; color:var(--muted); font-size:.7rem; font-weight:500; }}
  .total {{ background:rgba(242,179,61,.06); }}
  .barcell {{ position:relative; min-width:180px; }}
  .bar {{ position:absolute; left:.7rem; top:50%; transform:translateY(-50%);
    height:8px; border-radius:999px; background:linear-gradient(90deg,var(--cyan),var(--turquoise));
    opacity:.55; }}
  .barcell .barval {{ position:relative; font-weight:700; font-variant-numeric:tabular-nums; }}
  .dist {{ display:grid; gap:.45rem; max-width:640px; }}
  .dist-row {{ display:grid; grid-template-columns:70px 1fr 60px; gap:.7rem;
    align-items:center; font-size:.82rem; }}
  .dist-bar {{ position:relative; height:10px; border-radius:999px;
    background:rgba(244,241,234,.08); overflow:hidden; }}
  .dist-bar .bar {{ position:absolute; inset:0 auto 0 0; transform:none; height:100%;
    left:0; background:linear-gradient(90deg,var(--gold),var(--gold-soft)); opacity:.7; }}
  .dist-row b {{ text-align:right; font-variant-numeric:tabular-nums; }}
  .notes {{ display:grid; gap:.7rem; margin-top:.4rem; }}
  .note {{ margin:0; border-left:3px solid var(--gold); padding:.55rem .9rem;
    background:rgba(242,179,61,.06); border-radius:0 8px 8px 0; }}
  .note strong {{ color:var(--gold-soft); }}
  .note.cyan {{ border-color:var(--cyan); background:rgba(51,187,204,.06); }}
  .note.cyan strong {{ color:var(--cyan); }}
  .note.coral {{ border-color:var(--coral); background:rgba(224,101,80,.06); }}
  .note.coral strong {{ color:var(--coral); }}
  footer {{ margin-top:2.5rem; padding-top:1rem; border-top:1px solid var(--line);
    color:var(--muted); font-size:.75rem; }}
  @media (max-width:720px) {{
    .block-head {{ flex-direction:column; align-items:flex-start; }}
    table {{ min-width:640px; }}
  }}
</style>
</head>
<body>
<div class="wrap">
  <header>
    <p class="eyebrow">Reporte de simulación</p>
    <h1>XP · {games} partidas por jugador y modo</h1>
    <p class="lead">Cuatro arquetipos juegan el prototipo con las reglas de la rama
    <strong>{html.escape(branch)}</strong>: la carta se juega antes de elegir la Misión,
    la mano se mantiene (robás 1 por turno, tope 3), los apoyos arrancan en la mano y la
    derrota se evalúa al principio del cierre. Las cartas se leen de <code>cartas/</code>,
    la misma fuente que usa la app.</p>
    <div class="meta">
      <span class="pill">{hoy}</span>
      <span class="pill">commit {html.escape(commit)}</span>
      <span class="pill">semilla {seed}</span>
      <span class="pill">{total} partidas</span>
      <span class="pill">{fmt(elapsed)} s</span>
    </div>
    <div class="summary">
      <div class="stat gold"><b>{fmt(pct(victorias, total))}%</b><span>victorias</span></div>
      <div class="stat cyan"><b>{fmt(statistics.mean(turnos))}</b><span>turnos promedio</span></div>
      <div class="stat"><b>{fmt(statistics.median(turnos), 0)}</b><span>turnos mediana</span></div>
      <div class="stat coral"><b>{fmt(statistics.mean(derrotas_turnos)) if derrotas_turnos else "—"}</b><span>turnos al perder</span></div>
      <div class="stat green"><b>{fmt(statistics.mean(victorias_turnos)) if victorias_turnos else "—"}</b><span>turnos al ganar</span></div>
    </div>
  </header>

  <section class="block">
    <div class="block-head"><h2>Resultado por jugador y modo</h2>
      <p>Porcentaje de victorias y turnos promedio de cada célula ({games} partidas).</p></div>
    <div class="table-wrap"><table>
      <thead><tr><th>Jugador</th><th class="num">Experto</th><th class="num">Normal</th>
      <th class="num">Asistido</th><th class="num">Total</th></tr></thead>
      <tbody>{''.join(filas)}</tbody>
    </table></div>
  </section>

  {tabla_detalle}

  <section class="block">
    <div class="block-head"><h2>Cuándo termina la partida</h2>
      <p>Distribución de turnos de todas las partidas. Un turno = una Misión resuelta y su cierre.</p></div>
    <div class="dist">{dist_rows}</div>
  </section>

  <section class="block">
    <div class="block-head"><h2>Lectura rápida</h2><p>Lo que muestran los números.</p></div>
    <div class="notes">
      <p class="note"><strong>Rango de victorias:</strong> de {fmt(min(win_cells))}% a {fmt(max(win_cells))}%
      según jugador y modo. La brecha más grande está entre {html.escape(mejor_arq[1])} y
      {html.escape(peor_arq[1])}.</p>
      <p class="note cyan"><strong>Maniobra más jugada:</strong> {html.escape(mas_man)}.
      <strong>Menos jugada:</strong> {html.escape(menos_man)}.
      El Giro Brusco invierte el dado pero no cambia la probabilidad, así que los jugadores
      que calculan no lo juegan.</p>
      <p class="note"><strong>Misión más elegida:</strong> {html.escape(mas_mis)}.
      <strong>Menos elegida:</strong> {html.escape(menos_mis)}.
      Exploración y Peligro se eligen {fmt(tasa_pista)}% de las veces que están en la mesa;
      los Dilemas, {fmt(tasa_dilema)}%.</p>
      <p class="note coral"><strong>Ojo:</strong> son bots con reglas fijas, no personas.
      Sirven para ver qué cartas quedan muertas y si el reloj de Energía aprieta; no para
      predecir una mesa real. Tampoco modelan la charla de la mesa ni los dados físicos.
      El Sonar y el Señuelo dependen de información y de leer la mesa: los bots casi no
      los usan, así que su lugar habla más de la simulación que del juego.</p>
    </div>
  </section>

  {tabla_equipo(orden_man[:10], "Equipo más jugado", "Top 10 por jugadas totales. Por partida = jugadas / partidas totales.")}
  {tabla_equipo(sorted(equip_rows, key=lambda r: r[0])[:9], "Equipo menos jugado", "Las 9 cartas con menos jugadas, incluidas las que nunca se jugaron.")}
  {tabla_misiones}
  {tabla_familias}

  <footer>
    Generado por <code>tools/simular.py</code> el {hoy}. Reglas de la rama
    {html.escape(branch)} (commit {html.escape(commit)}). Cada partida usa una semilla
    derivada de {seed}, así el reporte se puede reproducir con
    <code>python3 tools/simular.py --games {games} --seed {seed}</code>.
  </footer>
</div>
</body>
</html>
"""
    return html_out


# --------------------------------------------------------------------------
# Principal
# --------------------------------------------------------------------------

def main():
    ap = argparse.ArgumentParser(description="Simula partidas de XP y genera reporte.html")
    ap.add_argument("--games", type=int, default=3000, help="partidas por arquetipo y modo")
    ap.add_argument("--seed", type=int, default=20261124, help="semilla base")
    ap.add_argument("--out", default=str(ROOT / "reporte.html"), help="archivo de salida")
    args = ap.parse_args()

    missions, equipment = load_cards()
    total_copias = sum(c["copias"] for c in equipment.values())
    print(f"Cartas: {len(missions)} Misiones, {len(equipment)} Equipo ({total_copias} copias)")
    if len(missions) != 40:
        print("Ojo: se esperaban 40 Misiones")

    t0 = time.time()
    results = simulate(args.games, args.seed, missions, equipment)
    elapsed = time.time() - t0
    print(f"{len(results)} partidas en {elapsed:.1f}s")

    out = build_report(results, missions, equipment, args.games, args.seed, elapsed)
    Path(args.out).write_text(out, encoding="utf-8")
    print(f"Reporte: {args.out}")

    wins = sum(1 for r in results if r["resultado"] == "victoria")
    print(f"Victorias: {wins}/{len(results)} = {100 * wins / len(results):.1f}%")
    for cls in ARCHETIPOS:
        for mode, _ in MODOS:
            rs = [r for r in results if r["arquetipo"] == cls.key and r["modo"] == mode]
            w = sum(1 for r in rs if r["resultado"] == "victoria")
            t = statistics.mean(r["turnos"] for r in rs)
            print(f"  {cls.nombre:12} {mode:9} {100 * w / len(rs):5.1f}%  {t:4.1f} turnos")


if __name__ == "__main__":
    main()
