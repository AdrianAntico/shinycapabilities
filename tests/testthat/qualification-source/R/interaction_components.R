normalize_component_records <- function(x, kind) {
  if (is.data.frame(x)) {
    x <- lapply(seq_len(nrow(x)), function(index) {
      lapply(x, function(column) column[[index]])
    })
  }
  if (!is.list(x)) stop(kind, " must be a data frame or list of records.", call. = FALSE)
  unname(x)
}

normalize_tree_browser_nodes <- function(nodes) {
  records <- normalize_component_records(nodes, "nodes")
  flattened <- list()
  visit <- function(record, inherited_parent = NULL) {
    if (!is.list(record)) stop("Each tree node must be a named list.", call. = FALSE)
    id <- as.character(record$id %||% "")
    label <- as.character(record$label %||% "")
    if (length(id) != 1L || !nzchar(id)) stop("Every tree node requires a non-empty id.", call. = FALSE)
    if (length(label) != 1L || !nzchar(label)) stop("Every tree node requires a non-empty label.", call. = FALSE)
    children <- record$children %||% list()
    parent_id <- record$parent_id %||% inherited_parent
    flattened[[length(flattened) + 1L]] <<- list(
      id = id,
      parentId = if (is.null(parent_id) || !nzchar(as.character(parent_id))) NULL else as.character(parent_id),
      label = label,
      description = as.character(record$description %||% ""),
      badge = as.character(record$badge %||% ""),
      status = as.character(record$status %||% ""),
      disabled = isTRUE(record$disabled),
      metadata = record$metadata %||% list()
    )
    if (length(children)) {
      lapply(children, visit, inherited_parent = id)
    }
    invisible(NULL)
  }
  lapply(records, visit)
  ids <- vapply(flattened, `[[`, character(1), "id")
  if (anyDuplicated(ids)) stop("Tree node ids must be unique.", call. = FALSE)
  parents <- vapply(flattened, function(node) node$parentId %||% "", character(1))
  unknown <- setdiff(parents[nzchar(parents)], ids)
  if (length(unknown)) stop("Unknown tree parent id: ", unknown[[1]], call. = FALSE)
  if (any(ids == parents)) stop("A tree node cannot be its own parent.", call. = FALSE)
  parent_by_id <- stats::setNames(parents, ids)
  for (id in ids) {
    path <- character()
    current <- id
    while (nzchar(current)) {
      if (current %in% path) stop("Tree parent relationships must not contain a cycle.", call. = FALSE)
      path <- c(path, current)
      current <- parent_by_id[[current]] %||% ""
    }
  }
  flattened
}

normalize_command_palette_items <- function(items) {
  records <- normalize_component_records(items, "items")
  normalized <- lapply(records, function(record) {
    if (!is.list(record)) stop("Each command item must be a named list.", call. = FALSE)
    id <- as.character(record$id %||% "")
    label <- as.character(record$label %||% "")
    if (length(id) != 1L || !nzchar(id)) stop("Every command item requires a non-empty id.", call. = FALSE)
    if (length(label) != 1L || !nzchar(label)) stop("Every command item requires a non-empty label.", call. = FALSE)
    list(
      id = id,
      label = label,
      group = as.character(record$group %||% "Commands"),
      description = as.character(record$description %||% ""),
      keywords = unname(as.character(record$keywords %||% character())),
      shortcut = as.character(record$shortcut %||% ""),
      disabled = isTRUE(record$disabled),
      metadata = record$metadata %||% list()
    )
  })
  ids <- vapply(normalized, `[[`, character(1), "id")
  if (anyDuplicated(ids)) stop("Command item ids must be unique.", call. = FALSE)
  unname(normalized)
}

#' Virtualized hierarchical browser
#'
#' Render a searchable, keyboard-navigable tree without sending domain-specific
#' behavior to the browser. In Shiny, selection and activation events are
#' published as `<outputId>_selection` and `<outputId>_activate`; expansion
#' changes are published as `<outputId>_toggle`.
#'
#' @param nodes A data frame or list of node records. Records require `id` and
#'   `label`; optional fields are `parent_id`, `children`, `description`,
#'   `badge`, `status`, `disabled`, and `metadata`.
#' @param selected Initially selected node id.
#' @param expanded Initially expanded node ids.
#' @param searchable Show the local tree search field.
#' @param empty_message Message shown when no nodes match.
#' @param width,height Widget dimensions.
#' @param row_height Estimated row height used by the virtualizer.
#' @param element_id Optional HTML element id.
#' @export
virtual_tree_browser <- function(nodes, selected = NULL, expanded = character(),
                                 searchable = TRUE,
                                 empty_message = "No matching items.",
                                 width = NULL, height = "480px",
                                 row_height = 42L, element_id = NULL) {
  new_direct_component("virtual_tree_browser", list(
      nodes = normalize_tree_browser_nodes(nodes),
      selected = selected,
      expanded = unname(as.character(expanded)),
      options = list(
        searchable = isTRUE(searchable),
        emptyMessage = as.character(empty_message),
        rowHeight = max(28L, as.integer(row_height))
      )
    ), element_id = element_id, width = width, height = height)
}

#' @rdname virtual_tree_browser
#' @param output_id Shiny output identifier.
#' @export
virtual_tree_browser_output <- function(output_id, width = "100%", height = "480px") {
  direct_component_output(output_id, "virtual_tree_browser", width, height)
}

#' @rdname virtual_tree_browser
#' @param expr Expression returning a widget.
#' @param env Evaluation environment.
#' @param quoted Whether `expr` is quoted.
#' @export
render_virtual_tree_browser <- function(expr, env = parent.frame(), quoted = FALSE) {
  if (!quoted) expr <- substitute(expr)
  render_direct_component(expr, virtual_tree_browser_output, env, quoted = TRUE)
}

#' Virtualized command palette
#'
#' Render a dense, keyboard-first command finder. In Shiny, activation events
#' are published as `<outputId>_command`. When `server_search` is true, query
#' changes are also published as `<outputId>_query`.
#'
#' @param items A data frame or list of command records. Records require `id`
#'   and `label`; optional fields are `group`, `description`, `keywords`,
#'   `shortcut`, `disabled`, and `metadata`.
#' @param placeholder Search-field placeholder.
#' @param shortcut Enable the Ctrl/Cmd+K focus shortcut while this widget exists.
#' @param server_search Publish query changes to Shiny.
#' @param empty_message Message shown when no commands match.
#' @param width,height Widget dimensions.
#' @param row_height Estimated row height used by the virtualizer.
#' @param element_id Optional HTML element id.
#' @export
command_palette <- function(items, placeholder = "Search commands...",
                            shortcut = TRUE, server_search = FALSE,
                            empty_message = "No matching commands.",
                            width = NULL, height = "420px",
                            row_height = 54L, element_id = NULL) {
  value <- command_palette_direct(items, placeholder, shortcut, server_search,
    empty_message, width, height, row_height, element_id)
  class(value) <- unique(c("command_palette", class(value)))
  value
}

#' @rdname command_palette
#' @param output_id Shiny output identifier.
#' @export
command_palette_output <- function(output_id, width = "100%", height = "420px") {
  command_palette_direct_output(output_id, width, height)
}

#' @rdname command_palette
#' @param expr Expression returning a widget.
#' @param env Evaluation environment.
#' @param quoted Whether `expr` is quoted.
#' @export
render_command_palette <- function(expr, env = parent.frame(), quoted = FALSE) {
  if (!quoted) expr <- substitute(expr)
  render_direct_component(expr, command_palette_output, env, quoted = TRUE)
}

#' Run the interaction-components demo
#' @param ... Arguments passed to [shiny::runApp()].
#' @export
run_interaction_components_demo <- function(...) {
  shiny::runApp(system.file("examples/interaction-components",
    package = "shinycapabilities"), ...)
}
