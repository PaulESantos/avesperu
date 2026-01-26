describe("create_empty_result()", {

  it("creates a single-row data frame", {
    result <- create_empty_result("Falco sparverius")
    expect_s3_class(result, "data.frame")
    expect_equal(nrow(result), 1)
  })

  it("returns correct column structure", {
    result <- create_empty_result("Falco sparverius")
    expect_named(
      result,
      c("name_submitted", "accepted_name", "order_name", "family_name",
        "english_name", "spanish_name", "status", "dist")
    )
  })

  it("sets name_submitted to provided value", {
    sp_name <- "Falco sparverius"
    result <- create_empty_result(sp_name)
    expect_equal(result$name_submitted, sp_name)
  })

  it("sets all other columns to NA", {
    result <- create_empty_result("Falco sparverius")
    expect_true(is.na(result$accepted_name))
    expect_true(is.na(result$order_name))
    expect_true(is.na(result$family_name))
    expect_true(is.na(result$english_name))
    expect_true(is.na(result$spanish_name))
    expect_true(is.na(result$status))
    expect_true(is.na(result$dist))
  })

  it("handles empty string input", {
    result <- create_empty_result("")
    expect_equal(result$name_submitted, "")
    expect_true(is.na(result$accepted_name))
  })

  it("returns character columns", {
    result <- create_empty_result("Falco sparverius")
    expect_type(result$name_submitted, "character")
    expect_type(result$accepted_name, "character")
    expect_type(result$status, "character")
  })
})

describe("create_match_result()", {

  it("creates a single-row data frame", {
    matched_row <- data.frame(
      scientific_name = "Falco sparverius",
      order_name = "Falconiformes",
      family_name = "Falconidae",
      english_name = "American Kestrel",
      spanish_name = "Cernícalo Americano",
      status = "Residente"
    )
    result <- create_match_result("Falco sparverius", matched_row, 0)
    expect_s3_class(result, "data.frame")
    expect_equal(nrow(result), 1)
  })

  it("returns correct column structure", {
    matched_row <- data.frame(
      scientific_name = "Falco sparverius",
      order_name = "Falconiformes",
      family_name = "Falconidae",
      english_name = "American Kestrel",
      spanish_name = "Cernícalo Americano",
      status = "Residente"
    )
    result <- create_match_result("Falco sparverius", matched_row, 0)
    expect_named(
      result,
      c("name_submitted", "accepted_name", "order_name", "family_name",
        "english_name", "spanish_name", "status", "dist")
    )
  })

  it("sets name_submitted correctly", {
    matched_row <- data.frame(
      scientific_name = "Falco sparverius",
      order_name = "Falconiformes",
      family_name = "Falconidae",
      english_name = "American Kestrel",
      spanish_name = "Cernícalo Americano",
      status = "Residente"
    )
    submitted_name <- "Falko sparverius"
    result <- create_match_result(submitted_name, matched_row, 1)
    expect_equal(result$name_submitted, submitted_name)
  })

  it("copies species data from matched_row", {
    matched_row <- data.frame(
      scientific_name = "Falco sparverius",
      order_name = "Falconiformes",
      family_name = "Falconidae",
      english_name = "American Kestrel",
      spanish_name = "Cernícalo Americano",
      status = "Residente"
    )
    result <- create_match_result("Falco sparverius", matched_row, 0)
    expect_equal(result$accepted_name, "Falco sparverius")
    expect_equal(result$order_name, "Falconiformes")
    expect_equal(result$family_name, "Falconidae")
    expect_equal(result$english_name, "American Kestrel")
  })

  it("converts distance to character", {
    matched_row <- data.frame(
      scientific_name = "Falco sparverius",
      order_name = "Falconiformes",
      family_name = "Falconidae",
      english_name = "American Kestrel",
      spanish_name = "Cernícalo Americano",
      status = "Residente"
    )
    result <- create_match_result("Falco sparverius", matched_row, 2)
    expect_type(result$dist, "character")
    expect_equal(result$dist, "2")
  })

  it("handles distance of 0", {
    matched_row <- data.frame(
      scientific_name = "Falco sparverius",
      order_name = "Falconiformes",
      family_name = "Falconidae",
      english_name = "American Kestrel",
      spanish_name = "Cernícalo Americano",
      status = "Residente"
    )
    result <- create_match_result("Falco sparverius", matched_row, 0)
    expect_equal(result$dist, "0")
  })

  it("handles large distance values", {
    matched_row <- data.frame(
      scientific_name = "Falco sparverius",
      order_name = "Falconiformes",
      family_name = "Falconidae",
      english_name = "American Kestrel",
      spanish_name = "Cernícalo Americano",
      status = "Residente"
    )
    result <- create_match_result("Falco sparverius", matched_row, 10)
    expect_equal(result$dist, "10")
  })

  it("preserves NA values in matched_row", {
    matched_row <- data.frame(
      scientific_name = "Falco sparverius",
      order_name = "Falconiformes",
      family_name = NA_character_,
      english_name = "American Kestrel",
      spanish_name = NA_character_,
      status = "Residente"
    )
    result <- create_match_result("Falco sparverius", matched_row, 0)
    expect_true(is.na(result$family_name))
    expect_true(is.na(result$spanish_name))
  })
})
