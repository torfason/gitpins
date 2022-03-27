
## Build package and documentation (before commits)
{
  devtools::build()
  system("R CMD INSTALL --preclean --no-multiarch --with-keep.source .")
  devtools::document()
  devtools::build_readme()
}

## Final checks (before release)
{
  devtools::spell_check()
  devtools::test()
  devtools::check()
  devtools::release_checks()
  devtools:::git_checks()
}
