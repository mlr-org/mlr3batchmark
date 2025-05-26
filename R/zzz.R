#' @import data.table
#' @import checkmate
#' @import mlr3misc
#' @rawNamespace import(batchtools, except = chunk)
#' @importFrom uuid UUIDgenerate
#' @importFrom utils packageVersion
"_PACKAGE"


.onLoad = function(libname, pkgname) {
  assign("lg", lgr::get_logger(pkgname), envir = parent.env(environment()))
}
