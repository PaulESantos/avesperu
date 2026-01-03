#' aves_peru_2025_v4
#'
#' The `aves_peru_2025_v4` dataset provides an updated tibble of bird
#' species recorded in Peru, based on the most recent taxonomic revisions
#' by the South American Checklist Committee (SACC).
#'
#' This version reflects dramatic taxonomic changes and category updates
#' based on published articles, photographs, and sound recordings archived
#' in accredited institutions. It also includes a classification criterion
#' following the SACC guidelines. Species without a specific code are considered
#' resident species, equivalent to the "X" category of the SACC.
#'
#' @format A tibble with 1,917 rows and 6 columns:
#' \describe{
#'   \item{order_name}{Taxonomic order to which the bird species belongs.}
#'   \item{family_name}{Taxonomic family to which the bird species belongs.}
#'   \item{scientific_name}{Scientific name of the bird species.}
#'   \item{english_name}{English common name of the bird species.}
#'   \item{spanish_name}{Spanish common name of the bird species.}
#'   \item{status}{Category indicating the species' status, based on the following codes:
#'     \itemize{
#'       \item{\code{X}}: Resident species.
#'       \item{\code{E}}: Endemic species. A species is considered endemic to Peru until a record outside its borders is published.
#'       \item{\code{NB}}: Non-breeding (migratory) species. Species that occur regularly in Peru but only during their non-breeding period.
#'       \item{\code{V}}: Vagrant species. Species that occasionally occur in Peru but are not part of the usual avifauna.
#'       \item{\code{IN}}: Introduced species. Species introduced to Peru by humans (or have colonized from introduced populations elsewhere) and have established self-sustaining breeding populations.
#'       \item{\code{H}}: Hypothetical species. Records based only on observations, specimens of dubious origin, or unpublished photographs or recordings kept in private hands.
#'       \item{\code{EX}}: Extinct or extirpated species. Species that have gone extinct or have been extirpated from Peru.
#'     }
#'   }
#' }
#'
#' @details
#' - **Total species**: 1,917
#' - **Distribution by status**:
#'   \itemize{
#'     \item{\code{X}}: 1,547 species
#'     \item{\code{E}}: 120 species
#'     \item{\code{NB}}: 139 species
#'     \item{\code{V}}: 85 species
#'     \item{\code{IN}}: 3 species
#'     \item{\code{EX}}: 0 species
#'     \item{\code{H}}: 23 species
#'   }
#'
#'
#'
#' These updates reflect the SACC’s continuous evaluation process, which now recognizes several former subspecies as full species.
#'
#' @examples
#' # Load the dataset
#' data("aves_peru_2025_v4")
#'
#' @seealso
#' For more information about the data, visit:
#' \url{https://sites.google.com/site/boletinunop/checklist}
#'
#' @references
#' Plenge, M. A. Version (29-09-2025) List of the birds of Peru / Lista de
#' las aves del Perú. Unión de Ornitólogos del Perú:
#' \url{https://sites.google.com/site/boletinunop/checklist}
#'
#' @author
#' Data compilation: Manuel A. Plenge
#' Package implementation: Paul Efren Santos Andrade
#'
#' @keywords dataset birds Peru taxonomy SACC ornithology
"aves_peru_2025_v4"
