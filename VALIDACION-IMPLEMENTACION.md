# Correcciones y validación de la implementación

Implementación y comprobación: 8 de septiembre de 2026, America/Lima.
Cierre documental: 9 de septiembre de 2026.
Versión de trabajo: `0.1.1.9000`.
Base de la revisión: `9f286a7feb84f5d9d966188eefccfa535b87a12e`.

## Resultado

Se implementaron correcciones para H01–H11 y controles para los cuatro riesgos
adicionales. La comprobación final del paquete construido terminó con
**`Status: OK`**, sin errores, advertencias ni notas. La suite del paquete
instalado registró **284 aserciones aprobadas, 0 fallos, 0 advertencias y
0 omisiones**. Las viñetas se construyeron y se reconstruyeron durante el check.

Los cambios están en el árbol de trabajo. No se creó un commit, no se publicó
una versión y no se desplegó la aplicación.

## Trazabilidad entre hallazgos y pruebas

| Hallazgo | Implementación | Evidencia automatizada |
| --- | --- | --- |
| H01 | Importación por registros, encabezados explícitos/estándar, columna seleccionable, vista previa, `source_file` y `source_row` | `test-shiny-app.R`: CSV/TSV con/sin encabezado, una fila, blancos, NA, columna ambigua y Excel |
| H02 | Original y marcas conservadas, sugerencias con revisión; NA en salida básica para calificadores/híbridos | `test-get_avesperu.R`: CF., aff., híbrido, razón persistente y advertencia única |
| H03 | Empates devuelven ambiguous y candidatos ordenados; accepted_name/status ausentes | `test-get_avesperu.R`: permutar referencia mantiene resultado; prueba de API básica y detallada |
| H04 | `session$close()` en lugar de parada global | `test-shiny-app.R`: cerrar una sesión no cierra una segunda sesión mock del mismo proceso |
| H05 | Invalidación de entradas/resultados; carga fallida vacía datos; cancelación por generación; descargas condicionadas | `test-shiny-app.R` y `test-app-jobs.R`: Clear, reemplazo fallido, cancelación, resultados tardíos, bloqueo de descarga |
| H06 | Normalización por tokens, sin distinción de mayúsculas para marcadores, aplicada una vez al resolver | `test-internals.R`: idempotencia con CF./AFF., underscores, marcadores adyacentes, ×, vacíos y NA |
| H07 | Validación escalar finita y entera; control de mc.cores/detección; límites explícitos de distancia | `test-get_avesperu.R` y `test-parallel-processing.R`: valores inválidos, snapshots, fronteras y fallback de detección |
| H08 | Vector vacío character y tabla vacía de ocho columnas tipadas | `test-get_avesperu.R`: API y wrappers vacíos |
| H09 | Decisión de lotes independiente del ejecutor | `test-parallel-processing.R`: tamaños reales 2/2/1 en secuencial y comparación con ejecución paralela |
| H10 | Pruebas que fuerzan ramas y fallos; trabajadores reciben funciones actuales | `test-parallel-processing.R`: clúster real de dos trabajadores, fallo de creación, fallo de envío al clúster y limpieza |
| H11 | Autoría con año separada; trinomios/marcadores reconocidos; texto restante unparsed | `test-shiny-app.R`: autoría, epíteto infraespecífico, subsp. y texto no reconocido |

También se conserva alineación de la auditoría al seleccionar filas/columnas:
`test-result-subset.R` cubre reordenación, duplicación, filas NA, selección vacía,
columnas y salida vectorial explícita con `drop = TRUE`.

## Riesgos adicionales atendidos

- **Esquema y datos:** `read_checklist_source()` identifica columnas por sus
  etiquetas, localiza el encabezado y conserva filas parciales para validarlas.
  `validate_checklist()` comprueba campos, duplicados, códigos y coherencia entre
  nombre y componentes antes de guardar. Se probaron columnas reordenadas y
  datos inválidos; el archivo fuente local contiene 1925 registros.
- **Discrepancias de componentes:** la validación ampliada encontró dos filas.
  Sus nombres científicos permanecen iguales; los componentes ahora se derivan
  de esa clave y los originales quedan en `component_corrections`. Las pruebas
  verifican consistencia, dos registros de auditoría e idempotencia. No se
  interpreta esto como corrección científica de la lista fuente.
- **Procedencia:** `app.R` carga el código del bundle, los trabajadores usan las
  funciones vigentes y los procesos Shiny cargan la misma ruta de paquete.
  Los metadatos incluyen ID/fecha de referencia, versión de paquete, huella de
  serialización y modo, trabajadores, lotes y fallback efectivos.
- **UNOP:** el parser tolera mayúsculas, espacios no separables, día de uno o
  dos dígitos, setiembre/septiembre y varias fechas de actualización; ignora
  fechas sin etiqueta de actualización. Se probaron fixtures de texto y fechas
  inválidas. No se consultó el sitio remoto durante esta validación.
- **Concurrencia:** resolución en proceso separado con `callr`, consulta de
  estado con `later`, una tarea activa por sesión y cancelación al editar/cerrar.
  Límites por tarea: 10.000 nombres, 200 caracteres por nombre y cuatro núcleos.
  Las descargas CSV, TSV y XLSX se probaron desde una sesión con trabajo real.

## Medición local de concurrencia

Se iniciaron dos trabajos simultáneos, cada uno con 2.000 nombres únicos
sintéticos de la forma `Falko sparverius N`, distancia 0.1 y lotes secuenciales
de 100. Los dos devolvieron tablas idénticas, incluida su información de revisión.

| Medida | Resultado |
| --- | --- |
| Tiempo de iniciar ambos trabajos en el proceso principal | 0,491 segundos |
| Tiempo total hasta recibir ambos resultados | 5,257 segundos |
| Filas por resultado | 2.000 |
| Tamaño del objeto de una respuesta, medido con object.size | 861.776 bytes |

La medición se realizó durante el desarrollo, antes del ajuste final de la
subclase para selección de filas; verifica la arquitectura de trabajos que se
mantiene en la entrega. El tamaño del objeto **no es memoria pico**. No se
extrapola este resultado a capacidad de producción, otras máquinas ni un número
arbitrario de sesiones.

## Comprobación formal y herramientas

Entorno: Windows 11 x64, R 4.6.1; shiny 1.14.0, testthat 3.3.2,
stringdist 0.9.17 y pkgload 1.5.3. Documentación generada con roxygen2 8.1.0.

Comprobaciones realizadas:

1. `devtools::test(reporter = "summary", stop_on_failure = TRUE)` durante las
   iteraciones. Se corrigieron los fallos antes de validar el paquete instalado.
2. `devtools::document()` y `pkgdown::check_pkgdown()`; pkgdown indicó que no
   encontró problemas. Se usó el Pandoc ya instalado con Quarto.
3. `air format .` y `git diff --check`. Air excluye artefactos de despliegue y
   comprobación; también normalizó formato en archivos R existentes.
4. `R CMD build D:/avesperu`, con viñetas, y
   `R CMD check --no-manual avesperu_0.1.1.9000.tar.gz` sobre el archivo generado.
   Comprobó instalación, carga/descarga, dependencias, código, métodos S3,
   documentación, ejemplos, datos, pruebas y reconstrucción de viñetas.

`devtools::check()` inicialmente exigió Rtools, no disponible en esta máquina.
El paquete no contiene código compilado y el check directo de R pudo completarse.
R necesitó ejecución fuera del aislamiento para escribir en la carpeta de
comprobación; esa ejecución fue autorizada por la herramienta de permisos.
La primera pasada formal señaló `setNames` sin calificar: se cambió a
`stats::setNames` y se reconstruyó y comprobó de nuevo el paquete.

Registros locales de la comprobación final:

- [Registro completo de R CMD check](.validation/avesperu.Rcheck/00check.log)
- [Resultado de las pruebas del paquete instalado](.validation/avesperu.Rcheck/tests/testthat.Rout)
- [Paquete fuente comprobado](.validation/avesperu_0.1.1.9000.tar.gz)

## Compatibilidad y límites

- Se mantienen ocho columnas y su orden en la salida detallada. La clase ahora
  hereda de data.frame mediante `avesperu_result`; los atributos adicionales
  contienen revisión y procedencia. El método `[` conserva su alineación.
- Empates y entradas calificadas/híbridas cambian deliberadamente su tratamiento
  para evitar aceptación silenciosa. Los parámetros absolutos fraccionarios antes
  truncados ahora producen errores informativos.
- Las filas de CSV/TSV se identifican por registro, no por línea física cuando
  hay campos entrecomillados multilínea. Excel conserva números de fila de hoja.
- La huella usa serialización R versión 2 y se interpreta junto al entorno;
  no es una firma de autenticidad ni se promete igualdad entre serializadores.
- El resolvedor sigue siendo textual, sin catálogo de sinonimias ni validación
  taxonómica externa. El parser conserva como no interpretado lo que queda fuera
  de su gramática documentada.
- La comprobación inicial omitió el manual PDF; la validación posterior con
  `--as-cran` sí comprobó los manuales PDF y HTML. No se probaron otras plataformas
  ni una instancia desplegada. Las verificaciones de cierre emplean sesiones de
  prueba; las de procesamiento y descargas sí ejecutan procesos R reales.

Las decisiones adoptadas y sus motivos se encuentran en
[DECISIONES-REVISION.md](DECISIONES-REVISION.md). El diagnóstico original se
conserva en [REVISION-IMPLEMENTACION.md](REVISION-IMPLEMENTACION.md).

## Cierre de la entrega — 9 de septiembre de 2026

Se volvió a verificar el registro final: `Status: OK`, 280 aserciones y cero
fallos, advertencias u omisiones. Los 44 archivos comparados de código,
pruebas, documentación de referencia, datos y metadatos coinciden con el paquete
fuente comprobado. Se normalizaron los finales de línea de texto; DESCRIPTION
se comparó por campos, excluyendo los campos añadidos automáticamente por R CMD
build. No hay correcciones pendientes de H01–H11 dentro del alcance documentado.


## Corrección de la nota con --as-cran — 9 de septiembre de 2026

El usuario aportó una comprobación más estricta que detectó asignaciones a
`.GlobalEnv` en el código paralelo. La comprobación inicial sin `--as-cran`
no había señalado ese patrón.

Se sustituyeron `clusterExport()` y la asignación global por
`make_search_worker()`: copia las funciones vigentes en un entorno privado con
padre `baseenv()`. La función enviada por `parLapply()` lleva ese entorno al
trabajador, sin depender de un namespace instalado anterior ni escribir objetos
en el entorno global. La recuperación y limpieza ante fallos se mantienen.

La nueva regresión ejecuta una búsqueda fuzzy en un trabajador real y comprueba
que sus objetos globales son idénticos antes y después de la búsqueda.

Se reconstruyó el paquete y se ejecutó **`R CMD check --as-cran` con manuales**:
**0 errores, 0 advertencias, 0 notas; Status: OK**. La suite completa del paquete
instalado registró **284 aserciones aprobadas y 0 omisiones**. Pasaron expresamente
la inspección de posibles problemas de código y los manuales PDF y HTML.
Los registros enlazados en este documento corresponden ahora a esta ejecución.
