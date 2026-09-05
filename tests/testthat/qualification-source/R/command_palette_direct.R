#' Experimental direct-transport command palette
#'
#' Parallel implementation of [command_palette()] used to qualify the
#' package-owned Shiny transport. It does not alter the existing widget API.
#'
#' @inheritParams command_palette
#' @return A `shinycapabilities_direct_component`.
#' @export
command_palette_direct <- function(items, placeholder = "Search commands...",
                                   shortcut = TRUE, server_search = FALSE,
                                   empty_message = "No matching commands.",
                                   width = NULL, height = "420px",
                                   row_height = 54L, element_id = NULL) {
  component <- new_direct_component("command_palette_direct", list(
    items = normalize_command_palette_items(items),
    options = list(
      placeholder = as.character(placeholder), shortcut = isTRUE(shortcut),
      serverSearch = isTRUE(server_search), emptyMessage = as.character(empty_message),
      rowHeight = max(36L, as.integer(row_height))
    )
  ), element_id = element_id)
  component$width <- width
  component$height <- height
  component
}

#' @rdname command_palette_direct
#' @param output_id Shiny output identifier.
#' @export
command_palette_direct_output <- function(output_id, width = "100%", height = "420px") {
  direct_component_output(output_id, "command_palette_direct", width, height)
}

#' @rdname command_palette_direct
#' @param expr Expression returning a direct command palette.
#' @param env Evaluation environment.
#' @param quoted Whether `expr` is quoted.
#' @export
render_command_palette_direct <- function(expr, env = parent.frame(), quoted = FALSE) {
  if (!quoted) expr <- substitute(expr)
  render_direct_component(expr, command_palette_direct_output, env, quoted = TRUE)
}

#' @rdname command_palette_direct
#' @param session Active Shiny session.
#' @param items Replacement command records.
#' @param revision Optional monotonic revision.
#' @export
update_command_palette_direct <- function(session = shiny::getDefaultReactiveDomain(),
                                          output_id, items, placeholder = NULL,
                                          revision = as.integer(Sys.time())) {
  payload <- list(items = normalize_command_palette_items(items))
  if (!is.null(placeholder)) payload$options <- list(placeholder = as.character(placeholder))
  update_direct_component(session, output_id, "command_palette_direct", payload, revision)
}

#' Run the direct transport comparison demo
#' @param ... Arguments passed to [shiny::runApp()].
#' @export
run_direct_transport_demo <- function(...) {
  shiny::runApp(system.file("examples", "direct-transport",
    package = "shinycapabilities"), ...)
}
