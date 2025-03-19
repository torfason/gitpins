

#' @title Create a gp_options Object
#' @description Constructs a `gp_options` object with configurable parameters.
#'   The parameters can be set from the defaults, from R options, or directly
#'   when the options object is created.
#' @param ... Reserved. All arguments must be named.
#' @param pin_directory A character string specifying the directory to use
#'   for the pin repo
#' @return A list representing the `gp_options` object.
#' @export
gp_options <- function(...,
                       pin_directory = getOption("gitpins.pin_directory", here::here("gitpins"))
) {

  # Generate the object
  obj <- structure (
    list(
      pin_directory = pin_directory
    ),
    class = "gitpins_gp_options"
  )

  # Verify object and that ... was unused before returning the object
  assert_dots_empty()
  assert_gp_options(obj)
}


#' @title Verify that x is a valid gp_options object
#' @description Verifies that `x` is a `gp_options` object (of class
#'   `gitpins_gp_options`) and that all elements of the object are
#'   valid for such an object. Use `gp_options()` to create `gp_options`
#'   objects.
#' @param x An object to verify
#' @return Unchanged input if valid, otherwise an error is thrown.
#' @keywords internal
assert_gp_options <- function(x) {

  # Verify input
  assert_list(x)
  assert_class(x, "gitpins_gp_options")
  assert_string(x$pin_directory)

  # Return input unchanged if it is valid
  invisible(x)
}
