#' Inspect shinycapabilities compatibility contracts
#'
#' @return A closed compatibility manifest.
#' @export
shinycapabilities_compatibility_manifest <- function() {
  list(
    package_api_contract = "1.0.0",
    browser_bridge = "1.0.0",
    workflow_document = list(readable = "1.0.0", writable = "1.0.0"),
    presentation_hooks = "1.0.0",
    runtime_contract = "1.0.0",
    host_owned_presentation = "required"
  )
}

#' Validate a workflow document without mutating it
#'
#' @param value A workflow document, decoded list, or JSON text.
#' @return A validation result with deterministic findings.
#' @export
validate_workflow_document <- function(value) {
  decoded <- tryCatch(
    if (is.character(value)) jsonlite::fromJSON(value, simplifyVector = FALSE) else unclass(value),
    error = function(error) error
  )
  if (inherits(decoded, "error")) {
    return(list(valid = FALSE, findings = list(list(
      code = "invalid_json", message = conditionMessage(decoded)
    ))))
  }
  if (!is.list(decoded)) {
    return(list(valid = FALSE, findings = list(list(
      code = "invalid_document",
      message = "Workflow document schema 1.0.0 requires an object."
    ))))
  }
  findings <- list()
  allowed_top_level <- c("schema_version", "graph", "output_placements")
  unknown_top_level <- setdiff(names(decoded), allowed_top_level)
  if (length(unknown_top_level)) {
    findings <- append(findings, list(list(
      code = "unknown_document_field",
      message = paste("Unknown workflow document fields:", paste(unknown_top_level, collapse = ", "))
    )))
  }
  if (!identical(decoded$schema_version, "1.0.0")) {
    findings <- append(findings, list(list(
      code = "unsupported_schema_version",
      message = "Only workflow document schema 1.0.0 is readable."
    )))
  }
  if (!is.list(decoded$graph) || !is.list(decoded$graph$nodes) ||
      !is.list(decoded$graph$edges)) {
    findings <- append(findings, list(list(
      code = "invalid_graph", message = "Document graph must contain node and edge lists."
    )))
  } else {
    nodes <- decoded$graph$nodes
    edges <- decoded$graph$edges
    valid_nodes <- vapply(nodes, function(node) {
      is.list(node) && is.character(node$id) && length(node$id) == 1L &&
        nzchar(node$id) && is.character(node$capability_id) &&
        length(node$capability_id) == 1L && nzchar(node$capability_id)
    }, logical(1))
    if (any(!valid_nodes)) findings <- append(findings, list(list(
      code = "invalid_node", message = "Every node requires a nonempty id and capability_id."
    )))
    node_ids <- vapply(nodes[valid_nodes], `[[`, character(1), "id")
    if (anyDuplicated(node_ids)) findings <- append(findings, list(list(
      code = "duplicate_node", message = "Workflow node ids must be unique."
    )))
    valid_edges <- vapply(edges, function(edge) {
      is.list(edge) && all(c(
        "id", "source", "source_port", "target", "target_port"
      ) %in% names(edge)) && all(vapply(edge[c(
        "id", "source", "source_port", "target", "target_port"
      )], function(item) is.character(item) && length(item) == 1L &&
        nzchar(item), logical(1)))
    }, logical(1))
    if (any(!valid_edges)) findings <- append(findings, list(list(
      code = "invalid_edge", message = "Every edge requires the schema 1.0.0 identity and port fields."
    )))
    edge_ids <- vapply(edges[valid_edges], `[[`, character(1), "id")
    if (anyDuplicated(edge_ids)) findings <- append(findings, list(list(
      code = "duplicate_edge", message = "Workflow edge ids must be unique."
    )))
    endpoints <- edges[valid_edges]
    if (length(endpoints) && any(vapply(endpoints, function(edge) {
      !edge$source %in% node_ids || !edge$target %in% node_ids
    }, logical(1)))) findings <- append(findings, list(list(
      code = "unknown_edge_endpoint",
      message = "Every edge endpoint must identify a node in the document."
    )))
  }
  placements <- decoded$output_placements %||% list()
  if (!is.list(placements)) {
    findings <- append(findings, list(list(
      code = "invalid_output_placements", message = "Output placements must be a list."
    )))
  } else if (length(placements)) {
    required <- c("placement_id", "artifact_id", "region", "position")
    invalid <- vapply(placements, function(item) {
      !is.list(item) || !all(required %in% names(item))
    }, logical(1))
    if (any(invalid)) findings <- append(findings, list(list(
      code = "invalid_output_placement", message = "Every output placement must use the 1.0.0 shape."
    )))
    ids <- vapply(placements[!invalid], function(item) as.character(item$placement_id), character(1))
    if (anyDuplicated(ids)) findings <- append(findings, list(list(
      code = "duplicate_output_placement", message = "Output placement ids must be unique."
    )))
  }
  list(valid = !length(findings), findings = findings)
}
