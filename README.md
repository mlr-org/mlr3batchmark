
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

    ## Created registry in '/tmp/RtmpbcuMc4/registry27b8961304f5da' using cluster functions 'Interactive'

``` r
ids = batchmark(design, reg = reg)
```

    ## Adding algorithm 'run_learner'

    ## Adding problem 'abc694dd29a7a8ce'

    ## Exporting new objects: '2da7eeb80b94fc3b' ...

    ## Exporting new objects: 'c905990877a775af' ...

    ## Exporting new objects: '3acc41a799a260d8' ...

    ## Exporting new objects: 'ecf8ee265ec56766' ...

    ## Overwriting previously exported object: 'ecf8ee265ec56766'

    ## Adding 6 experiments ('abc694dd29a7a8ce'[1] x 'run_learner'[2] x repls[3]) ...

    ## Adding problem 'f9791e97f9813150'

    ## Exporting new objects: '62ac3bb85aabfbaf' ...

    ## Adding 6 experiments ('f9791e97f9813150'[1] x 'run_learner'[2] x repls[3]) ...

``` r
submitJobs()
```

    ## Submitting 12 jobs in 12 chunks using cluster functions 'Interactive' ...

    ## Error in workhorse(iteration = job$repl, task = data, learner = learner,  : 
    ##   unused argument (lgr_threshold = lgr::get_logger("mlr3")$threshold)
    ## Error in workhorse(iteration = job$repl, task = data, learner = learner,  : 
    ##   unused argument (lgr_threshold = lgr::get_logger("mlr3")$threshold)
    ## Error in workhorse(iteration = job$repl, task = data, learner = learner,  : 
    ##   unused argument (lgr_threshold = lgr::get_logger("mlr3")$threshold)
    ## Error in workhorse(iteration = job$repl, task = data, learner = learner,  : 
    ##   unused argument (lgr_threshold = lgr::get_logger("mlr3")$threshold)
    ## Error in workhorse(iteration = job$repl, task = data, learner = learner,  : 
    ##   unused argument (lgr_threshold = lgr::get_logger("mlr3")$threshold)
    ## Error in workhorse(iteration = job$repl, task = data, learner = learner,  : 
    ##   unused argument (lgr_threshold = lgr::get_logger("mlr3")$threshold)
    ## Error in workhorse(iteration = job$repl, task = data, learner = learner,  : 
    ##   unused argument (lgr_threshold = lgr::get_logger("mlr3")$threshold)
    ## Error in workhorse(iteration = job$repl, task = data, learner = learner,  : 
    ##   unused argument (lgr_threshold = lgr::get_logger("mlr3")$threshold)
    ## Error in workhorse(iteration = job$repl, task = data, learner = learner,  : 
    ##   unused argument (lgr_threshold = lgr::get_logger("mlr3")$threshold)
    ## Error in workhorse(iteration = job$repl, task = data, learner = learner,  : 
    ##   unused argument (lgr_threshold = lgr::get_logger("mlr3")$threshold)
    ## Error in workhorse(iteration = job$repl, task = data, learner = learner,  : 
    ##   unused argument (lgr_threshold = lgr::get_logger("mlr3")$threshold)
    ## Error in workhorse(iteration = job$repl, task = data, learner = learner,  : 
    ##   unused argument (lgr_threshold = lgr::get_logger("mlr3")$threshold)

``` r
getStatus()
```

    ## Status for 12 jobs at 2025-05-26 09:23:22:
    ##   Submitted    : 12 (100.0%)
    ##   -- Queued    :  0 (  0.0%)
    ##   -- Started   : 12 (100.0%)
    ##   ---- Running :  0 (  0.0%)
    ##   ---- Done    :  0 (  0.0%)
    ##   ---- Error   : 12 (100.0%)
    ##   ---- Expired :  0 (  0.0%)

``` r
reduceResultsBatchmark()
```

    ## 
    ## ── <BenchmarkResult> of 0 rows with 0 resampling run ───────────────────────────

## Resources

- The *Large-Scale Benchmarking* chapter of the [mlr3
  book](https://mlr3book.mlr-org.com/)
