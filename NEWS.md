# mlr3batchmark (development version)

* feat: `reduceResultsBatchmark` gains argument `fun` which is passed on to `batchtools::reduceResultsList`, useful for deleting model data to avoid running out of memory, https://github.com/mlr-org/mlr3batchmark/issues/18 Thanks to Toby Dylan Hocking @tdhock for the PR.
* docs: A warning is now given when the loaded mlr3 version differs from the
mlr3 version stored in the trained learners
* Support marshaling

# mlr3batchmark 0.1.1

* feat: `mlr3batchmark` now depends on package `batchtools` to avoid having to load `batchtools` explicitly.

# mlr3batchmark 0.1.0

* release: Initial release

