# Estado de emisoras, registro e importación

## Comprobación de disponibilidad

`StationChecker` comprueba si una emisora responde sin descargar intencionadamente el stream completo ni decodificar audio.

### Comprobación de conexión

`hasInternet()` realiza una resolución DNS de `example.com` con timeout de 4 segundos. Si falla, `StationHealthNotifier` registra un único aviso general y no marca todas las emisoras como caídas.

Esta comprobación es una heurística de conectividad, no una garantía de acceso a todos los dominios o streams.

### Comprobación individual

`check(url)`:

1. Resuelve primero playlists mediante `StreamResolver`.
2. Realiza un GET con respuesta de tipo stream.
3. Usa timeout de conexión/recepción de 6 segundos y timeout total de 10 segundos.
4. Sigue redirecciones, con máximo 4.
5. Considera error los estados HTTP 4xx/5xx.
6. Una vez recibidas las cabeceras, cancela la lectura del stream.
7. Devuelve `null` si considera que la emisora responde, o un mensaje legible si detecta un fallo.

La comprobación no decodifica audio. Una URL que responda HTTP puede seguir sin ser un stream de audio reproducible. Algunos servidores Shoutcast usan respuestas ICY que no se comportan como HTTP convencional; el código intenta no marcarlos como caídos ante errores desconocidos.

### Comprobación masiva

`checkAll` usa una cola y un conjunto de workers; la concurrencia por defecto es 4. El callback se invoca conforme termina cada emisora.

`StationHealthNotifier`:
- solo intenta ejecutarse una vez por ejecución;
- omite el proceso en web por limitaciones CORS;
- espera unos 4 segundos tras iniciar;
- consulta la lista actual;
- actualiza `unavailableStationsProvider` y `errorLogProvider`.

La lista de no disponibles es temporal/en memoria. La comprobación no equivale a una prueba de reproducción.

## Registro de errores

`errorLogProvider` conserva entradas en memoria, no en disco. Cada entrada contiene ID, hora, nivel y mensaje. Niveles observados: `error` y `success`.

- Máximo: 300 entradas.
- Las entradas nuevas aparecen primero.
- Un mensaje repetido con el mismo nivel se reemplaza por una entrada reciente, evitando duplicados.
- Permite eliminar una entrada o limpiar el registro completo.
- Se vacía al reiniciar la app.

`unavailableStationsProvider` guarda IDs de emisoras consideradas no disponibles. La tarjeta puede mostrarlas visualmente como deshabilitadas, pero los controles siguen activos para permitir reintentar.

## Importación y exportación

`StationImporter.parse` devuelve `ImportResult`, con:
- `stations`: emisoras importadas.
- `issues`: incidencias con número de línea, texto original y motivo.

Formatos admitidos:
1. `Nombre;URL;Categoría` (categoría opcional).
2. M3U extendido: `#EXTINF` con nombre y atributo `group-title`, seguido de URL.
3. URL HTTP(S) simple; si no hay nombre, se usa el host.

Las URLs deben empezar por `http://` o `https://`. Las líneas inválidas se añaden a `issues`, en lugar de descartarse silenciosamente.

Importante: las URLs que empiezan por `http` no se separan por `;`, porque algunos streams Shoutcast terminan en `;` (por ejemplo, `http://host:8000/;`).

`toText` exporta como `Nombre;URL;Categoría`. Los puntos y coma en nombre/categoría se sustituyen por comas para no romper el formato.

`StationsNotifier.addMany` evita duplicados por URL exacta y devuelve las emisoras realmente añadidas. La pantalla puede usar ese resultado para mostrar resumen de importación.

## Consideraciones y tests

- Probar importación con URL terminada en `;`.
- Probar M3U con y sin `group-title`.
- Probar líneas inválidas y numeración de incidencias.
- Probar URLs duplicadas y diferencias de normalización.
- Probar 200+ emisoras y límite de concurrencia.
- Probar conectividad ausente, DNS, timeout, 4xx/5xx, redirecciones y respuestas ICY.
- No presentar una emisora como definitivamente rota solo por un fallo transitorio de red.