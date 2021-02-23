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
#'
#' reduceResultsBatchmark(reg = reg)
batchmark = function(design, store_models = FALSE, reg = batchtools::getDefaultRegistry()) {
  design = as.data.table(assert_data_frame(design, min.rows = 1L))
  assert_names(names(design), permutation.of = c("task", "learner", "resampling"))
  assert_flag(store_models)
  batchtools::assertRegistry(reg, class = "ExperimentRegistry")

  # add worker algorithm
  if (!test_subset(reg$algorithms, "run_learner")) {
    stopf("No additional algorithms may be defined in the registry")
  }

  if ("run_learner" %nin% reg$algorithms) {
    batchtools::addAlgorithm("run_learner", fun = run_learner, reg = reg)
  }

  exports = batchtools::batchExport(reg = reg)$name

  for (i in seq_row(design)) {
    task = design$task[[i]]
    task_hash = task$hash
    if (task_hash %nin% reg$problems) {
      batchtools::addProblem(task_hash, data = task, reg = reg)
    }

    resampling = design$resampling[[i]]
    resampling_hash = resampling$hash
    if (resampling_hash %nin% exports) {
      batchtools::batchExport(export = set_names(list(resampling), resampling_hash), reg = reg)
      exports = c(exports, resampling_hash)
    }

    learner = design$learner[[i]]
    learner_hash = learner$hash
    if (learner_hash %nin% exports) {
      batchtools::batchExport(export = set_names(list(learner), learner_hash), reg = reg)
      exports = c(exports, learner_hash)
    }

    prob_design = set_names(list(data.table(
      task_hash = task_hash, task_id = task$id,
      resampling_hash = resampling_hash, resampling_id = resampling$id
    )), task_hash)

    algo_design = list(run_learner = data.table(
      learner_hash = learner_hash, learner_id = learner$id, store_models = store_models
    ))

    ids = batchtools::addExperiments(
      prob.designs = prob_design,
      algo.designs = algo_design,
      repls = resampling$iters,
      reg = reg
    )

    batchtools::setJobNames(ids, names = rep(uuid::UUIDgenerate(), nrow(ids)), reg = reg)
  }
}
