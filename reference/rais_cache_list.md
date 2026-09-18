# List the archives currently in the cache

List the archives currently in the cache

## Usage

``` r
rais_cache_list(cache_dir = NULL)
```

## Arguments

- cache_dir:

  Optional path. When given, it is returned as is (after creating the
  folder).

## Value

A tibble with columns `path`, `year`, `edition`, `type`, `group`,
`file`, `size_bytes` and `modified`.

## Examples

``` r
rais_cache_list()
#> # A tibble: 0 × 8
#> # ℹ 8 variables: path <chr>, year <int>, edition <chr>, type <chr>,
#> #   group <chr>, file <chr>, size_bytes <dbl>, modified <dttm>
```
