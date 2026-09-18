# Remove archives from the cache

Remove archives from the cache

## Usage

``` r
rais_cache_clear(year = NULL, cache_dir = NULL)
```

## Arguments

- year:

  Optional reference years whose archives are removed. `NULL` removes
  every cached archive.

- cache_dir:

  Optional path. When given, it is returned as is (after creating the
  folder).

## Value

Invisibly, the number of files removed.

## Examples

``` r
rais_cache_clear()
```
