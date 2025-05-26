run_learner = function(job, data, learner_hash, param_values_hash, store_models, renv_project = NULL, ...) {
  if (!is.null(renv_project)) {
    renv::load(renv_project)
  }
  workhorse = utils::getFromNamespace("workhorse", ns = asNamespace("mlr3"))
  resampling = get(job$prob.pars$resampling_hash, envir = .GlobalEnv)
  learner = get(learner_hash, envir = .GlobalEnv)
  param_values = get(param_values_hash, envir = .GlobalEnv)

  if (!is.null(param_values)) learner$param_set$set_values(.values = param_values)

  if (packageVersion("mlr3") > "0.23.0") {
    workhorse(
      iteration = job$repl,
      task = data,
      learner = learner,
      resampling = resampling,
      store_models = store_models,
      lgr_index = lgr::logger_index(),
      is_sequential = FALSE
    )
  } else {
    workhorse(
      iteration = job$repl,
      task = data,
      learner = learner,
      resampling = resampling,
      store_models = store_models,
      lgr_threshold = lgr::get_logger("mlr3")$threshold,
      is_sequential = FALSE
    )
  }
}

