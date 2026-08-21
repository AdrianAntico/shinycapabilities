relationship_graph_forbidden_keys <- function() {
  c("thinking", "scratchpad", "hidden_reasoning", "chain_of_thought", "cot",
    "tool_trace", "hidden_trace", "raw_prompt", "raw_response", "credentials", "secret")
}

relationship_graph_records <- function(x, name) {
  if (is.null(x)) return(list())
  if (is.data.frame(x)) return(lapply(seq_len(nrow(x)), function(i) lapply(x, function(column) column[[i]])))
  if (!is.list(x) || (length(x) && !is.list(x[[1L]]))) {
    stop(name, " must be a data frame or list of records.", call. = FALSE)
  }
  unname(x)
}

relationship_graph_scalar <- function(x, field, required = FALSE, default = "") {
  value <- as.character(x %||% default)
  if (!length(value) || (!required && is.na(value))) value <- as.character(default)
  if (length(value) != 1L || is.na(value)) stop(field, " must be a non-missing scalar.", call. = FALSE)
  value <- trimws(value)
  if (required && !nzchar(value)) stop(field, " must be non-empty.", call. = FALSE)
  value
}

relationship_graph_metadata <- function(x, max_fields = 20L, depth = 0L) {
  if (is.null(x)) return(list())
  if (!is.list(x)) return(substr(as.character(x)[[1L]], 1L, 1000L))
  if (depth >= 3L) return("[nested metadata omitted]")
  keys <- names(x)
  if (is.null(keys)) return(lapply(utils::head(x, max_fields), relationship_graph_metadata,
    max_fields = max_fields, depth = depth + 1L))
  forbidden <- paste(relationship_graph_forbidden_keys(), collapse = "|")
  x <- x[!grepl(forbidden, tolower(keys))]
  x <- utils::head(x, max_fields)
  lapply(x, relationship_graph_metadata, max_fields = max_fields, depth = depth + 1L)
}

normalize_relationship_graph_nodes <- function(nodes, max_metadata_fields = 20L) {
  result <- lapply(relationship_graph_records(nodes, "nodes"), function(x) list(
    id = relationship_graph_scalar(x$id, "node id", TRUE),
    label = relationship_graph_scalar(x$label, "node label", TRUE),
    type = relationship_graph_scalar(x$type, "node type", TRUE),
    status = relationship_graph_scalar(x$status, "node status"),
    group = relationship_graph_scalar(x$group, "node group"),
    metadata = relationship_graph_metadata(x$metadata %||% list(), max_metadata_fields)
  ))
  ids <- vapply(result, `[[`, character(1), "id")
  if (anyDuplicated(ids)) stop("Node id values must be unique.", call. = FALSE)
  result
}

normalize_relationship_graph_edges <- function(edges, node_ids, max_metadata_fields = 20L) {
  result <- lapply(relationship_graph_records(edges, "edges"), function(x) list(
    id = relationship_graph_scalar(x$id, "edge id", TRUE),
    source = relationship_graph_scalar(x$source, "edge source", TRUE),
    target = relationship_graph_scalar(x$target, "edge target", TRUE),
    type = relationship_graph_scalar(x$type, "edge type", TRUE),
    label = relationship_graph_scalar(x$label, "edge label"),
    status = relationship_graph_scalar(x$status, "edge status"),
    metadata = relationship_graph_metadata(x$metadata %||% list(), max_metadata_fields)
  ))
  ids <- vapply(result, `[[`, character(1), "id")
  if (anyDuplicated(ids)) stop("Edge id values must be unique.", call. = FALSE)
  if (length(result)) {
    endpoints <- unique(c(vapply(result, `[[`, character(1), "source"),
      vapply(result, `[[`, character(1), "target")))
    missing <- setdiff(endpoints, node_ids)
    if (length(missing)) stop("Edges reference missing node endpoints: ", paste(missing, collapse = ", "), call. = FALSE)
  }
  result
}

relationship_graph_diagnostics <- function(nodes, edges) {
  ids <- vapply(nodes, `[[`, character(1), "id")
  adjacency <- stats::setNames(vector("list", length(ids)), ids)
  undirected <- stats::setNames(vector("list", length(ids)), ids)
  for (edge in edges) {
    adjacency[[edge$source]] <- c(adjacency[[edge$source]], edge$target)
    undirected[[edge$source]] <- unique(c(undirected[[edge$source]], edge$target))
    undirected[[edge$target]] <- unique(c(undirected[[edge$target]], edge$source))
  }
  color <- stats::setNames(integer(length(ids)), ids)
  has_cycle <- FALSE
  visit <- function(id) {
    if (color[[id]] == 1L) { has_cycle <<- TRUE; return() }
    if (color[[id]] == 2L) return()
    color[[id]] <<- 1L
    for (next_id in adjacency[[id]]) visit(next_id)
    color[[id]] <<- 2L
  }
  for (id in ids) if (color[[id]] == 0L) visit(id)
  seen <- character(); components <- 0L
  for (id in ids) if (!id %in% seen) {
    components <- components + 1L; queue <- id
    while (length(queue)) {
      current <- queue[[1L]]; queue <- queue[-1L]
      if (current %in% seen) next
      seen <- c(seen, current); queue <- c(queue, setdiff(undirected[[current]], seen))
    }
  }
  list(hasCycle = has_cycle, componentCount = components,
    disconnected = length(ids) > 0L && components > 1L,
    nodeCount = length(nodes), edgeCount = length(edges))
}

relationship_graph_model <- function(nodes, edges, selected_id = NULL, focus_id = NULL,
    filters = list(), direction = "LR", max_render_nodes = 500L,
    max_metadata_fields = 20L, show_minimap = TRUE, state = "ready", message = NULL) {
  nodes <- normalize_relationship_graph_nodes(nodes, max_metadata_fields)
  edges <- normalize_relationship_graph_edges(edges,
    vapply(nodes, `[[`, character(1), "id"), max_metadata_fields)
  direction <- match.arg(direction, c("LR", "RL", "TB", "BT"))
  state <- match.arg(state, c("ready", "loading", "error"))
  if (!is.list(filters)) stop("filters must be a named list.", call. = FALSE)
  list(nodes = nodes, edges = edges,
    selectedId = if (is.null(selected_id)) NULL else as.character(selected_id)[[1L]],
    focusId = if (is.null(focus_id)) NULL else as.character(focus_id)[[1L]],
    filters = filters, diagnostics = relationship_graph_diagnostics(nodes, edges),
    options = list(direction = direction, maxRenderNodes = max(10L, as.integer(max_render_nodes)),
      showMinimap = isTRUE(show_minimap), maxMetadataFields = max(1L, as.integer(max_metadata_fields)),
      state = state, message = if (is.null(message)) NULL else as.character(message)[[1L]]))
}

#' Host-neutral relationship graph
#'
#' Render validated host-supplied analytical relationships without owning graph
#' semantics or mutating graph truth. Events are limited to selection,
#' navigation, filter, and neighborhood intents.
#'
#' @param nodes Node records with `id`, `label`, and `type`.
#' @param edges Edge records with `id`, `source`, `target`, and `type`.
#' @param selected_id Initially selected node or edge identity.
#' @param focus_id Optional node around which to focus the initial neighborhood.
#' @param filters Initial node/edge type and status filters.
#' @param direction Dagre layout direction: `LR`, `RL`, `TB`, or `BT`.
#' @param max_render_nodes Maximum nodes rendered before progressive disclosure.
#' @param max_metadata_fields Maximum metadata fields retained per record.
#' @param show_minimap Whether to show a minimap for non-trivial graphs.
#' @param state Host-supplied projection state: `ready`, `loading`, or `error`.
#' @param message Optional bounded loading or error message.
#' @param width,height Widget dimensions.
#' @param element_id Optional HTML element ID.
#' @export
relationship_graph <- function(nodes, edges, selected_id = NULL, focus_id = NULL,
    filters = list(), direction = "LR", max_render_nodes = 500L,
    max_metadata_fields = 20L, show_minimap = TRUE, state = "ready", message = NULL, width = NULL,
    height = "680px", element_id = NULL) {
  new_direct_component("relationship_graph",
    relationship_graph_model(nodes, edges, selected_id, focus_id, filters,
      direction, max_render_nodes, max_metadata_fields, show_minimap, state, message),
    element_id, width, height)
}

#' @rdname relationship_graph
#' @param output_id Shiny output identifier.
#' @export
relationship_graph_output <- function(output_id, width = "100%", height = "680px") {
  direct_component_output(output_id, "relationship_graph", width, height)
}

#' @rdname relationship_graph
#' @param expr Expression returning a relationship graph widget.
#' @param env Evaluation environment.
#' @param quoted Whether `expr` is quoted.
#' @export
render_relationship_graph <- function(expr, env = parent.frame(), quoted = FALSE) {
  if (!quoted) expr <- substitute(expr)
  render_direct_component(expr, relationship_graph_output, env, quoted = TRUE)
}

#' Update a relationship graph
#'
#' Replaces only supplied projections. The browser preserves viewport and
#' selection unless explicit selection, focus, layout, or fit requests are sent.
#'
#' @param session Active Shiny session.
#' @param output_id Graph output identifier.
#' @inheritParams relationship_graph
#' @param fit_request Incrementing value or token requesting fit-to-view.
#' @param revision Optional monotonic transport revision.
#' @export
update_relationship_graph <- function(session, output_id, nodes = NULL, edges = NULL,
    selected_id = NULL, focus_id = NULL, filters = NULL, direction = NULL,
    fit_request = NULL, max_render_nodes = 500L, max_metadata_fields = 20L,
    state = NULL, message = NULL, revision = as.integer(Sys.time())) {
  payload <- list()
  normalized_nodes <- if (is.null(nodes)) NULL else normalize_relationship_graph_nodes(nodes, max_metadata_fields)
  if (!is.null(normalized_nodes)) payload$nodes <- normalized_nodes
  if (!is.null(edges)) {
    if (is.null(normalized_nodes)) stop("nodes must accompany edges in an update for endpoint validation.", call. = FALSE)
    payload$edges <- normalize_relationship_graph_edges(edges,
      vapply(normalized_nodes, `[[`, character(1), "id"), max_metadata_fields)
    payload$diagnostics <- relationship_graph_diagnostics(normalized_nodes, payload$edges)
  }
  if (!is.null(selected_id)) payload$selectedId <- as.character(selected_id)[[1L]]
  if (!is.null(focus_id)) payload$focusId <- as.character(focus_id)[[1L]]
  if (!is.null(filters)) {
    if (!is.list(filters)) stop("filters must be a named list.", call. = FALSE)
    payload$filters <- filters
  }
  if (!is.null(direction)) payload$direction <- match.arg(direction, c("LR", "RL", "TB", "BT"))
  if (!is.null(fit_request)) payload$fitRequest <- as.character(fit_request)[[1L]]
  if (!is.null(state)) payload$state <- match.arg(state, c("ready", "loading", "error"))
  if (!is.null(message)) payload$message <- as.character(message)[[1L]]
  payload$maxRenderNodes <- max(10L, as.integer(max_render_nodes))
  update_direct_component(session, output_id, "relationship_graph", payload, revision)
  invisible(NULL)
}

#' Run the Relationship Graph demo
#' @param ... Arguments passed to [shiny::runApp()].
#' @export
run_relationship_graph_demo <- function(...) {
  shiny::runApp(system.file("examples", "relationship-graph", package = "shinycapabilities"), ...)
}
