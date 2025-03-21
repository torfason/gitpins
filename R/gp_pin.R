

#' Convert date-time variable to sub-millisecond timestamp
#'
#' @param the_datetime a date variable
#' @return a character representation of `the_datetime` as a sub-millisecond
#'   timestamp
#' @md
#' @keywords internal
tstamp <- function(the_datetime) {
  assert_posixct(the_datetime)

  strftime(the_datetime, "%Y-%m-%d %H:%M:%OS5")
}


#' Convert date-time variable to file-compatible timestamp
#'
#' @param the_datetime a date variable
#' @return a character representation of `the_datetime` as
#'     a timestamp with only file-compatible characters
#' @md
#' @keywords internal
fstamp <- function(the_datetime) {
  assert_posixct(the_datetime)

  strftime(the_datetime, "%Y-%m-%d.%H%M%S")
}


#' Download URL, add to gitpins repository, and return filename
#'
#' The `pin()` function downloads a URL to a local file in the `gitpins`
#' folder inside your project (the currently fixed path is determined by
#' `here("gitpins")`), and then returns the full file name name of the
#' local file, which can be passed as an argument to any function that
#' expects to read such a file.
#'
#' @param url The URL do download (or get a cached copy of)
#' @param refresh_hours How old, in hours, can the locally cached copy be
#'   before downloading a new version.
#' @return The path of the locally downloaded file
#'
#' @export
pin <- function(url, refresh_hours=12) {
  assert_string(url)
  assert_number(refresh_hours)

  # Default frequency of downloads, configurable with config_gitpins()
  # could be to redownload if not the same day as the last download.
  recent_version_found <- FALSE

  # Initialize variables
  gp_init()
  stopifnot(!is.null(url) && is.character(url) && length(url)==1)
  url_hash <- digest::digest(url)
  timestamp <-  Sys.time()
  destfile_data <- file.path(.globals$repo, paste0(url_hash, ".data"))
  destfile_temp <- file.path(.globals$repo, paste0(url_hash, ".temp"))
  on.exit(if (file.exists(destfile_temp)) file.remove(destfile_temp)) # nolint
  destfile_json <- file.path(.globals$repo, paste0(url_hash, ".json"))

  # Read some metadata, to determine what to do next
  if ( file.exists(destfile_json) ) {
    meta_last <- readLines(destfile_json) |> jsonlite::fromJSON()
    delta_hours <- as.double(difftime(timestamp,
                             as.POSIXct(meta_last$timestamp),
                             units="hours"))
    if ( delta_hours < refresh_hours ) {
      recent_version_found <- TRUE
    }
    if (tstamp(timestamp)==meta_last$timestamp) {
      stop(paste("Timestamps are equal:", tstamp(timestamp), meta_last$timestamp))
    }
  }

  # Do the download and determine next steps
  if ( recent_version_found ) {
    message(paste("pin() found recent version, using it ..."))
  } else {

    tryCatch(
      { curl::curl_download(url, destfile_temp, quiet=TRUE) },
        error=function(e) {},     # nolint
        warning=function(e) {}    # nolint
    )

    if ( !file.exists(destfile_temp) || file.size(destfile_temp)==0 ) {
      # Download failed in some way
      if (!file.exists(destfile_data)) {
        stop("pin() failed to download file and no earlier version found: Aborting!")
      } else {
        message("pin() failed to download file, using last good version ...")
        return(destfile_data)
      }
    }

    # Download succeeded
    message("pin() downloaded fresh version ...")
    file.copy(destfile_temp, destfile_data, overwrite = TRUE)
    list(timestamp=jsonlite::unbox(tstamp(timestamp)), url=jsonlite::unbox(url)) |>
      jsonlite::toJSON(pretty = TRUE, simplifyVector=TRUE) |>
      writeLines(destfile_json)

    gert::git_add(
      basename(c(destfile_data, destfile_json)), # Must be relative to repo root
      repo=.globals$repo)
    gert::git_commit_all(paste0("[", tstamp(timestamp), "] ", url), repo=.globals$repo)
  }
  destfile_data
}

#' The `gp_pin()` function is provided as an alias for `pin()`, to address
#' naming conflicts (for example with [pins::pin()]).
#'
#' @rdname pin
#'
#' @export
gp_pin <- pin

