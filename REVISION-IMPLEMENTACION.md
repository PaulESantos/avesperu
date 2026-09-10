# Revisión de debilidades de implementación

Fecha: 8 de septiembre de 2026 (America/Lima). Paquete: avesperu 0.1.1.
Referencia Git: `9f286a7feb84f5d9d966188eefccfa535b87a12e`.

## Actualización: correcciones implementadas

El usuario autorizó implementar las correcciones después de esta
revisión. Los once hallazgos se han corregido y tienen regresiones
automatizadas. También se atendieron los cuatro riesgos adicionales:
validación del esquema, procedencia efectiva, lectura de fechas UNOP y
ejecución concurrente de Shiny. La revisión original que sigue se
conserva como evidencia histórica; sus referencias de línea corresponden
al commit inicial, no al código actualizado.

La validación ampliada descubrió dos discrepancias reales entre el
nombre científico y sus componentes en los datos. Se conservaron los
nombres científicos, se derivaron componentes consistentes y se
guardaron los valores fuente en el atributo `component_corrections`. No
se hizo una revisión taxonómica externa.

Consultar
[VALIDACION-IMPLEMENTACION.md](https://paulesantos.github.io/avesperu/VALIDACION-IMPLEMENTACION.md)
para pruebas, límites y resultados;
[DECISIONES-REVISION.md](https://paulesantos.github.io/avesperu/DECISIONES-REVISION.md)
registra las políticas adoptadas y la sustitución del alcance inicial.

## Alcance y estado

Revisión de la búsqueda, normalización, importación, estado y
exportación de Shiny, procesamiento paralelo, construcción de datos y
pruebas existentes. Se inspeccionaron `R/`, `tests/testthat/`,
`data-raw/`, `app.R`, `deploy_shinyapps.R`, `DESCRIPTION` y los
resúmenes históricos de mejoras. No se modificó código de producción,
datos ni pruebas. No se desplegó la app.

Las estrategias siguientes son propuestas, no decisiones de
implementación aprobadas. Las decisiones efectivamente tomadas se
registran en
[DECISIONES-REVISION.md](https://paulesantos.github.io/avesperu/DECISIONES-REVISION.md).

P1: priorizar por pérdida silenciosa, interpretación incorrecta o
alcance global. P2: corregir por contrato, consistencia,
reproducibilidad o cobertura. «Reproducido» significa ejecutado contra
el código local; «estático» identifica una ruta demostrable por lectura;
«riesgo» requiere validación adicional.

## Resumen priorizado

| ID | Prioridad | Debilidad | Evidencia |
|----|----|----|----|
| H01 | P1 | CSV/TSV sin encabezado pierde la primera fila | Reproducido con CSV |
| H02 | P1 | Calificadores e híbridos terminan como exactos sin revisión | Reproducido |
| H03 | P1 | Empates fuzzy dependen del orden de la base | Reproducido con fixture |
| H04 | P1 | Botón de cierre modifica el estado global de Shiny | Estático y código de Shiny local |
| H05 | P2 | Clear y carga fallida conservan estado anterior | Reproducido con testServer |
| H06 | P2 | Normalización no idempotente para CF./AFF. | Reproducido con CF. |
| H07 | P2 | Validación incompleta de NA, infinitos y enteros | Reproducido |
| H08 | P2 | Entrada vacía devuelve NULL y rompe el contrato | Reproducido |
| H09 | P2 | batch_size no se aplica en modo secuencial | Reproducido con trace |
| H10 | P2 | Pruebas no ejercitan algunas ramas que afirman verificar | Estático, suite ejecutada |
| H11 | P2 | Autorías se clasifican como rango infraespecífico | Reproducido |

## Hallazgos

### H01. Importación omite registros y pierde identidad de filas

**Ubicación:** `R/shiny-app.R:157-168`; conversión de Excel en `:135`.

El lector intenta `header = TRUE` y solo prueba `FALSE` cuando hay error
o ninguna columna. Un archivo sin encabezado es perfectamente legible
con `header = TRUE`: su primera especie se convierte en nombre de
columna.

**Reproducción:** un CSV con dos líneas, `Falco sparverius` y
`Tinamus osgoodi`, devolvió únicamente `"Tinamus osgoodi"`. La rama TSV
usa el mismo mecanismo; no se ejecutó un caso TSV separado. Además, una
celda ausente leída como `NA` se convierte en texto `"NA"` al pasar por
[`paste()`](https://rdrr.io/r/base/paste.html). Las líneas vacías se
eliminan y `input_order` se genera después, por lo que no identifica la
fila original del archivo.

**Impacto:** pérdida silenciosa de una observación y dificultades para
unir los resultados con el archivo de origen.

**Propuesta:** hacer explícitos encabezado y columna, mostrar una vista
previa cuando haya ambigüedad y conservar `source_file`, `source_row` y
valores ausentes como datos estructurados, sin convertir toda la columna
en un bloque de texto.

**Aceptación:** archivos con/sin encabezado y con una sola especie no
pierden filas; vacíos y NA mantienen identidad; CSV, TSV y Excel
conservan la fila fuente.

### H02. La limpieza elimina incertidumbre sin conservarla en el resultado

**Ubicación:** `R/internals.R:24-33`; `R/shiny-app.R:254-277`.

Se eliminan `cf.`, `aff.` y marcadores de híbridos antes de buscar.
Shiny clasifica por distancia al nombre ya limpio y solo marca revisión
si el resultado no es exacto. La advertencia sobre híbridos no queda
como bandera persistente en la fila; para `cf.` ni siquiera hay esa
advertencia.

**Reproducción:** `build_resolution_results("Falco cf. sparverius")`
devuelve `match_type = "exact"` y `review_flag = FALSE`.
`"Falco x sparverius"` produce las mismas banderas, aunque emite
advertencias.

**Impacto:** una identificación originalmente calificada se presenta
como coincidencia que no necesita revisión. En la API básica tampoco se
conserva el texto original: `name_submitted` contiene el valor
estandarizado.

**Propuesta:** separar original, nombre de búsqueda y marcas de
interpretación; mantener una bandera de revisión por
calificadores/híbridos independientemente de la distancia. Definir
explícitamente la política de aceptación de estos casos.

**Aceptación:** la coincidencia textual exacta no borra calificadores;
las exportaciones conservan motivo de revisión y transformaciones
aplicadas.

### H03. El desempate automático no representa la ambigüedad

**Ubicación:** `R/get_avesperu.R:294-298`.

[`which.min()`](https://rdrr.io/r/base/which.min.html) elige el primer
candidato a distancia mínima. No se registra cuántos candidatos empatan
ni se ofrecen alternativas.

**Reproducción controlada:** para `Testus albi`, una base de dos filas
con `Testus alba` y `Testus albe` devuelve `Testus alba`. Invertir las
filas cambia el resultado a `Testus albe`, manteniendo distancia 1. Son
nombres sintéticos para aislar la lógica; no se afirma que esos nombres
estén en el checklist.

**Impacto:** un cambio de orden de la referencia puede cambiar la
especie aceptada y su estatus sin cambiar la evidencia de similitud.

**Propuesta:** devolver estado ambiguo, número de candidatos y
alternativas; separar sugerencia de aceptación automática. Definir la
política antes de cambiar la salida pública. Ordenar alfabéticamente no
resuelve la ambigüedad.

**Aceptación:** permutar la referencia mantiene el conjunto de
alternativas y la condición de ambigüedad; no se acepta una especie por
posición de fila.

### H04. El cierre de una sesión usa una operación global de aplicación

**Ubicación:** `R/shiny-app.R:1084-1085`; contexto de despliegue en
`app.R` y `deploy_shinyapps.R`.

El botón de cualquier sesión ejecuta
[`shiny::stopApp()`](https://rdrr.io/pkg/shiny/man/stopApp.html). Se
inspeccionó su implementación local, Shiny 1.14.0: modifica
`.globals$stopped` y llama a
[`httpuv::interrupt()`](https://rstudio.github.io/httpuv/reference/interrupt.html).
No es una operación de cierre limitada a `session`.

**Impacto:** en una instancia compartida puede detener el servicio de
las sesiones atendidas por ese proceso. El alcance exacto en
shinyapps.io depende del hospedaje; no se desplegó ni se detuvo una
instancia para probarlo.

**Propuesta:** usar cierre de sesión en modo hospedado y reservar el
cierre global para una modalidad local explícita.

**Aceptación:** cerrar una sesión no interrumpe otra conectada al mismo
proceso; una prueba de integración verifica ambas modalidades sin tocar
producción.

### H05. El estado visible y los datos disponibles pueden divergir

**Ubicación:** `R/shiny-app.R:1063-1066`, `:1075-1078`, `:1168` y
`:1297`.

`Clear` vacía entradas, pero el resultado depende exclusivamente de
Submit y permanece almacenado. Una carga nueva que falla deja intacto
`uploaded_names()`.

**Reproducción con
[`shiny::testServer()`](https://rdrr.io/pkg/shiny/man/testServer.html):**
después de resolver una fila y ejecutar Clear, `combined_names()` tenía
longitud 0 y los resultados conservaban 1 fila. Después de cargar un TXT
válido y reemplazarlo por una extensión inválida, `uploaded_names()`
conservó `Falco sparverius` del archivo anterior.

**Impacto:** se pueden exportar resultados anteriores después de limpiar
o procesar datos del archivo anterior tras fallar su reemplazo. La app
sí muestra una notificación de error de carga, pero no modela un estado
inválido de entrada.

**Propuesta:** definir estados explícitos de entrada, ejecución y
resultado; Clear debe invalidar resultados y descargas. Una carga
fallida debe invalidar la entrada o mostrar claramente que se conserva
el archivo anterior con su identidad. Si se conserva una ejecución
anterior al editar entradas, etiquetarla como tal y marcar que hay
cambios pendientes.

**Aceptación:** pruebas de sesión cubren resolver → limpiar → descargar
y cargar válido → cargar inválido → enviar; nunca se usan datos de
origen ambiguo.

### H06. La normalización cambia al aplicarla por segunda vez

**Ubicación:** `R/internals.R:33` y capitalización posterior;
`R/shiny-app.R:238-242`.

La eliminación de `cf.` y `aff.` distingue mayúsculas, pero se pasa a
minúsculas después. `standardize_names("Falco CF. sparverius")` devuelve
`"Falco cf. sparverius"`; normalizar ese resultado devuelve
`"Falco sparverius"`. En Shiny, el mismo caso en mayúsculas quedó
unmatched mientras el de minúsculas quedó exacto. El wrapper además
normaliza para metadatos y vuelve a normalizar el original dentro de la
búsqueda, duplicando advertencias de híbridos.

**Propuesta:** establecer una normalización idempotente y límites de
token claros; interpretar calificadores sin borrarlos del registro de
procedencia. Compartir una única representación normalizada entre
parsing y búsqueda.

**Aceptación:** `normalize(normalize(x))` coincide con `normalize(x)`;
variantes de mayúsculas de los calificadores tienen igual tratamiento y
una sola advertencia.

### H07. La validación permite valores que rompen o cambian el procesamiento

**Ubicación:** `R/get_avesperu.R:125-151`, `:263-265`.

No se excluyen explícitamente NA/NaN ni infinitos, ni se verifica
integridad de los parámetros anunciados como enteros.

**Resultados observados:**

- `max_distance = NA_real_`: error genérico
  `missing value where TRUE/FALSE needed`.
- `return_details = NA`: el mismo error, después de buscar.
- `max_distance = Inf` con `Falko sparverius`: devuelve NA y avisa de
  conversión fuera de rango a entero; no rechaza el parámetro de forma
  controlada.
- `batch_size = 1.5, n_cores = 1.5` con una especie exacta: acepta ambos
  valores.

**Propuesta:** validar escalares no ausentes y finitos, integridad y
rango antes de cargar/procesar datos. Aclarar la semántica del umbral:
entre 0 y 1 es proporción con
[`ceiling()`](https://rdrr.io/r/base/Round.html), pero 1 es una edición
absoluta; valores absolutos fraccionarios actualmente se truncan.
También validar la opción `mc.cores` y la eventual ausencia de resultado
de `detectCores()`.

**Aceptación:** matriz de NA, NaN, Inf, longitudes incorrectas y
fracciones produce errores informativos por argumento; exactos y fuzzy
validan igual. La política de redondeo y la frontera en 1 quedan
documentadas y probadas.

### H08. La entrada vacía no devuelve un objeto del tipo documentado

**Ubicación:** `R/get_avesperu.R:303-306`, `:189-205`;
`tests/testthat/test-search-avesperu.R:75-78`.

`do.call(rbind, list())` devuelve NULL. Tanto la búsqueda vacía
detallada como la básica devuelven NULL. La prueba existente solo
comprueba longitud cero, que NULL también satisface.

**Impacto:** consumidores que esperan una tabla con columnas o un vector
character necesitan excepciones y pueden fallar al encadenar
operaciones.

**Propuesta:** retorno temprano con `character(0)` o tabla de cero filas
y las ocho columnas tipadas, según `return_details`.

**Aceptación:** verificar tipo, nombres de columnas y número de filas,
además de longitud; probar los wrappers con entradas vacías.

### H09. Desactivar paralelismo también desactiva los lotes

**Ubicación:** `R/get_avesperu.R:177-187`.

La condición `n_unique <= batch_size || !parallel` dirige cualquier
ejecución secuencial al motor completo, aunque haya más nombres que el
tamaño de lote. Se instrumentó `search_with_agrep_batched()` con
[`trace()`](https://rdrr.io/r/base/trace.html) y una consulta de dos
nombres únicos, `batch_size = 1, parallel = FALSE`, no ingresó en esa
función.

**Impacto:** el control de lotes mostrado por Shiny en su modo
secuencial por defecto no se aplica; tampoco se obtiene el progreso por
lotes esperado. No se midió consumo de memoria, por lo que no se
cuantifica una mejora potencial.

**Propuesta:** separar elección de lotes y elección de ejecutor. Primero
decidir si dividir; luego usar lapply o clúster. El agrupamiento actual
conserva todos los resultados, así que no debe prometer memoria total
acotada sin otro diseño.

**Aceptación:** comprobar ingreso real en la rama y tamaños de los
lotes; comparar valores y orden entre modos con duplicados, NA, exactos
y fuzzy.

### H10. Parte de la suite da garantías que sus escenarios no comprueban

**Ubicación:** `tests/testthat/test-parallel-processing.R:3`, `:24`,
`:87`, `:168`; prueba vacía referenciada en H08.

- La prueba de igualdad paralelo/secuencial usa tres nombres y
  batch_size predeterminado 100: ambas llamadas son secuenciales.
- La prueba de batching usa `parallel = FALSE`: activa H09, no los
  lotes.
- La prueba de detección automática también desactiva el paralelismo.
- La prueba de recuperación ante fallo de clúster usa dos nombres, lote
  100 y no inyecta ningún fallo: no crea clúster ni comprueba
  recuperación.

Sí hay otras pruebas que crean clústeres de uno y dos trabajadores; no
se afirma ausencia total de pruebas paralelas. La suite completa pasó en
esta revisión. No se encontraron pruebas `testServer` en la suite
existente.

**Propuesta:** probar la rama ejecutada y el resultado; inyectar fallo
de creación de clúster de manera controlada y comprobar advertencia,
fallback y limpieza. Añadir regresiones centradas en los casos de este
informe y sesiones Shiny.

**Aceptación:** una regresión en esas ramas hace fallar su prueba
correspondiente; la equivalencia paralela fuerza más nombres únicos que
batch_size e incluye fuzzy.

### H11. El parser confunde texto adicional con rango infraespecífico

**Ubicación:** `R/shiny-app.R:187-199`.

Todo nombre con tres o más tokens se etiqueta `infraspecific`.
`extract_name_parts("Falco sparverius Linnaeus, 1758")` devuelve
`submitted_infraspecific = "Linnaeus, 1758"` y rango `infraspecific`. El
campo se llama `rank_guess`, pero la inferencia no discrimina autorías.

**Impacto:** los componentes exportados pueden usarse como datos
taxonómicos cuando en realidad representan texto no interpretado.

**Propuesta:** definir el formato admitido; reconocer autorías y
marcadores de rango o devolver `unparsed` con texto restante y motivo de
revisión.

**Aceptación:** distinguir binomios con autor, trinomios, abreviaturas
de rango y texto desconocido sin inventar un rango para este último.

## Riesgos adicionales pendientes de validación

Estos puntos no se contabilizan como defectos reproducidos.

- **Construcción de referencia:** `data-raw/table_from_excel.R:61-78`
  depende de `skip = 18` y renombra por posición. Un cambio de orden con
  igual número de columnas puede pasar inadvertido. Hay validación de
  duplicados y códigos, pero falta validar relación
  nombre/género/epíteto y campos taxonómicos obligatorios antes de
  `use_data(overwrite = TRUE)`. Probar fuentes alteradas de forma
  controlada y validar esquema por contenido. La base actual comprobada
  tiene 1925 filas, cero nombres duplicados y cero nombres diferentes de
  su estandarización; no se detectó corrupción actual ni se reconstruyó
  la base.
- **Procedencia efectiva:** `app.R:5-14` usa el paquete instalado si
  existe, aunque el checkout contenga otro código. La resolución fija
  `aves_peru_2026_v1` en varias funciones y los metadatos registran
  opciones solicitadas, no número real de trabajadores o fallback.
  Probar con versión instalada distinta; proponer origen explícito,
  identificador de referencia y configuración efectiva en resultados. No
  se comparó un despliegue remoto.
- **Consulta UNOP:** `R/internals.R:130-139` depende de la primera
  coincidencia literal `Actualizado` y fecha con día de dos dígitos y
  mes minúsculo. Preparar fixtures HTML con cambios de formato. No se
  consultó el sitio en esta revisión, por lo que no se afirma un fallo
  actual del servicio.
- **Escalabilidad Shiny:** la resolución se ejecuta dentro de
  `eventReactive` de forma síncrona, incluso si internamente espera a
  trabajadores paralelos. No hay benchmark concurrente ni límite
  explícito de número de nombres en el código revisado. Medir latencia y
  memoria con varias sesiones antes de decidir un cambio de
  arquitectura; no se propone paralelizar por defecto como solución.

## Evidencia y límites de la verificación

Entorno: Windows, R 4.6.1; shiny 1.14.0, testthat 3.3.2, stringdist
0.9.17, pkgload 1.5.3. Se cargó el checkout con
[`pkgload::load_all()`](https://pkgload.r-lib.org/reference/load_all.html).

Se ejecutó `devtools::test(reporter = "summary")`: terminó sin fallos
reportados, incluyendo las siete familias de archivos de pruebas. Hubo
avisos de inicio de R por configuración `LC_*=C.UTF-8`, también en
trabajadores; se separan de los hallazgos de aplicación. No se ejecutó R
CMD check ni se midió cobertura porcentual.

Las comprobaciones adicionales se ejecutaron en procesos R temporales,
usando fixtures locales y
[`shiny::testServer()`](https://rdrr.io/pkg/shiny/man/testServer.html).
[`trace()`](https://rdrr.io/r/base/trace.html) fue retirado al
finalizar. Los archivos temporales de importación fueron eliminados. No
se añadieron pruebas permanentes ni se navegaron sesiones de producción.

Ejemplos mínimos para volver a comprobar los hallazgos, después de
[`pkgload::load_all()`](https://pkgload.r-lib.org/reference/load_all.html)
(las funciones internas quedan disponibles en ese entorno):

``` r

search_avesperu(character(0), return_details = TRUE) # NULL
search_avesperu("Falko sparverius", max_distance = NA_real_)
build_resolution_results("Falco cf. sparverius")[, c("match_type", "review_flag")]
x <- standardize_names("Falco CF. sparverius")
c(x, standardize_names(x))
extract_name_parts("Falco sparverius Linnaeus, 1758")

local({
  path <- tempfile(fileext = ".csv")
  on.exit(unlink(path))
  writeLines(c("Falco sparverius", "Tinamus osgoodi"), path)
  print(read_avesperu_name_file(path)) # solo Tinamus osgoodi
})
```

## Secuencia de mejora propuesta

1.  Resolver políticas de encabezados, ambigüedad, calificadores y
    cierre local frente a hospedado; registrar la decisión concreta y el
    contrato esperado.
2.  Corregir H01–H04 con regresiones que expresen esas políticas.
3.  Corregir estado Shiny, normalización y validación/entrada vacía
    (H05–H08).
4.  Ajustar lotes y pruebas de ramas (H09–H10), luego el contrato del
    parser H11.
5.  Validar los riesgos de datos, procedencia y concurrencia con
    mediciones y fixtures antes de ampliar el alcance.

Para cerrar un hallazgo: registrar cambio/commit, prueba que antes
fallaba, resultado de verificación y decisión de compatibilidad. No
marcarlo cerrado solo por añadir documentación o porque pase la suite
previa.
