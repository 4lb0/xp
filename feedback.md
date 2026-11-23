# Feedback de desarrollo — Bialet

**Fecha:** 23/11/2026
**Versión:** bialet 1.2.27 (macOS, `bialet .` y `bialet -T`)
**App:** XP — Equipo eXPedición (Wren server-rendered, SQLite, un CSS, JS vanilla)
**Contexto:** tres sesiones de trabajo sobre la misma app: rediseño de tipografía y
paleta, arreglos de accesibilidad, favicon/íconos y una regla nueva de juego.

---

## Resumen

Lo estructural anduvo bien: rutas por archivo, sesiones, redirects con POST,
migraciones idempotentes, estáticos anidados y tests contra una base temporal.
Los problemas aparecieron en los bordes: el favicon, el MIME de fuentes, el
chequeo de árbol y el modo silencioso.

## Errores encontrados

### 1. `/favicon.ico` está reservado por el servidor (alto)

Bialet responde `/favicon.ico` con **su propio ícono de bicicleta** e ignora el
archivo del proyecto. No es caché del navegador ni del servidor: es la ruta.

```bash
curl -s http://127.0.0.1:7002/favicon.ico | wc -c      # 15406
magick 'favicon.ico[1]' 32.png                          # bici, 32 bpp
printf 'XXXX' > favicon.ico
curl -s http://127.0.0.1:7002/favicon.ico | wc -c      # 15406 (sigue la bici)
```

- El proyecto tenía un `favicon.ico` de 7.406 B con frames propios; nunca se sirvió.
- El tamaño es siempre el mismo (15.406 B) aunque el archivo pese 4 bytes.
- **Impacto:** si el HTML declara `<link rel="icon" href="/favicon.ico" sizes="any">`,
  la pestaña muestra la bicicleta. Un deploy detrás de un host estático se ve bien
  y el bug aparece sólo en Bialet, que es donde se prueba.
- **Workaround aplicado:** dejar de declarar el `.ico` y usar los PNG
  (`/img/favicon-16.png`, `32`, `48`). Igual quedó el archivo en el repo para
  otros hosts.
- **Pedido:** permitir pisar `/favicon.ico`, o documentar que está reservado.

### 2. Las fuentes salen como `application/octet-stream` (alto)

```bash
curl -sI http://127.0.0.1:7002/css/fonts/archivo-latin.woff2
# Content-Type: application/octet-stream
```

- `.woff2` no tiene MIME en la tabla y no hay forma de declararlo desde la app.
- **Impacto:** Chrome y Firefox aceptan la fuente por el `format("woff2")` del
  `@font-face`, pero Safari es más estricto con el MIME y puede descartarla. En
  un producto donde la tipografía es parte de la marca, es un riesgo silencioso.
- **Pedido:** un mapa MIME configurable (por ejemplo `.bialet-mime` o una entrada
  en `AGENTS`), o al menos `font/woff2`, `font/woff2` y `font/ttf` en la tabla base.

### 3. `bialet check` no sirve con el layout de tests estándar (alto)

```bash
bialet check
# Compilation Error .../_tests/branding.wren line 5 Error at 'Test': Variable is used but not defined.
# ✗ Syntax errors found in: . (8 of 19 files failed)
```

- Recorre `_tests/` y compila cada archivo sin el global `Test`, que sólo existe
  bajo `-T`.
- **Impacto:** el comando de validación de árbol falla en una app sana, así que no
  se puede usar en CI ni como pre-commit. Justo el caso donde más se necesita.
- **Esperado:** excluir `_tests/` en modo check (ya se excluye al servir) o
  inyectar `Test` como global cuando se valida el árbol.

### 4. `-T -q` no es silencioso (medio)

```bash
bialet -T -q 2>&1 | head -3
# 2026-11-23 20:09:27 Log Migration applied - xp-games
# 2026-11-23 20:09:27 Log Migration applied - xp-cards
# 2026-11-23 20:09:27 Log Migration applied - xp-log
```

- `-q` calla el resultado por test pero no los logs: sale una línea por cada
  migración aplicada (hoy 17) más el veredicto.
- **Impacto:** ruido en CI y en cualquier script que parsee la salida.
- **Pedido:** que `-q` silencie también los `Log ...`, o un `-Q` para "sólo el
  veredicto".

### 5. Estáticos sin caché ni compresión (medio)

```bash
curl -sI http://127.0.0.1:7002/css/style.css
# HTTP/1.1 200 OK
# Content-Type: text/css
# Content-Length: 60977
```

- No hay `Cache-Control`, `ETag`, `Last-Modified` ni `Content-Encoding` en CSS,
  fuentes, imágenes ni PDF.
- **Impacto:** cada navegación vuelve a pedir 61 KB de CSS y 90 KB de fuente. En
  producción Cloudflare lo tapa; en LAN, en el aula o con el server pelado, no.
  Además, sin validador el navegador no puede hacer 304.
- **Pedido:** `ETag` + `Cache-Control: no-cache` para HTML y `max-age` largo para
  estáticos versionados (`?v=` ya se usa en la app).

### 6. El literal HTML no se puede usar después de un `if` en un método (medio)

Método que quería devolver dos variantes de una tarjeta:

```wren
static die(value, extra) {
  if (value > 6) return <span class="die die-number">…</span>
  <span class="die">…</span>
}
```

```
Compilation Error /_app/template line 103 Error at end of file: Expect method definition.
Runtime Error Could not compile module '/_app/template'.
Stack Error /juego.wren line 1 (script)
```

- El literal HTML sólo vale como expresión final o en un ternario; después de un
  `if` el parser espera otra definición de método.
- **Impacto:** el mensaje apunta al final del archivo y al módulo que importa, no
  al método ni a la línea real. Se pierden varios minutos hasta encontrar el `if`.
- **Pedido:** mejorar el mensaje (marcar el método y la línea del literal), o
  aceptar el bloque como valor de retorno.

### 7. `-p` es "best effort" y el reinicio se va a otro puerto (bajo)

- Con `-p 7001` ocupado, el server arranca en 7004 sin error; sólo lo dice el
  banner. Al reiniciar quedó en 7002.
- **Impacto:** un script o un test de humo que espera el puerto configurado falla
  con `curl: (7) Failed to connect` (código 000) sin pista del motivo.
- **Pedido:** fallar con error claro si el puerto pedido está ocupado, o un flag
  `--port-strict`.

### 8. Errores de compilación con dos mensajes que se contradicen (bajo)

Cuando un módulo no compila, además del error real aparece
`Stack Error /juego.wren line 1 (script)` y el request devuelve 500. El segundo
mensaje sugiere que el problema está en `juego.wren`, cuando está en el módulo
importado. Conviene uno solo, o que el segundo diga "no se pudo cargar el módulo".

---

## Lo que funcionó bien

- **Rutas por archivo**: `/juego`, `/cartas`, `/reglas` sin configuración, y
  `Request.post` / `Session` / `Response.redirect` sin fricción.
- **Tests con base temporal**: 8 archivos en 1,8 s y `_db.sqlite3` intacta.
- **Prefijo `_` protegido**: `/_db.sqlite3`, `/_app/game.wren`, `/_tests/*` y
  `/.git/config` devuelven 403. Muy bien.
- **Migraciones idempotentes** con `Db.migrate` y `strftime(..., 'localtime')` de SQLite
  resolviendo la zona horaria sin código extra.
- **Estáticos anidados** (`/css/fonts/*.woff2`, `/img/*.png`, `/pdf/*.pdf`) sin
  configurar nada.
- **Modo dev** mostrando el error en el navegador: hizo la iteración mucho más rápida.

## Pedidos, en orden

1. Poder pisar `/favicon.ico` (o documentar que está reservado).
2. Mapa MIME configurable, con `font/woff2` en la tabla base.
3. `check` que ignore `_tests/` o conozca `Test`.
4. `-q` realmente silencioso.
5. `ETag` + `Cache-Control` + gzip para estáticos.
6. Mensajes de compilación que apunten al método y la línea del literal HTML.
