#' @title Collect Results from batchmark
#'
#' @description
#' Collect the results from jobs defined via [batchmark()] and combine them into
#' a [mlr3::BenchmarkResult].
#'
#' Note that `ids` defaults to finished jobs (as reported by [batchtools::findDone()]).
#' If a job threw an error, is expired or is still running, it will be ignored with this default.
#' Just leaving these jobs out in an analysis is **not** statistically sound.
#' Instead, try to robustify your jobs by using a fallback learner (c.f. [mlr3::Learner]).
#'
#' @inheritParams batchtools::reduceResultsList
#' @inheritParams mlr3::benchmark
#'
#' @return [mlr3::BenchmarkResult].
#' @export
reduceResultsBatchmark = function(ids = NULL, store_backends = TRUE, reg = batchtools::getDefaultRegistry()) { # nolint
  if (is.null(ids)) {
    ids = batchtools::findDone(ids, reg = reg)
  } else if (nrow(batchtools::findNotDone(ids, reg = reg))) {
    stop("All jobs must be have been successfully computed")
  }

  tabs = split(unnest(batchtools::getJobTable(ids, reg = reg), c("prob.pars", "algo.pars")), by = "job.name")
  bmr = mlr3::BenchmarkResult$new()

  for (tab in tabs) {
    job = batchtools::makeJob(tab$job.id[1L], reg = reg)

    thash = job$prob.pars$task_hash
    ii = bmr$tasks[list(thash), on = "task_hash", which = TRUE, nomatch = NULL]
    if (length(ii)) {
      task = bmr$tasks$task[[ii]]
    } else {
      task = job$problem$data
    }

    rhash = job$prob.pars$resampling_hash
    ii = bmr$resamplings[list(rhash), on = "resampling_hash", which = TRUE, nomatch = NULL]
    if (length(ii)) {
      resampling = bmr$resamplings$resampling[[ii]]
    } else {
      resampling = get_export(rhash, reg)
    }

    lhash = job$algo.pars$learner_hash
    ii = bmr$learners[list(lhash), on = "learner_hash", which = TRUE, nomatch = NULL]
    if (length(ii)) {
      learner = bmr$learners$learner[[ii]]
    } else {
      learner = get_export(lhash, reg)
    }

    results = batchtools::reduceResultsList(tab$job.id, reg = reg)
    rdata = ResultData$new(data.table(
      task = list(task),
      learner = list(learner),
      learner_state = map(results, "learner_state"),
      resampling = list(resampling),
      iteration = tab$repl,
      prediction = map(results, "prediction"),
      uhash = tab$job.name
    ), store_backends = store_backends)
    bmr$combine(mlr3::BenchmarkResult$new(rdata))
  }

  return(bmr)
}
