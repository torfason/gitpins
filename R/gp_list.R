
#' List available pins
#'
#' @param history Should full (git) history be returned?
#' @return A `data.frame` with the timestamps and urls of available pins.
#'
#' @export
gp_list <- function(history=FALSE) {
  assert_flag(history)

  gp_init()

  # Function to return empty data.frame on fresh repo instead of erroring
  get_repo_log_messages <- function(the_repo) {
    tryCatch({
      gert::git_log(repo=.globals$repo)$message
    }, error=function(cond) {
      character()
    })
  }

  if (!history) {
    # Return result based on what is in the working copy
    d.result <- list.files(.globals$repo, pattern="*.json", full.names = TRUE) |>
      lapply(readLines) |>
      lapply(jsonlite::fromJSON) |>
      lapply(as.data.frame) |>
      do.call(what=rbind)
    if (is.null(d.result)) d.result <- data.frame(timestamp=character(), url=character())
    d.result <- d.result[order(d.result$timestamp, decreasing=TRUE), ]
  } else {
    # Return result based on what is in the gitlog
    logmessages <- get_repo_log_messages()
    d.result <- data.frame(
      timestamp = gsub("\\[(.*)\\].*", "\\1", logmessages),
      url = gsub(".*\\] (.*)", "\\1", logmessages) |>
        sub(pattern="\\n", replacement="")
    )
  }

  # Be nice and return a tibble if it is available
  if (requireNamespace("tibble")) {
    d.result <- tibble::as_tibble(d.result)
  }
  d.result
}

#' Clearing old pins is not currently implemented
#' @keywords internal
gp_clear <- function() {
  stop("not implemented")
}
