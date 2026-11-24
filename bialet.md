# Bialet 1.2.27 — problemas encontrados en una app real

**Fecha:** 24/11/2026
**Versión probada:** bialet 1.2.27 (macOS, binario instalado; `bialet -v`)
**App:** XP — Equipo eXPedición. Wren server-rendered + SQLite, un CSS, JS vanilla.
6 páginas (`index`, `juego`, `cartas`, `reglas`, `como-jugar`, `editar-cartas`),
4 módulos en `_app/`, una migración con 17 pasos y 8 archivos de test.
Deploy real en `https://xp.iz.ar` detrás de Cloudflare.
**Método:** servidor de desarrollo en `http://127.0.0.1:7002` (`bialet .`), `curl`,
`bialet check`, `bialet -t`, `bialet -T -q` y apps mínimas en directorios temporales
para no tocar el árbol de la app.

> La documentación pública de bialet.dev ya se identifica como 1.2.28. Todo lo de
> abajo está verificado contra el binario **1.2.27** instalado en esta máquina.

## Resumen

| # | Problema | Estado |
|---|---|---|
| 1 | `/favicon.ico` reservado: sirve la bici del framework e ignora el archivo | Confirmado |
| 2 | `.woff2` se sirve como `application/octet-stream` + `nosniff` | Confirmado (local y prod) |
| 3 | `bialet check` falla en una app sana por `_tests/` (`Test` no existe) | Confirmado |
| 4 | `-T -q` no es silencioso: 17 líneas de migraciones por corrida | Confirmado |
| 5 | Estáticos sin `ETag`/`Last-Modified`/`Cache-Control`/compresión; con Cloudflare quedan 4 h de caché | Confirmado (local y prod) |
| 6 | El literal HTML no se puede usar después de un `if` dentro de un método | Confirmado |
| 7 | Sin `-p`, el puerto por defecto se corre en silencio a otro | Confirmado (parcial: `-p` explícito ya falla bien) |
| 8 | Errores de compilación duplicados y contradictorios (`Stack Error ... line 1`) | Confirmado |
| 9 | Una página que es sólo HTML no compila ni se sirve; el error no lo explica | Confirmado |

---

## 1. `/favicon.ico` está reservado y siempre sirve el ícono del framework

### Reproducción

En la app real, con un `favicon.ico` propio de 7.406 B (3 frames, 16/32 px a 8 bpp):

```bash
$ wc -c favicon.ico
7406

$ curl -s http://127.0.0.1:7002/favicon.ico | wc -c
15406

$ curl -sI http://127.0.0.1:7002/favicon.ico
HTTP/1.1 200 OK
Content-Type: image/x-icon
X-Content-Type-Options: nosniff
Content-Length: 15406
```

No es caché: en una app vacía, con un `favicon.ico` de **4 bytes**, la ruta sigue
devolviendo 15.406 B.

```bash
$ mkdir /tmp/favtest && cd /tmp/favtest
$ printf 'ABCD' > favicon.ico
$ printf 'return <p>ok</p>\n' > index.wren
$ bialet . -p 7311
$ curl -s http://127.0.0.1:7311/favicon.ico | wc -c
15406
```

Comparando los frames:

```bash
$ curl -s http://127.0.0.1:7002/favicon.ico -o /tmp/served.ico
$ magick '/tmp/served.ico[1]' /tmp/served32.png    # bicicleta
$ magick 'favicon.ico[1]' /tmp/repo32.png          # monograma XP
```

El servido es la bici (3 frames, 32 bpp); el del repo es el monograma XP.

### Impacto

Cualquier `<link rel="icon" href="/favicon.ico">` muestra la bicicleta de Bialet:
pestaña, marcadores, historial y el ícono que toma un lector de feeds o un
`manifest`. El archivo del repo es válido (monograma XP), así que el problema no
es del asset sino de la ruta. Además ese archivo queda muerto: nadie detecta que
nunca se sirvió.

### Pedido / workaround

**Workaround aplicado:** no declarar el `.ico`; declarar PNGs (verificado,
`image/png`, 200):

```html
<link rel="icon" type="image/png" sizes="32x32" href="/img/favicon-32.png">
<link rel="icon" type="image/png" sizes="16x16" href="/img/favicon-16.png">
<link rel="apple-touch-icon" href="/img/apple-touch-icon.png">
```

El `.ico` queda en el repo para otros hostings.

**Pedido:** que el archivo del proyecto gane en `/favicon.ico`, o que la ruta deje
de estar reservada. Si se mantiene reservada, documentarlo en la página de
estáticos y no devolver 200 silenciosamente.

---

## 2. `.woff2` sale como `application/octet-stream`

### Reproducción

```bash
$ curl -sI http://127.0.0.1:7002/css/fonts/archivo-latin.woff2
HTTP/1.1 200 OK
Content-Type: application/octet-stream
X-Content-Type-Options: nosniff
Content-Length: 90096
```

Los bytes son un WOFF2 válido:

```bash
$ curl -s http://127.0.0.1:7002/css/fonts/archivo-latin.woff2 | head -c 4 | xxd
00000000: 774f 4632                                wOF2
```

En producción pasa lo mismo, y encima queda cacheado 4 h:

```bash
$ curl -sI https://xp.iz.ar/css/fonts/archivo-latin.woff2
content-type: application/octet-stream
cache-control: max-age=14400
cf-cache-status: HIT
age: 5169
```

No hay opción de MIME en `bialet -H`.

### Impacto

Chrome y Firefox aceptan la fuente por el `format("woff2")` del `@font-face`.
Safari es más estricto con el MIME de las fuentes y, sumado a
`X-Content-Type-Options: nosniff`, es un riesgo silencioso de caer a la fuente
del sistema. En una marca donde la tipografía es parte del producto, el bug no
aparece en el navegador donde se desarrolla. No pude probar Safari en este
equipo: el MIME incorrecto y `nosniff` están verificados; la caída en Safari es
el riesgo conocido, no una observación local.

### Pedido / workaround

**Workaround:** servir las fuentes desde un host estático/CDN con MIME correcto,
o incrustarlas como `data:` URI en el CSS (opción conocida, no probada en este
equipo; suma ~33 % al CSS: 86 KB → ~120 KB). Un proxy inverso que reescriba el
`Content-Type` también sirve.

**Pedido:** agregar `font/woff2`, `font/woff`, `font/ttf` y `font/otf` a la tabla
base, y un mapa MIME configurable (por ejemplo `.bialet-mime` o una entrada en
la configuración) para no depender de un release del binario.

---

## 3. `bialet check` falla en una app sana por culpa de `_tests/`

### Reproducción

```bash
$ bialet check
Compilation Error /Users/albo/self/xp/_tests/ambush.wren line 27 Error at 'Test': Variable is used but not defined.
Compilation Error /Users/albo/self/xp/_tests/rules.wren line 7 Error at 'Test': Variable is used but not defined.
Compilation Error /Users/albo/self/xp/_tests/game-deck.wren line 24 Error at 'Test': Variable is used but not defined.
Compilation Error /Users/albo/self/xp/_tests/game-apply.wren line 27 Error at 'Test': Variable is used but not defined.
Compilation Error /Users/albo/self/xp/_tests/cards.wren line 8 Error at 'Test': Variable is used but not defined.
Compilation Error /Users/albo/self/xp/_tests/juego-flow.wren line 47 Error at 'Test': Variable is used but not defined.
Compilation Error /Users/albo/self/xp/_tests/game-resolve.wren line 38 Error at 'Test': Variable is used but not defined.
Compilation Error /Users/albo/self/xp/_tests/branding.wren line 5 Error at 'Test': Variable is used but not defined.
✗ Syntax errors found in: . (8 of 19 files failed)
$ echo $?
1
```

Los 19 archivos son los 11 de la app más los 8 de `_tests/`. Los 8 que fallan son
exactamente los tests. La misma app, con el runner:

```bash
$ bialet -T
0 of 8 tests failed in 2082ms
```

`check` compila los tests sin el global `Test`, que sólo existe bajo `-T`. Peor:
la lista de ignore no aplica a `check`, así que no hay forma de excluirlos por
configuración.

```bash
$ bialet check -i "_tests/*"
...
✗ Syntax errors found in: . (8 of 19 files failed)
```

### Impacto

El comando de validación de árbol falla en una app sana: no se puede usar como
pre-commit ni en CI, justo donde más se necesita. La salida además contradice al
runner de tests de la misma versión.

### Pedido / workaround

**Workaround verificado** (valida los 11 archivos de la app en unos segundos):

```bash
find . -name '*.wren' -not -path './_tests/*' -not -path './.git/*' -print0 \
  | xargs -0 -n1 bialet -t
# 11 × ✓ Syntax OK
```

**Pedido:** que `check` excluya `_tests/` (como ya hace el servidor) o inyecte
`Test` como global al validar el árbol. Y que `-i` también se aplique a `check`.

---

## 4. `-T -q` no es silencioso: imprime una línea por migración

### Reproducción

```bash
$ bialet -T -q
2026-11-24 08:55:23 Log Migration applied - xp-games
2026-11-24 08:55:23 Log Migration applied - xp-cards
2026-11-24 08:55:23 Log Migration applied - xp-log
...
2026-11-24 08:55:23 Log Migration applied - xp-descartes
2026-11-24 08:55:23 Migration start
0 of 8 tests failed in 1849ms
```

`-q` no cambia nada de esas líneas: 19 líneas en total (17 migraciones +
`Migration start` + veredicto), y siempre con timestamp. Los logs van a stdout
(el resumen de `check`, en cambio, sale por stderr).

### Impacto

Ruido en CI y en cualquier script que parsee la salida. `-q` promete suprimir
"browser auto-open and colored output", pero no hay un modo de obtener sólo el
veredicto, que es lo que un pipeline necesita.

### Pedido / workaround

**Workaround:**

```bash
bialet -T -q 2>&1 | grep -vE 'Log Migration applied|Migration start'
# 0 of 8 tests failed in 1849ms
```

**Pedido:** que `-q` silencie también los `Log ...` (o agregar `-Q` para "sólo el
veredicto"). Si las migraciones se aplican a una base temporal en cada corrida,
tampoco hace falta contarlas una por una.

---

## 5. Estáticos sin validadores, sin caché y sin compresión; Cloudflare tapa el agujero con 4 h de caché

### Reproducción (origen, sin CDN)

```bash
$ curl -sI http://127.0.0.1:7002/css/style.css
HTTP/1.1 200 OK
Content-Type: text/css
X-Content-Type-Options: nosniff
Connection: close
Content-Length: 86661
```

No hay `Cache-Control`, `ETag`, `Last-Modified` ni `Content-Encoding`. Tampoco
hay compresión al pedirla, ni respuesta condicional:

```bash
$ curl -sI -H 'Accept-Encoding: gzip, br' http://127.0.0.1:7002/css/style.css
# igual: 200, sin Content-Encoding

$ curl -sI -H 'If-Modified-Since: Tue, 24 Nov 2026 10:00:00 GMT' \
    http://127.0.0.1:7002/css/style.css
# 200 OK, Content-Length: 86661 (cuerpo completo, no 304)
```

Cada respuesta además cierra la conexión (`Connection: close`), así que CSS,
cuatro fuentes e imágenes implican una conexión TCP por archivo.

### Reproducción (producción, detrás de Cloudflare)

```bash
$ curl -sI https://xp.iz.ar/css/style.css
cache-control: max-age=14400
cf-cache-status: EXPIRED        # después HIT, age: 415
last-modified: Tue, 24 Nov 2026 11:50:39 GMT
vary: accept-encoding
```

El `last-modified` no coincide con el `mtime` del archivo (08:57 local = 11:57
GMT): coincide con el momento en que se llenó la caché. No es un validador del
archivo; el origen no manda ninguno y el TTL de navegador que llega al cliente es
de 4 h. La compresión también la agrega la cadena CDN/proxy:

```bash
$ curl -s -H 'Accept-Encoding: br,gzip' -D - -o /dev/null https://xp.iz.ar/css/style.css
content-encoding: gzip          # 16.559 B sobre 86.269 B
```

Las fuentes quedan cacheadas igual, con la misma URL para siempre:

```bash
$ grep -n 'woff2' css/style.css | head -1
9:  src: url("/css/fonts/archivo-latin.woff2") format("woff2");
```

### Caso real: el bug de la columna en móvil

El 23/11 a las 22:29 se arregló la mesa de Misterios para que fuera a una columna
en móvil (`ea8a058`). El teléfono siguió viendo dos columnas porque la URL del
CSS no cambiaba y Cloudflare/browser servían la hoja vieja. A las 22:51 hubo que
hacer un segundo commit sólo para subir `Layout.assetVersion` (`1f2d2ef`):

> "El CSS se cachea 4 horas con max-age y la URL no cambiaba desde antes del
> rediseño: el celular seguía bajando la hoja vieja, por eso la mesa seguía en
> dos columnas."

O sea: el arreglo visual no llegó hasta que se inventó una URL nueva. Con
`?v=` el cache-busting funciona (verificado: URL nueva → `cf-cache-status:
MISS`), pero es manual y no cubre las fuentes, que van sin versión dentro del
CSS: cambiar una fuente y subir `assetVersion` deja la fuente vieja 4 h.

### Impacto

- **Sin CDN** (LAN, aula, server pelado): 86 KB de CSS y 90 KB de fuente por
  navegación, sin validadores para hacer 304 y con una conexión nueva por asset.
- **Con CDN**: 4 h de ventana de desactualización para CSS y fuentes; cada
  cambio de CSS exige acordarse de subir `assetVersion`; cada cambio de fuente
  exige además tocar las cuatro URLs del CSS o purgar Cloudflare.
- El `last-modified` sintético no sirve para revalidar: no refleja el archivo.

### Pedido / workaround

**Workaround aplicado:** subir `Layout.assetVersion` en cada cambio de CSS (ya
está automatizado en el proceso del repo) y purgar Cloudflare en el deploy.

**Pedido:**

- `ETag` y `Last-Modified` reales para estáticos.
- `Cache-Control: public, max-age=31536000, immutable` para URLs versionadas y
  `no-cache` para las que no lo están.
- gzip/brotli para texto (CSS, JS, HTML, SVG) en origen.
- keep-alive en vez de `Connection: close`.

Mientras tanto, servir las fuentes desde un host con caché y MIME correctos, o
versionar también sus URLs (`...woff2?v=...`).

---

## 6. El literal HTML no se puede usar después de un `if` dentro de un método

### Reproducción

```wren
class Tarjeta {
  static cara(valor) {
    if (valor > 6) {
      return "grande"
    }
    <span class="cara">{{ valor }}</span>
  }
}
```

```bash
$ bialet -t tarjeta.wren
Compilation Error /tmp/tarjeta.wren line 7 Error at '}': Expect newline after statement.
Compilation Error /tmp/tarjeta.wren line 9 Error at end of file: Expect method definition.
✗ Syntax errors found in: tarjeta.wren
```

El archivo termina en la línea 8; el segundo error apunta a la 9. La misma falla
con el `if` de una línea:

```wren
if (valor > 6) return "grande"
<span class="cara">{{ valor }}</span>
```

Con el literal HTML como única expresión del método, compila. Con el literal
después de cualquier sentencia, no. Tampoco dentro de un bloque con llaves:

```wren
if (valor > 6) { return <b>grande</b> }   # Error at 'return': Expected expression.
```

En runtime, el request devuelve 500 genérico y el log agrega dos mensajes que
mandan a otro lado (ver problema 8):

```text
Compilation Error /app/_app/tarjeta line 7 Error at '}': Expect newline after statement.
Compilation Error /app/_app/tarjeta line 9 Error at end of file: Expect method definition.
Runtime Error Could not compile module '/app/_app/tarjeta'.
Stack Error /app/juego.wren line 1 (script)
Request GET /juego status=500 bytes=724
```

### Impacto

El error apunta al final del archivo (en la app real, a la línea 103 de una
plantilla) y no al `if` ni al literal. El `Stack Error` sugiere que el problema
está en la página que importa, no en el método. Se pierden varios minutos hasta
encontrar la sentencia.

### Pedido / workaround

**Workarounds verificados:**

```wren
// 1) ternario en una expresión
var out = valor > 6 ? <b>grande</b> : <i>chico</i>

// 2) return por rama, sin bloque
if (valor > 6) return <b>grande</b>
return <i>chico</i>
```

**Pedido:** aceptar el literal como valor de retorno después de sentencias
(al menos como última expresión de un bloque), o mejorar el mensaje: marcar el
método y la línea del literal en vez de "end of file".

---

## 7. Sin `-p`, el puerto por defecto se corre en silencio

> Este ítem cambió al verificarlo: en 1.2.27 un `-p` **explícito** ya falla con
> error claro. La parte que sigue pasando es la del puerto por defecto.

### Reproducción

Con `-p` explícito y el puerto ocupado, el comportamiento es correcto:

```bash
$ bialet . -p 7001          # 7001 ocupado por otro proceso
2026-11-24 08:58:19 Could not bind port 7001 - Check if the port is already in use.
$ echo $?
1
```

Sin `-p`, con 7001 y 7002 ocupados:

```bash
$ bialet .
2026-11-24 08:53:27 🚲 bialet is riding on http://127.0.0.1:7003
```

Arranca en 7003 sin error ni explicación; el único aviso es el banner. Un script
que espera `127.0.0.1:7001` puede terminar hablando con el otro proceso que
ocupaba el puerto (en la prueba, un servidor ajeno respondió 200); si el ocupante
no habla HTTP, el síntoma es el `curl: (7)` / código `000` ya reportado.

### Impacto

Un test de humo, un `wait-for-port` o un README que asume 7001 falla de forma
confusa, o peor, valida la app equivocada. En CI el fallback silencioso convierte
un puerto ocupado en un resultado engañoso.

### Pedido / workaround

**Workaround:** pasar siempre `-p` en scripts y CI; ahí el error es explícito.

**Pedido:** que el puerto por defecto también sea estricto, o un flag
`--port-strict` / `BIALET_PORT_STRICT=1` para que el fallback sea opt-in. Si se
mantiene el fallback, que el banner diga "7001 ocupado, usando 7003".

---

## 8. Errores de compilación duplicados y contradictorios

### Reproducción

Con un módulo que no compila e importado por una página, el log del servidor
muestra cuatro mensajes para un solo error de origen:

```text
Compilation Error /app/_app/tarjeta line 7 Error at '}': Expect newline after statement.
Compilation Error /app/_app/tarjeta line 9 Error at end of file: Expect method definition.
Runtime Error Could not compile module '/app/_app/tarjeta'.
Stack Error /app/juego.wren line 1 (script)
Request GET /juego status=500 bytes=724
```

`tarjeta` es el módulo roto; `juego.wren` sólo lo importa. El `Stack Error`
siempre dice "line 1 (script)", sin relación con el import ni con el método. La
ruta del módulo perdió el `.wren` (`_app/tarjeta`), lo que complica buscarlo.

En `check` también se duplica: si una página importa el módulo roto, los mismos
dos errores salen dos veces.

```text
Compilation Error /tmp/dup/_app/bad.wren line 5 Error at '}': Expect newline after statement.
Compilation Error /tmp/dup/_app/bad.wren line 7 Error at end of file: Expect method definition.
Compilation Error /tmp/dup/_app/bad.wren line 5 Error at '}': Expect newline after statement.
Compilation Error /tmp/dup/_app/bad.wren line 7 Error at end of file: Expect method definition.
✗ Syntax errors found in: . (2 of 2 files failed)
```

### Impacto

El mensaje que más se lee (`Stack Error .../juego.wren line 1`) es el que menos
información tiene y apunta a un archivo sano. En una app con imports anidados
hay que reconstruir a mano cuál módulo falló. Los errores repetidos tapan el
error real en salidas largas de CI.

### Pedido / workaround

**Workaround:** buscar en el log la primera línea `Compilation Error` con ruta de
`_app/`; es la única que importa.

**Pedido:** un solo mensaje por error, con la ruta completa (con `.wren`) y la
línea real; el fallo de import como "no se pudo compilar el módulo X" una vez, y
sin `Stack Error` de la página que importa. En `check`, deduplicar por archivo.

---

## 9. Una página que es sólo HTML no compila ni se sirve, y el error no lo dice

### Reproducción

```bash
$ printf '<h1>ok</h1>\n' > solo-html.wren
$ bialet -t solo-html.wren
Compilation Error /tmp/solo-html.wren line 1 Error at '<': Expected expression.
Compilation Error /tmp/solo-html.wren line 1 Error at 'h1': Expect end of file.
✗ Syntax errors found in: solo-html.wren
```

Servida como página (el mismo archivo copiado a `index.wren`), devuelve 500:

```bash
$ curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:7314/
500
```

```text
Compilation Error .../index.wren line 1 Error at '<': Expected expression.
Compilation Error .../index.wren line 1 Error at 'h1': Expect end of file.
Request GET / status=500 bytes=724
```

Con `return` delante sí funciona (y es lo que muestran los ejemplos de la doc):

```wren
return <h1>ok</h1>
```

Un archivo con una sentencia antes del literal también compila
(`var x = 1` + `<h1>ok</h1>`).

### Impacto

Es la primera página que escribe alguien que arranca con "HTML server-rendered":
un `.wren` con HTML y nada más. El error habla de expresiones de Wren y no de que
falta un `return`, así que parece un problema del framework o de la sintaxis HTML.

### Pedido / workaround

**Workaround:** empezar la página con `return` (o con cualquier sentencia).

**Pedido:** aceptar el archivo que es sólo un literal HTML, o un mensaje del
tipo "una página debe devolver el HTML con `return`". Si es intencional, que la
documentación de páginas lo diga en la primera línea.

---

## Lo que funcionó bien

- **Rutas por archivo**: `/`, `/juego`, `/cartas`, `/reglas`, `/como-jugar`,
  `/editar-cartas` devuelven 200 sin configuración; `/no-existe` devuelve 404
  limpio (714 B).
- **Sesiones**: `Session.new()` + `set/get` funcionan; cookie `BIALETSESSID`
  `HttpOnly`, `SameSite=Lax`, `Secure` en producción.
- **Redirects**: `Response.redirect("/destino")` devuelve 302 con `Location`
  correcto, también después de un POST.
- **Migraciones idempotentes**: al arrancar sobre la base existente sólo se ve
  `Migration start`; los 17 `Log Migration applied` aparecen únicamente en la
  base temporal nueva. `Db.migrate` con nombre no repite el trabajo.
- **Tests con base temporal**: `bialet -T` corre los 8 archivos en ~1,8–2,1 s y
  no toca `_db.sqlite3` (mtime intacto, verificado antes/después).
- **Prefijo `_` protegido**: `/_db.sqlite3`, `/_app/template.wren`,
  `/_tests/cards.wren`, `/_migration.wren` y `/.git/config` devuelven 403.
- **Estáticos anidados**: `/css/style.css`, `/css/fonts/*.woff2`,
  `/img/*.png`, `/img/*.jpg` y `/pdf/*.pdf` se sirven sin configuración; PNG,
  JPEG y PDF con el MIME correcto.
- **HTML dinámico**: `Cache-Control: no-store` en las páginas, lo que evita
  repetir el problema de caché del lado del HTML.
- **`-t` por archivo**: valida un `.wren` suelto en milisegundos y fue el
  workaround usable para el problema 3.

## Pedidos, en orden de prioridad

1. **`check` que entienda `_tests/`** (excluirlos o inyectar `Test`) y que
   respete `-i`. Es lo que bloquea CI hoy.
2. **Poder pisar `/favicon.ico`**, o documentar que está reservado.
3. **MIME configurable**, con `font/woff2` (y `woff`, `ttf`, `otf`) en la tabla
   base.
4. **Validadores y caché en estáticos**: `ETag`, `Last-Modified`,
   `Cache-Control` según versión, compresión y keep-alive. Documentar el efecto
   combinado con Cloudflare y cómo versionar fuentes.
5. **`-q` realmente silencioso** (o un `-Q` de sólo veredicto).
6. **Literal HTML después de sentencias**: aceptarlo o marcar la línea real.
7. **Mensaje claro para una página que es sólo HTML**.
8. **Puerto por defecto estricto** (o fallback explícito/opt-in).
9. **Un solo error de compilación**, con ruta completa y sin `Stack Error` de la
   página que importa.

## Anexo: qué no se reprodujo

- **`-p` explícito "best effort"**: ya no. En 1.2.27, con el puerto ocupado,
  falla con `Could not bind port 7001 - Check if the port is already in use.` y
  sale con código 1. Sólo queda el fallback silencioso cuando se omite `-p`
  (problema 7).
- **Error de compilación con un solo mensaje `Error at end of file`**: en esta
  versión salen dos errores de compilación (el de la llave y el del EOF) además
  del `Stack Error`. La confusión sigue, con más ruido (problema 8).
- **Tamaño del CSS**: cambia mientras se edita la app; los 86.661 B citados son
  la medición del 24/11 a las 09:00, no una constante del framework.
