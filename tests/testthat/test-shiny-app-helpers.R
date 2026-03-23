describe("Shiny app helpers", {

  it("splits pasted names by line and trims whitespace", {
    input <- "  Falco sparverius \n\n Tinamus osgoodi\r\nPenelope albipennis  "
    result <- split_submitted_names(input)

    expect_equal(
      result,
      c("Falco sparverius", "Tinamus osgoodi", "Penelope albipennis")
    )
  })

  it("reads plain text uploads as one name per line", {
    path <- withr::local_tempfile(fileext = ".txt")
    writeLines(c("Falco sparverius", "", "Tinamus osgoodi"), path)

    result <- read_avesperu_name_file(path, filename = "birds.txt")

    expect_equal(result, c("Falco sparverius", "Tinamus osgoodi"))
  })

  it("prefers a scientific_name column in uploaded csv files", {
    path <- withr::local_tempfile(fileext = ".csv")
    utils::write.csv(
      data.frame(
        id = 1:2,
        scientific_name = c("Falco sparverius", "Tinamus osgoodi"),
        stringsAsFactors = FALSE
      ),
      path,
      row.names = FALSE
    )

    result <- read_avesperu_name_file(path, filename = "birds.csv")

    expect_equal(result, c("Falco sparverius", "Tinamus osgoodi"))
  })

  it("reads uploaded xlsx files from a name-like column", {
    skip_if_not_installed("writexl")
    skip_if_not_installed("readxl")

    path <- withr::local_tempfile(fileext = ".xlsx")
    writexl::write_xlsx(
      data.frame(
        scientific_name = c("Falco sparverius", "Tinamus osgoodi"),
        notes = c("exact", "exact"),
        stringsAsFactors = FALSE
      ),
      path = path
    )

    result <- read_avesperu_name_file(path, filename = "birds.xlsx")

    expect_equal(result, c("Falco sparverius", "Tinamus osgoodi"))
  })

  it("builds parse results with inferred parts and duplicate flags", {
    result <- build_parse_results(c(
      "falco sparverius",
      "Falco sparverius",
      "Xenoglaux loweryi"
    ))

    expect_equal(nrow(result), 3)
    expect_equal(result$standardized_name[1], "Falco sparverius")
    expect_equal(result$submitted_genus[3], "Xenoglaux")
    expect_equal(result$submitted_species_epithet[3], "loweryi")
    expect_true(all(result$duplicate_input[1:2]))
    expect_false(result$duplicate_input[3])
  })

  it("builds resolution results with exact, fuzzy, and unmatched rows", {
    result <- build_resolution_results(
      c("Falco sparverius", "Tinamus osgodi", "Invented bird species"),
      max_distance = 0.1,
      batch_size = 10,
      parallel = FALSE
    )

    expect_equal(nrow(result), 3)
    expect_equal(result$match_type[1], "exact")
    expect_equal(result$match_type[2], "fuzzy")
    expect_equal(result$accepted_name[1], "Falco sparverius")
    expect_true(is.na(result$accepted_name[3]))
    expect_true(result$review_flag[2])
    expect_true(result$review_flag[3])
  })

  it("summarizes parse and resolve results for metric cards", {
    parse_results <- build_parse_results(c("Falco sparverius", "Falco sparverius"))
    resolve_results <- build_resolution_results(
      c("Falco sparverius", "Invented bird species"),
      max_distance = 0,
      batch_size = 10,
      parallel = FALSE
    )

    parse_summary <- summarize_app_results(parse_results, mode = "parse")
    resolve_summary <- summarize_app_results(resolve_results, mode = "resolve")

    expect_true(all(c("label", "value", "note") %in% names(parse_summary)))
    expect_equal(resolve_summary$value[resolve_summary$label == "Exact"], 1)
    expect_equal(resolve_summary$value[resolve_summary$label == "Unmatched"], 1)
  })
})
