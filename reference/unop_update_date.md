# Get Last Update Date from UNOP Checklist Website

This function scrapes the "Boletin UNOP" checklist page and extracts the
last update date mentioned in the text.

## Usage

``` r
unop_update_date()
```

## Value

A character string with the date in the format "dd de mes de yyyy", or
NA if no date is found.
