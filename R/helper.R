get_export = function(needle, reg) {
  readRDS(batchtools::batchExport(reg = reg)[list(needle), on = "name"]$uri)
}

update_job_names = function(reg) {
  generate_job_name = function(names) {
    name = unique(names[!is.na(names)])
    if (length(name) == 0L)
      return(uuid::UUIDgenerate())
    if (length(name) == 1L)
      return(name)
    stop("Ambiguous uhashes for job names found in registry")
  }

  reg$status[, "job.name" := generate_job_name(.SD$job.name), by = "def.id", .SDcols = "job.name"]
  batchtools::saveRegistry(reg)
}
