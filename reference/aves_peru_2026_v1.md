# aves_peru_2026_v1

The `aves_peru_2026_v1` dataset provides the most current and
comprehensive tibble of bird species recorded in Peru, based on the
taxonomic revisions by the South American Checklist Committee (SACC) as
of February 27, 2026.

## Usage

``` r
aves_peru_2026_v1
```

## Format

A tibble with 1,925 rows and 9 columns:

- order_name:

  Character. Taxonomic order to which the bird species belongs.

- family_name:

  Character. Taxonomic family to which the bird species belongs.

- genus:

  Character. Genus name of the bird species.

- species_epithet:

  Character. Specific epithet (species name without genus).

- scientific_name:

  Character. Complete scientific name of the bird species (binomial
  nomenclature: genus + species epithet).

- english_name:

  Character. Common name in English.

- spanish_name:

  Character. Common name in Spanish (Peruvian usage).

- status:

  Character. Conservation and occurrence status category in Spanish. See
  Details section for complete descriptions.

- status_code:

  Character. Original SACC status code. Values: X, E, NB, V, IN, U, EX.
  See Details section for code definitions.

## Source

Data compiled by Manuel A. Plenge and Fernando Angulo (UNOP). For
corrections or updates, contact: chamaepetes@gmail.com

## Details

All records are based on published evidence (specimens, photographs,
videos, or recordings) deposited in accredited institutional
collections. The dataset follows strict inclusion criteria established
by the SACC and the Unión de Ornitólogos del Perú (UNOP).

### Dataset Summary

- **Total species**: 1,925

- **Version date**: March 23, 2026

- **SACC baseline date**: February 27, 2026

### Distribution by Status

|               |          |           |                           |
|---------------|----------|-----------|---------------------------|
| **Status**    | **Code** | **Count** | **Description**           |
| Residente     | X        | 1,552     | Resident breeding species |
| Endémico      | E        | 119       | Endemic to Peru           |
| Migratorio    | NB       | 140       | Non-breeding migrants     |
| Divagante     | V        | 90        | Vagrant species           |
| Introducido   | IN       | 3         | Introduced species        |
| No confirmado | U        | 21        | Unconfirmed records       |
| Extirpado     | EX       | 0         | Extirpated species        |

### Status Categories (Detailed)

#### Residente (X - Resident)

Species that breed in Peru and maintain permanent or seasonal
populations. This is the default category for species without a specific
status code.

#### Endémico (E - Endemic)

Species whose entire known range is within Peru. A species is considered
endemic until a published record documents its occurrence outside
Peruvian borders.

#### Migratorio (NB - Non-breeding)

Species that occur regularly in Peru but only during their non-breeding
period. These are typically austral or boreal migrants that breed
elsewhere.

#### Divagante (V - Vagrant)

Species that occur occasionally in Peru and are not part of the regular
avifauna. These represent extralimital records or irregular visitors.

#### Introducido (IN - Introduced)

Species introduced to Peru by humans (directly or colonized from
introduced populations elsewhere) that have established self-sustaining
breeding populations.

#### No confirmado (U - Unconfirmed)

Records that lack definitive published evidence. This includes:

- Sight records without corroborating physical evidence

- Specimens of dubious or uncertain origin

- Unpublished photographs or recordings in private collections

#### Extirpado (EX - Extirpated/Extinct)

Species that have gone extinct globally or have been extirpated from
Peru.

### Taxonomic Authority

The taxonomic sequence and species limits follow the South American
Checklist Committee (SACC) of the American Ornithological Society,
reflecting the committee's decisions through February 27, 2026.

To compare this local dataset version against the latest UNOP checklist
available online, run
[`unop_check_update()`](https://paulesantos.github.io/avesperu/reference/unop_check_update.md).

## Note

This dataset is updated periodically as new species are documented and
taxonomic revisions are published. Check the UNOP website for the most
current version.

## References

Plenge, M. A. & F. Angulo. Version 23-03-2026. Lista de las aves del
Perú / List of the birds of Peru. Unión de Ornitólogos del Perú:
<https://sites.google.com/site/boletinunop/checklist>

## See also

- UNOP Checklist: <https://sites.google.com/site/boletinunop/checklist>

- SACC: <http://www.museum.lsu.edu/~Remsen/SACCBaseline.htm>

- [`search_avesperu`](https://paulesantos.github.io/avesperu/reference/search_avesperu.md)
  for species name validation

## Author

Data compilation: Manuel A. Plenge & Fernando Angulo Package
implementation: Paul Efren Santos Andrade

## Examples

``` r
# Load the dataset
data("aves_peru_2026_v1")

# View structure
str(aves_peru_2026_v1)
#> tibble [1,925 × 9] (S3: tbl_df/tbl/data.frame)
#>  $ order_name     : chr [1:1925] "Rheiiformes" "Tinamiformes" "Tinamiformes" "Tinamiformes" ...
#>  $ family_name    : chr [1:1925] "Rheidae" "Tinamidae" "Tinamidae" "Tinamidae" ...
#>  $ genus          : chr [1:1925] "Pterocnemia" "Nothocercus" "Nothocercus" "Nothocercus" ...
#>  $ species_epithet: chr [1:1925] "pennata" "julius" "bonapartei" "nigrocapillus" ...
#>  $ scientific_name: chr [1:1925] "Pterocnemia pennata" "Nothocercus julius" "Nothocercus bonapartei" "Nothocercus nigrocapillus" ...
#>  $ english_name   : chr [1:1925] "Lesser Rhea" "Tawny-breasted Tinamou" "Highland Tinamou" "Hooded Tinamou" ...
#>  $ spanish_name   : chr [1:1925] "Ñandú Petizo" "Perdiz de Pecho Leonado" "Perdiz Montesa" "Perdiz de Cabeza Negra" ...
#>  $ status         : chr [1:1925] "Residente" "Residente" "Residente" "Residente" ...
#>  $ status_code    : chr [1:1925] "X" "X" "X" "X" ...
#>  - attr(*, "version_date")= chr "23 de marzo de 2026"
#>  - attr(*, "sacc_date")= chr "27 de febrero de 2026"
#>  - attr(*, "authors")= chr [1:2] "Manuel A. Plenge" "Fernando Angulo"
#>  - attr(*, "contact")= chr "chamaepetes@gmail.com"
#>  - attr(*, "source_url")= chr "https://sites.google.com/site/boletinunop/checklist"
#>  - attr(*, "created_on")= POSIXct[1:1], format: "2026-03-25 03:08:59"

# Summary by status
table(aves_peru_2026_v1$status)
#> 
#>     Divagante      Endémico   Introducido    Migratorio No confirmado 
#>            90           119             3           140            21 
#>     Residente 
#>          1552 

```
