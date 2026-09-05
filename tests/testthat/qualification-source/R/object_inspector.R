object_inspector_forbidden_keys <- function() {
  c("password", "passwd", "secret", "token", "credential", "api_key",
    "apikey", "private_key", "raw_prompt", "raw_response", "chain_of_thought",
    "hidden_reasoning", "scratchpad")
}

object_inspector_pointer_escape <- function(x) {
  gsub("/", "~1", gsub("~", "~0", as.character(x), fixed = TRUE), fixed = TRUE)
}

object_inspector_path <- function(parent, key) {
  paste0(parent, "/", object_inspector_pointer_escape(key))
}

object_inspector_type_at <- function(path, types) {
  value <- types[[path]]
  if (is.null(value)) NULL else tolower(as.character(value)[[1L]])
}

object_inspector_is_redacted <- function(key, path, redact_paths) {
  key_match <- nzchar(key) && any(vapply(object_inspector_forbidden_keys(), function(pattern) {
    grepl(pattern, tolower(key), fixed = TRUE)
  }, logical(1)))
  key_match || path %in% redact_paths
}

object_inspector_scalar <- function(value, type = NULL) {
  if (identical(type, "redacted")) {
    return(list(nodeType = "scalar", valueType = "redacted", value = NULL))
  }
  if (is.null(value)) return(list(nodeType = "scalar", valueType = "null", value = NULL))
  if (identical(type, "missing") || (length(value) == 1L && is.na(value))) {
    return(list(nodeType = "scalar", valueType = "missing", value = NULL))
  }
  if (identical(type, "opaque")) {
    return(list(nodeType = "scalar", valueType = "opaque",
      value = substr(as.character(value)[[1L]], 1L, 240L)))
  }
  if (inherits(value, "POSIXt") || identical(type, "datetime")) {
    return(list(nodeType = "scalar", valueType = "datetime",
      value = format(as.POSIXct(value), "%Y-%m-%dT%H:%M:%OS%z")))
  }
  if (inherits(value, "Date") || identical(type, "date")) {
    return(list(nodeType = "scalar", valueType = "date", value = as.character(value)[[1L]]))
  }
  if (is.logical(value)) return(list(nodeType = "scalar", valueType = "boolean", value = isTRUE(value[[1L]])))
  if (is.integer(value)) return(list(nodeType = "scalar", valueType = "integer", value = value[[1L]]))
  if (is.numeric(value)) return(list(nodeType = "scalar", valueType = "number", value = value[[1L]]))
  if (is.raw(value)) return(list(nodeType = "scalar", valueType = "opaque",
    value = paste0("<", length(value), " bytes>")))
  list(nodeType = "scalar", valueType = type %||% "string",
    value = substr(as.character(value)[[1L]], 1L, 4000L))
}

normalize_object_inspector_object <- function(object, types = list(), redact_paths = character(),
    max_nodes = 50000L, max_depth = 64L) {
  if (!is.list(types) || (length(types) && is.null(names(types)))) {
    stop("types must be a named list keyed by JSON pointer.", call. = FALSE)
  }
  redact_paths <- unique(as.character(redact_paths))
  count <- 0L
  truncated <- 0L
  walk <- function(value, path = "", key = "", depth = 0L) {
    count <<- count + 1L
    if (count > max_nodes || depth > max_depth) {
      truncated <<- truncated + 1L
      return(list(nodeType = "scalar", valueType = "opaque", value = "[truncated]"))
    }
    type <- object_inspector_type_at(path, types)
    if (object_inspector_is_redacted(key, path, redact_paths)) return(object_inspector_scalar(NULL, "redacted"))
    if (!is.null(type) && type %in% c("missing", "date", "datetime", "opaque", "redacted")) {
      return(object_inspector_scalar(value, type))
    }
    if (is.data.frame(value)) value <- as.list(value)
    if (is.list(value)) {
      named <- !is.null(names(value)) && all(nzchar(names(value)))
      children <- lapply(seq_along(value), function(i) {
        child_key <- if (named) names(value)[[i]] else as.character(i - 1L)
        list(key = child_key, node = walk(value[[i]], object_inspector_path(path, child_key),
          child_key, depth + 1L))
      })
      return(list(nodeType = if (named) "object" else "array", children = children))
    }
    if (length(value) > 1L) {
      children <- lapply(seq_along(value), function(i) list(key = as.character(i - 1L),
        node = walk(value[[i]], object_inspector_path(path, i - 1L), as.character(i - 1L), depth + 1L)))
      return(list(nodeType = "array", children = children))
    }
    object_inspector_scalar(value, type)
  }
  root <- walk(object)
  list(root = root, nodeCount = count - truncated, truncated = truncated)
}

#' Structured Object Inspector
#'
#' A persistent, searchable, virtualized projection over host-supplied nested
#' objects. The inspector never mutates host state and recursively replaces
#' sensitive values before serialization.
#'
#' @param object Nested R list, vector, data frame, or JSON-like value.
#' @param types Optional named list mapping JSON-pointer paths to `date`,
#'   `datetime`, `missing`, `opaque`, or another scalar display type.
#' @param redact_paths JSON-pointer paths whose values must be replaced before
#'   browser serialization. Common credential-like keys are always redacted.
#' @param selected_path Initially selected JSON-pointer path.
#' @param expanded_paths Initially expanded JSON-pointer paths. The root is `""`.
#' @param search Initial search query.
#' @param state One of `ready`, `loading`, `empty`, or `error`.
#' @param message Optional loading, empty, or error message.
#' @param max_nodes,max_depth Serialization safety limits.
#' @param title Visible inspector title.
#' @param revision Monotonic host revision.
#' @param element_id Optional static element id.
#' @return A `shinycapabilities_direct_component`.
#' @export
object_inspector <- function(object = NULL, types = list(), redact_paths = character(),
    selected_path = NULL, expanded_paths = "", search = "", state = NULL,
    message = NULL, max_nodes = 50000L, max_depth = 64L,
    title = "Object inspector", revision = 1L, element_id = NULL) {
  if (!is.list(types) || (length(types) && is.null(names(types)))) {
    stop("types must be a named list keyed by JSON pointer.", call. = FALSE)
  }
  max_nodes <- max(1L, as.integer(max_nodes)); max_depth <- max(1L, as.integer(max_depth))
  state <- state %||% if (is.null(object)) "empty" else "ready"
  state <- match.arg(state, c("ready", "loading", "empty", "error"))
  normalized <- if (state == "ready") normalize_object_inspector_object(object, types,
    redact_paths, max_nodes, max_depth) else list(root = NULL, nodeCount = 0L, truncated = 0L)
  value <- new_direct_component("object_inspector", list(
    root = normalized$root, nodeCount = normalized$nodeCount,
    truncated = normalized$truncated, selectedPath = selected_path,
    expandedPaths = unique(as.character(expanded_paths)), search = as.character(search)[[1L]],
    state = state, message = as.character(message %||% ""), title = as.character(title)[[1L]],
    options = list(maxNodes = max_nodes, maxDepth = max_depth)
  ), element_id)
  value$revision <- as.integer(revision)
  value
}

#' @rdname object_inspector
#' @param output_id Shiny output id.
#' @param width,height CSS dimensions.
#' @export
object_inspector_output <- function(output_id, width = "100%", height = "560px") {
  direct_component_output(output_id, "object_inspector", width, height)
}

#' @rdname object_inspector
#' @param expr Expression returning [object_inspector()].
#' @param env Evaluation environment.
#' @param quoted Whether `expr` is quoted.
#' @export
render_object_inspector <- function(expr, env = parent.frame(), quoted = FALSE) {
  if (!quoted) expr <- substitute(expr)
  render_direct_component(expr, object_inspector_output, env, quoted = TRUE)
}

#' @rdname object_inspector
#' @param session Active Shiny session.
#' @param patches Optional list of `set` or `remove` operations with JSON-pointer
#'   `path` and normalized `value`. Full object replacement is preferred unless
#'   the host already owns keyed patches.
#' @param focus_path Path to select and reveal without remounting.
#' @export
update_object_inspector <- function(session = shiny::getDefaultReactiveDomain(), output_id,
    object = NULL, types = list(), redact_paths = character(), patches = NULL,
    focus_path = NULL, state = NULL, message = NULL, max_nodes = 50000L,
    max_depth = 64L, revision = as.integer(Sys.time())) {
  if (!is.list(types) || (length(types) && is.null(names(types)))) {
    stop("types must be a named list keyed by JSON pointer.", call. = FALSE)
  }
  payload <- list()
  if (!is.null(object)) {
    normalized <- normalize_object_inspector_object(object, types, redact_paths,
      max(1L, as.integer(max_nodes)), max(1L, as.integer(max_depth)))
    payload <- c(payload, list(root = normalized$root, nodeCount = normalized$nodeCount,
      truncated = normalized$truncated, state = "ready"))
  }
  if (!is.null(patches)) {
    if (!is.list(patches) || (length(patches) && !is.list(patches[[1L]]))) {
      stop("patches must be a list of patch records.", call. = FALSE)
    }
    payload$patches <- lapply(patches, function(patch) {
      operation <- match.arg(as.character(patch$operation %||% "set"), c("set", "remove"))
      path <- as.character(patch$path %||% "")[[1L]]
      list(operation = operation, path = path,
        value = if (operation == "remove") NULL else normalize_object_inspector_object(
          patch$value, types, redact_paths, max_nodes, max_depth)$root)
    })
  }
  if (!is.null(focus_path)) payload$focusPath <- as.character(focus_path)[[1L]]
  if (!is.null(state)) payload$state <- match.arg(state, c("ready", "loading", "empty", "error"))
  if (!is.null(message)) payload$message <- as.character(message)[[1L]]
  update_direct_component(session, output_id, "object_inspector", payload, revision)
}

#' Run the Structured Object Inspector 1.0 demo
#' @param ... Arguments passed to [shiny::runApp()].
#' @export
run_object_inspector_demo <- function(...) {
  shiny::runApp(system.file("examples", "object-inspector", package = "shinycapabilities"), ...)
}
