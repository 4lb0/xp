Db.migrate("xp-games", "CREATE TABLE IF NOT EXISTS games (id INTEGER PRIMARY KEY AUTOINCREMENT, players INTEGER NOT NULL DEFAULT 3, energia INTEGER NOT NULL DEFAULT 6, escudo INTEGER NOT NULL DEFAULT 6, pistas INTEGER NOT NULL DEFAULT 0, turno INTEGER NOT NULL DEFAULT 1, jugador INTEGER NOT NULL DEFAULT 1, status TEXT NOT NULL DEFAULT 'activa', fase TEXT NOT NULL DEFAULT 'listo', pruebaCarta TEXT, pruebaOpcion TEXT, dado1 INTEGER NOT NULL DEFAULT 0, dado2 INTEGER NOT NULL DEFAULT 0, tirado INTEGER NOT NULL DEFAULT 0, bonus INTEGER NOT NULL DEFAULT 0, cebo INTEGER NOT NULL DEFAULT 0, ahorro INTEGER NOT NULL DEFAULT 0, blindajeUsado INTEGER NOT NULL DEFAULT 0, focosUsado INTEGER NOT NULL DEFAULT 0, jugadas INTEGER NOT NULL DEFAULT 0, resueltas INTEGER NOT NULL DEFAULT 0, resultado TEXT, ultimo TEXT, createdAt DATETIME DEFAULT CURRENT_TIMESTAMP)")

Db.migrate("xp-cards", "CREATE TABLE IF NOT EXISTS game_cards (id INTEGER PRIMARY KEY AUTOINCREMENT, gameId INTEGER NOT NULL, cardId TEXT NOT NULL, zone TEXT NOT NULL DEFAULT 'mazo', ord INTEGER NOT NULL DEFAULT 0)")

Db.migrate("xp-log", "CREATE TABLE IF NOT EXISTS game_log (id INTEGER PRIMARY KEY AUTOINCREMENT, gameId INTEGER NOT NULL, text TEXT NOT NULL, createdAt DATETIME DEFAULT CURRENT_TIMESTAMP)")

Db.migrate("xp-giro", "ALTER TABLE games ADD COLUMN giro INTEGER NOT NULL DEFAULT 0")

Db.migrate("xp-suerte", "ALTER TABLE games ADD COLUMN suerte INTEGER NOT NULL DEFAULT 0")

Db.migrate("xp-empujado", "ALTER TABLE games ADD COLUMN empujado INTEGER NOT NULL DEFAULT 0")

Db.migrate("xp-pistas-turno", "ALTER TABLE games ADD COLUMN pistasTurno INTEGER NOT NULL DEFAULT 0")

Db.migrate("xp-saltar", "ALTER TABLE games ADD COLUMN saltar INTEGER NOT NULL DEFAULT 0")

Db.migrate("xp-modo", "ALTER TABLE games ADD COLUMN modo TEXT NOT NULL DEFAULT 'normal'")

Db.migrate("xp-reparado", "ALTER TABLE games ADD COLUMN reparado INTEGER NOT NULL DEFAULT 0")

Db.migrate("xp-apoyo", "ALTER TABLE games ADD COLUMN apoyo INTEGER NOT NULL DEFAULT 0")

Db.migrate("xp-apoyo-carta", "ALTER TABLE games ADD COLUMN apoyoCarta INTEGER")

Db.migrate("xp-apoyo-origen", "ALTER TABLE games ADD COLUMN apoyoOrigen TEXT")

Db.migrate("xp-fase-previa", "ALTER TABLE games ADD COLUMN fasePrevia TEXT")

Db.migrate("xp-blindaje-m", "ALTER TABLE games ADD COLUMN blindajeM INTEGER NOT NULL DEFAULT 0")

Db.migrate("xp-focos-m", "ALTER TABLE games ADD COLUMN focosM INTEGER NOT NULL DEFAULT 0")

// Maniobras que piden tirar un dado antes de elegir la Misión (hoy, el Arpón
// Rastreador). Guarda la fila de game_cards mientras la tirada está pendiente.
Db.migrate("xp-maniobra-row", "ALTER TABLE games ADD COLUMN maniobraRow INTEGER")

// Los descartes de Misión y de Equipo ahora son pilas separadas. Las
// partidas viejas tenían una sola zona 'descarte'; se reparte por el prefijo
// de la carta. Las partidas nuevas ya nacen con las dos zonas.
Db.migrate("xp-descartes", "UPDATE game_cards SET zone = CASE WHEN cardId LIKE 'm%' THEN 'descarteJuego' ELSE 'descarteEquipo' END WHERE zone = 'descarte'")
