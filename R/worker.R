get_resampling = function(resampling_hash, ...) {
  get(sprintf("resampling_%s", resampling_hash), envir = .GlobalEnv)
}

run_learner = function(job, data, instance, learner_hash, ...) {
  workhorse = getFromNamespace("workhorse", ns = asNamespace("mlr3"))
  learner = get(sprintf("learner_%s", learner_hash), envir = .GlobalEnv)

  workhorse(iteration = job$repl,
    task = data,
    learner = learner,
    resampling = instance)
}
