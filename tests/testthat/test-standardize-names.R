describe("standardize_names()", {

  it("removes leading and trailing whitespace", {
    result <- standardize_names("  Falco sparverius  ")
    expect_equal(result, "Falco sparverius")
  })

  it("capitalizes first letter of genus", {
    result <- standardize_names("falco sparverius")
    expect_equal(result, "Falco sparverius")
  })

  it("lowercases first letter of species", {
    result <- standardize_names("FALCO SPARVERIUS")
    expect_equal(result, "Falco sparverius")
  })

  it("handles single word correctly", {
    result <- standardize_names("falcon")
    expect_equal(result, "Falcon")
  })

  it("normalizes multiple spaces to single space", {
    result <- standardize_names("Falco    sparverius")
    expect_equal(result, "Falco sparverius")
  })

  it("removes cf. abbreviation", {
    result <- standardize_names("Falco cf. sparverius")
    expect_equal(result, "Falco sparverius")
  })

  it("removes aff. abbreviation", {
    result <- standardize_names("Falco aff. sparverius")
    expect_equal(result, "Falco sparverius")
  })

  it("removes underscore characters", {
    result <- standardize_names("Falco_sparverius")
    expect_equal(result, "Falco sparverius")
  })

  it("warns about hybrid species markers", {
    expect_warning(
      standardize_names("x Falco sparverius"),
      "hybrids have been removed"
    )
  })

  it("removes hybrid marker at end of name", {
    expect_warning(
      standardize_names("Falco sparverius x"),
      "hybrids have been removed"
    )
    result <- suppressWarnings(standardize_names("Falco sparverius x"))
    expect_equal(result, "Falco sparverius")
  })

  it("removes hybrid marker in middle of name", {
    expect_warning(
      standardize_names("Falco x sparverius"),
      "hybrids have been removed"
    )
    result <- suppressWarnings(standardize_names("Falco x sparverius"))
    expect_equal(result, "Falco sparverius")
  })

  it("handles multiple problematic patterns", {
    result <- standardize_names("  falco   cf.  sparverius  ")
    expect_equal(result, "Falco sparverius")
  })

  it("returns vector of same length as input", {
    input <- c("Falco sparverius", "Crypturellus soui", "  test  ")
    result <- standardize_names(input)
    expect_length(result, 3)
  })

  it("applies transformations element-wise", {
    input <- c("falco sparverius", "CRYPTURELLUS SOUI")
    result <- standardize_names(input)
    expect_equal(result[1], "Falco sparverius")
    expect_equal(result[2], "Crypturellus soui")
  })

  it("preserves NA values", {
    input <- c("Falco sparverius", NA)
    result <- standardize_names(input)
    expect_true(is.na(result[2]))
  })

  it("handles empty string input", {
    result <- standardize_names("")
    expect_equal(result, "")
  })

  it("counts hybrid warnings correctly", {
    # Múltiples híbridos
    input <- c("x Falco", "Crypturellus x", "x Tinamus x")
    expect_warning(
      standardize_names(input),
      "3 name"
    )
  })
})
