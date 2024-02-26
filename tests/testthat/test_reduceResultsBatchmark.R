test_that("reduceResultsBatchmark", {
  tasks = list(mlr3::tsk("iris"), mlr3::tsk("sonar"))
  learners = list(mlr3::lrn("classif.featureless"), mlr3::lrn("classif.rpart"))
  resamplings = list(mlr3::rsmp("cv", folds = 3), mlr3::rsmp("holdout"))

  design = mlr3::benchmark_grid(
    tasks = tasks,
    learners = learners,
    resamplings = resamplings
  )

  reg = batchtools::makeExperimentRegistry(NA)
  batchmark(design, reg = reg, store_models = TRUE)
  batchtools::submitJobs(reg = reg)
  batchtools::waitForJobs(reg = reg)

  bmr = reduceResultsBatchmark(reg = reg)
  expect_character(bmr$uhashes, len = nrow(design), any.missing = FALSE, unique = TRUE)
  expect_equal(bmr$n_resample_results, 8)
  expect_equal(sum(map_int(bmr$resample_results$resample_result, function(rr) nrow(rr$errors))), 0)

  tab = bmr$tasks
  expect_data_table(tab, nrow = 2)
  expect_set_equal(tab$task_id, ids(tasks))

  tab = bmr$learners
  expect_data_table(tab, nrow = 2)
  expect_set_equal(tab$learner_id, ids(learners))

  tab = bmr$resamplings
  expect_data_table(tab, nrow = 4)
  expect_set_equal(tab$resampling_id, ids(resamplings))

  rpart_model = function(b){
    b$score()[learner_id == "classif.rpart"]$learner[[1]]$model
  }
  expect_is(rpart_model(bmr), "rpart")
  no_models = reduceResultsBatchmark(reg = reg, fun = function(L){
    L$learner_state$model = NULL
    L
  })
  expect_null(rpart_model(no_models))
  
})

test_that("warning is given when mlr3 versions mismatch", {
  mlr_reflections = mlr3::mlr_reflections
  mlr3_version = mlr_reflections$package_version
  reg = makeExperimentRegistry(NA)
  batchmark(benchmark_grid(tsk("mtcars"), lrn("regr.featureless"), rsmp("holdout")))
  submitJobs()
  waitForJobs()

  on.exit({mlr_reflections$package_version = mlr3_version}, add = TRUE)

  mlr_reflections$package_version = "100.0.0"

  capture.output(reduceResultsBatchmark(reg = reg))
  expect_true(grepl("The mlr3 version", lg$last_event$msg, fixed = TRUE))
})
