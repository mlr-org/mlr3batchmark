#' @title Benchmark Experiments on Batch Systems
#'
#' @description
#' This function provides the functionality to leave the interface of \CRANpkg{mlr3} for the computation
#' of benchmark experiments and switch over to \CRANpkg{batchtools} for a more fine grained control over
#' the execution.
#'
#' `batchmark()` populates a [batchtools::ExperimentRegistry] with jobs in a [mlr3::benchmark()] fashion.
#' Each combination of [mlr3::Task] and [mlr3::Resampling] defines a [batchtools::Problem],
#' each [mlr3::Learner] is an [batchtools::Algorithm].
#'
#' After the jobs have been submitted and are terminated, results can be collected with [reduceResultsBatchmark()]
#' which returns a [mlr3::BenchmarkResult] and thus to return to the interface of \CRANpkg{mlr3}.
#'
#' @inheritParams mlr3::benchmark
#' @param reg [batchtools::ExperimentRegistry].
#' @param renv_project `character(1)`\cr
#' Path to a renv project.
#' If not `NULL`, the renv project is activated in the job environment.
#'
#' @return [data.table::data.table()] with ids of created jobs (invisibly).
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
batchmark = function(design, store_models = FALSE, reg = batchtools::getDefaultRegistry(), renv_project = NULL) {
  design = as.data.table(assert_data_frame(design, min.rows = 1L))
  assert_names(names(design), must.include = c("task", "learner", "resampling"))
  assert_flag(store_models)
  batchtools::assertRegistry(reg, class = "ExperimentRegistry", writeable = TRUE, sync = TRUE, running.ok = FALSE)
  if (!is.null(renv_project)) {
    require_namespaces("renv")
    assert_directory_exists(renv_project)
  }

  assert_list(design$task, "Task")
  assert_list(design$learner, "Learner")
  assert_list(design$resampling, "Resampling")

  # add worker algorithm
  if (!test_subset(reg$algorithms, "run_learner")) {
    stopf("No additional algorithms may be defined in the registry")
  }

  if ("run_learner" %nin% reg$algorithms) {
    batchtools::addAlgorithm("run_learner", fun = run_learner, reg = reg)
  }

  # set hashes
  set(design, j = "task_hash", value = map_chr(design$task, "hash"))
  set(design, j = "learner_hash", value = map_chr(design$learner, "hash"))
  set(design, j = "resampling_hash", value = map_chr(design$resampling, "hash"))

  # expand with param values
  if (is.null(design$param_values)) {
    design$param_values = list()
  } else {
    design$param_values = list(assert_param_values(design$param_values, n_learners = length(design$learner)))
    task = learner = resampling = NULL
    design = design[, list(task, learner, resampling, param_values = unlist(get("param_values"), recursive = FALSE)), by = c("learner_hash", "task_hash", "resampling_hash")]
  }
  design[, "param_values_hash" := map(get("param_values"), calculate_hash)]

  # group per problem to speed up addExperiments()
  design[, "group" := .GRP, by = c("task_hash", "resampling_hash")]

  groups = unique(design$group)
  ids = vector("list", length(groups))
  exports = batchtools::batchExport(reg = reg)$name

  for (g in groups) {
    tab = design[list(g), on = "group"]

    task = tab$task[[1L]]
    task_hash = tab$task_hash[1L]
    if (task_hash %nin% reg$problems) {
      batchtools::addProblem(task_hash, data = task, reg = reg)
    }

    resampling = tab$resampling[[1L]]
    resampling_hash = tab$resampling_hash[1L]
    if (resampling_hash %nin% exports) {
      batchtools::batchExport(export = set_names(list(resampling), resampling_hash), reg = reg)
      exports = c(exports, resampling_hash)
    }

    learner_hashes = tab$learner_hash
    for (i in which(learner_hashes %nin% exports)) {
      batchtools::batchExport(export = set_names(list(tab$learner[[i]]), learner_hashes[i]), reg = reg)
      exports = c(exports, learner_hashes[i])
    }

    param_values_hashes = tab$param_values_hash
    for (i in which(param_values_hashes %nin% exports)) {
      batchtools::batchExport(export = set_names(list(tab$param_values[[i]]), param_values_hashes[i]), reg = reg)
      exports = c(exports, param_values_hashes[i])
    }

    prob_design = data.table(
      task_hash = task_hash,
      task_id = task$id,
      resampling_hash = resampling_hash,
      resampling_id = resampling$id
    )

    algo_design = data.table(
      learner_hash = learner_hashes,
      learner_id = map_chr(tab$learner, "id"),
      param_values_hash = param_values_hashes,
      store_models = store_models,
      renv_project = renv_project
    )

    ids[[g]] = batchtools::addExperiments(
      prob.designs = set_names(list(prob_design), task_hash),
      algo.designs = list(run_learner = algo_design),
      repls = resampling$iters,
      reg = reg
    )
  }

  # name jobs belonging to the same resampling with a unique identifier
  update_job_names(reg)

  invisible(rbindlist(ids, use.names = FALSE))
}
