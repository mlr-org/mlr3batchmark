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
  batchmark(design, reg = reg)
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
})
