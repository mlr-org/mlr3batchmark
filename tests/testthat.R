if (requireNamespace("testthat", quietly = TRUE)) {
  library("testthat")
  library("mlr3batchmark")
  test_check("mlr3batchmark")
}
