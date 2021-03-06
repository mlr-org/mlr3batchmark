% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/batchmark.R
\name{batchmark}
\alias{batchmark}
\title{Benchmark experiments on batch systems}
\usage{
batchmark(design, store_models = FALSE, reg = batchtools::getDefaultRegistry())
}
\arguments{
\item{design}{(\code{\link[=data.frame]{data.frame()}})\cr
Data frame (or \code{\link[data.table:data.table]{data.table::data.table()}}) with three columns: "task", "learner", and "resampling".
Each row defines a resampling by providing a \link[mlr3]{Task}, \link[mlr3]{Learner} and an instantiated \link[mlr3]{Resampling} strategy.
The helper function \code{\link[mlr3:benchmark_grid]{benchmark_grid()}} can assist in generating an exhaustive design (see examples) and
instantiate the \link[mlr3]{Resampling}s per \link[mlr3]{Task}.}

\item{store_models}{(\code{logical(1)})\cr
Store the fitted model in the resulting object=
Set to \code{TRUE} if you want to further analyse the models or want to
extract information like variable importance.}

\item{reg}{\link[batchtools:makeExperimentRegistry]{batchtools::ExperimentRegistry}.}
}
\value{
\code{\link[=data.table]{data.table()}} with ids of created jobs (invisibly).
}
\description{
Populates a \link[batchtools:makeExperimentRegistry]{batchtools::ExperimentRegistry} with jobs in a \code{\link[mlr3:benchmark]{mlr3::benchmark()}} fashion.
Each combination of \link[mlr3:Task]{mlr3::Task} and \link[mlr3:Resampling]{mlr3::Resampling} defines a \link[batchtools:addProblem]{batchtools::Problem},
each \link[mlr3:Learner]{mlr3::Learner} is an \link[batchtools:addAlgorithm]{batchtools::Algorithm}.
}
\examples{
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

reduceResultsBatchmark(reg = reg)
}
