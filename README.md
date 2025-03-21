
<!-- README.md is generated from README.Rmd. Please edit that file -->

# gitpins

<!-- badges: start -->

[![R-CMD-check](https://github.com/torfason/gitpins/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/torfason/gitpins/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

Pin URLs to local file and version the pins with git. Repeated downloads
are versioned using a local git repository, and if getting a document
from the web is not successful, a previous local download is made
available.

## The Problem

You want to quickly and easily process an online resource using R
functions, some of which only accept local files. Thus you would like
the following properties for your workflow:

- Download to a local file
- But avoid downloading on every single run
- Refresh your data regularly from the online source
- Use a local copy if the online resource is not accessible
- Have the local copy be easily accessible in a predictable location
- Not ruin your local copy if the online version should change in a
  “bad” way

## The Solution

The `gitpins` package downloads a URL to a local file in the `gitpins`
folder (defaults to `here::here("gitpins")`, but can be configured using
`gp_options()`), and then returns the full file name name of the local
file, which can be passed as an argument to any function that expects to
read such a file.

## Installation

Install `gitpins` using `pak`:

``` r
pak::pak("torfason/gitpins")
```

## Usage

``` r
# Downloads on first try
pin("https://vincentarelbundock.github.io/Rdatasets/csv/openintro/country_iso.csv") |> 
  read.csv() |> head()
#> pin() downloaded fresh version ...
#>   rownames country_code         country_name year top_level_domain
#> 1        1           AD              Andorra 1974              .ad
#> 2        2           AE United Arab Emirates 1974              .ae
#> 3        3           AF          Afghanistan 1974              .af
#> 4        4           AG  Antigua and Barbuda 1974              .ag
#> 5        5           AI             Anguilla 1985              .ai
#> 6        6           AL              Albania 1974              .al
```

You can maintain as many resources as you need:

``` r
# Another resource
pin("https://vincentarelbundock.github.io/Rdatasets/csv/datasets/sunspot.month.csv") |> 
  read.csv() |> head()
#> pin() downloaded fresh version ...
#>   rownames     time value
#> 1        1 1749.000  58.0
#> 2        2 1749.083  62.6
#> 3        3 1749.167  70.0
#> 4        4 1749.250  55.7
#> 5        5 1749.333  85.0
#> 6        6 1749.417  83.5
```

The file is downloaded the first time you run `pin()` on a given URL
(the actual download is done with `curl::curl_download()`). After that,
it checks to see the age of the local file and re-downloads if it is to
old. The default refresh interval is 12 hours, but is configurable with
a parameter.

Note that the return value of the `pin()` function is simply the full
path to the local copy of the file. You can therefore use `pin()` with
the original URL wherever you would have used the local path of the
resource. The exact name of the file is constructed in a deterministic
way based on the URL (specifically, the base name is the `digest()` of
the URL).

``` r
# Uses a cached copy if a recent one is available (start of the url changed for privacy)
pin("https://vincentarelbundock.github.io/Rdatasets/csv/openintro/country_iso.csv") |>
  gsub(pattern=".*/(gitpins/.*)", replacement="/home/user/project/\\1")
#> pin() found recent version, using it ...
#> [1] "/home/user/project/gitpins/5ad1e570044be11330713642c682b9db.data"
```

The refresh interval is configured with the `refresh_hours` parameter.
Use `refresh_hours=0` to force a download on every call, and
`refresh_hours=Inf` to always use the local copy (after the first
download). A helper function, `gp_dropper()` is provided for the case
where a new version of the resource “drops” at the same time every day.
The function allows you to set a lower interval in a given time window
after the expected drop time, to maximize the probability that an
updated version gets downloaded quickly.

``` r
# Force a reload by specifying zero refresh time
pin("https://vincentarelbundock.github.io/Rdatasets/csv/openintro/country_iso.csv",
       refresh_hours = 0) |>
  gsub(pattern=".*/(gitpins/.*)", replacement="/home/user/project/\\1")
#> pin() downloaded fresh version ...
#> [1] "/home/user/project/gitpins/5ad1e570044be11330713642c682b9db.data"

# Always use local copy by specifying Inf refresh time
pin("https://vincentarelbundock.github.io/Rdatasets/csv/openintro/country_iso.csv",
       refresh_hours = Inf) |>
  gsub(pattern=".*/(gitpins/.*)", replacement="/home/user/project/\\1")
#> pin() found recent version, using it ...
#> [1] "/home/user/project/gitpins/5ad1e570044be11330713642c682b9db.data"

# Set a lower interval for a given time window after a resource update "drops"
pin("https://vincentarelbundock.github.io/Rdatasets/csv/openintro/country_iso.csv",
       refresh_hours = gp_dropper(drop_hour = 12, drop_tz = "US/Eastern")) |>
  gsub(pattern=".*/(gitpins/.*)", replacement="/home/user/project/\\1")
#> pin() found recent version, using it ...
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
withr::with_options(list(width = 130), {
  gp_list()
  gp_list(history = TRUE)
})
#> Loading required namespace: tibble
#> # A tibble: 3 × 2
#>   timestamp                 url                                                 
#>   <chr>                     <chr>                                               
#> 1 2025-03-21 19:06:10.31363 https://vincentarelbundock.github.io/Rdatasets/csv/…
#> 2 2025-03-21 19:06:10.13430 https://vincentarelbundock.github.io/Rdatasets/csv/…
#> 3 2025-03-21 19:06:09.81114 https://vincentarelbundock.github.io/Rdatasets/csv/…
```

## Function Name Conflicts

For use with with another package that also defines a `pin()` function
(such as the `pins` package), the `conflicted` package comes highly
recommended, but the `exclude` option of the `library()` function is
also a valid approach. In either case, the `gp_pin()` function is
provided as an alias for `pin()` so you don’t need to specify the full
package name on each call:

### Using `conflicted`

``` r
library(conflicted)
conflicts_prefer(pins::pin())
library(pins)
library(gitpins)
gp_pin(URL)
```

### Using `exclude`

``` r
library(pins)
library(gitpins, exclude="pin")
gp_pin(URL)
```

## Related Packages, System Requirements, and Feedback

This package was inspired by the `pins` package, and in particular the
`pins::pin()` function. However, that function stores the actual local
file in a system location rather than inside the project, so using it
did not prove reliable. Furthermore, it did not have the desired
versioning properties, and finally, it is now defined as a legacy
function and is not part of the new api for that package. As a result,
`gitpins` was born.

Note that `gitpins` uses the native pipe operator (`|>`) and so depends
on `R (>= 4.1.0)`.

For feature requests, bugs, or other feedback, feel free to file an
issue.
