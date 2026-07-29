if (!requireNamespace("rsconnect", quietly = TRUE)) {
  stop("Install 'rsconnect' before deploying.", call. = FALSE)
}

app_name <- Sys.getenv("AVESPERU_SHINYAPP_NAME", unset = "avesperu")

rsconnect::deployApp(
  appDir = normalizePath(".", winslash = "/", mustWork = TRUE),
  appPrimaryDoc = "app.R",
  appName = app_name,
  forceUpdate = TRUE
)
