describe("Parallel processing in search_avesperu()", {

  it("returns same results with parallel = TRUE and parallel = FALSE", {
    skip_if_not_installed("parallel")

    splist <- c("Falco sparverius", "Crypturellus soui", "Tinamus major")

    result_seq <- search_avesperu(splist, parallel = FALSE, return_details = TRUE)
    result_par <- search_avesperu(splist, parallel = TRUE, return_details = TRUE)

    expect_equal(result_seq, result_par)
  })

  it("processes large lists correctly with batching", {
    skip_if_not_installed("parallel")

    # Crear una lista más grande
    splist <- c(
      "Falco sparverius", "Crypturellus soui", "Tinamus major",
      "Penelope jacquacu", "Ortalis motmot", "Colinus cristatus"
    )

    result_batch <- search_avesperu(
      splist,
      batch_size = 2,
      parallel = FALSE,
      return_details = TRUE
    )

    expect_equal(nrow(result_batch), length(splist))
    expect_equal(ncol(result_batch), 8)
  })

  it("respects batch_size parameter", {
    skip_if_not_installed("parallel")

    splist <- c(
      "Falco sparverius", "Crypturellus soui", "Tinamus major",
      "Penelope jacquacu", "Ortalis motmot"
    )

    # No debería error con diferentes tamaños de batch
    expect_no_error(
      search_avesperu(splist, batch_size = 1, parallel = FALSE)
    )
    expect_no_error(
      search_avesperu(splist, batch_size = 10, parallel = FALSE)
    )
  })

  it("validates batch_size parameter", {
    splist <- c("Falco sparverius", "Crypturellus soui")

    expect_error(
      search_avesperu(splist, batch_size = -1),
      "'batch_size' must be a positive integer"
    )
    expect_error(
      search_avesperu(splist, batch_size = 0),
      "'batch_size' must be a positive integer"
    )
  })

  it("validates n_cores parameter", {
    splist <- c("Falco sparverius", "Crypturellus soui")

    expect_error(
      search_avesperu(splist, n_cores = -1),
      "'n_cores' must be NULL or a positive integer"
    )
    expect_error(
      search_avesperu(splist, n_cores = 0),
      "'n_cores' must be NULL or a positive integer"
    )
  })

  it("accepts NULL for n_cores to auto-detect", {
    skip_if_not_installed("parallel")

    splist <- c("Falco sparverius", "Crypturellus soui")

    # No debería error
    expect_no_error(
      search_avesperu(splist, n_cores = NULL, parallel = FALSE)
    )
  })

  it("uses detectCores() when n_cores is NULL", {
    skip_if_not_installed("parallel")

    splist <- c(
      "Falco sparverius", "Crypturellus soui", "Tinamus major",
      "Penelope jacquacu", "Ortalis motmot", "Colinus cristatus"
    )

    # Esto debe ejecutar sin error usando detectCores - 1
    expect_no_error(
      search_avesperu(
        splist,
        batch_size = 2,
        parallel = TRUE,
        n_cores = NULL
      )
    )
  })

  it("validates parallel parameter", {
    splist <- c("Falco sparverius")

    expect_error(
      search_avesperu(splist, parallel = "yes"),
      "'parallel' must be a single logical value"
    )
    expect_error(
      search_avesperu(splist, parallel = c(TRUE, FALSE)),
      "'parallel' must be a single logical value"
    )
  })

  it("disables parallel for small lists automatically", {
    skip_if_not_installed("parallel")

    # Una lista pequeña (< batch_size) no debería usar paralelización
    splist <- c("Falco sparverius")
    result <- search_avesperu(
      splist,
      batch_size = 100,
      parallel = TRUE,
      return_details = TRUE
    )

    expect_equal(nrow(result), 1)
  })

  it("maintains result order across parallel processing", {
    skip_if_not_installed("parallel")

    splist <- c("Falco sparverius", "Crypturellus soui", "Tinamus major")

    result_par <- search_avesperu(
      splist,
      batch_size = 1,
      parallel = TRUE,
      return_details = TRUE
    )

    # El orden debe coincidir con el input
    expect_equal(result_par$name_submitted, splist)
  })
})
