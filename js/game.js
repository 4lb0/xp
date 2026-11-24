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
    // El ícono es un <use> del sprite: no se le escribe texto encima. El
    // estado on/off lo dicen aria-pressed y la opacidad del botón.
    if (motion) motion.setAttribute("aria-pressed", state.motion === "on" ? "true" : "false");
    if (sound) sound.setAttribute("aria-pressed", state.sound === "on" ? "true" : "false");
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

  // ----- Anuncio del resultado de la prueba -----
  // El panel ya declara role="status"; además llevamos el foco al título para
  // que el lector de pantalla lea "Prueba superada" / "Prueba fallida".
  function announceResult() {
    const panel = document.querySelector("#resultado");
    if (!panel) return;
    const title = panel.querySelector("h2");
    if (!title) return;
    title.setAttribute("tabindex", "-1");
    title.focus();
  }
  announceResult();

  // ----- Mazos y descartes -----

  const dialog = document.getElementById("mazos-dialog");
  // Cada pila de la mesa abre el estado de mazos: la mesa tiene los objetos.
  document.querySelectorAll("[data-pile], #mazos-btn").forEach((pile) => {
    pile.addEventListener("click", () => {
      if (!dialog) return;
      if (typeof dialog.showModal === "function") dialog.showModal();
      else dialog.setAttribute("open", "");
    });
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

  const anim = main.dataset.anim || "";
  const outcome = main.dataset.outcome || "";
  let pendingOutcome = null;

  const draws = moves.filter((move) => move.kind === "draw");
  const discards = moves.filter((move) => move.kind === "discard");
  const plays = moves.filter((move) => move.kind === "play");

  const revealed = new Set();
  if (motionOn() && document.querySelector("[data-pile], #mazos-btn")) {
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
    if (anim === "dados") playSound("dice", 100);
  }

  if (anim === "dados") {
    if (motionOn()) animateDice();
    // El parámetro es efímero: si recargás, no se repite la tirada.
    try { history.replaceState(null, "", location.pathname + location.hash); } catch (error) {}
  }

  if (outcome && soundOn()) {
    pendingOutcome = outcome;
    window.setTimeout(() => {
      if (!pendingOutcome) return;
      const context = audioContext();
      if (context && context.state === "running") {
        playSound(pendingOutcome);
        pendingOutcome = null;
      }
    }, 350);
  }

  // ----- Fuegos suaves de victoria -----
  // Decoración: detrás del contenido, sin capturar el puntero y apagada por
  // el toggle de Animaciones (o por prefers-reduced-motion al arrancar).
  if (outcome === "victoria") {
    window.setTimeout(celebrate, 620);
  }

  function celebrate() {
    if (!motionOn() || !document.querySelector(".ending.victoria")) return;
    const canvas = document.createElement("canvas");
    canvas.className = "fireworks";
    canvas.setAttribute("aria-hidden", "true");
    document.body.appendChild(canvas);
    const context = canvas.getContext("2d");
    if (!context) {
      canvas.remove();
      return;
    }

    // Los acentos del manual: latón, turquesa y coral, siempre con poca opacidad.
    const colors = ["#F2B33D", "#F5DA8C", "#0FA8A2", "#9BD7E1", "#E06550", "#F0BEB4"];
    const particles = [];
    const bursts = [0, 340, 680, 1020, 1360, 1700];
    let width = 0;
    let height = 0;

    function resize() {
      const dpr = Math.min(window.devicePixelRatio || 1, 2);
      width = window.innerWidth;
      height = window.innerHeight;
      canvas.width = Math.round(width * dpr);
      canvas.height = Math.round(height * dpr);
      context.setTransform(dpr, 0, 0, dpr, 0, 0);
    }
    resize();
    window.addEventListener("resize", resize);

    function burst() {
      const margin = Math.min(width * 0.16, 96);
      const top = Math.max(64, height * 0.12);
      const bottom = Math.max(top, height * 0.46);
      const x = margin + Math.random() * Math.max(width - margin * 2, 1);
      const y = top + Math.random() * (bottom - top);
      const color = colors[Math.floor(Math.random() * colors.length)];
      const count = 30 + Math.floor(Math.random() * 10);
      const speed = 56 + Math.random() * 36;
      const twist = Math.random() * Math.PI * 2;
      for (let i = 0; i < count; i += 1) {
        const angle = twist + (Math.PI * 2 * i) / count;
        const velocity = speed * (0.6 + Math.random() * 0.55);
        const life = 1.45 + Math.random() * 0.75;
        particles.push({
          x,
          y,
          vx: Math.cos(angle) * velocity,
          vy: Math.sin(angle) * velocity - 8,
          life,
          maxLife: life,
          color,
          size: 1.35 + Math.random() * 1.7
        });
      }
    }

    let startedAt = 0;
    let lastAt = 0;

    function tick(now) {
      if (!motionOn() || !canvas.isConnected) {
        window.removeEventListener("resize", resize);
        canvas.remove();
        return;
      }
      if (!startedAt) {
        startedAt = now;
        lastAt = now;
      }
      const dt = Math.min((now - lastAt) / 1000, 0.05);
      lastAt = now;
      if (bursts.length && now - startedAt >= bursts[0]) {
        bursts.shift();
        burst();
      }

      context.clearRect(0, 0, width, height);
      context.globalCompositeOperation = "lighter";
      for (let i = particles.length - 1; i >= 0; i -= 1) {
        const particle = particles[i];
        particle.life -= dt;
        if (particle.life <= 0) {
          particles.splice(i, 1);
          continue;
        }
        particle.vy += 22 * dt;
        particle.vx *= 0.985;
        particle.vy *= 0.985;
        particle.x += particle.vx * dt;
        particle.y += particle.vy * dt;
        const fade = particle.life / particle.maxLife;
        context.fillStyle = particle.color;
        // Halo tenue: da el brillo sin llegar a saturar el fondo oscuro.
        context.globalAlpha = Math.min(1, fade * 0.18);
        context.beginPath();
        context.arc(particle.x, particle.y, particle.size * 2.5 * (0.4 + fade * 0.6), 0, Math.PI * 2);
        context.fill();
        // Estela corta en el sentido de la velocidad.
        context.globalAlpha = Math.min(1, fade * 0.34);
        context.strokeStyle = particle.color;
        context.lineWidth = particle.size * 0.9;
        context.lineCap = "round";
        context.beginPath();
        context.moveTo(particle.x - particle.vx * 0.085, particle.y - particle.vy * 0.085);
        context.lineTo(particle.x, particle.y);
        context.stroke();
        // Núcleo.
        context.globalAlpha = Math.min(1, fade * 0.88);
        context.beginPath();
        context.arc(particle.x, particle.y, particle.size * (0.35 + fade * 0.65), 0, Math.PI * 2);
        context.fill();
      }
      context.globalAlpha = 1;
      context.globalCompositeOperation = "source-over";

      if (particles.length || bursts.length) {
        window.requestAnimationFrame(tick);
      } else {
        window.removeEventListener("resize", resize);
        canvas.remove();
      }
    }
    window.requestAnimationFrame(tick);
  }

  function animateDice() {
    const dice = [...main.querySelectorAll(".dice-roll")];
    dice.forEach((die, index) => {
      const finalValue = die.dataset.value;
      die.classList.add("is-rolling");
      const timer = window.setInterval(() => {
        die.dataset.value = String(1 + Math.floor(Math.random() * 6));
      }, 95);
      window.setTimeout(() => {
        window.clearInterval(timer);
        die.dataset.value = finalValue;
        die.classList.remove("is-rolling");
      }, 300 + index * 40);
    });
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

  function pileNode(kind, deck) {
    const juego = deck !== "equipo";
    if (kind === "draw") return document.getElementById(juego ? "pila-misterio" : "pila-equipo");
    return document.getElementById(juego ? "pila-descarte-juego" : "pila-descarte-equipo");
  }

  function showGhosts(list) {
    if (!document.querySelector("[data-pile], #mazos-btn")) return;
    const interesting = list.filter((move) => {
      return move.kind === "draw" || move.kind === "discard" || move.kind === "play";
    }).slice(0, 6);

    interesting.forEach((move, index) => {
      window.setTimeout(() => {
        if (!motionOn()) return;
        // El sobre sale de la pila real y aterriza en la pila real: la mesa
        // tiene mazos y descartes a la vista, no un modal escondido.
        const pile = pileNode(move.kind, move.deck);
        const stack = pile ? pile.querySelector(".pile-stack") || pile : null;
        const start = move.kind === "draw" ? (stack || pile)?.getBoundingClientRect() : zoneRect(move.from);
        const end = move.kind === "discard" ? (stack || pile)?.getBoundingClientRect() : (newCardRect(move) || zoneRect(move.to));
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
      ghost.style.backgroundImage = `url("/img/dorso-${move.deck === "juego" ? "misterio" : "equipo"}-thumb.png")`;
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
      context.resume().then(() => {
        if (pendingOutcome) {
          playSound(pendingOutcome);
          pendingOutcome = null;
        }
      }).catch(() => {});
    } else if (context && pendingOutcome) {
      playSound(pendingOutcome);
      pendingOutcome = null;
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
      if (kind === "victoria") {
        victory(context, now);
      } else if (kind === "derrota") {
        defeat(context, now);
      } else if (kind === "dice") {
        diceSound(context, now);
      } else if (kind === "shuffle") {
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
      : (["tirar", "mesa", "reroll"].includes(action) ? "dice" : (action === "nueva" ? "shuffle" : "click"));
    const play = () => {
      playSound(kind);
      write(tab, "xpSoundAt", String(Date.now()));
    };
    const context = audioContext();
    if (context && context.state === "suspended") context.resume().then(play).catch(() => {});
    else play();
  }, true);

  function tone(context, frequency, at, duration, type, volume) {
    const oscillator = context.createOscillator();
    const gain = context.createGain();
    oscillator.type = type || "sine";
    oscillator.frequency.setValueAtTime(frequency, at);
    gain.gain.setValueAtTime(0.0001, at);
    gain.gain.exponentialRampToValueAtTime(volume || 0.07, at + 0.02);
    gain.gain.exponentialRampToValueAtTime(0.0001, at + duration);
    oscillator.connect(gain).connect(context.destination);
    oscillator.start(at);
    oscillator.stop(at + duration + 0.03);
  }

  function victory(context, now) {
    tone(context, 523.25, now, 0.18, "triangle", 0.08);
    tone(context, 659.25, now + 0.12, 0.2, "triangle", 0.08);
    tone(context, 783.99, now + 0.24, 0.32, "triangle", 0.09);
  }

  function defeat(context, now) {
    tone(context, 220, now, 0.32, "sine", 0.09);
    tone(context, 164.81, now + 0.16, 0.5, "sine", 0.09);
    tone(context, 110, now + 0.32, 0.55, "sine", 0.07);
  }

  function diceSound(context, now) {
    [0, 0.05, 0.11, 0.17].forEach((offset) => noise(context, now + offset, "play"));
  }

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
