run_learner = function(job, data, learner_hash, store_models, ...) {
  workhorse = utils::getFromNamespace("workhorse", ns = asNamespace("mlr3"))
  resampling = get(job$prob.pars$resampling_hash, envir = .GlobalEnv)
  learner = get(learner_hash, envir = .GlobalEnv)

  workhorse(
    iteration = job$repl,
    task = data,
    learner = learner,
    resampling = resampling,
    store_models = store_models,
    lgr_threshold = lgr::get_logger("mlr3")$threshold
  )
}
