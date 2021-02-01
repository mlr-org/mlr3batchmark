#' @title Collect Results from batchmark
#'
#' @description
#' Collect the results from jobs defined via [batchmark()] and combine them into
#' a [mlr3::BenchmarkResult].
#'
#' @inheritParams batchtools::reduceResultsList
#'
#' @return [mlr3::BenchmarkResult].
#' @export
reduceResultsBatchmark = function(ids = NULL, reg = batchtools::getDefaultRegistry()) { # nolint
  ids = batchtools::findDone(ids, reg = reg)
  tabs = split(unnest(batchtools::getJobTable(ids, reg = reg), c("prob.pars", "algo.pars")), by = "job.name")
  bmr = mlr3::BenchmarkResult$new()

  for (tab in tabs) {
    job = batchtools::makeJob(tab$job.id[1L], reg = reg)

    task_hash = job$prob.pars$task_hash
    ii = bmr$tasks[list(task_hash), on = "task_hash", which = TRUE, nomatch = NULL]
    if (length(ii)) {
      task = bmr$tasks$task[[ii]]
    } else {
      task = job$problem$data
    }

    resampling_hash = job$prob.pars$resampling_hash
    ii = bmr$resamplings[list(resampling_hash), on = "resampling_hash", which = TRUE, nomatch = NULL]
    if (length(ii)) {
      resampling = bmr$resamplings$resampling[[ii]]
    } else {
      resampling = get_export(resampling_hash, reg)
    }

    learner_hash = job$algo.pars$learner_hash
    ii = bmr$learners[list(learner_hash), on = "learner_hash", which = TRUE, nomatch = NULL]
    if (length(ii)) {
      learner = bmr$learners$learner[[ii]]
    } else {
      learner = get_export(learner_hash, reg)
    }

    results = batchtools::reduceResultsList(tab$job.id, reg = reg)
    results = mlr3::ResultData$new(data.table(
      task = list(task),
      learner = list(learner),
      resampling = list(resampling),
      iteration = tab$repl,
      prediction = map(results, "prediction"),
      learner_state = map(results, "learner_state"),
      uhash = tab$job.name
    ), store_backends = FALSE)

    bmr$combine(mlr3::BenchmarkResult$new(results))
  }

  return(bmr)
}
