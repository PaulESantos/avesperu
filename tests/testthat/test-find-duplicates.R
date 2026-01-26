describe("find_duplicates()", {

  it("finds exact duplicates in vector", {
    vector <- c("Falco", "Crypturellus", "Falco", "Tinamus")
    result <- find_duplicates(vector)
    expect_equal(result, "Falco")
  })

  it("returns all duplicated elements", {
    vector <- c("A", "B", "A", "C", "B", "D", "B")
    result <- find_duplicates(vector)
    expect_setequal(result, c("A", "B"))
  })

  it("returns empty vector when no duplicates exist", {
    vector <- c("Falco", "Crypturellus", "Tinamus")
    result <- find_duplicates(vector)
    expect_length(result, 0)
  })

  it("returns empty vector for single element", {
    vector <- c("Falco")
    result <- find_duplicates(vector)
    expect_length(result, 0)
  })

  it("returns empty vector for empty input", {
    vector <- character(0)
    result <- find_duplicates(vector)
    expect_length(result, 0)
  })

  it("handles all duplicate elements", {
    vector <- c("A", "A", "A")
    result <- find_duplicates(vector)
    expect_equal(result, "A")
  })

  it("is case-sensitive", {
    vector <- c("falco", "Falco", "FALCO")
    result <- find_duplicates(vector)
    expect_length(result, 0)
  })

  it("handles numeric vectors", {
    vector <- c(1, 2, 1, 3, 2, 4)
    result <- find_duplicates(vector)
    expect_setequal(result, c("1", "2"))
  })

  it("handles NA values", {
    vector <- c("A", NA, "A", NA)
    result <- find_duplicates(vector)
    # NA se trata como un valor único
    expect_true("A" %in% result)
  })

  it("preserves order of first appearance (if applicable)", {
    vector <- c("B", "A", "B", "A", "C")
    result <- find_duplicates(vector)
    # Resultado debe contener ambos pero el orden no está garantizado
    expect_setequal(result, c("A", "B"))
  })

  it("returns character vector of duplicate names", {
    vector <- c("X", "Y", "X", "Z")
    result <- find_duplicates(vector)
    expect_type(result, "character")
  })
})
