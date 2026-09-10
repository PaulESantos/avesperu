test_that("row selection preserves audit alignment including duplicates and NA rows", {
  out <- search_avesperu(
    c("Falco CF. sparverius", "Tinamus major"),
    return_details = TRUE
  )
  subset <- out[c(2, 1, 1, NA), ]
  expect_identical(
    attr(subset, "reconciliation")$submitted_name,
    c(
      "Tinamus major",
      "Falco CF. sparverius",
      "Falco CF. sparverius",
      NA_character_
    )
  )
  expect_identical(nrow(attr(out[FALSE, ], "reconciliation")), 0L)
  expect_identical(
    attr(out["status"], "reconciliation"),
    attr(out, "reconciliation")
  )
  expect_identical(out[1, "status", drop = TRUE], "Residente")
})
