
.onAttach <- function(lib, pkg) {
  packageStartupMessage("This is avesperu ",
                        utils::packageDescription("avesperu",
                                                  fields = "Version"
                        ),
                        appendLF = TRUE
  )
}


# -------------------------------------------------------------------------

show_progress <- function() {
  isTRUE(getOption("avesperu.show_progress")) && # user disables progress bar
    interactive() # Not actively knitting a document
}



.onLoad <- function(libname, pkgname) {
  opt <- options()
  opt_avesperu<- list(
    avesperu.show_progress = TRUE
  )
  to_set <- !(names(opt_avesperu) %in% names(opt))
  if (any(to_set)) options(opt_avesperu[to_set])
  invisible()
}

