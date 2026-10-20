# Admission of browser graph edits. Incomplete authoring graphs are legitimate;
# missing required inputs prevent execution, not construction.
admit_graph_mutation <- function(registry, event, revision) {
  refusal <- function(code, message) list(accepted = FALSE, code = code, message = message)
  scalar_id <- function(x) is.character(x) && length(x) == 1L && !is.na(x) && nzchar(x)
  if (!scalar_id(event$mutationId))
    return(refusal("invalid_mutation_identity", "Graph edit has no valid request identity. Reload the canvas and try again."))
  base <- event$baseGraphRevision
  if (!is.numeric(base) || length(base) != 1L || !is.finite(base) || base != trunc(base))
    return(refusal("invalid_graph_revision", "Graph edit has no valid base revision. Reload the canvas and try again."))
  if (base != revision)
    return(refusal("stale_graph_revision", "The workflow changed before this edit was accepted. Review the current canvas and try again."))
  tryCatch({
    if (!is.list(event$graph) || !is.list(event$graph$nodes) || !is.list(event$graph$edges))
      stop("Graph nodes and connections must be lists.")
    candidate <- normalize_workflow_graph(event$graph)
    if (!all(vapply(candidate$edges, function(e) all(vapply(e, scalar_id, logical(1))), logical(1))) ||
        anyDuplicated(vapply(candidate$edges, `[[`, character(1), "id"))) stop("Connections require unique identities and scalar endpoints.")
    if (!all(vapply(candidate$nodes, function(n)
      scalar_id(n$id) && scalar_id(n$capability_id) && is.list(n$config) &&
        is.list(n$metadata) && length(n$state) == 1L && n$state %in% allowed_node_states &&
        all(vapply(c(n$position,n$size), function(v) is.numeric(v) && length(v)==1L && is.finite(v), logical(1))) &&
        n$size$width > 0 && n$size$height > 0, logical(1)))) stop("A graph node has invalid identity, configuration, state or geometry.")
    findings <- validate_workflow(registry, candidate)$findings
    invalid <- Filter(function(f) !identical(f$code, "required_input_missing"), findings)
    if (length(invalid)) return(refusal("invalid_graph_edit", paste("Graph edit refused:", invalid[[1]]$message %||% invalid[[1]]$code)))
    list(accepted = TRUE, code = "accepted", message = "Graph edit accepted.", graph = candidate)
  }, error = function(e) refusal("invalid_graph_edit", paste("Graph edit refused:", conditionMessage(e))))
}
