#' Create a secondary output placement
#' @param artifact_id Stable output artifact reference.
#' @param placement_id Stable placement identifier.
#' @param region Host-owned output region.
#' @param position Ordering or layout position.
#' @export
output_placement <- function(artifact_id, placement_id = artifact_id,
                             region = "artifact_tray", position = 1L) {
  list(
    placement_id = as.character(placement_id),
    artifact_id = as.character(artifact_id),
    region = as.character(region),
    position = as.integer(position)
  )
}

#' Create a serializable workflow document
#' @param graph Workflow graph.
#' @param output_placements Secondary output placements.
#' @export
workflow_document <- function(graph, output_placements = list()) {
  placements <- output_placements
  ids <- vapply(placements, `[[`, character(1), "placement_id")
  if (anyDuplicated(ids)) stop("Output placement ids must be unique.", call. = FALSE)
  structure(list(
    schema_version = "1.0.0",
    graph = normalize_workflow_graph(graph),
    output_placements = placements
  ), class = "shinycap_workflow_document")
}

#' Serialize a workflow document
#' @param document Workflow document.
#' @export
serialize_workflow_document <- function(document) {
  stopifnot(inherits(document, "shinycap_workflow_document"))
  stable_json(unclass(document))
}

#' Restore a workflow document
#' @param value JSON text or decoded list.
#' @export
restore_workflow_document <- function(value) {
  decoded <- if (is.character(value)) jsonlite::fromJSON(value, simplifyVector = FALSE) else value
  graph <- normalize_workflow_graph(decoded$graph)
  interrupted <- c("pending", "queued", "running", "cancelling")
  graph$nodes <- lapply(graph$nodes, function(node) {
    if (node$state %in% interrupted) node$state <- "stale"
    if (isTRUE(node$metadata$composite)) {
      node$metadata$internal_graph$nodes <- lapply(
        node$metadata$internal_graph$nodes %||% list(), function(internal) {
          if (internal$state %in% interrupted) internal$state <- "stale"
          internal
        }
      )
    }
    node
  })
  workflow_document(graph, decoded$output_placements %||% list())
}
