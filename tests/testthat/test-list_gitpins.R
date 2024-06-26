
test_that("listing works", {

  # Always return two-colum tibble on default call
  list_pins() |>
    names() |>
    expect_equal(c("timestamp", "url"))

  # Always return tibble when including history
  list_pins(history=TRUE) |>
    names() |>
    expect_equal(c("timestamp", "url"))

})

test_that("listing is in default order", {

  # Nohist listing should be indecreasing order
  listing_nohist <- list_pins()
  expect_equal(listing_nohist$timestamp, sort(listing_nohist$timestamp, decreasing=TRUE))

  # Hist listing should be indecreasing order
  listing_hist <- list_pins(history = TRUE)
  expect_equal(listing_hist$timestamp, sort(listing_hist$timestamp, decreasing=TRUE))

  # Nohist should be subset of hist
  matches <- listing_hist$timestamp %in% listing_nohist$timestamp
  listing_hist_subset <- listing_hist[matches, ]
  expect_equal(listing_hist_subset, listing_nohist)

})
