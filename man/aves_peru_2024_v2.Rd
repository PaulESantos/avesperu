% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/aves_peru_2024_v2.R
\docType{data}
\name{aves_peru_2024_v2}
\alias{aves_peru_2024_v2}
\title{aves_peru_2024_v2 Dataset}
\format{
A tibble with 1,909 rows and 6 columns:
\describe{
\item{order_name}{Taxonomic order to which the bird species
belongs.}
\item{family_name}{Taxonomic family to which the bird species
belongs.}
\item{scientific_name}{Scientific name of the bird species.}
\item{english_name}{English common name of the bird species.}
\item{spanish_name}{Spanish common name of the bird species.}
\item{status}{Category indicating the species' status, based on
the following codes:
X - Resident species.
E - Endemic species.
NB - Migratory species.
V - Vagrant species.
IN - Introduced species.
EX - Extirpated species.
H - Hypothetical species.
}
}
}
\usage{
aves_peru_2024_v2
}
\description{
The \code{aves_peru_2024_v2} dataset provides an updated tibble of bird
species recorded in Peru, based on the latest taxonomic revisions
by the South American Checklist Committee (SACC).
}
\details{
This version incorporates significant taxonomic changes, new categories,
and updates derived from recent publications, photographs, and sound
recordings archived in accredited institutions.
\itemize{
\item \strong{Total species}: 1,909
\item \strong{Distribution by status}:
\itemize{
\item{\code{X}}: 1,542 species
\item{\code{E}}: 117 species
\item{\code{NB}}: 138 species
\item{\code{V}}: 83 species
\item{\code{IN}}: 3 species
\item{\code{EX}}: 0 species
\item{\code{H}}: 26 species
}
}

Species near Peru’s borders with Ecuador, Colombia, Brazil, and Chile
are included at the end of the list as potential additions to the
Peruvian bird inventory. These updates reflect the SACC's ongoing
efforts to evaluate and recognize certain subspecies as full species.
}
\examples{
# Load the dataset
data("aves_peru_2024_v2")

# Display the first few rows
head(aves_peru_2024_v2)


}
\references{
Plenge, M. A. (2024). Lista de las aves del Perú. Last updated: December 2, 2024.
Unión de Ornitólogos del Perú.
}
\seealso{
For more information about the taxonomy, visit the South American Checklist Committee (SACC) website:
\url{https://sites.google.com/site/boletinunop/checklist}
}
\author{
Data compilation: Manuel A. Plenge
Package implementation: Paul Efren Santos Andrade
}
\keyword{Peru}
\keyword{SACC}
\keyword{birds}
\keyword{dataset}
\keyword{ornithology}
\keyword{taxonomy}
