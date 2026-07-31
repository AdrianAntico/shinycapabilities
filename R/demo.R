#' Run the bundled demonstration Shiny app
#' @param ... Arguments passed to \code{shiny::runApp()}.
#' @export
run_capability_demo <- function(...) {
  shiny::runApp(system.file("examples/workflow", package = "shinycapabilities"), ...)
}
