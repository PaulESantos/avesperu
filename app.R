# Load the source shipped with this application, never a stale installed copy.
options(avesperu.check_updates = FALSE)
if (!requireNamespace("pkgload", quietly = TRUE)) {
  stop("Install pkgload to load the bundled avesperu source.", call. = FALSE)
}
pkgload::load_all(path = ".", export_all = FALSE, helpers = FALSE, quiet = TRUE)
app_ns <- asNamespace("avesperu")
get("check_avesperu_app_deps", app_ns)()
shiny::shinyApp(
  ui = get("avesperu_app_ui", app_ns)(),
  server = get("avesperu_app_server", app_ns)
)
