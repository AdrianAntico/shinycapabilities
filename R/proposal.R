#' Create a bounded workflow proposal
#' @param id Stable proposal identifier.
#' @param graph Proposed workflow graph.
#' @param explanations Named node explanations.
#' @param connection_explanations Named connection explanations.
#' @param overall_rationale Overall plan rationale.
#' @param missing_evidence Missing evidence or unresolved questions.
#' @param recommended_execution_order Proposed topological execution order.
#' @param groups Optional proposed composite groups.
#' @export
workflow_proposal <- function(
    id, graph, explanations = list(), connection_explanations = list(),
    overall_rationale = "", missing_evidence = list(),
    recommended_execution_order = character(), groups = list()) {
  graph <- normalize_workflow_graph(graph)
  graph$nodes <- lapply(graph$nodes, function(node) {
    node$metadata$proposal_status <- "proposed"
    node
  })
  structure(list(
    schema_version = "1.0.0",
    id = as.character(id),
    graph = graph,
    explanations = explanations,
    connection_explanations = connection_explanations,
    overall_rationale = as.character(overall_rationale),
    missing_evidence = missing_evidence,
    recommended_execution_order = as.character(recommended_execution_order),
    groups = groups
  ), class = "shinycap_workflow_proposal")
}

#' Accept all or selected nodes from a workflow proposal
#' @param proposal Workflow proposal.
#' @param graph Existing graph to merge into.
#' @param node_ids Optional proposed node identifiers to accept.
#' @export
accept_workflow_proposal <- function(proposal, graph = list(nodes = list(), edges = list()),
                                     node_ids = NULL) {
  stopifnot(inherits(proposal, "shinycap_workflow_proposal"))
  existing <- normalize_workflow_graph(graph)
  proposed <- normalize_workflow_graph(proposal$graph)
  node_ids <- node_ids %||% vapply(proposed$nodes, `[[`, character(1), "id")
  accepted <- Filter(function(node) node$id %in% node_ids, proposed$nodes)
  accepted <- lapply(accepted, function(node) {
    node$metadata$proposal_status <- "accepted"
    node
  })
  known <- c(vapply(existing$nodes, `[[`, character(1), "id"),
    vapply(accepted, `[[`, character(1), "id"))
  edges <- Filter(function(edge) edge$source %in% known && edge$target %in% known, proposed$edges)
  normalize_workflow_graph(list(
    nodes = c(existing$nodes, accepted),
    edges = c(existing$edges, edges),
    groups = existing$groups,
    proposal = list(id = proposal$id, accepted = node_ids)
  ))
}
