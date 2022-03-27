test_that("listing is in default order", {

  # Nohist listing should be indecreasing order
  listing_nohist <- list_gitpins()
  expect_equal(listing_nohist$timestamp, sort(listing_nohist$timestamp, decreasing=TRUE))

  # Hist listing should be indecreasing order
  listing_hist <- list_gitpins(history = TRUE)
  expect_equal(listing_hist$timestamp, sort(listing_hist$timestamp, decreasing=TRUE))

  # Nohist should be subset of hist
  matches <- listing_hist$timestamp %in% listing_nohist$timestamp
  listing_hist_subset <- listing_hist[matches,]
  expect_equal(listing_hist_subset, listing_nohist)

})
