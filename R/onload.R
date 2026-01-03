#' .onAttach hook
#'
#' Hook function that runs when the package is attached via \code{library()}.
#' It displays the package version and checks for UNOP checklist updates.
#'
#' @param lib A character string indicating the path to the library.
#' @param pkg A character string with the name of the package.
#' @keywords internal

.onAttach <- function(lib, pkg) {

  if (!interactive()) return(invisible(NULL))

  cli::cli_rule(
    left = "avesperu",
    right = paste("v", utils::packageVersion("avesperu"))
  )

  cli::cli_alert_success("Package successfully loaded.")
  cli::cli_alert_info("Checking UNOP checklist status...")

  tryCatch(
    unop_check_update(),
    error = function(e) {
      cli::cli_alert_warning(
        "Unable to verify whether the UNOP checklist is up to date."
      )
    }
  )

  invisible(NULL)
}
# -------------------------------------------------------------------------

#' Determine whether to show progress bar
#' Return logical TRUE/FALSE depending on options and interactive session
show_progress <- function() {
  isTRUE(getOption("avesperu.show_progress")) && # Usuario activa opción
    interactive() # Sesión interactiva (no knit)
}


# -------------------------------------------------------------------------
#' .onLoad hook
#'
#' Hook function that runs when the package is loaded.
#' It sets default options for the package.
#'
#' @param libname A character string with the name of the library directory.
#' @param pkgname A character string with the name of the package.
#' @keywords internal
.onLoad <- function(libname, pkgname) {
  # Leer opciones actuales
  opt <- options()

  # Establecer opciones por defecto para el paquete
  opt_avesperu <- list(
    avesperu.show_progress = TRUE
  )

  # Solo establecer opciones si no están ya definidas
  to_set <- !(names(opt_avesperu) %in% names(opt))
  if (any(to_set)) options(opt_avesperu[to_set])

  invisible()
}
