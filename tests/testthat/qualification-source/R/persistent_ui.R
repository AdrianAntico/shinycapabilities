persistent_ui_types <- function() c("section", "row", "text", "value", "badge", "field", "action")

normalize_persistent_ui_nodes <- function(nodes) {
  records <- normalize_component_records(nodes, "nodes")
  flattened <- list()
  visit <- function(record, parent = NULL) {
    if (!is.list(record)) stop("Each persistent UI node must be a named list.", call. = FALSE)
    id <- as.character(record$id %||% "")
    type <- match.arg(as.character(record$type %||% "text"), persistent_ui_types())
    if (length(id) != 1L || !nzchar(id)) stop("Every persistent UI node requires a non-empty id.", call. = FALSE)
    children <- record$children %||% list()
    flattened[[length(flattened) + 1L]] <<- list(
      id = id, type = type,
      parentId = as.character(record$parent_id %||% record$parentId %||% parent %||% ""),
      label = as.character(record$label %||% ""),
      value = record$value %||% NULL,
      description = as.character(record$description %||% ""),
      status = as.character(record$status %||% "neutral"),
      visible = !identical(record$visible, FALSE),
      enabled = !identical(record$enabled, FALSE),
      expanded = !identical(record$expanded, FALSE),
      selected = isTRUE(record$selected),
      order = as.numeric(record$order %||% length(flattened)),
      inputType = match.arg(as.character(record$input_type %||% record$inputType %||% "text"), c("text", "number", "checkbox")),
      metadata = record$metadata %||% list()
    )
    if (length(children)) lapply(children, visit, parent = id)
    invisible(NULL)
  }
  lapply(records, visit)
  ids <- vapply(flattened, `[[`, character(1), "id")
  if (anyDuplicated(ids)) stop("Persistent UI node ids must be unique.", call. = FALSE)
  parents <- vapply(flattened, `[[`, character(1), "parentId")
  unknown <- setdiff(parents[nzchar(parents)], ids)
  if (length(unknown)) stop("Unknown persistent UI parent id: ", unknown[[1]], call. = FALSE)
  types <- stats::setNames(vapply(flattened, `[[`, character(1), "type"), ids)
  invalid_parent <- nzchar(parents) & !types[parents] %in% c("section", "row")
  if (any(invalid_parent)) stop("Only section and row nodes may contain children.", call. = FALSE)
  parent_map <- stats::setNames(parents, ids)
  for (id in ids) {
    seen <- character(); current <- id
    while (nzchar(current)) {
      if (current %in% seen) stop("Persistent UI parent relationships must not contain a cycle.", call. = FALSE)
      seen <- c(seen, current); current <- parent_map[[current]] %||% ""
    }
  }
  unname(flattened)
}

#' Experimental persistent dynamic UI
#'
#' Render a bounded, keyed UI schema once and patch subsequent state in the
#' browser. This is not an arbitrary HTML renderer and does not own business
#' state.
#'
#' @param nodes A data frame or list of records. Each record requires stable
#'   `id` and a `type`: `section`, `row`, `text`, `value`, `badge`, `field`, or
#'   `action`. Nested `children` or `parent_id` express bounded structure.
#' @param revision Monotonic host revision.
#' @param aria_label Accessible region label.
#' @param element_id Optional id for static rendering.
#' @export
persistent_ui <- function(nodes, revision = 1L,
                          aria_label = "Dynamic analytical interface",
                          element_id = NULL) {
  value <- new_direct_component("persistent_ui", list(
    nodes = normalize_persistent_ui_nodes(nodes),
    options = list(ariaLabel = as.character(aria_label))
  ), element_id = element_id)
  value$revision <- as.integer(revision)
  value
}

#' @rdname persistent_ui
#' @param output_id Shiny output identifier.
#' @param width,height CSS dimensions.
#' @export
persistent_ui_output <- function(output_id, width = "100%", height = "520px") {
  direct_component_output(output_id, "persistent_ui", width, height)
}

#' @rdname persistent_ui
#' @param expr Expression returning [persistent_ui()].
#' @param env Evaluation environment.
#' @param quoted Whether `expr` is quoted.
#' @export
render_persistent_ui <- function(expr, env = parent.frame(), quoted = FALSE) {
  if (!quoted) expr <- substitute(expr)
  render_direct_component(expr, persistent_ui_output, env, quoted = TRUE)
}

#' @rdname persistent_ui
#' @param session Active Shiny session.
#' @param previous_nodes Optional prior schema. When supplied, only changed,
#'   added, removed, or reordered records are transmitted.
#' @export
update_persistent_ui <- function(session = shiny::getDefaultReactiveDomain(),
                                 output_id, nodes, revision,
                                 aria_label = NULL, previous_nodes = NULL) {
  normalized <- normalize_persistent_ui_nodes(nodes)
  if (is.null(previous_nodes)) {
    payload <- list(nodes = normalized)
  } else {
    previous <- normalize_persistent_ui_nodes(previous_nodes)
    old <- stats::setNames(previous, vapply(previous, `[[`, character(1), "id"))
    current <- stats::setNames(normalized, vapply(normalized, `[[`, character(1), "id"))
    changed <- names(current)[vapply(names(current), function(id) {
      is.null(old[[id]]) || !identical(old[[id]], current[[id]])
    }, logical(1))]
    payload <- list(patch = list(
      upsert = unname(current[changed]),
      remove = unname(setdiff(names(old), names(current)))
    ))
  }
  if (!is.null(aria_label)) payload$options <- list(ariaLabel = as.character(aria_label))
  update_direct_component(session, output_id, "persistent_ui", payload, revision)
  invisible(normalized)
}

#' Run the Persistent Dynamic UI comparison demo
#' @param ... Arguments passed to [shiny::runApp()].
#' @export
run_persistent_ui_demo <- function(...) {
  shiny::runApp(system.file("examples", "persistent-ui", package = "shinycapabilities"), ...)
}
