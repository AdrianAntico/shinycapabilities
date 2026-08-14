\name{admit_workflow_runtime}
\alias{admit_workflow_runtime}
\title{Admit a Workflow Runtime to Canonical Execution}
\usage{
admit_workflow_runtime(runtime, maximum_ticks = NULL)
}
\arguments{
\item{runtime}{Runtime returned by \code{workflow_runtime()}.}

\item{maximum_ticks}{Maximum admission ticks before progress is considered
stalled. Defaults to the number of planned steps plus one.}
}
\value{
A list containing \code{active}, \code{terminal}, \code{state}, and the
serializable runtime \code{snapshot}.
}
\description{
Advances a runtime through bounded inline prerequisites until it owns a
background worker or reaches a terminal state. A runtime that cannot establish
either condition is failed explicitly rather than retained as an orphaned
active run.
}
