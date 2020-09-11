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
batchmark = function(design, store_models = FALSE, reg = batchtools::getDefaultRegistry()) {
  design = as.data.table(assert_data_frame(design, min.rows = 1L))
  assert_names(names(design), permutation.of = c("task", "learner", "resampling"))
  assert_flag(store_models)
  batchtools::assertRegistry(reg, class = "ExperimentRegistry")

  phashes = character()
  ahashes = character()
  rhashes = character()
  if (FALSE) {
    reg = makeExperimentRegistry(NA)
  }

  for (i in seq_row(design)) {
    task = design$task[[i]]
    learner = design$learner[[i]]
    resampling = design$resampling[[i]]

    prob_id = task$id
    algo_id = learner$id

    phash = task$hash
    if (phash %nin% phashes) {
      phashes = c(phash, phashes)
      addProblem(prob_id, data = task, fun = get_resampling, reg = reg)
    }

    rhash = resampling$hash
    if (rhash %nin% rhashes) {
      batchExport(set_names(list(resampling), sprintf("resampling_%s", resampling$hash)))
    }

    ahash = learner$hash
    if (ahash %nin% ahashes) {
      ahashes = c(ahash, ahashes)
      batchExport(set_names(list(learner), sprintf("learner_%s", learner$hash)))
      addAlgorithm(algo_id, fun = run_learner, reg = reg)
    }

    prob_design = data.table(task_hash = task$hash, resampling_hash = resampling$hash, resampling_id = resampling$id)
    algo_design = data.table(learner_hash = learner$hash)

    addExperiments(
      prob.designs = named_list(prob_id, prob_design),
      algo.designs = named_list(algo_id, algo_design),
      repls = resampling$iters,
      reg = reg
    )
  }
}

reduceResultsBatchmark = function(ids = NULL, reg = batchtools::getDefaultRegistry()) {
  ids = batchtools::findDone(ids, reg = reg)

  tab = unnest(getJobPars(ids), c("prob.pars", "algo.pars"))
  grouped = tab[, list(job.id = list(job.id)),  by = c("task_hash", "learner_hash", "resampling_hash")]

  for (ids in tab$job.id) {
    job = makeJob(ids[1L])
    task = job$problem$data
    resampling = job$instance
    learner = job
  }
}

if (FALSE) {
  library(mlr3)
  tasks = list(mlr3::tsk("iris"), mlr3::tsk("sonar"))
  learners = list(mlr3::lrn("classif.featureless"), mlr3::lrn("classif.rpart"))
  resamplings = list(mlr3::rsmp("cv", folds = 3), mlr3::rsmp("holdout"))

  design = mlr3::benchmark_grid(
    tasks = tasks,
    learners = learners,
    resamplings = resamplings
  )

  reg = batchtools::makeExperimentRegistry(NA)
  batchmark(design)

  submitJobs()

  batchtools::getStatus()

  showLog(1)

  findErrors()
  getJobPars(findErrors())
  makeJob(2)
  getJobTable()


  batchtools::reduceResultsList()
}
