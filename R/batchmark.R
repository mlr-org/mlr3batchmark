#' @title Benchmark experiments on batch systems
#'
#' @inheritParams mlr3::benchmark
#'
#' @export
batchmark = function(design, store_models = FALSE, reg = batchtools::getDefaultRegistry()) {
  design = as.data.table(assert_data_frame(design, min.rows = 1L))
  assert_names(names(design), permutation.of = c("task", "learner", "resampling"))

  design$task = mlr3::assert_tasks(mlr3::as_tasks(design$task))
  design$resampling = mlr3::assert_resamplings(mlr3::as_resamplings(design$resampling), instantiated = TRUE)
  assert_flag(store_models)

  task_types = unique(map_chr(design$task, "task_type"))
  if (length(task_types) > 1L) {
    stopf("Multiple task types detected: %s", str_collapse(task_types))
  }

  task = resampling = NULL
  design[, `:=`("task", list(list(task[[1L]]$clone()))), by = list(map_chr(task
      , "hash"))]
  design[, `:=`("resampling", list(list(resampling[[1L]]$clone()))),
    by = list(map_chr(resampling, "hash"))]

  grid = pmap_dtr(design, function(task, learner, resampling) {
    learner = mlr3::assert_learner(mlr3::as_learner(learner))
    mlr3::assert_learnable(task, learner)
    data.table(task = list(task), learner = list(learner),
      resampling = list(resampling), iteration = seq_len(resampling$iters),
      uhash = UUIDgenerate())
  })

  workhorse = getFromNamespace("workhorse", ns = asNamespace("mlr3"))
  batchtools::batchMap(workhorse,
    args = grid[, !"uhash"],
    more.args = list(store_models = store_models)
  )

}

if (FALSE) {
  library(mlr3)
  tasks = list(mlr3::tsk("iris"), mlr3::tsk("sonar"))
  learners = list(mlr3::lrn("classif.featureless"), mlr3::lrn("classif.rpart"))
  resamplings = list(mlr3::rsmp("cv", folds = 3), mlr3::rsmp("holdout"))

  bm_grid = mlr3::benchmark_grid(
    tasks = tasks,
    learners = learners,
    resamplings = resamplings
  )

  reg = batchtools::makeRegistry(NA)
  batchmark(bm_grid)
  batchtools::submitJobs()
  batchtools::getStatus()


  batchtools::reduceResultsList(1)
}
