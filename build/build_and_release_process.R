
## Build package and documentation (before commits)
{
  gpdir <- here::here("gitpins")
  if (file.exists(gpdir)) {
    file.rename(gpdir, paste0(gpdir,"_",fstamp(Sys.time())))
  }
  devtools::build()
  devtools::document()
  devtools::build_readme()
  devtools::test()
  message("Build OK")
}

## Final checks (before release)
{
  system("R CMD INSTALL --preclean --no-multiarch --with-keep.source .")
  devtools::spell_check()
  devtools::check()
  devtools::release_checks()
  devtools:::git_checks()
}
