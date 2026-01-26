# Mejoras de Paralelismo Robusto - search_avesperu()

## Problema Original

El código original de paralelismo falló en contextos restrictivos (CRAN
checks, CI/CD, contenedores) con el error:

    "19 simultaneous processes spawned" → error en makeCluster()

### Causas

1.  **detectCores() sin capping**: En máquinas de 20+ cores, resolvía
    `n_cores = 19`
2.  **Entornos restrictivos**: CRAN/CI/tests limitan procesos
    simultáneos
3.  **Sin fallback**: Si `makeCluster()` fallaba, toda la función
    colapsaba
4.  **Sin respeto a opciones globales**: No consideraba
    `getOption("mc.cores")`

------------------------------------------------------------------------

## Solución Implementada

### 1. Cálculo Robusto de n_cores en `search_with_agrep_batched()`

``` r
# Antes: n_cores <- max(1, parallel::detectCores() - 1)  ❌ Peligroso

# Ahora:
if (is.null(n_cores)) {
  # Respetar opción global (CRAN, CI la fijan bajo)
  max_by_option <- getOption("mc.cores", 2L)

  # Auto-detectar prudentemente
  n_cores_detected <- max(1L, parallel::detectCores(logical = FALSE) - 1L)

  # No más cores que batches
  max_by_batches <- n_batches

  # Tapa prudente: máximo 4 cores (evita problemas en checks)
  n_cores <- min(n_cores_detected, max_by_batches, max_by_option, 4L)
}
```

**Lógica:** 1. Respeta `getOption("mc.cores")` (usado por CRAN/CI) 2.
Detecta cores disponibles 3. Limita por número de batches (sin sentido
\> cores que batches) 4. Impone máximo de 4 cores para seguridad en
checks 5. Usuario puede especificar explícitamente (capeado por
n_batches)

### 2. Fallback Seguro si el Cluster Falla

``` r
cl <- NULL
cluster_created <- FALSE

cl <- tryCatch(
  parallel::makeCluster(n_cores),
  error = function(e) {
    warning("Could not create cluster... Falling back to sequential")
    NULL
  }
)

if (!is.null(cl)) {
  cluster_created <- TRUE
  # ... usar paralelo
} else {
  # ... usar secuencial automáticamente
}
```

**Beneficios:** - Si el cluster falla, la función NO colapsa - Warnings
informativos (no errores silenciosos) - Fallback automático a
secuencial - Resultado final siempre correcto

------------------------------------------------------------------------

## Tests Actualizados

### Cambios en `test-parallel-processing.R`

#### ❌ Antes (PROBLEMÁTICO)

``` r
it("maintains result order across parallel processing", {
  splist <- c("Falco sparverius", "Crypturellus soui", "Tinamus major")
  result_par <- search_avesperu(
    splist,
    batch_size = 1,
    parallel = TRUE,           # ← Usa detectCores() - 1 (en checks: puede ser 19)
    return_details = TRUE
  )
})
```

**Problema:** En checks con límites de procesos, fallaba al crear
cluster.

#### ✅ Ahora (SEGURO)

``` r
it("maintains result order with explicit n_cores", {
  splist <- c("Falco sparverius", "Crypturellus soui", "Tinamus major")
  result_par <- search_avesperu(
    splist,
    batch_size = 1,
    parallel = TRUE,
    n_cores = 2L,             # ← Explícitamente seguro
    return_details = TRUE
  )
})
```

### Patrones de Tests Robustos

#### Opción 1: Usar n_cores Explícito

``` r
result <- search_avesperu(
  splist,
  parallel = TRUE,
  n_cores = 2L,    # Siempre 2, seguro en cualquier contexto
  return_details = TRUE
)
```

#### Opción 2: Usar withr para Controlar Opción Global

``` r
it("respects mc.cores option", {
  skip_if_not_installed("parallel")

  withr::local_options(list(mc.cores = 2L))

  result <- search_avesperu(
    splist,
    parallel = TRUE,
    n_cores = NULL,  # Usará mc.cores = 2L
    return_details = TRUE
  )
})
```

### Tests Agregados

1.  **“caps n_cores to reasonable values in any environment”**
    - Simula restricciones CRAN con `mc.cores = 2L`
    - Verifica que no intente crear 19 cores
2.  **“respects mc.cores option when n_cores is NULL”**
    - Prueba que la opción global es respetada
    - Importante para CRAN/CI
3.  **“recovers gracefully if cluster creation fails”**
    - Verifica fallback automático a secuencial
    - Valida que no haya error incluso si falla paralelismo

------------------------------------------------------------------------

## Resumen de Cambios

| Aspecto               | Antes             | Después                   |
|-----------------------|-------------------|---------------------------|
| n_cores máximo        | 19+ (detectCores) | 4 (capeado, configurable) |
| Respeta mc.cores      | ❌ No             | ✅ Sí                     |
| Fallback si falla     | ❌ No             | ✅ Sí (secuencial)        |
| Tests paralelo        | 10                | 12 (más robustos)         |
| Falla en checks       | ❌ Sí             | ✅ No                     |
| Explícitamente seguro | \-                | ✅ n_cores=2L en tests    |

------------------------------------------------------------------------

## Cómo Usar

### Usuarios

``` r
# Opción 1: Dejar que la función auto-detecte (ahora seguro)
result <- search_avesperu(splist, parallel = TRUE)

# Opción 2: Especificar cores explícitamente (más control)
result <- search_avesperu(splist, parallel = TRUE, n_cores = 2)

# Opción 3: Deshabilitar paralelo para datos pequeños
result <- search_avesperu(splist, parallel = FALSE)
```

### En Checks/CI

Si quieres controlar globalmente:

``` r
# En tu .Rprofile o setup de tests
options(mc.cores = 2)

# O con withr en un test específico
withr::local_options(list(mc.cores = 2L))
```

------------------------------------------------------------------------

## Referencias

- [parallel::makeCluster
  documentation](https://stat.ethz.ch/R-manual/R-devel/library/parallel/html/makeCluster.html)
- [CRAN Policy on parallel
  computing](https://cran.r-project.org/web/packages/policies.html)
- [testthat best practices for parallel
  code](https://testthat.r-lib.org/)
- [withr package for temporary options](https://withr.r-lib.org/)

------------------------------------------------------------------------

## Verificación

Para verificar que los tests pasan en tu entorno:

``` r
# Ejecutar tests de paralelismo
devtools::test(filter = "parallel")

# O todos los tests
devtools::test()
```

Si algo falla, el mensaje será informativo gracias al nuevo sistema de
warnings/fallback.
