registry_payload <- function(registry) {
  lapply(capability_registry_list(registry), function(capability) {
    presentation <- capability_presentation(capability)
    list(
      id = capability$id,
      version = capability$version,
      displayName = capability$display_name,
      description = capability$description,
      category = capability$category,
      inputs = capability$inputs,
      outputs = capability$outputs,
      config = capability$config,
      icon = presentation$icon,
      style = capability$style
    )
  })
}

#' Create a capability canvas htmlwidget
#' @param registry Capability registry.
#' @param graph Initial workflow graph.
#' @param read_only Disable graph editing.
#' @param minimap Display the minimap.
#' @param width,height Widget dimensions.
#' @param element_id Optional HTML element identifier.
#' @export
capability_canvas <- function(
    registry, graph = list(nodes = list(), edges = list()),
    read_only = FALSE, minimap = TRUE, width = NULL, height = "640px",
    element_id = NULL) {
  htmlwidgets::createWidget(
    name = "capability_canvas",
    x = list(
      capabilities = registry_payload(registry),
      graph = normalize_workflow_graph(graph),
      options = list(readOnly = isTRUE(read_only), minimap = isTRUE(minimap))
    ),
    width = width,
    height = height,
    package = "shinycapabilities",
    elementId = element_id
  )
}

#' Shiny output binding for capability_canvas
#' @param output_id Shiny output identifier.
#' @param width,height Widget dimensions.
#' @export
capability_canvas_output <- function(output_id, width = "100%", height = "640px") {
  htmlwidgets::shinyWidgetOutput(output_id, "capability_canvas", width, height,
    package = "shinycapabilities")
}

#' Shiny renderer for capability_canvas
#' @param expr Expression returning a widget.
#' @param env Evaluation environment.
#' @param quoted Whether \code{expr} is quoted.
#' @export
render_capability_canvas <- function(expr, env = parent.frame(), quoted = FALSE) {
  if (!quoted) expr <- substitute(expr)
  htmlwidgets::shinyRenderWidget(expr, capability_canvas_output, env, quoted = TRUE)
}
