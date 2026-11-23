/* XP · Equipo eXPedición — animaciones y sonidos del tablero.
   Sin frameworks ni dependencias. Todo se apaga desde los dos toggles. */
(() => {
  "use strict";

  const main = document.querySelector(".game");
  if (!main) return;

  const root = document.documentElement;
  const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  const prefKey = { motion: "xp-motion", sound: "xp-sound" };
  const store = (() => { try { return window.localStorage; } catch (error) { return null; } })();
  const tab = (() => { try { return window.sessionStorage; } catch (error) { return null; } })();
  const read = (area, key) => { try { return area ? area.getItem(key) : null; } catch (error) { return null; } };
  const write = (area, key, value) => { try { if (area) area.setItem(key, value); } catch (error) {} };
  const state = {
    motion: read(store, prefKey.motion) || (reduce ? "off" : "on"),
    sound: read(store, prefKey.sound) || "on"
  };
  let audio = null;
  const escapeId = (value) => (window.CSS && CSS.escape ? CSS.escape(value) : String(value).replace(/["\\]/g, "\\$&"));

  const motionOn = () => root.dataset.motion !== "off";
  const soundOn = () => root.dataset.sound !== "off";

  function syncPrefs() {
    root.dataset.motion = state.motion;
    root.dataset.sound = state.sound;
    const motion = document.getElementById("toggle-motion");
    const sound = document.getElementById("toggle-sound");
    if (motion) {
      motion.setAttribute("aria-pressed", state.motion === "on" ? "true" : "false");
      const icon = motion.querySelector("[aria-hidden]");
      if (icon) icon.textContent = state.motion === "on" ? "✨" : "🚫";
    }
    if (sound) {
      sound.setAttribute("aria-pressed", state.sound === "on" ? "true" : "false");
      const icon = sound.querySelector("[aria-hidden]");
      if (icon) icon.textContent = state.sound === "on" ? "🔊" : "🔇";
    }
  }
  syncPrefs();

  document.getElementById("toggle-motion")?.addEventListener("click", () => {
    state.motion = state.motion === "on" ? "off" : "on";
    write(store, prefKey.motion, state.motion);
    syncPrefs();
  });

  document.getElementById("toggle-sound")?.addEventListener("click", () => {
    state.sound = state.sound === "on" ? "off" : "on";
    write(store, prefKey.sound, state.sound);
    syncPrefs();
    if (state.sound === "on") playSound("toggle");
  });

  // ----- Mazos y descartes -----

  const dialog = document.getElementById("mazos-dialog");
  document.getElementById("mazos-btn")?.addEventListener("click", () => {
    if (!dialog) return;
    if (typeof dialog.showModal === "function") dialog.showModal();
    else dialog.setAttribute("open", "");
  });
  dialog?.querySelectorAll("[data-close]").forEach((button) => {
    button.addEventListener("click", () => dialog.close());
  });
  dialog?.addEventListener("click", (event) => {
    if (event.target === dialog) dialog.close();
  });

  // ----- Movimientos de cartas -----

  let moves = [];
  try {
    moves = JSON.parse(main.dataset.moves || "[]");
  } catch (error) {
    moves = [];
  }
  if (!Array.isArray(moves)) moves = [];

  const draws = moves.filter((move) => move.kind === "draw");
  const discards = moves.filter((move) => move.kind === "discard");
  const plays = moves.filter((move) => move.kind === "play");

  const revealed = new Set();
  if (motionOn() && document.getElementById("mazos-btn")) {
    prepareReveals(moves);
    showGhosts(moves);
  }
  showToast(draws, discards, plays);
  const lastHandledSound = Number(read(tab, "xpSoundAt") || 0);
  const soundAlreadyPlayed = Date.now() - lastHandledSound < 5000;
  if (soundOn() && !soundAlreadyPlayed) {
    if (draws.length) playSound("draw", 0);
    if (plays.length) playSound("play", 90);
    if (discards.length) playSound("discard", 160);
  }

  function cardNode(move) {
    return main.querySelector(`[data-row="${escapeId(move.rowId)}"]`);
  }

  function prepareReveals(list) {
    const drawMoves = list.filter((move) => move.kind === "draw");
    const playMoves = list.filter((move) => move.kind === "play");
    drawMoves.forEach((move, index) => {
      const card = cardNode(move);
      // En la pantalla de emboscada inicial las cartas son una decisión:
      // no se tapan. El resto de los robos sí viaja con el dorso.
      if (card && !card.closest("#emboscada")) card.classList.add("is-drawing");
      // Si no hay fantasma (por ejemplo, más de 6 robos), la carta igual
      // aparece; nunca se queda tapada.
      window.setTimeout(() => revealCard(move), 1600 + index * 70);
    });
    playMoves.slice(0, 8).forEach((move, index) => markNew(move, index));
  }

  function markNew(move, index) {
    const card = cardNode(move);
    if (!card) return;
    card.classList.remove("is-drawing");
    card.classList.add("is-new");
    card.style.animationDelay = `${Math.min(index, 5) * 60}ms`;
    window.setTimeout(() => {
      card.classList.remove("is-new");
      card.style.animationDelay = "";
    }, 1900 + Math.min(index, 5) * 60);
  }

  function revealCard(move) {
    if (revealed.has(move.rowId)) return;
    revealed.add(move.rowId);
    const card = cardNode(move);
    if (!card) return;
    const wasDrawing = card.classList.contains("is-drawing");
    card.classList.remove("is-drawing");
    card.classList.remove("is-new");
    if (wasDrawing) {
      void card.offsetWidth;
      card.classList.add("is-revealed");
      window.setTimeout(() => card.classList.remove("is-revealed"), 430);
    }
    card.classList.add("is-new");
    window.setTimeout(() => card.classList.remove("is-new"), 1950);
  }

  function showGhosts(list) {
    const anchor = document.getElementById("mazos-btn");
    if (!anchor) return;
    const interesting = list.filter((move) => {
      return move.kind === "draw" || move.kind === "discard" || move.kind === "play";
    }).slice(0, 6);

    interesting.forEach((move, index) => {
      window.setTimeout(() => {
        if (!motionOn()) return;
        const start = move.kind === "draw" ? anchor.getBoundingClientRect() : zoneRect(move.from);
        const end = move.kind === "discard" ? anchor.getBoundingClientRect() : (newCardRect(move) || zoneRect(move.to));
        if (!start || !end) return;
        flyCard(move, start, end, () => {
          if (move.kind === "draw") revealCard(move);
        });
      }, index * 90);
    });
  }

  function newCardRect(move) {
    const card = cardNode(move);
    return card ? card.getBoundingClientRect() : null;
  }

  function zoneRect(zone) {
    const section = document.getElementById(sectionForZone(zone));
    return section ? section.getBoundingClientRect() : null;
  }

  function sectionForZone(zone) {
    if (zone === "mano") return "mano";
    if (zone === "mesa") return "cartas-activas";
    if (zone === "herramientas") return "herramientas";
    if (zone === "ayuda") return "ayuda";
    return null;
  }

  function flyCard(move, start, end, onDone) {
    const isDraw = move.kind === "draw";
    const ghost = document.createElement("div");
    ghost.className = "card-ghost";
    ghost.setAttribute("aria-hidden", "true");
    if (isDraw) {
      ghost.style.backgroundImage = `url("/img/dorso-${move.deck === "juego" ? "misterio" : "equipo"}.png")`;
    } else {
      ghost.classList.add("card-ghost-front");
      ghost.textContent = move.emoji || "🃏";
    }

    // Coordenadas del documento: si el usuario hace scroll, la carta fantasma
    // se mueve con la página en vez de quedar clavada en la ventana.
    const width = isDraw ? 76 : 64;
    const height = isDraw ? 107 : 90;
    const sx = start.left + window.scrollX + start.width / 2;
    const sy = start.top + window.scrollY + start.height / 2;
    const ex = end.left + window.scrollX + end.width / 2;
    const ey = end.top + window.scrollY + end.height / 2;

    ghost.style.width = `${width}px`;
    ghost.style.height = `${height}px`;
    ghost.style.left = `${sx - width / 2}px`;
    ghost.style.top = `${sy - height / 2}px`;
    document.body.appendChild(ghost);

    const dx = ex - sx;
    const dy = ey - sy;
    const spin = move.kind === "discard" ? 10 : -8;
    const animation = ghost.animate(
      [
        { transform: "translate(0, 0) scale(0.82) rotate(0deg)", opacity: 0.2 },
        { transform: `translate(${dx * 0.6}px, ${dy * 0.55 - 14}px) scale(1.04) rotate(${spin / 2}deg)`, opacity: 1, offset: 0.55 },
        { transform: `translate(${dx}px, ${dy}px) scale(${isDraw ? 1.1 : 0.95}) rotate(${spin}deg)`, opacity: 1, offset: 0.9 },
        { transform: `translate(${dx}px, ${dy}px) scale(${isDraw ? 1.1 : 0.95}) rotate(${spin}deg)`, opacity: 0 }
      ],
      { duration: isDraw ? 680 : 540, easing: "cubic-bezier(.2,.7,.25,1)" }
    );
    const done = () => {
      ghost.remove();
      if (onDone) onDone();
    };
    animation.onfinish = done;
    animation.oncancel = done;
  }

  function showToast(drawList, discardList, playList) {
    const pieces = [];
    if (drawList.length) {
      const counts = deckCounts(drawList);
      let label = `Robaste ${drawList.length}`;
      if (counts.juego && !counts.equipo) label += " del Juego";
      else if (counts.equipo && !counts.juego) label += " de Equipo";
      pieces.push(label);
    }
    if (playList.length) pieces.push(`${playList.length} en juego`);
    if (discardList.length) {
      const counts = deckCounts(discardList);
      if (counts.juego && counts.equipo) {
        pieces.push(`${discardList.length} al descarte (${counts.juego} Juego · ${counts.equipo} Equipo)`);
      } else if (counts.juego) {
        pieces.push(`${counts.juego} al descarte del Juego`);
      } else {
        pieces.push(`${counts.equipo} al descarte de Equipo`);
      }
    }
    if (!pieces.length) return;

    const toast = document.createElement("div");
    toast.className = "move-toast";
    toast.setAttribute("role", "status");
    toast.setAttribute("aria-live", "polite");
    const icon = document.createElement("span");
    icon.className = "move-toast-icon";
    icon.setAttribute("aria-hidden", "true");
    icon.textContent = drawList.length ? "🂠" : (discardList.length ? "🗂️" : "✨");
    const text = document.createElement("span");
    text.textContent = pieces.join(" · ");
    toast.append(icon, text);
    document.body.appendChild(toast);
    window.requestAnimationFrame(() => toast.classList.add("is-visible"));
    window.setTimeout(() => {
      toast.classList.remove("is-visible");
      window.setTimeout(() => toast.remove(), 220);
    }, 3600);
  }

  function deckCounts(list) {
    const counts = { juego: 0, equipo: 0 };
    list.forEach((move) => {
      if (counts[move.deck] != null) counts[move.deck] += 1;
    });
    return counts;
  }

  // ----- Sonido sintetizado -----

  function audioContext() {
    if (audio) return audio;
    const Context = window.AudioContext || window.webkitAudioContext;
    if (!Context) return null;
    try {
      audio = new Context();
    } catch (error) {
      audio = null;
    }
    return audio;
  }

  function unlockAudio() {
    const context = audioContext();
    if (context && context.state === "suspended") {
      context.resume().catch(() => {});
    }
  }
  document.addEventListener("pointerdown", unlockAudio, { once: true, capture: true });

  function playSound(kind, delay = 0) {
    if (!soundOn()) return;
    const context = audioContext();
    if (!context || context.state !== "running") return;
    window.setTimeout(() => {
      if (!soundOn()) return;
      const now = context.currentTime;
      if (kind === "shuffle") {
        noise(context, now, "draw");
        noise(context, now + 0.07, "draw");
      } else if (kind === "draw" || kind === "discard" || kind === "play" || kind === "card") {
        noise(context, now, kind === "card" ? "discard" : kind);
        if (kind === "discard" || kind === "card") thump(context, now);
      } else {
        click(context, now);
      }
    }, delay);
  }

  function noise(context, now, kind) {
    const duration = kind === "draw" ? 0.13 : 0.09;
    const buffer = context.createBuffer(1, Math.floor(context.sampleRate * duration), context.sampleRate);
    const data = buffer.getChannelData(0);
    for (let i = 0; i < data.length; i += 1) {
      const fade = Math.pow(1 - i / data.length, 2.2);
      data[i] = (Math.random() * 2 - 1) * fade;
    }
    const source = context.createBufferSource();
    source.buffer = buffer;
    const filter = context.createBiquadFilter();
    filter.type = "bandpass";
    filter.frequency.value = kind === "draw" ? 1600 : 900;
    filter.Q.value = 0.9;
    const gain = context.createGain();
    gain.gain.setValueAtTime(kind === "draw" ? 0.10 : 0.14, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + duration);
    source.connect(filter).connect(gain).connect(context.destination);
    source.start(now);
    source.stop(now + duration);
  }

  function thump(context, now) {
    const oscillator = context.createOscillator();
    const gain = context.createGain();
    oscillator.type = "sine";
    oscillator.frequency.setValueAtTime(150, now);
    oscillator.frequency.exponentialRampToValueAtTime(70, now + 0.12);
    gain.gain.setValueAtTime(0.10, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.14);
    oscillator.connect(gain).connect(context.destination);
    oscillator.start(now);
    oscillator.stop(now + 0.15);
  }

  // El submit es un gesto real: el sonido de la acción suena antes de navegar.
  // Si el navegador permite audio en la página nueva, se evita el doble sonido
  // con la marca xpSoundAt de sessionStorage.
  document.addEventListener("submit", (event) => {
    const form = event.target;
    const action = form?.querySelector('[name="accion"]')?.value;
    if (!action || !soundOn()) return;
    const kind = ["terminar", "jugar", "maniobra", "descartar", "usar_ayuda", "elegir_apoyo"].includes(action)
      ? "card"
      : (action === "nueva" ? "shuffle" : "click");
    const play = () => {
      playSound(kind);
      write(tab, "xpSoundAt", String(Date.now()));
    };
    const context = audioContext();
    if (context && context.state === "suspended") context.resume().then(play).catch(() => {});
    else play();
  }, true);

  function click(context, now) {
    const oscillator = context.createOscillator();
    const gain = context.createGain();
    oscillator.type = "triangle";
    oscillator.frequency.setValueAtTime(420, now);
    gain.gain.setValueAtTime(0.06, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.05);
    oscillator.connect(gain).connect(context.destination);
    oscillator.start(now);
    oscillator.stop(now + 0.06);
  }
})();
