#' @title Collect Results from batchmark
#'
#' @description
#' Collect the results from jobs defined via [batchmark()] and combine them into a [mlr3::BenchmarkResult].
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
reduceResultsBatchmark = function(ids = NULL, store_backends = TRUE, reg = batchtools::getDefaultRegistry(), fun = NULL, unmarshal = TRUE) { # nolint
  assert_flag(unmarshal)
  if (is.null(ids)) {
    ids = batchtools::findDone(ids, reg = reg)
  } else {
    ids = batchtools::findJobs(ids = ids, reg = reg) # convert to proper table
    if (nrow(batchtools::findNotDone(ids, reg = reg))) {
      stop("All jobs must have been successfully computed")
    }
  }

  tabs = batchtools::getJobTable(ids, reg = reg)[, c("job.id", "job.name", "repl", "prob.pars", "algo.pars"), with = FALSE]
  tabs = unnest(tabs, c("prob.pars", "algo.pars"))
  tabs = split(tabs, by = "job.name")
  bmr = mlr3::BenchmarkResult$new()

  version_checked = FALSE

  for (tab in tabs) {
    job = batchtools::makeJob(tab$job.id[1L], reg = reg)
    bmr_tasks = bmr$tasks
    bmr_learners = bmr$learners
    bmr_resamplings = bmr$resamplings

    needle = job$prob.pars$task_hash
    ii = bmr_tasks[list(needle), on = "task_hash", which = TRUE, nomatch = NULL]
    if (length(ii)) {
      task = bmr_tasks$task[[ii]]
    } else {
      task = job$problem$data
    }

    needle = job$prob.pars$resampling_hash
    ii = bmr_resamplings[list(needle), on = "resampling_hash", which = TRUE, nomatch = NULL]
    if (length(ii)) {
      resampling = bmr_resamplings$resampling[[ii]]
    } else {
      resampling = get_export(needle, reg)
    }

    needle = job$algo.pars$learner_hash
    ii = bmr_learners[list(needle), on = "learner_hash", which = TRUE, nomatch = NULL]
    if (length(ii)) {
      learner = bmr_learners$learner[[ii]]
    } else {
      learner = get_export(needle, reg)
    }

    results = batchtools::reduceResultsList(tab$job.id, reg = reg, fun = fun)

    if (!version_checked) {
      version_checked = TRUE
      if (mlr3::mlr_reflections$package_version != results[[1]]$learner_state$mlr3_version) {
        lg$warn(paste(sep = "\n",
          "The mlr3 version (%s) from one of the trained learners differs from the currently loaded mlr3 version (%s).",
          "This can lead to unexpected behavior and we recommend using the same versions of all mlr3 packages for collecting the results."),
          results[[1]]$learner_state$mlr3_version, mlr3::mlr_reflections$package_version)
      }
    }

    rdata = mlr3::ResultData$new(data.table(
      task = list(task),
      learner = list(learner),
      resampling = list(resampling),
      iteration = tab$repl,
      prediction = map(results, "prediction"),
      learner_state = map(results, "learner_state"),
      param_values = map(results, "param_values"),
      learner_hash = map_chr(results, "learner_hash"),
      uhash = tab$job.name
    ), store_backends = store_backends)
    bmr$combine(mlr3::BenchmarkResult$new(rdata))
  }

  if (unmarshal) {
    bmr$unmarshal()
  }

  return(bmr)
}
