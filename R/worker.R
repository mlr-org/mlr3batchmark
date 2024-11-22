run_learner = function(job, data, learner_hash, param_values_hash, store_models, renv_project = NULL, ...) {
  if (!is.null(renv_project)) {
    renv::load(renv_project)
  }

  message(sprintf("Loaded renv project %s", renv::project()))
  message(sprintf("Passed renv project %s", renv_project))

  Sys.sleep(30)

  workhorse = utils::getFromNamespace("workhorse", ns = asNamespace("mlr3"))
  resampling = get(job$prob.pars$resampling_hash, envir = .GlobalEnv)
  learner = get(learner_hash, envir = .GlobalEnv)
  param_values = get(param_values_hash, envir = .GlobalEnv)

  if (!is.null(param_values)) learner$param_set$set_values(.values = param_values)

  result = workhorse(
    iteration = job$repl,
    task = data,
    learner = learner,
    resampling = resampling,
    store_models = store_models,
    lgr_threshold = lgr::get_logger("mlr3")$threshold,
    is_sequential = FALSE
  )

  Sys.sleep(30)

  return(result)
}
