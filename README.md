
# mlr3batchmark

[![r-cmd-check](https://github.com/mlr-org/mlr3batchmark/actions/workflows/r-cmd-check.yml/badge.svg)](https://github.com/mlr-org/mlr3batchmark/actions/workflows/r-cmd-check.yml)
[![CRAN
status](https://www.r-pkg.org/badges/version/mlr3batchmark)](https://CRAN.R-project.org/package=mlr3batchmark)
[![StackOverflow](https://img.shields.io/badge/stackoverflow-mlr3-orange.svg)](https://stackoverflow.com/questions/tagged/mlr3)
[![Mattermost](https://img.shields.io/badge/chat-mattermost-orange.svg)](https://lmmisld-lmu-stats-slds.srv.mwn.de/mlr_invite/)

A connector between [mlr3](https://github.com/mlr-org/mlr3) and
[batchtools](http://batchtools.mlr-org.com/). This allows to run
large-scale benchmark experiments on scheduled high-performance
computing clusters.

The package comes with two core functions for switching between `mlr3`
and `batchtools` to perform a benchmark:

- After creating a `design` object (as required for `mlr3`’s
  `benchmark()` function), instead of `benchmark()` call `batchmark()`
  which populates an `ExperimentRegistry` for the computational jobs of
  the benchmark. You are now in the world of `batchtools` where you can
  selectively submit jobs with different resources, monitor the progress
  or resubmit as needed.
- After the computations are finished, collect the results with
  `reduceResultsBatchmark()` to return to `mlr3`. The resulting object
  is a regular `BenchmarkResult`.

## Example

``` r
library("mlr3")
library("batchtools")
library("mlr3batchmark")
tasks = tsks(c("iris", "sonar"))
learners = lrns(c("classif.featureless", "classif.rpart"))
resamplings = rsmp("cv", folds = 3)

design = benchmark_grid(
  tasks = tasks,
  learners = learners,
  resamplings = resamplings
)

reg = makeExperimentRegistry(NA)
```

    ## No readable configuration file found

    ## Created registry in '/tmp/Rtmpqi04ir/registry12bb56a23ce1' using cluster functions 'Interactive'

``` r
ids = batchmark(design, reg = reg)
```

    ## Adding algorithm 'run_learner'

    ## Adding problem 'abc694dd29a7a8ce'

    ## Exporting new objects: '10ee41ae832e9304' ...

    ## Exporting new objects: 'c555f9dfec9c1e4f' ...

    ## Exporting new objects: '02253ecc9afd614a' ...

    ## Exporting new objects: 'ecf8ee265ec56766' ...

    ## Overwriting previously exported object: 'ecf8ee265ec56766'

    ## Adding 6 experiments ('abc694dd29a7a8ce'[1] x 'run_learner'[2] x repls[3]) ...

    ## Adding problem 'f9791e97f9813150'

    ## Exporting new objects: 'd9b697eed2a7335a' ...

    ## Adding 6 experiments ('f9791e97f9813150'[1] x 'run_learner'[2] x repls[3]) ...

``` r
submitJobs()
```

    ## Submitting 12 jobs in 12 chunks using cluster functions 'Interactive' ...

``` r
getStatus()
```

    ## Status for 12 jobs at 2026-06-11 11:59:26:
    ##   Submitted    : 12 (100.0%)
    ##   -- Queued    :  0 (  0.0%)
    ##   -- Started   : 12 (100.0%)
    ##   ---- Running :  0 (  0.0%)
    ##   ---- Done    : 12 (100.0%)
    ##   ---- Error   :  0 (  0.0%)
    ##   ---- Expired :  0 (  0.0%)

``` r
reduceResultsBatchmark()
```

    ## 
    ## ── <BenchmarkResult> of 12 rows with 4 resampling run ──────────────────────────
    ##  nr task_id          learner_id resampling_id iters warnings errors
    ##   1    iris classif.featureless            cv     3        0      0
    ##   2    iris       classif.rpart            cv     3        0      0
    ##   3   sonar classif.featureless            cv     3        0      0
    ##   4   sonar       classif.rpart            cv     3        0      0

## Resources

- The *Large-Scale Benchmarking* chapter of the [mlr3
  book](https://mlr3book.mlr-org.com/)
