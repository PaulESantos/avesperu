# Registro de decisiones de la revisión

Fecha de apertura: 8 de septiembre de 2026 (America/Lima).
Base: `9f286a7feb84f5d9d966188eefccfa535b87a12e`.
Informe asociado: [REVISION-IMPLEMENTACION.md](REVISION-IMPLEMENTACION.md).

Este registro distingue las decisiones de trabajo ya tomadas de las propuestas
de producto y arquitectura. No implica aprobación de cambios de implementación.

## Decisiones tomadas

| ID | Decisión | Motivo y fundamento | Consecuencia |
| --- | --- | --- | --- |
| D01 | Limitar esta entrega a identificación y documentación | Solicitud explícita del usuario de centrarse en puntos débiles para plantear mejoras | Sin cambios de código, pruebas, datos o despliegue |
| D02 | Contrastar lectura con suite existente y casos adversos locales | La existencia de pruebas no demuestra cobertura de rutas límite | Se ejecutaron la suite y reproducciones temporales, sin alterar las pruebas permanentes |
| D03 | Separar defectos reproducidos, evidencia estática y riesgos | Evitar presentar hipótesis como errores actuales | Cada hallazgo declara evidencia; los riesgos adicionales tienen validación pendiente |
| D04 | Priorizar pérdida silenciosa y significado de resultados | Una ejecución exitosa puede entregar una identificación incorrecta o incompleta | H01–H04 se proponen como P1; no equivale a un calendario aprobado |
| D05 | Mantener los informes históricos intactos | Describen trabajos anteriores, no garantizan el comportamiento presente | Este informe documenta las brechas observadas y la revisión queda ligada a un commit |
| D06 | No detener ni desplegar la aplicación para comprobar el cierre global | El código local permite identificar el alcance de stopApp sin afectar usuarios | H04 tiene evidencia estática; la integración con dos sesiones queda pendiente |

## Decisiones pendientes para la fase de corrección

| ID | Tema / hallazgos | Propuesta a evaluar | Alternativa o coste a resolver | Estado |
| --- | --- | --- | --- | --- |
| P01 | Encabezados y filas fuente / H01 | Selector explícito y vista previa; conservar identidad de fila | Inferencia automática requiere tratamiento de ambigüedad y no debe descartar filas | Propuesta |
| P02 | Calificadores e híbridos / H02, H06 | Conservar marcadores y forzar revisión aunque la distancia sea cero | Definir si permiten sugerencia o bloquean aceptación automática | Propuesta |
| P03 | Empates / H03 | Estado ambiguo y candidatos alternativos | Cambia el contrato actual que siempre escoge una fila; diseñar compatibilidad | Propuesta |
| P04 | Cierre / H04 | Cerrar sesión en hospedaje; parada global solo en modalidad local explícita | Definir cómo se selecciona y prueba la modalidad | Propuesta |
| P05 | Estado de app / H05 | Invalidar al limpiar y distinguir entrada fallida de ejecución previa | Conservar resultados anteriores puede ser útil si se identifican y bloquea confusión | Propuesta |
| P06 | API y umbral / H07, H08 | Validación estricta y objetos vacíos tipados | Fijar redondeo y frontera entre proporción y distancia absoluta | Propuesta |
| P07 | Lotes y pruebas / H09, H10 | Separar lotes del ejecutor; probar ingreso y fallos de ramas | No prometer memoria acotada sin medir ni cambiar acumulación | Propuesta |
| P08 | Parsing / H11 | Autorías separadas o texto no interpretado con revisión | Delimitar gramática admitida antes de añadir un parser más complejo | Propuesta |
| P09 | Fuente y ejecución efectiva / riesgos | Registrar identificador de datos y ejecución real | Determinar mecanismo compatible para seleccionar versión de referencia | Propuesta |

## Cómo registrar las decisiones futuras

Por cada decisión añadir fecha, responsable, hallazgos asociados, opción elegida,
motivo, alternativas descartadas, consecuencias de compatibilidad y evidencia de
validación. Al implementar, añadir commit y resultado de las pruebas. Mantener
la diferencia entre propuesta, aceptada, implementada y verificada. Si se cambia
una decisión, enlazar la que la sustituye en vez de borrar su historia.

Estado al entregar esta revisión: D01–D06 tomadas para la auditoría; P01–P09
pendientes. Ningún hallazgo se considera corregido.


## Resoluciones de implementación — 8 de septiembre de 2026

**D07 — Autorización y alcance.** La instrucción posterior del usuario,
«implementa las acciones necesarias para corregir todos los hallazgos y
debilidades», sustituye D01 para esta fase. Autoriza código, regresiones,
documentación y correcciones estructurales de datos. No se ha publicado una
versión ni desplegado la aplicación. La versión de trabajo es `0.1.1.9000`.

| Propuesta | Decisión adoptada | Consecuencia / compatibilidad | Estado |
| --- | --- | --- | --- |
| P01 | Reconocer solo encabezados estándar; controles explícitos para otros diseños; vista previa y registros estructurados | No se omiten primera especie, NA ni vacíos de archivos. `source_row` es fila Excel o registro delimitado, no línea física de un campo multilínea | Implementada y probada |
| P02 | Conservar original y banderas; normalización única, por tokens e idempotente | La salida básica devuelve NA para calificadores/híbridos; la detallada conserva sugerencia y motivo de revisión | Implementada y probada |
| P03 | Devolver ambiguous con candidatos ordenados, sin especie aceptada | Conserva ocho columnas; atributos documentados aportan auditoría. Subclase data.frame `avesperu_result` preserva alineación con `[` | Implementada y probada |
| P04 | Cerrar solo la sesión en todos los modos | No se expone parada global desde un cliente. El dueño detiene el proceso local desde su consola R | Implementada y probada |
| P05 | Invalidar al editar/limpiar; vaciar e invalidar carga fallida; cancelar trabajo y rechazar resultados de generaciones anteriores | Descargas requieren ejecución vigente completada. No se reutiliza el archivo anterior después de un fallo | Implementada y probada |
| P06 | Escalares finitos; enteros para lotes/núcleos y distancias absolutas; objetos vacíos tipados | Se mantiene ceiling para proporciones estrictamente entre 0 y 1; 1 significa una edición. Valores antes truncados ahora se rechazan | Implementada y probada |
| P07 | Separar lotes de ejecutor; enviar funciones actuales a trabajadores; registrar fallback y cerrar recursos | La salida registra modo y núcleos reales. La API conserva acumulación completa del resultado, no promete memoria total constante | Implementada y probada |
| P08 | Gramática conservadora: binomio, trinomio, marcadores infraespecíficos y autoría con año; resto unparsed | No se presenta texto no reconocido como rango confirmado; autoría queda separada | Implementada y probada |
| P09 | Centralizar la referencia vigente; cargar el bundle local explícitamente; registrar ID, fecha, versión y huella de contenido, más ejecución real | No se añade un selector de catálogos como función nueva. La huella procede de serialización R versión 2; se interpreta junto al entorno registrado | Implementada y probada |

**D08 — Datos de referencia.** `scientific_name` continúa siendo la clave
canónica del resolvedor. En `Pterodroma axillaris` se deriva el epíteto axillaris;
en `Diglosa melanopis` se deriva el género Diglosa. Los componentes fuente
phaeopygia y Diglossa se conservan en `component_corrections`. Esto evita combinar
una clave con componentes distintos y no establece cuál grafía o taxón debe
adoptar una futura revisión científica. Se valida el esquema antes de guardar.

**D09 — Concurrencia.** Una tarea `callr` por sesión evita bloquear el bucle Shiny.
`later` consulta su estado; cambiar entradas o cerrar la sesión cancela el árbol
de procesos. Límites: 10.000 registros, 200 caracteres por nombre y cuatro
trabajadores opcionales por tarea. La prueba local con dos tareas de 2.000
nombres terminó correctamente. No se infiere capacidad de producción a partir
de esa medición.

**D10 — Verificación y entorno.** Se mantienen las pruebas de API existentes y
se añaden casos de importación, estado, cancelación, descargas, esquema,
normalización y fallos reales/instrumentados del clúster. Los snapshots se
revisaron; no se aceptaron salidas con errores inesperados. El formateador Air
excluye artefactos `rsconnect/` y `.validation/`. La comprobación directa de R
sustituye el prechequeo de compiladores de devtools en este entorno sin Rtools.
Los detalles finales quedan en el informe de validación.

Las filas P01–P09 anteriores permanecen como historial de propuestas. Su estado
actual es el de la tabla de resoluciones. No se creó un commit automáticamente;
los cambios están disponibles en el árbol de trabajo para revisión.


**D11 — Cierre, 9 de septiembre de 2026.** Se verificó nuevamente la coincidencia
del código con el paquete comprobado, su `Status: OK` y las 280 aserciones
aprobadas. Se cierra la fase de corrección y verificación de H01–H11; permanecen
únicamente los límites de plataforma, validación taxonómica y despliegue
expresamente descritos en el informe, no fallos de pruebas pendientes.


**D12 — Trabajadores privados y comprobación --as-cran, 9 de septiembre de 2026.**
La nota aportada por el usuario mostró una limitación de la comprobación anterior
sin `--as-cran`. Se eliminan tanto la asignación a `.GlobalEnv` como la exportación
de funciones a ese entorno. Los trabajadores reciben las funciones actuales en
un entorno privado serializado. La regresión comprueba que el entorno global
del trabajador no cambia. Se verificó el paquete con `--as-cran`, incluidos los
manuales PDF/HTML: Status: OK, 284 aserciones, cero errores, advertencias o notas.
