#' @title Benchmark experiments on batch systems
#'
#' @description
#' Populates a [batchtools::ExperimentRegistry] with jobs in a [mlr3::benchmark()] fashion.
#' Each combination of [mlr3::Task] and [mlr3::Resampling] defines a [batchtools::Problem],
#' each [mlr3::Learner] is an [batchtools::Algorithm].
#'
#' @inheritParams mlr3::benchmark
#' @param reg [batchtools::ExperimentRegistry].
#'
#' @return [data.table()] with ids of created jobs.
#' @export
#' @examples
#' tasks = list(mlr3::tsk("iris"), mlr3::tsk("sonar"))
#' learners = list(mlr3::lrn("classif.featureless"), mlr3::lrn("classif.rpart"))
#' resamplings = list(mlr3::rsmp("cv", folds = 3), mlr3::rsmp("holdout"))
#'
#' design = mlr3::benchmark_grid(
#'   tasks = tasks,
#'   learners = learners,
#'   resamplings = resamplings
#' )
#'
#' reg = batchtools::makeExperimentRegistry(NA)
#' batchmark(design, reg = reg)
#' batchtools::submitJobs(reg = reg)
batchmark = function(design, store_models = FALSE, reg = batchtools::getDefaultRegistry()) {
  design = as.data.table(assert_data_frame(design, min.rows = 1L))
  assert_names(names(design), permutation.of = c("task", "learner", "resampling"))
  assert_flag(store_models)
  batchtools::assertRegistry(reg, class = "ExperimentRegistry")
  exports = batchtools::batchExport(reg = reg)$name

  for (i in seq_row(design)) {
    task = design$task[[i]]
    thash = task$hash
    if (thash %nin% reg$problems) {
      batchtools::addProblem(thash, data = task, reg = reg)
    }

    resampling = design$resampling[[i]]
    rhash = resampling$hash
    if (rhash %nin% exports) {
      batchtools::batchExport(export = set_names(list(resampling), rhash), reg = reg)
      exports = c(exports, rhash)
    }

    learner = design$learner[[i]]
    lhash = learner$hash
    if (lhash %nin% exports) {
      batchtools::batchExport(export = set_names(list(learner), lhash), reg = reg)
      exports = c(exports, lhash)
    }

    if ("run_learner" %nin% reg$algorithms) {
      batchtools::addAlgorithm("run_learner", fun = run_learner, reg = reg)
    }

    prob_design = set_names(list(data.table(
      task_hash = thash, task_id = task$id,
      resampling_hash = rhash, resampling_id = resampling$id
    )), thash)
    algo_design = list(run_learner = data.table(
      learner_hash = lhash, learner_id = learner$id)
    )

    ids = batchtools::addExperiments(
      prob.designs = prob_design,
      algo.designs = algo_design,
      repls = resampling$iters,
      reg = reg
    )

    batchtools::setJobNames(ids, names = rep(uuid::UUIDgenerate(), nrow(ids)), reg = reg)
  }
}

reduceResultsBatchmark = function(ids = NULL, reg = batchtools::getDefaultRegistry()) {
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
      state = map(results, "learner_state"),
      resampling = list(resampling),
      iteration = tab$repl,
      prediction = map(results, "prediction"),
      uhash = tab$job.name
    ))

    bmr$combine(new_bmr)
  }

  return(bmr)
}

if (FALSE) {
  library(mlr3)
  library(batchtools)
  tasks = list(mlr3::tsk("iris"), mlr3::tsk("sonar"))
  learners = list(mlr3::lrn("classif.featureless"), mlr3::lrn("classif.rpart"))
  resamplings = list(mlr3::rsmp("cv", folds = 3), mlr3::rsmp("holdout"))

  design = mlr3::benchmark_grid(
    tasks = tasks,
    learners = learners,
    resamplings = resamplings
  )

  reg = batchtools::makeExperimentRegistry(NA)
  reg$cluster.functions = makeClusterFunctionsSocket()
  batchmark(design)
  submitJobs()

  getErrorMessages()

  reduceResultsBatchmark()
}
