allowed_node_states <- c(
  "unconfigured", "ready", "pending", "queued", "running", "cancelling",
  "succeeded", "failed", "blocked", "stale", "cancelled", "reused",
  "skipped/current"
)

#' Normalize a workflow graph for deterministic persistence
#' @param graph Workflow graph list.
#' @export
normalize_workflow_graph <- function(graph) {
  graph <- graph %||% list()
  nodes <- graph$nodes %||% list()
  edges <- graph$edges %||% list()
  nodes <- lapply(nodes, function(node) {
    list(
      id = as.character(node$id),
      capability_id = as.character(node$capability_id %||% node$data$capabilityId),
      position = list(
        x = as.numeric(node$position$x %||% 0),
        y = as.numeric(node$position$y %||% 0)
      ),
      size = list(
        width = as.numeric(node$size$width %||% node$width %||% 260),
        height = as.numeric(node$size$height %||% node$height %||% 138)
      ),
      config = node$config %||% node$data$config %||% list(),
      state = node$state %||% node$data$state %||% "unconfigured",
      parent_id = node$parent_id %||% NULL,
      metadata = node$metadata %||% list()
    )
  })
  edges <- lapply(edges, function(edge) {
    list(
      id = as.character(edge$id %||% paste(edge$source, edge$source_port, edge$target, edge$target_port, sep = "__")),
      source = as.character(edge$source),
      source_port = as.character(edge$source_port %||% edge$sourceHandle),
      target = as.character(edge$target),
      target_port = as.character(edge$target_port %||% edge$targetHandle)
    )
  })
  node_order <- order(vapply(nodes, `[[`, character(1), "id"))
  edge_order <- order(vapply(edges, `[[`, character(1), "id"))
  list(
    schema_version = "1.0.0",
    nodes = if (length(nodes)) nodes[node_order] else list(),
    edges = if (length(edges)) edges[edge_order] else list(),
    groups = graph$groups %||% list(),
    proposal = graph$proposal %||% NULL
  )
}

#' Fingerprint a normalized graph
#' @param graph Workflow graph list.
#' @export
graph_fingerprint <- function(graph) stable_hash(normalize_workflow_graph(graph))

#' Validate a proposed typed connection
#' @param registry Capability registry.
#' @param graph Workflow graph.
#' @param edge Proposed edge.
#' @export
validate_connection <- function(registry, graph, edge) {
  graph <- normalize_workflow_graph(graph)
  nodes <- setNames(graph$nodes, vapply(graph$nodes, `[[`, character(1), "id"))
  source <- nodes[[edge$source]]
  target <- nodes[[edge$target]]
  if (is.null(source) || is.null(target)) {
    return(list(valid = FALSE, code = "unknown_node", message = "Connection references an unknown node."))
  }
  if (identical(source$id, target$id)) {
    return(list(valid = FALSE, code = "self_connection", message = "A node cannot connect to itself."))
  }
  source_cap <- capability_registry_get(registry, source$capability_id)
  target_cap <- capability_registry_get(registry, target$capability_id)
  output <- source_cap$outputs[[edge$source_port %||% edge$sourceHandle]]
  input <- target_cap$inputs[[edge$target_port %||% edge$targetHandle]]
  if (is.null(output) || is.null(input)) {
    return(list(valid = FALSE, code = "unknown_port", message = "Connection references an unknown port."))
  }
  if (!identical(output$type, input$type) && !identical(input$type, "any")) {
    return(list(
      valid = FALSE, code = "type_mismatch",
      message = sprintf("Output %s is %s, but input %s requires %s.",
        edge$source_port, output$type, edge$target_port, input$type)
    ))
  }
  list(valid = TRUE, code = "accepted", message = "Typed connection accepted.")
}

#' Validate a workflow graph
#' @param registry Capability registry.
#' @param graph Workflow graph.
#' @export
validate_workflow <- function(registry, graph) {
  graph <- normalize_workflow_graph(graph)
  findings <- list()
  ids <- vapply(graph$nodes, `[[`, character(1), "id")
  if (anyDuplicated(ids)) {
    findings <- append(findings, list(list(code = "duplicate_node", severity = "error")))
  }
  for (edge in graph$edges) {
    result <- validate_connection(registry, graph, edge)
    if (!isTRUE(result$valid)) findings <- append(findings, list(result))
  }
  for (node in graph$nodes) {
    cap <- capability_registry_get(registry, node$capability_id)
    if (is.null(cap)) {
      findings <- append(findings, list(list(
        code = "unknown_capability", severity = "error", node_id = node$id
      )))
      next
    }
    incoming <- Filter(function(edge) identical(edge$target, node$id), graph$edges)
    for (port_name in names(cap$inputs)) {
      port <- cap$inputs[[port_name]]
      bound <- any(vapply(incoming, function(edge) identical(edge$target_port, port_name), logical(1)))
      if (isTRUE(port$required) && !bound) findings <- append(findings, list(list(
        code = "required_input_missing", severity = "error",
        node_id = node$id, port = port_name
      )))
    }
  }
  list(valid = !any(vapply(findings, function(x) identical(x$severity %||% "error", "error"), logical(1))),
       findings = findings)
}
