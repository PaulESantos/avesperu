# aves_peru_2025_v4

The `aves_peru_2025_v4` dataset provides an updated tibble of bird
species recorded in Peru, based on the most recent taxonomic revisions
by the South American Checklist Committee (SACC).

## Usage

``` r
aves_peru_2025_v4
```

## Format

A tibble with 1,916 rows and 6 columns:

- order_name:

  Taxonomic order to which the bird species belongs.

- family_name:

  Taxonomic family to which the bird species belongs.

- scientific_name:

  Scientific name of the bird species.

- english_name:

  English common name of the bird species.

- spanish_name:

  Spanish common name of the bird species.

- status:

  Category indicating the species' status, based on the following codes:

  - `X`: Resident species.

  - `E`: Endemic species. A species is considered endemic to Peru until
    a record outside its borders is published.

  - `NB`: Non-breeding (migratory) species. Species that occur regularly
    in Peru but only during their non-breeding period.

  - `V`: Vagrant species. Species that occasionally occur in Peru but
    are not part of the usual avifauna.

  - `IN`: Introduced species. Species introduced to Peru by humans (or
    have colonized from introduced populations elsewhere) and have
    established self-sustaining breeding populations.

  - `H`: Hypothetical species. Records based only on observations,
    specimens of dubious origin, or unpublished photographs or
    recordings kept in private hands.

  - `EX`: Extinct or extirpated species. Species that have gone extinct
    or have been extirpated from Peru.

## Details

This version reflects dramatic taxonomic changes and category updates
based on published articles, photographs, and sound recordings archived
in accredited institutions. It also includes a classification criterion
following the SACC guidelines. Species without a specific code are
considered resident species, equivalent to the "X" category of the SACC.

- **Total species**: 1,916

- **Distribution by status**:

  - `X`: 1,547 species

  - `E`: 119 species

  - `NB`: 139 species

  - `V`: 85 species

  - `IN`: 3 species

  - `EX`: 0 species

  - `H`: 23 species

These updates reflect the SACC’s continuous evaluation process, which
now recognizes several former subspecies as full species.

## References

Plenge, M. A. Version (29-09-2025) List of the birds of Peru / Lista de
las aves del Perú. Unión de Ornitólogos del Perú:
<https://sites.google.com/site/boletinunop/checklist>

## See also

For more information about the data, visit:
<https://sites.google.com/site/boletinunop/checklist>

## Author

Data compilation: Manuel A. Plenge Package implementation: Paul Efren
Santos Andrade

## Examples

``` r
# Load the dataset
data("aves_peru_2025_v4")
```
