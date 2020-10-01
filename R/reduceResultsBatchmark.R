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
    new_bmr = mlr3::BenchmarkResult$new(data.table(
      task = list(task),
      learner = list(learner),
      learner_state = map(results, "learner_state"),
      resampling = list(resampling),
      iteration = tab$repl,
      prediction = map(results, "prediction"),
      uhash = tab$job.name
    ))

    bmr$combine(new_bmr)
  }

  return(bmr)
}
