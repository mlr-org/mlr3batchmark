
test_that("basic workflow", {
  tasks = list(mlr3::tsk("iris"), mlr3::tsk("sonar"))
  learners = list(mlr3::lrn("classif.featureless"), mlr3::lrn("classif.rpart"))
  resamplings = list(mlr3::rsmp("cv", folds = 3), mlr3::rsmp("holdout"))

  design = mlr3::benchmark_grid(
    tasks = tasks,
    learners = learners,
    resamplings = resamplings
  )

  reg = batchtools::makeExperimentRegistry(NA, make.default = FALSE)
  batchmark(design, reg = reg)
  ids = batchtools::submitJobs(reg = reg)
  expect_data_table(ids, nrows = 16)

  expect_data_table(batchtools::getErrorMessages(reg = reg), nrows = 0L)
  results = reduceResultsBatchmark(reg = reg)
  expect_is(results, "BenchmarkResult")
})
