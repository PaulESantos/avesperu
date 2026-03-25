describe("unop_check_update()", {

  it("returns a structured result when the local dataset is current", {
    local_mocked_bindings(
      unop_update_date = function() "23 de marzo de 2026"
    )

    result <- unop_check_update(verbose = FALSE)

    expect_true(result$success)
    expect_true(result$is_up_to_date)
    expect_false(result$has_update)
    expect_equal(result$current_version_date, "23 de marzo de 2026")
    expect_equal(result$online_version_date, "23 de marzo de 2026")
  })

  it("detects when a newer UNOP version is available", {
    local_mocked_bindings(
      unop_update_date = function() "24 de marzo de 2026"
    )

    result <- unop_check_update(verbose = FALSE)

    expect_true(result$success)
    expect_false(result$is_up_to_date)
    expect_true(result$has_update)
  })

  it("returns a failed result when the website date cannot be retrieved", {
    local_mocked_bindings(
      unop_update_date = function() {
        out <- NA_character_
        attr(out, "reason") <- "mock failure"
        out
      }
    )

    result <- unop_check_update(verbose = FALSE)

    expect_false(result$success)
    expect_true(is.na(result$is_up_to_date))
    expect_match(result$message, "mock failure")
  })

  it("validates the verbose parameter", {
    expect_error(
      unop_check_update(verbose = "yes"),
      "must be a single TRUE or FALSE value"
    )
  })
})
