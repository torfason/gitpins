
#' Initialize gitpins repository
#'
#' This function is generally called automatically as needed. Note, however,
#' that to set a non-standard directory for the pinned files, this function must
#' be called before any other functions.
#'
#' @param ... Reserved. All arguments must be named.
#' @param options A `gp_options()` object, used in particular to select
#'   the directory for storing the pins (defaults to `here::here("gitpins")`).
#' @return The path to the repository
#'
#' @export
gp_init <- function(..., options = gp_options()) {

  # Verify inputs
  assert_dots_empty()
  assert_gp_options(options)

  .globals$repo <- options$pin_directory
  gert::git_init(path=.globals$repo)
  gert::git_config_set(repo=.globals$repo, "user.name", "Git Pins")
  gert::git_config_set(repo=.globals$repo, "user.email", "gitpins@zulutime.net")
}
