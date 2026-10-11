test_that("run_avesperu_app does not start Shiny during non-interactive checks", {
  expect_error(
    run_avesperu_app(),
    "interactive R session"
  )
})

test_that("run_avesperu_app does not start Shiny while pkgdown builds", {
  withr::local_envvar(IN_PKGDOWN = "true")

  expect_error(
    run_avesperu_app(),
    "pkgdown build"
  )
})
