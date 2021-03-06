do_package_checks(error_on = "warning")

get_stage("install") %>%
  # install ranger for README
  add_step(step_install_cran("ranger")) %>%
  add_step(step_install_github("mlr-org/mlr3pkgdowntemplate"))

if (ci_on_ghactions() && ci_has_env("BUILD_PKGDOWN")) {
  # creates pkgdown site and pushes to gh-pages branch
  # only for the runner with the "BUILD_PKGDOWN" env var set
  get_stage("install") %>%
    add_step(step_install_github("mlr-org/mlr3pkgdowntemplate"))
  do_pkgdown()
}

if (ci_on_ghactions() && identical(ci_get_env("MLR3"), "devel")) {
  get_stage("install") %>%
    add_step(step_install_github("mlr-org/mlr3"))
}
