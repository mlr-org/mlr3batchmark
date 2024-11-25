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
  ids = batchmark(design, reg = reg)
  expect_data_table(ids, ncol = 1L, nrows = 16L)
  ids = batchtools::submitJobs(reg = reg)
  batchtools::waitForJobs(reg = reg)
  expect_data_table(ids, nrows = 16)

  logs = batchtools::getErrorMessages(reg = reg)
  expect_data_table(logs, nrows = 0L)
  results = reduceResultsBatchmark(reg = reg)
  expect_is(results, "BenchmarkResult")
  expect_benchmark_result(results)
  expect_data_table(as.data.table(results), nrow = 16L)
})

test_that("parallel multicore", {
  skip_on_os("windows")

  tasks = list(mlr3::tsk("iris"), mlr3::tsk("sonar"))
  learners = list(mlr3::lrn("classif.featureless"), mlr3::lrn("classif.rpart"))
  resamplings = list(mlr3::rsmp("cv", folds = 3), mlr3::rsmp("holdout"))

  design = mlr3::benchmark_grid(
    tasks = tasks,
    learners = learners,
    resamplings = resamplings
  )

  reg = batchtools::makeExperimentRegistry(NA, make.default = FALSE)
  reg$cluster.functions = batchtools::makeClusterFunctionsMulticore(2)
  batchmark(design, reg = reg)
  ids = batchtools::submitJobs(reg = reg)
  batchtools::waitForJobs(reg = reg)
  expect_data_table(ids, nrows = 16)

  logs = batchtools::getErrorMessages(reg = reg)
  expect_data_table(logs, nrows = 0L)
  results = reduceResultsBatchmark(reg = reg)
  expect_is(results, "BenchmarkResult")
  expect_benchmark_result(results)
  expect_data_table(as.data.table(results), nrow = 16L)
})

test_that("failing jobs", {
  tasks = list(mlr3::tsk("iris"), mlr3::tsk("sonar"))
  learners = list(mlr3::lrn("classif.debug", error_train = 1), mlr3::lrn("classif.rpart"))
  resamplings = list(mlr3::rsmp("cv", folds = 3), mlr3::rsmp("holdout"))

  design = mlr3::benchmark_grid(
    tasks = tasks,
    learners = learners,
    resamplings = resamplings
  )

  reg = batchtools::makeExperimentRegistry(NA, make.default = FALSE)
  batchmark(design, reg = reg)
  ids = batchtools::submitJobs(reg = reg)
  batchtools::waitForJobs(reg = reg)
  expect_data_table(ids, nrows = 16)

  # grep error logs
  logs = batchtools::getErrorMessages(reg = reg)
  expect_data_table(logs, nrows = 8L)
  expect_true(all(grepl("classif.debug->train", logs$message, fixed = TRUE)))

  # grep log files
  failing = batchtools::findErrors(reg = reg)
  lines = batchtools::getLog(failing[1], reg = reg)
  expect_true(any(grepl("classif.debug->train", lines, fixed = TRUE)))

  # collect partial results
  results = reduceResultsBatchmark(reg = reg)
  expect_is(results, "BenchmarkResult")
  expect_benchmark_result(results)
  expect_data_table(as.data.table(results), nrow = 8L)
  expect_error(reduceResultsBatchmark(reg = reg, ids = ids), "successfully computed")
})

test_that("marshaling", {
  reg = batchtools::makeExperimentRegistry(NA)
  batchmark(benchmark_grid(tsk("iris"), lrn("classif.debug"), rsmp("holdout")), store_models = TRUE)
  submitJobs()
  bmr_unmarshaled = reduceResultsBatchmark(unmarshal = TRUE)
  bmr_marshaled = reduceResultsBatchmark(unmarshal = FALSE)

  expect_true(bmr_marshaled$resample_result(1)$learners[[1]]$marshaled)
  expect_false(bmr_unmarshaled$resample_result(1)$learners[[1]]$marshaled)
})

test_that("adding parameter values works", {
  tasks = tsks(c("iris", "spam"))
  resamplings = list(rsmp("cv", folds = 3)$instantiate(tasks[[1]]))
  learners = lrns("classif.debug")

  design = data.table(
    task = tasks,
    learner = learners,
    resampling = resamplings,
    param_values = list(list(list(x = 1), list(x = 0.5))))

  reg = batchtools::makeExperimentRegistry(NA, make.default = FALSE)

  ids = batchmark(design, reg = reg)
  expect_data_table(ids, ncol = 1L, nrows = 12L)
  ids = batchtools::submitJobs(reg = reg)
  batchtools::waitForJobs(reg = reg)
  expect_data_table(ids, nrows = 12)

  logs = batchtools::getErrorMessages(reg = reg)
  expect_data_table(logs, nrows = 0L)
  results = reduceResultsBatchmark(reg = reg)
  expect_is(results, "BenchmarkResult")
  expect_benchmark_result(results)
  expect_data_table(as.data.table(results), nrow = 12L)

  expect_set_equal(
    map_dbl(results$learners$learner, function(x) x$param_set$values$x),
    c(0.5, 1)
  )
})

# test_that("renv_project works", {
#   tasks = list(mlr3::tsk("iris"), mlr3::tsk("sonar"))
#   learners = list(mlr3::lrn("classif.featureless"), mlr3::lrn("classif.rpart"))
#   resamplings = list(mlr3::rsmp("cv", folds = 3), mlr3::rsmp("holdout"))

#   design = mlr3::benchmark_grid(
#     tasks = tasks,
#     learners = learners,
#     resamplings = resamplings
#   )

#   reg = batchtools::makeExperimentRegistry(NA, make.default = FALSE)
#   batchmark(design, reg = reg, renv_project = ".")
#   batchtools::submitJobs(reg = reg)
# })
