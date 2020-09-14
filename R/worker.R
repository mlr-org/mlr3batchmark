run_learner = function(job, data, learner_hash, ...) {
  workhorse = utils::getFromNamespace("workhorse", ns = asNamespace("mlr3"))
  resampling = get(job$prob.pars$resampling_hash, envir = .GlobalEnv)
  learner = get(learner_hash, envir = .GlobalEnv)

  workhorse(iteration = job$repl,
    task = data,
    learner = learner,
    resampling = resampling
  )
}
