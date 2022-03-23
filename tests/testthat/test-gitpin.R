

test_that("gitpin works",{

  # Skip test if suggested packages callr and servr are not installed
  if ( !requireNamespace("callr", quietly = TRUE) ||
       !requireNamespace("servr", quietly = TRUE) ) {
    skip()
  }

  # Set here with reference to the test file
  here::i_am("tests/testthat/test-gitpin.R")  |> expect_message("gitpins")

  # Set the remote testing urls
  test_url_remote <- "https://raw.githubusercontent.com/vincentarelbundock/Rdatasets/master/csv/boot/acme.csv"
  test_url_remote_2 <- "https://vincentarelbundock.github.io/Rdatasets/csv/openintro/country_iso.csv"

  # Start with a remote test
  expect_equal(
    gitpin(test_url_remote) |> read.csv() |> nrow(),
    60) |> expect_message()

  # Followed with a test that fails
  expect_error(gitpin("bla"))

  # If here does not get us the path to the local www_root, we panic
  if(!file.exists(here::here("tests","www_root"))) stop("Web root not found, skipping test")

  # Function to start a local server.
  callr_servr <- function() {
    host    <- getOption("servr.host", "127.0.0.1")
    port    <- servr:::random_port()
    dir     <- here::here("tests","www_root")
    proc <- callr::r_bg(servr::httd,
                        args=list(daemon=FALSE, dir=dir, host=host, port=port),
                        package="servr")
    url     <- paste0("http://", host, ":", port, "/")
    result  <- list(
      dir=dir,
      url=url,
      host=host,
      port=port,
      proc=proc
    )
    result
  }

  # Start local server
  x <- callr_servr()
  Sys.sleep(1)
  if (!x$proc$is_alive()) {
    print(x$proc$get_result())
    stop(paste("Failed to start local server", x$url))
  }
  test_url_local <- paste0(x$url, "trees.csv")

  # The server should be up and running
  expect_true(x$proc$is_alive())

  # Test with the local server
  expect_equal(
    gitpin(test_url_local) |> read.csv() |> nrow(),
    10) |> expect_message()

  # Check refresh logic
  expect_message(
    gitpin(test_url_local, refresh_hours = 0),
    "Downloaded fresh version ...")

  # Immediately again should work, or after sleeping a bit
  expect_message(
    gitpin(test_url_local, refresh_hours = 0),
    "Downloaded fresh version ...")
  expect_message(
    gitpin(test_url_local, refresh_hours = 1/3600),
    "Recent version found, using it ...")
  Sys.sleep(1.1)
  expect_message(
    gitpin(test_url_local, refresh_hours = 1/3600),
    "Downloaded fresh version ...")

  # Shut down server
  x$proc$kill()

  # And now we should use last good version
  expect_message(
    gitpin(test_url_local, refresh_hours = 0),
    "Download failed, using last good version ...")

})

