
#' Calculate refresh interval to target specific daily drop time
#'
#' @description
#' Assuming that one is looking to pin an online resource that is typically
#' updated at the same time each day, this function calculates a refresh
#' interval that maximizes the likelihood that a pin is refreshed close to the
#' time the new version "drops" (the `drop_hour`).
#'
#' The assumption is that the resource drops sometime between `drop_hour` and
#' `drop_hour + drop_window`. During that time, the refresh interval is lowered
#' to `refresh_floor`. After the drop window closes, the interval slowly rises
#' to `refresh_ceiling`, in a way that ensures that a refresh is always
#' triggered if a resource has not been refreshed after the last drop window
#' closed.
#'
#' @param drop_hour The hour at which the resource typically drops. Either
#'   specified as a numeric in 24h time, or as a POSIX time object.
#' @param drop_window The window, in hours, during the time we expect the drop
#'   to happen.
#' @param drop_tz The time zone of the resource. In particular, this is relevant
#'   if the `drop_hour` is specified as a number, but `now_hour` is specified as
#'   a POSIX time object.
#' @param refresh_floor The lowest allowed refresh interval.
#' @param refresh_ceiling The highest allowed refresh interval.
#' @param now_hour The hour at which the pin is taking place. Can be passed as a
#'   numeric in 24h time, or as a POSIX time. Defaults to current time, which is
#'   often appropriate.
#'
#' @examples
#' # Assuming that the resource is updated at noon, US/Eastern time zone
#' url <- "https://vincentarelbundock.github.io/Rdatasets/csv/openintro/country_iso.csv"
#' pin(url, refresh_hours = gp_dropper(drop_hour = 12, drop_tz = "US/Eastern"))
#'
#' # Demonstration of the actual refresh interval returned by gp_dropper()
#' gp_dropper(drop_hour = 12, drop_tz = "US/Eastern")
#' @export
gp_dropper <- function(
    drop_hour,
    drop_window = 1,
    drop_tz = Sys.timezone(),
    refresh_floor = 0.1,
    refresh_ceiling = 12,
    now_hour = Sys.time()) {

  offset <- calc_hour_diff(drop_hour = drop_hour, drop_tz = drop_tz, now_hour = now_hour)

  # First, the max of refresh_floor and a line with slope 1 crossing x axis at drop_window
  result <- pmax(refresh_floor, offset-drop_window)

  # Then, the min of prior result and the refresh_ceiling
  result <- pmin(result, refresh_ceiling)

  result
}

# Helper function to calculate differnce between two times within a day
calc_hour_diff <- function(drop_hour, drop_tz, now_hour) {

  # Case 1: Both are numeric
  if (is.numeric(drop_hour) && is.numeric(now_hour)) {
    return((now_hour - drop_hour) %% 24)
  }

  # Case 2: Both are POSIXct date-times
  if (inherits(drop_hour, "POSIXct") && inherits(now_hour, "POSIXct")) {
    return(as.numeric(difftime(now_hour, drop_hour, units = "hours")) %% 24)
  }

  # Case 3: now_hour is a POSIXct date-time and drop_hour is numeric
  if (is.numeric(drop_hour) && inherits(now_hour, "POSIXct")) {
    # Convert now_hour to the specified drop time zone.
    now_in_drop_tz <- lubridate::with_tz(now_hour, drop_tz)
    # Create a drop date by extracting the date from now_in_drop_tz and adding the drop_hour as hours.
    drop_date <- as.POSIXct(format(now_in_drop_tz, "%Y-%m-%d"), tz = drop_tz) + drop_hour * 3600
    return(as.numeric(difftime(now_in_drop_tz, drop_date, units = "hours")) %% 24)
  }

  # Case 4: now_hour is numeric and drop_hour is a POSIXct date-time: error out.
  if (inherits(drop_hour, "POSIXct") && is.numeric(now_hour)) {
    stop("Error: now_hour is numeric while drop_hour is a date-time. Incompatible types.")
  }

  stop("Invalid input types for drop_hour and now_hour.")
}

