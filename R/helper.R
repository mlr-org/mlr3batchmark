get_export = function(needle, reg) {
  readRDS(batchtools::batchExport(reg = reg)[list(needle), on = "name"]$uri)
}
