# .onAttach hook

Hook function that runs when the package is attached via
[`library()`](https://rdrr.io/r/base/library.html). It displays the
package version and checks for UNOP checklist updates.

## Usage

``` r
.onAttach(lib, pkg)
```

## Arguments

- lib:

  A character string indicating the path to the library.

- pkg:

  A character string with the name of the package.
