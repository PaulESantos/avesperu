describe("search_avesperu()", {

  # Test con múltiples especies exactas
  it("returns expected results for multiple species", {
    result <- search_avesperu(
      c("Patagioenas picazuros", "Columba livia",
        "Chordeiles nacunda", "Laterallus albigularis"),
      return_details = TRUE
    )

    expect_equal(nrow(result), 4)
    expect_equal(ncol(result), 8)
    expect_equal(
      result$name_submitted,
      c("Patagioenas picazuros", "Columba livia",
        "Chordeiles nacunda", "Laterallus albigularis")
    )
    expect_equal(
      result$accepted_name,
      c("Patagioenas picazuro", "Columba livia",
        "Chordeiles nacunda", "Laterallus albigularis")
    )
    expect_equal(
      result$order_name,
      c("Columbiformes", "Columbiformes",
        "Caprimulgiformes", "Gruiformes")
    )
  })

  # Test con una sola especie
  it("returns expected results for a single species", {
    result <- search_avesperu("Falco sparverius", return_details = TRUE)

    expect_equal(nrow(result), 1)
    expect_equal(ncol(result), 8)
    expect_equal(result$name_submitted, "Falco sparverius")
    expect_equal(result$accepted_name, "Falco sparverius")
    expect_equal(result$order_name, "Falconiformes")
    expect_equal(result$family_name, "Falconidae")
    expect_equal(result$status, "Residente")
  })

  # Test con nombres exactos
  it("finds exact matches correctly", {
    splist <- c("Falco sparverius", "Crypturellus soui")
    result <- search_avesperu(splist, return_details = TRUE)

    expect_s3_class(result, "data.frame")
    expect_equal(nrow(result), length(splist))
    expect_equal(result$name_submitted, splist)
    expect_true(all(!is.na(result$accepted_name)))
  })

  # Test con fuzzy matching
  it("finds approximate matches with fuzzy matching", {
    splist <- c("Falko sparverius", "Crypturelus soui")
    result <- search_avesperu(splist, max_distance = 0.2, return_details = TRUE)

    expect_s3_class(result, "data.frame")
    expect_equal(nrow(result), length(splist))
    expect_true(all(!is.na(result$accepted_name)))
  })

  # Test con especies inexistentes
  it("returns NA for non-existent species", {
    splist <- c("Nonexistent species", "Another fake bird")
    result <- search_avesperu(splist, return_details = TRUE)

    expect_s3_class(result, "data.frame")
    expect_equal(nrow(result), length(splist))
    expect_true(all(is.na(result$accepted_name)))
  })

  # Test con entrada vacía
  it("handles empty input correctly", {
    result <- search_avesperu(character(0))
    expect_length(result, 0)
  })

  # Test con valores NA
  it("handles NA values in input", {
    result <- search_avesperu(c("Falco sparverius", NA), return_details = TRUE)
    expect_equal(nrow(result), 2)
    expect_true(is.na(result$accepted_name[2]))
  })

  # Test con strings vacíos
  it("handles empty strings in input", {
    result <- search_avesperu(c("Falco sparverius", ""), return_details = TRUE)
    expect_equal(nrow(result), 2)
    expect_true(is.na(result$accepted_name[2]))
  })

  # Test de validación de entrada
  it("validates input type correctly", {
    expect_error(
      search_avesperu(123),
      "must be a character vector or a factor"
    )
    expect_error(
      search_avesperu(list("Falco sparverius")),
      "must be a character vector or a factor"
    )
  })

  # Test de parámetro return_details
  it("returns status vector when return_details = FALSE", {
    result <- search_avesperu("Falco sparverius", return_details = FALSE)
    expect_type(result, "character")
    expect_equal(result, "Residente")
  })

  # Test de parámetro batch_size
  it("processes correctly with different batch_size values", {
    splist <- c("Falco sparverius", "Crypturellus soui")
    result1 <- search_avesperu(splist, batch_size = 1)
    result2 <- search_avesperu(splist, batch_size = 10)
    expect_equal(result1, result2)
  })

  # Test de validación de max_distance
  it("validates max_distance parameter", {
    expect_error(
      search_avesperu("Falco sparverius", max_distance = -0.1),
      "must be a single non-negative numeric value"
    )
    expect_error(
      search_avesperu("Falco sparverius", max_distance = c(0.1, 0.2)),
      "must be a single non-negative numeric value"
    )
  })

  # Test con factor como entrada
  it("accepts factor input and converts to character", {
    splist_factor <- factor(c("Falco sparverius", "Crypturellus soui"))
    result <- search_avesperu(splist_factor, return_details = TRUE)

    expect_s3_class(result, "data.frame")
    expect_equal(nrow(result), 2)
  })

  # Test de estructura de salida
  it("returns data frame with correct column structure", {
    result <- search_avesperu("Falco sparverius", return_details = TRUE)

    expect_named(
      result,
      c("name_submitted", "accepted_name", "order_name", "family_name",
        "english_name", "spanish_name", "status", "dist")
    )
    expect_type(result$name_submitted, "character")
    expect_type(result$accepted_name, "character")
    expect_type(result$order_name, "character")
    expect_type(result$family_name, "character")
    expect_type(result$english_name, "character")
    expect_type(result$spanish_name, "character")
    expect_type(result$status, "character")
    expect_type(result$dist, "character")
  })

  it("keeps exact matching distance and output structure stable", {
    splist <- c("Falco sparverius", "Crypturellus soui")
    result <- search_avesperu(splist, max_distance = 0, return_details = TRUE)

    expect_equal(result$name_submitted, splist)
    expect_equal(result$accepted_name, splist)
    expect_equal(result$dist, c("0", "0"))
    expect_valid_search_result(result)
  })

  it("uses edit distance for fuzzy matching without changing output types", {
    result <- search_avesperu("Falko sparverius", max_distance = 0.2, return_details = TRUE)

    expect_equal(nrow(result), 1)
    expect_equal(result$name_submitted, "Falko sparverius")
    expect_equal(result$accepted_name, "Falco sparverius")
    expect_equal(result$dist, "1")
    expect_valid_search_result(result)
  })

  # Test de detección de duplicados
  it("detects and reports duplicate entries", {
    expect_message(
      search_avesperu(c("Falco sparverius", "Falco sparverius")),
      "names are repeated"
    )
  })
})
