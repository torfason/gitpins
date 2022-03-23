

test_that("gitpin works",{

  test_url_remote <- "https://raw.githubusercontent.com/vincentarelbundock/Rdatasets/master/csv/boot/acme.csv"
  test_url_remote_2 <- "https://vincentarelbundock.github.io/Rdatasets/csv/openintro/country_iso.csv"

  callr_servr <- function() {
    host    <- getOption("servr.host", "127.0.0.1")
    port    <- servr:::random_port()
    dir     <- here::here("www_root")
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
  stopifnot(x$proc$is_alive())
  Sys.sleep(1)
  paste("ALIVE:", x$proc$is_alive(), x$url)
  test_url_local <- paste0(x$url, "trees.csv")

  # Test with a local server
  expect_equal(
    gitpin(test_url_local) |> read.csv() |> nrow(),
    10) |> expect_message()

  expect_equal(
    gitpin(test_url_remote) |> read.csv() |> nrow(),
    60) |> expect_message()

  expect_error(gitpin("bla"))

  # Check refresh logic
  expect_message(
    gitpin(test_url_local, refresh_hours = 0),
    "Downloaded fresh version ...")
  # Immediately again shouls work.
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

