#' Collapse workflow nodes into an executable composite
#' @param graph Workflow graph.
#' @param node_ids Node identifiers to collapse.
#' @param composite_id Stable composite identifier.
#' @param name Human-readable composite name.
#' @export
collapse_workflow <- function(graph, node_ids, composite_id, name = composite_id) {
  graph <- normalize_workflow_graph(graph)
  node_ids <- unique(as.character(node_ids))
  ids <- vapply(graph$nodes, `[[`, character(1), "id")
  if (!length(node_ids) || !all(node_ids %in% ids)) {
    stop("Composite nodes must all exist in the workflow.", call. = FALSE)
  }
  if (composite_id %in% ids) stop("Composite id already exists.", call. = FALSE)

  internal_nodes <- Filter(function(node) node$id %in% node_ids, graph$nodes)
  internal_edges <- Filter(function(edge) edge$source %in% node_ids && edge$target %in% node_ids, graph$edges)
  incoming <- Filter(function(edge) !edge$source %in% node_ids && edge$target %in% node_ids, graph$edges)
  outgoing <- Filter(function(edge) edge$source %in% node_ids && !edge$target %in% node_ids, graph$edges)
  untouched <- Filter(function(edge) !edge$source %in% node_ids && !edge$target %in% node_ids, graph$edges)

  input_mappings <- lapply(seq_along(incoming), function(index) {
    edge <- incoming[[index]]
    list(
      exposed_port = paste0("input_", index),
      internal_node = edge$target,
      internal_port = edge$target_port,
      original_edge_id = edge$id
    )
  })
  output_mappings <- lapply(seq_along(outgoing), function(index) {
    edge <- outgoing[[index]]
    list(
      exposed_port = paste0("output_", index),
      internal_node = edge$source,
      internal_port = edge$source_port,
      original_edge_id = edge$id
    )
  })
  collapsed_incoming <- Map(function(edge, mapping) {
    edge$target <- composite_id
    edge$target_port <- mapping$exposed_port
    edge
  }, incoming, input_mappings)
  collapsed_outgoing <- Map(function(edge, mapping) {
    edge$source <- composite_id
    edge$source_port <- mapping$exposed_port
    edge
  }, outgoing, output_mappings)
  positions <- lapply(internal_nodes, `[[`, "position")
  composite <- list(
    id = composite_id,
    capability_id = "workflow.composite",
    position = list(
      x = mean(vapply(positions, `[[`, numeric(1), "x")),
      y = mean(vapply(positions, `[[`, numeric(1), "y"))
    ),
    state = "ready",
    metadata = list(
      display_name = name,
      composite = TRUE,
      input_mappings = input_mappings,
      output_mappings = output_mappings,
      internal_graph = list(nodes = internal_nodes, edges = internal_edges)
    )
  )
  normalize_workflow_graph(list(
    nodes = c(Filter(function(node) !node$id %in% node_ids, graph$nodes), list(composite)),
    edges = c(untouched, collapsed_incoming, collapsed_outgoing),
    groups = graph$groups,
    proposal = graph$proposal
  ))
}

#' Expand one workflow composite
#' @param graph Workflow graph.
#' @param composite_id Composite identifier.
#' @export
expand_workflow_composite <- function(graph, composite_id) {
  graph <- normalize_workflow_graph(graph)
  matches <- Filter(function(node) identical(node$id, composite_id), graph$nodes)
  if (length(matches) != 1L || !isTRUE(matches[[1]]$metadata$composite)) {
    stop("Unknown workflow composite.", call. = FALSE)
  }
  composite <- matches[[1]]
  metadata <- composite$metadata
  input_by_port <- setNames(metadata$input_mappings, vapply(metadata$input_mappings, `[[`, character(1), "exposed_port"))
  output_by_port <- setNames(metadata$output_mappings, vapply(metadata$output_mappings, `[[`, character(1), "exposed_port"))
  external <- Filter(function(edge) !(edge$source == composite_id && edge$target == composite_id), graph$edges)
  restored_external <- lapply(external, function(edge) {
    if (identical(edge$target, composite_id)) {
      mapping <- input_by_port[[edge$target_port]]
      edge$target <- mapping$internal_node
      edge$target_port <- mapping$internal_port
      edge$id <- mapping$original_edge_id
    }
    if (identical(edge$source, composite_id)) {
      mapping <- output_by_port[[edge$source_port]]
      edge$source <- mapping$internal_node
      edge$source_port <- mapping$internal_port
      edge$id <- mapping$original_edge_id
    }
    edge
  })
  normalize_workflow_graph(list(
    nodes = c(Filter(function(node) !identical(node$id, composite_id), graph$nodes),
      metadata$internal_graph$nodes),
    edges = c(restored_external, metadata$internal_graph$edges),
    groups = graph$groups,
    proposal = graph$proposal
  ))
}

expand_workflow_composites <- function(graph) {
  graph <- normalize_workflow_graph(graph)
  repeat {
    composites <- Filter(function(node) isTRUE(node$metadata$composite), graph$nodes)
    if (!length(composites)) break
    graph <- expand_workflow_composite(graph, composites[[1]]$id)
  }
  graph
}
