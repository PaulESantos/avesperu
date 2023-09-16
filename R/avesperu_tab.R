#' avesperu_tab Dataset
#'
#' The avesperu_tab dataset contains a tibble that provides information on bird
#' species recorded in Peru, based on the "List of the Birds of Peru"
#' by M. A. Plenge. It includes details such as scientific names, English names,
#'  Spanish names, order, family, and status of each species.
#'
#' @format A tibble with 1,892 rows and 6 columns:
#'   \describe{
#'     \item{scientific_name}{Scientific name of the bird species.}
#'     \item{english_name}{English common name of the bird species.}
#'     \item{spanish_name}{Spanish common name of the bird species.}
#'     \item{order}{The order to which the bird species belongs.}
#'     \item{family}{The family to which the bird species belongs.}
#'     \item{status}{Status of the bird species (e.g., resident, endémic,
#'     migratory, etc.).}
#'   }
#'
#'
#' @details This dataset is designed to provide users with comprehensive
#' information about the avian species found in Peru, as documented
#' by M. A. Plenge. It is organized for easy access and utilization within
#' the R environment.
#'
#' @examples
#' # Load the avesperu package
#' library(avesperu)
#'
#' # Access the avesperu_tab dataset
#' data("avesperu_tab")
#'
#' # Display the first few rows
#' head(avesperu_tab)
#'
#' @seealso
#' For more information about the "avesperu" package and the data sources, visit
#' the package's GitHub repository: \url{https://github.com/PaulESantos/avesperu}
#'
#' @references
#' The dataset is based on the "List of the Birds of Peru" by M. A. Plenge.
#'
#' @author
#' Data compilation: M. A. Plenge, Package implementation: Paul Efren Santos Andrade
#'
#' @keywords dataset
"avesperu_tab"
