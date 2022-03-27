
.globals <- new.env()

#' Convert datetime to sub-millisecond timestamp
#'
#' @param the_datetime A date variable
#' @return A character representation of `the_datetime` as a sub-millisecond timestamp
#' @md
#' @keywords internal
tstamp <- function(the_datetime) {
  strftime(the_datetime , "%Y-%m-%d %H:%M:%OS5")
}

#' Initialize gitpins repo
#'
#' This function is called automatically as needed and should not
#' need to be called by the user
#'
#' @return The path to the repo
#' @md
#' @keywords internal
init_gitpins <- function() {
  .globals$repo <- here::here("gitpins")
  gert::git_init(path=.globals$repo)
}

#' Download URL, add to gitpins repo, and return filename
#'
#' The `gitpin()` function downloads a URL to a local file in the `gitpins`
#' folder inside your project (the currently fixed path is determined by
#' `here("gitpins")`), and then returns the full file name name of the
#' local file, which can be passed as an argument to any function that
#' expects to read such a file.
#'
#' @param url The URL do townload (or get a cached copy of)
#' @param refresh_hours How old, in hours, can the locally cached copy be
#'   before downloading a new version.
#' @return The path of the locally downloaded file
#'
#' @md
#' @export
gitpin <- function(url, refresh_hours=12) {
  #url <- "https://raw.githubusercontent.com/vincentarelbundock/Rdatasets/master/csv/boot/acme.csv"

  # Default frequency of downloads, configurable with config_gitpins()
  # could be to redownload if not the same day as the last download.
  recent_version_found <- FALSE

  # Initialize variables
  init_gitpins()
  stopifnot(!is.null(url) && is.character(url) && length(url)==1)
  url_hash <- digest::digest(url)
  timestamp <-  Sys.time()
  destfile_data <- file.path(.globals$repo,paste0(url_hash,".data"))
  destfile_temp <- file.path(.globals$repo,paste0(url_hash,".temp"))
  on.exit(if(file.exists(destfile_temp))file.remove(destfile_temp))
  destfile_info <- file.path(.globals$repo,paste0(url_hash,".info"))
  destfile_json <- file.path(.globals$repo,paste0(url_hash,".json"))

  # Read some metadata, to determine what to do next
  if ( file.exists(destfile_json) ) {
    meta_last <- readLines(destfile_json) |> jsonlite::fromJSON()
    delta_hours <- as.double(difftime(timestamp, as.POSIXct(meta_last$timestamp), units="hours"))
    if ( delta_hours < refresh_hours ) {
      recent_version_found <- TRUE
    }
    if (tstamp(timestamp)==meta_last$timestamp) {
      stop(paste("Timestamps are equal:", tstamp(timestamp), meta_last$timestamp))
    }
  }

  # Do the download and determine next steps
  if ( recent_version_found ) {
    message(paste("Recent version found, using it ..."))
  } else {

    tryCatch(
      { dl_result <- utils::download.file(url, destfile_temp, quiet=TRUE) },
        error=function(e) {},
        warning=function(e) {}
    )

    if ( !file.exists(destfile_temp) || file.size(destfile_temp)==0) {
      # Download failed in some way
      if (!file.exists(destfile_data)) {
        stop("Download failed and no earlier version found: Aborting!")
      } else {
        message("Download failed, using last good version ...")
        return(destfile_data)
      }
    }

    # Download succeeded
    message("Downloaded fresh version ...")
    file.copy(destfile_temp, destfile_data, overwrite = TRUE)
    #writeLines(c(timestamp, url), destfile_info)
    list(timestamp=jsonlite::unbox(tstamp(timestamp)), url=jsonlite::unbox(url)) |>
      jsonlite::toJSON(pretty = TRUE, simplifyVector=TRUE) |>
      writeLines(destfile_json)

    gert::git_add(
      basename(c(destfile_data,destfile_json)), # Must be relative to repo root
      repo=.globals$repo)
    gert::git_commit_all(paste0("[", tstamp(timestamp), "] ", url), repo=.globals$repo)
  }
  destfile_data
}

#' List available gitpins
#'
#' @param history Should full (git) history be returned?
#' @return A `data.frame` with the timestamps and urls of available gitpins.
#'
#' @md
#' @export
list_gitpins <- function(history=FALSE) {
  init_gitpins()

  if (!history) {
    # Return result based on what is in the working copy
    d.result <- list.files(.globals$repo, pattern="*.json", full.names = TRUE) |>
      lapply(readLines) |>
      lapply(jsonlite::fromJSON) |>
      lapply(as.data.frame) |>
      do.call(what=rbind)
    d.result <- d.result[order(d.result$timestamp, decreasing=TRUE),]
  } else {
    # Return result based on what is in the gitlog
    logmessages <- gert::git_log(repo=.globals$repo)$message
    d.result <- data.frame(
      timestamp = gsub('\\[(.*)\\].*','\\1',logmessages),
      url = gsub('.*\\] (.*)','\\1',logmessages) |>
        sub(pattern="\\n", replacement="")
    )
  }

  # Be nice and return a tibble if it is available
  if (requireNamespace("tibble")){
    d.result <- tibble::as_tibble(d.result)
  }
  d.result
}

#' Clearing old gitpins is not currently implemented
#' @md
#' @keywords internal
clear_old_gitpins <- function() {
  stop("not implemented")
}

