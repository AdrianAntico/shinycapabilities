#' Experimental shared-runtime split pane
#'
#' A Direct Component Transport qualification variant of [split_pane()]. The
#' existing public split-pane contract remains unchanged.
#'
#' @param panes Named list of bounded HTML strings or tag objects.
#' @param direction Horizontal or vertical layout.
#' @param sizes,min_sizes,max_sizes Length-one or pane-length percentages.
#' @param collapsible Length-one or pane-length logical vector.
#' @param collapsed Pane ids initially collapsed.
#' @param reset_on_double_click Reset sizes by double-clicking a separator.
#' @param revision Monotonic host revision.
#' @param element_id Optional static element id.
#' @export
split_pane_direct <- function(panes, direction = c("horizontal", "vertical"),
                              sizes = NULL, min_sizes = NULL, max_sizes = NULL,
                              collapsible = FALSE, collapsed = character(),
                              reset_on_double_click = TRUE, revision = 1L,
                              element_id = NULL) {
  if (!is.list(panes)) stop("panes must be a named list.", call. = FALSE)
  model <- normalize_split_pane_model(panes, direction, sizes, min_sizes,
    max_sizes, collapsible, collapsed, reset_on_double_click)
  names(panes) <- model$ids
  model$html <- stats::setNames(lapply(panes, function(content) {
    htmltools::renderTags(content)$html
  }), model$ids)
  value <- new_direct_component("split_pane_direct", model, element_id)
  value$revision <- as.integer(revision)
  value
}

#' @rdname split_pane_direct
#' @param output_id Shiny output id.
#' @param width,height CSS dimensions.
#' @export
split_pane_direct_output <- function(output_id, width = "100%", height = "520px") {
  direct_component_output(output_id, "split_pane_direct", width, height)
}

#' @rdname split_pane_direct
#' @param expr Expression returning [split_pane_direct()].
#' @param env Evaluation environment.
#' @param quoted Whether `expr` is quoted.
#' @export
render_split_pane_direct <- function(expr, env = parent.frame(), quoted = FALSE) {
  if (!quoted) expr <- substitute(expr)
  render_direct_component(expr, split_pane_direct_output, env, quoted = TRUE)
}

#' @rdname split_pane_direct
#' @param session Active Shiny session.
#' @param collapse,expand Pane ids to collapse or expand.
#' @param reset Restore initial sizes.
#' @export
update_split_pane_direct <- function(session = shiny::getDefaultReactiveDomain(),
                                     output_id, sizes = NULL, collapse = NULL,
                                     expand = NULL, reset = FALSE,
                                     revision = as.integer(Sys.time())) {
  payload <- list()
  if (!is.null(sizes)) payload$sizes <- sizes
  if (!is.null(collapse)) payload$collapse <- as.character(collapse)
  if (!is.null(expand)) payload$expand <- as.character(expand)
  if (isTRUE(reset)) payload$reset <- TRUE
  update_direct_component(session, output_id, "split_pane_direct", payload, revision)
}

#' Run the Shared Browser Runtime composition demo
#' @param ... Arguments passed to [shiny::runApp()].
#' @export
run_shared_browser_runtime_demo <- function(...) {
  shiny::runApp(system.file("examples", "shared-runtime", package = "shinycapabilities"), ...)
}
