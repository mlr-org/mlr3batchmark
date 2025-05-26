# mlr3batchmark 0.2.1

* compatibility: mlr3 1.0.0

# mlr3batchmark 0.2.0

* feat: The design of `batchmark()` can now include parameter settings.
* feat: `reduceResultsBatchmark` gains argument `fun` which is passed on to `batchtools::reduceResultsList`.
Useful for deleting model data to avoid running out of memory.
Thanks to Toby Dylan Hocking @tdhock for the PR (https://github.com/mlr-org/mlr3batchmark/issues/18).
* docs: A warning is now given when the loaded mlr3 version differs from the mlr3 version stored in the trained learners.
* feat: Support marshaling.
* feat: A `renv` project can be passed to `batchmark()` that is loaded in the job environment.

# mlr3batchmark 0.1.1

* feat: `mlr3batchmark` now depends on package `batchtools` to avoid having to load `batchtools` explicitly.

# mlr3batchmark 0.1.0

* release: Initial release

