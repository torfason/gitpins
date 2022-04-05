
<!-- README.md is generated from README.Rmd. Please edit that file -->

# gitpins

<!-- badges: start -->

[![R-CMD-check](https://github.com/torfason/gitpins/workflows/R-CMD-check/badge.svg)](https://github.com/torfason/gitpins/actions)
<!-- badges: end -->

Pin URLs to local file and version the pins with git. Repeated downloads
are versioned using a local git repository, and if getting a document
from the web is not successful, a previous local download is made
available.

## The problem

You want to quickly and easily process an online resource using R
functions, some of which only accept local files. Thus you would like
the following properties for your workflow:

-   Download to a local file
-   But avoid downloading on every single run
-   Refresh your data regularly from the online source
-   Use a local copy if the online resource is not accessible
-   Have the local copy be easily accessible in a predictable location
-   Not ruin your local copy if the online version should change in a
    “bad” way

## The solution

The `gitpins` package downloads a URL to a local file in the `gitpins`
folder inside your project (the currently fixed path is determined by
`here("gitpins")`), and then returns the full file name name of the
local file, which can be passed as an argument to any function that
expects to read such a file.

``` r
# Downloads on first try
gitpin("https://vincentarelbundock.github.io/Rdatasets/csv/openintro/country_iso.csv") |> 
  read.csv() |> head()
#> Downloaded fresh version ...
#>   X country_code         country_name year top_level_domain
#> 1 1           AD              Andorra 1974              .ad
#> 2 2           AE United Arab Emirates 1974              .ae
#> 3 3           AF          Afghanistan 1974              .af
#> 4 4           AG  Antigua and Barbuda 1974              .ag
#> 5 5           AI             Anguilla 1985              .ai
#> 6 6           AL              Albania 1974              .al
```

You can maintain as many resources as you need:

``` r
# Another resource
gitpin("https://vincentarelbundock.github.io/Rdatasets/csv/datasets/sunspot.month.csv") |> 
  read.csv() |> head()
#> Downloaded fresh version ...
#>   X     time value
#> 1 1 1749.000  58.0
#> 2 2 1749.083  62.6
#> 3 3 1749.167  70.0
#> 4 4 1749.250  55.7
#> 5 5 1749.333  85.0
#> 6 6 1749.417  83.5
```

The file is downloaded the first time you run `gitpin` on a given URL
(the actual download is done with `curl::curl_download()`). After that,
it checks to see the age of the local file and re-downloads if it is to
old. The default refresh interval is 12 hours, but is configurable with
a parameter.

Note that the return value of the `gitpin()` function is simply the full
path to the local copy of the file. You can therefore use `gitpin()`
with the original URL wherever you would have used the local path of the
resource. The exact name of the file is constructed in a deterministic
way based on the URL (specifically, the base name is the `digest()` of
the URL).

``` r
# Uses a cached copy if a recent one is available (start of the url changed for privacy)
gitpin("https://vincentarelbundock.github.io/Rdatasets/csv/openintro/country_iso.csv") |>
  gsub(pattern=".*/(gitpins/.*)", replacement="/home/user/project/\\1")
#> Recent version found, using it ...
#> [1] "/home/user/project/gitpins/5ad1e570044be11330713642c682b9db.data"
```

The refresh interval is configured with the `refresh_hours` parameter.
Use `refresh_hours=0` to force a download on every call, and
`refresh_hours=Inf` to always use the local copy (after the first
download).

``` r
# Force a reload by specifying zero refresh time
gitpin("https://vincentarelbundock.github.io/Rdatasets/csv/openintro/country_iso.csv",
       refresh_hours = 0) |>
  gsub(pattern=".*/(gitpins/.*)", replacement="/home/user/project/\\1")
#> Downloaded fresh version ...
#> [1] "/home/user/project/gitpins/5ad1e570044be11330713642c682b9db.data"

# Always use local copy by specifying Inf refresh time
gitpin("https://vincentarelbundock.github.io/Rdatasets/csv/openintro/country_iso.csv",
       refresh_hours = Inf) |>
  gsub(pattern=".*/(gitpins/.*)", replacement="/home/user/project/\\1")
#> Recent version found, using it ...
#> [1] "/home/user/project/gitpins/5ad1e570044be11330713642c682b9db.data"
```

The `gitpins` directory is actually a local `git` repository, and each
new version is committed to the repository. That way, a complete history
of the downloads is kept, but if the resource is not changing a lot,
this history will not take up an inordinate amount of space (because of
the deduplication properties of `git`).

If the resource gets borked, you can retrieve older versions using git.
A function is provided to list available pins (with or without history),
but beyond that, the user is expected to use `git` directly for more
complex retrieval operations.

``` r
list_gitpins()
#> Loading required namespace: tibble
#> # A tibble: 2 × 2
#>   timestamp                 url                                                                          
#>   <chr>                     <chr>                                                                        
#> 1 2022-04-05 18:10:13.14187 https://vincentarelbundock.github.io/Rdatasets/csv/openintro/country_iso.csv 
#> 2 2022-04-05 18:10:12.93155 https://vincentarelbundock.github.io/Rdatasets/csv/datasets/sunspot.month.csv
list_gitpins(history = TRUE)
#> # A tibble: 3 × 2
#>   timestamp                 url                                                                          
#>   <chr>                     <chr>                                                                        
#> 1 2022-04-05 18:10:13.14187 https://vincentarelbundock.github.io/Rdatasets/csv/openintro/country_iso.csv 
#> 2 2022-04-05 18:10:12.93155 https://vincentarelbundock.github.io/Rdatasets/csv/datasets/sunspot.month.csv
#> 3 2022-04-05 18:10:12.50094 https://vincentarelbundock.github.io/Rdatasets/csv/openintro/country_iso.csv
```

## Installation

You can install the development version of `gitpins` like so:

``` r
pak::pak("torfason/gitpins")
# or alternatively
remotes::install_github("torfason/gitpins")
```

Note that `gitpins` uses the native pipe operator (`|>`) and so depends
on `R (>= 4.1.0)`. If this is an issue for you, holler and I can
probably be convinced of changing it to make it compatible with older
versions.

## Related packages and feedback

This package was inspired by the `pins` package, and in particular the
`pin()` function. However, that function stores the actual local file in
a system location rather than inside the project, so using it was not
totally reliable. Also, it did not have the desired versioning
properties. Thus, `gitpins` was born.

For feature requests, bugs, or other feedback, feel free to file an
issue.
