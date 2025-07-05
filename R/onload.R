#' .onAttach hook
#'
#' Hook function that runs when the package is attached via \code{library()}.
#' It displays the package version and checks for UNOP checklist updates.
#'
#' @param lib A character string indicating the path to the library.
#' @param pkg A character string with the name of the package.
#' @keywords internal
.onAttach <- function(lib, pkg) {
  # Mostrar mensaje de bienvenida con versión del paquete
  packageStartupMessage("This is avesperu ",
                        utils::packageDescription("avesperu",
                                                  fields = "Version"),
                        appendLF = TRUE
  )

  # Verificar si la base de datos UNOP ha sido actualizada
  aviso <- tryCatch({
    unop_check_update("23 de junio de 2025")
  }, error = function(e) {
    "Could not verify whether the UNOP database has been updated."
  })

  packageStartupMessage(aviso)
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
