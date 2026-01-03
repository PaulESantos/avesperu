#' aves_peru_2025_v5
#'
#' The `aves_peru_2025_v5` dataset provides the most current and comprehensive
#' tibble of bird species recorded in Peru, based on the latest taxonomic
#' revisions by the South American Checklist Committee (SACC) as of December
#' 22, 2025.
#'
#' All records are based on published evidence (specimens, photographs, videos, or recordings) deposited in accredited
#' institutional collections. The dataset follows strict inclusion criteria
#' established by the SACC and the Unión de Ornitólogos del Perú (UNOP).
#'
#' @format A tibble with 1,919 rows and 9 columns:
#' \describe{
#'   \item{order_name}{Character. Taxonomic order to which the bird species belongs.}
#'   \item{family_name}{Character. Taxonomic family to which the bird species belongs.}
#'   \item{genus}{Character. Genus name of the bird species.}
#'   \item{species_epithet}{Character. Specific epithet (species name without genus).}
#'   \item{scientific_name}{Character. Complete scientific name of the bird species
#'     (binomial nomenclature: genus + species epithet).}
#'   \item{english_name}{Character. Common name in English.}
#'   \item{spanish_name}{Character. Common name in Spanish (Peruvian usage).}
#'   \item{status}{Character. Conservation and occurrence status category in Spanish.
#'     See Details section for complete descriptions.}
#'   \item{status_code}{Character. Original SACC status code. Values: X, E, NB, V,
#'     IN, U, EX. See Details section for code definitions.}
#' }
#'
#' @details
#' ## Dataset Summary
#' - **Total species**: 1,919
#' - **Version date**: December 29, 2025
#' - **SACC baseline date**: December 22, 2025
#'
#' ## Distribution by Status
#' \tabular{lrrl}{
#'   \strong{Status} \tab \strong{Code} \tab \strong{Count} \tab \strong{Description} \cr
#'   Residente \tab X \tab ~1,547 \tab Resident breeding species \cr
#'   Endémico \tab E \tab ~120 \tab Endemic to Peru \cr
#'   Migratorio \tab NB \tab ~140 \tab Non-breeding migrants \cr
#'   Divagante \tab V \tab ~85 \tab Vagrant species \cr
#'   Introducido \tab IN \tab 3 \tab Introduced species \cr
#'   No confirmado \tab U \tab ~23 \tab Unconfirmed records \cr
#'   Extirpado \tab EX \tab 0 \tab Extirpated species \cr
#' }
#'
#' ## Status Categories (Detailed)
#'
#' ### Residente (X - Resident)
#' Species that breed in Peru and maintain permanent or seasonal populations.
#' This is the default category for species without a specific status code.
#'
#' ### Endémico (E - Endemic)
#' Species whose entire known range is within Peru. A species is considered
#' endemic until a published record documents its occurrence outside Peruvian
#' borders.
#'
#' ### Migratorio (NB - Non-breeding)
#' Species that occur regularly in Peru but only during their non-breeding
#' period. These are typically austral or boreal migrants that breed elsewhere.
#'
#' ### Divagante (V - Vagrant)
#' Species that occur occasionally in Peru and are not part of the regular
#' avifauna. These represent extralimital records or irregular visitors.
#'
#' ### Introducido (IN - Introduced)
#' Species introduced to Peru by humans (directly or colonized from
#' introduced populations elsewhere) that have established self-sustaining
#' breeding populations.
#'
#' ### No confirmado (U - Unconfirmed)
#' Records that lack definitive published evidence. This includes:
#' \itemize{
#'   \item Sight records without corroborating physical evidence
#'   \item Specimens of dubious or uncertain origin
#'   \item Unpublished photographs or recordings in private collections
#' }
#'
#' ### Extirpado (EX - Extirpated/Extinct)
#' Species that have gone extinct globally or have been extirpated from Peru.
#'
#' ## Taxonomic Authority
#'
#' The taxonomic sequence and species limits follow the South American
#' Checklist Committee (SACC) of the American Ornithological Society,
#' reflecting the committee's decisions through December 22, 2025.
#'
#'
#' @examples
#' # Load the dataset
#' data("aves_peru_2025_v5")
#'
#' # View structure
#' str(aves_peru_2025_v5)
#'
#' # Summary by status
#' table(aves_peru_2025_v5$status)
#'
#'
#' @seealso
#' \itemize{
#'   \item UNOP Checklist: \url{https://sites.google.com/site/boletinunop/checklist}
#'   \item SACC: \url{http://www.museum.lsu.edu/~Remsen/SACCBaseline.htm}
#'   \item \code{\link{search_avesperu}} for species name validation
#' }
#'
#' @references
#' Plenge, M. A. & F. Angulo. Version 29-12-2025. Lista de las aves del Perú /
#' List of the birds of Peru. Unión de Ornitólogos del Perú:
#' \url{https://sites.google.com/site/boletinunop/checklist}
#'
#' @source
#' Data compiled by Manuel A. Plenge and Fernando Angulo (UNOP).
#' For corrections or updates, contact: chamaepetes@gmail.com
#'
#' @author
#' Data compilation: Manuel A. Plenge & Fernando Angulo
#' Package implementation: Paul Efren Santos Andrade
#'
#' @note
#' This dataset is updated periodically as new species are documented and
#' taxonomic revisions are published. Check the UNOP website for the most
#' current version.
#'
#' @keywords datasets birds Peru taxonomy SACC ornithology checklist avifauna
"aves_peru_2025_v5"
