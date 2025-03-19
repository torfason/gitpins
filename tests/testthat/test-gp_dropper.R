
# Test that gp_dropper() returns the correct refresh inteval
test_that("gp_dropper() returns the correct refresh inteval", {

  # Drop at 10 am, calculate variations on that
  gp_dropper(10, now_hour = 10)   |> expect_equal(0.1)
  gp_dropper(10, now_hour = 10.5) |> expect_equal(0.1)
  gp_dropper(10, now_hour = 11)   |> expect_equal(0.1)
  gp_dropper(10, now_hour = 11.5) |> expect_equal(0.5)
  gp_dropper(10, now_hour = 12)   |> expect_equal(1)
  gp_dropper(10, now_hour = 9)   |> expect_equal(12)

  # Custom window or other variables
  gp_dropper(10, drop_window = 2, now_hour = 13)     |> expect_equal(1)
  gp_dropper(10, drop_window = 2, now_hour = 20)     |> expect_equal(8)
  gp_dropper(10, refresh_floor = 1.5, now_hour = 10) |> expect_equal(1.5)
  gp_dropper(10, refresh_ceiling = 5, now_hour = 9)  |> expect_equal(5)

})

# calc_hour_diff(): Numeric-numeric cases.
test_that("calc_hour_diff(): Numeric-numeric differences are computed modulo 24", {
  expect_equal(calc_hour_diff(10, Sys.timezone(), 15), 5)
  expect_equal(calc_hour_diff(22, Sys.timezone(), 2), 4)
  expect_equal(calc_hour_diff(5, Sys.timezone(), 5), 0)
  expect_equal(calc_hour_diff(23, Sys.timezone(), 1), 2)
})

# calc_hour_diff(): POSIXct-POSIXct cases.
test_that("calc_hour_diff(): POSIXct-POSIXct differences are calculated correctly", {
  now <- as.POSIXct("2023-03-20 18:00:00", tz = "UTC")
  drop <- as.POSIXct("2023-03-20 16:00:00", tz = "UTC")
  expect_equal(calc_hour_diff(drop, Sys.timezone(), now), 2)

  # Negative difference test.
  now2 <- as.POSIXct("2023-03-20 14:00:00", tz = "UTC")
  drop2 <- as.POSIXct("2023-03-20 16:00:00", tz = "UTC")
  expect_equal(calc_hour_diff(drop2, Sys.timezone(), now2), 22)
})

# calc_hour_diff(): now_hour is POSIXct and drop_hour is numeric.
test_that("calc_hour_diff(): POSIXct now_hour with numeric drop_hour computes correctly", {
  # Using drop_tz "UTC"
  now <- as.POSIXct("2023-03-20 18:00:00", tz = "UTC")
  # drop_date should be "2023-03-20 16:00:00" in UTC.
  expect_equal(calc_hour_diff(16, "UTC", now), 2)

  # Using a different timezone.
  now2 <- as.POSIXct("2023-03-20 20:00:00", tz = "America/New_York")
  # drop_date becomes "2023-03-20 16:00:00" in America/New_York, so the difference is 4 hours.
  expect_equal(calc_hour_diff(16, "America/New_York", now2), 4)

  # Edge case: now_hour earlier than the drop time on the same day.
  now3 <- as.POSIXct("2023-03-20 15:00:00", tz = "UTC")
  # drop_date will be "2023-03-20 16:00:00" in UTC, so the difference is -1,
  # and with modulo 24 it becomes 23
  expect_equal(calc_hour_diff(16, "UTC", now3), 23)
})

# calc_hour_diff(): Error when now_hour is numeric and drop_hour is POSIXct.
test_that("calc_hour_diff(): Error when now_hour is numeric and drop_hour is POSIXct", {
  drop <- as.POSIXct("2023-03-20 16:00:00", tz = "UTC")
  expect_error(calc_hour_diff(drop, "UTC", 18),
               "now_hour is numeric while drop_hour is a date-time")
})

# calc_hour_diff(): Invalid input types.
test_that("calc_hour_diff(): Invalid input types return an error", {
  expect_error(calc_hour_diff("16", Sys.timezone(), "18"),
               "Invalid input types")
})
