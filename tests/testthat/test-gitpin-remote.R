
test_that("gitpin works with remote URLs", {

  skip_if_offline()

  # Set the remote testing urls
  test_url_remote_1 <- "https://raw.githubusercontent.com/vincentarelbundock/Rdatasets/master/csv/boot/acme.csv"
  test_url_remote_2 <- "https://vincentarelbundock.github.io/Rdatasets/csv/openintro/country_iso.csv"

  # Start with a remote test
  expect_equal(
    pin(test_url_remote_1) |> read.csv() |> nrow(),
    60) |> expect_message()

  # Different servers
  expect_equal(
    pin(test_url_remote_2) |> read.csv() |> nrow(),
    249) |> expect_message()


  # Followed with a test that fails
  expect_error(pin("bla"))

})
