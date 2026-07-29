# shinyapps.io entrypoint for avesperu

options(avesperu.check_updates = FALSE)

if (!requireNamespace("avesperu", quietly = TRUE)) {
  if (!requireNamespace("pkgload", quietly = TRUE)) {
    stop(
      "The 'pkgload' package is required to load the local avesperu source bundle.",
      call. = FALSE
    )
  }

  pkgload::load_all(path = ".", export_all = FALSE, helpers = FALSE, quiet = TRUE)
}

app_ns <- asNamespace("avesperu")

shiny::shinyApp(
  ui = get("avesperu_app_ui", envir = app_ns)(),
  server = get("avesperu_app_server", envir = app_ns)
)
