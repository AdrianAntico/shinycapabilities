#' Experimental direct browser component
#'
#' Construct a host-neutral component payload for the package-owned direct
#' Shiny transport. This is the package's canonical browser transport.
#'
#' @param component Registered browser component name.
#' @param payload Named list sent to the browser.
#' @param element_id Optional stable id used for static rendering. Shiny output
#'   ids are supplied by [direct_component_output()].
#' @return An object of class `shinycapabilities_direct_component`.
#' @keywords internal
new_direct_component <- function(component, payload, element_id = NULL,
                                 width = NULL, height = NULL) {
  component <- as.character(component)
  if (length(component) != 1L || !nzchar(component)) {
    stop("component must be one non-empty string.", call. = FALSE)
  }
  if (!is.list(payload)) stop("payload must be a named list.", call. = FALSE)
  if (!is.null(element_id)) {
    element_id <- as.character(element_id)
    if (length(element_id) != 1L || !nzchar(element_id)) {
      stop("element_id must be NULL or one non-empty string.", call. = FALSE)
    }
  }
  normalized <- json_object_payload(payload)
  structure(list(
    component = component,
    payload = normalized,
    x = normalized,
    element_id = element_id,
    width = width,
    height = height,
    revision = 1L
  ), class = c(component, "shinycapabilities_direct_component"))
}

browser_runtime_dependency <- function() {
  root <- system.file("www", "direct-transport", package = "shinycapabilities")
  if (!nzchar(root)) root <- file.path("inst", "www", "direct-transport")
  htmltools::htmlDependency(
    name = "shinycapabilities-browser-runtime",
    version = "1.1.0",
    src = c(file = normalizePath(root, winslash = "/", mustWork = TRUE)),
    script = "browser-runtime-v1.js"
  )
}

direct_transport_core_dependency <- function() {
  root <- system.file("www", "direct-transport", package = "shinycapabilities")
  if (!nzchar(root)) root <- file.path("inst", "www", "direct-transport")
  htmltools::htmlDependency(
    name = "shinycapabilities-direct-transport",
    version = "1.1.0",
    src = c(file = normalizePath(root, winslash = "/", mustWork = TRUE)),
    script = "direct-transport.js"
  )
}

direct_component_dependency <- function(component) {
  root <- system.file("www", "direct-transport", package = "shinycapabilities")
  if (!nzchar(root)) root <- file.path("inst", "www", "direct-transport")
  script <- switch(component,
    command_palette_direct = "command-palette-direct.js",
    persistent_ui = "persistent-ui.js",
    split_pane_direct = "split-pane-direct.js",
    code_editor = "code-editor.js",
    object_inspector = "object-inspector.js",
    capability_canvas = "shinycapabilities.js",
    virtual_tree_browser = "interaction-components.js",
    data_grid = "data-grid.js",
    agent_activity_monitor = "agent-activity-monitor.js",
    relationship_graph = "relationship-graph.js",
    execution_replay = "execution-replay.js",
    stop("Unknown direct component: ", component, call. = FALSE))
  htmltools::htmlDependency(
    name = paste0("shinycapabilities-direct-", gsub("_", "-", component)),
    version = "1.0.0",
    src = c(file = normalizePath(root, winslash = "/", mustWork = TRUE)),
    script = if (identical(component, "code_editor")) {
      list(src = script, type = "module")
    } else script,
    stylesheet = switch(component,
      command_palette_direct = "command-palette-direct.css",
      persistent_ui = "persistent-ui.css",
      split_pane_direct = "split-pane-direct.css",
      code_editor = "code-editor.css",
      object_inspector = "object-inspector.css",
      capability_canvas = "shinycapabilities.css",
      virtual_tree_browser = "interaction-components.css",
      data_grid = "data-grid.css",
      agent_activity_monitor = "agent-activity-monitor.css",
      relationship_graph = "relationship-graph.css",
      execution_replay = "execution-replay.css",
      NULL)
  )
}

direct_transport_dependencies <- function(component) {
  uses_runtime <- component %in% c("command_palette_direct", "split_pane_direct",
    "object_inspector", "virtual_tree_browser", "agent_activity_monitor",
    "execution_replay")
  c(if (uses_runtime) list(browser_runtime_dependency()) else list(),
    list(direct_transport_core_dependency(), direct_component_dependency(component)))
}

# Kept as one internal lookup for tests and transitional callers.
direct_transport_dependency <- function(component = NULL) {
  if (is.null(component)) return(direct_transport_core_dependency())
  direct_transport_dependencies(component)
}

direct_component_tag <- function(id, component, height = "420px", width = "100%",
                                 static_payload = NULL) {
  tag <- htmltools::tags$div(
    id = id,
    class = "sc-direct-component-output",
    `data-sc-direct-component` = component,
    style = paste0("width:", width, ";height:", height, ";"),
    role = "region",
    `aria-busy` = "true"
  )
  if (!is.null(static_payload)) {
    tag <- htmltools::tagAppendChild(tag, htmltools::tags$script(
      type = "application/json",
      `data-sc-direct-payload` = id,
      htmltools::HTML(jsonlite::toJSON(static_payload, auto_unbox = TRUE,
        null = "null", digits = NA, force = TRUE))
    ))
  }
  htmltools::attachDependencies(tag, direct_transport_dependencies(component), append = TRUE)
}

#' @exportS3Method htmltools::as.tags
as.tags.shinycapabilities_direct_component <- function(x, ...) {
  id <- x$element_id %||% paste0("sc-direct-", substr(stable_hash(list(
    x$component, x$payload
  )), 1L, 12L))
  direct_component_tag(id, x$component, height = x$height %||% "420px",
    width = x$width %||% "100%", static_payload = list(
    component = x$component, payload = x$payload, revision = x$revision
  ))
}

#' Direct component Shiny output
#'
#' @param output_id Shiny output id.
#' @param component Registered direct component name.
#' @param width,height CSS dimensions.
#' @export
direct_component_output <- function(output_id, component, width = "100%", height = "420px") {
  direct_component_tag(output_id, component, height = height, width = width)
}

#' Render a direct component
#'
#' @param expr Expression returning a `shinycapabilities_direct_component`.
#' @param output_func Output constructor.
#' @param env Evaluation environment.
#' @param quoted Whether `expr` is quoted.
#' @export
render_direct_component <- function(expr, output_func, env = parent.frame(), quoted = FALSE) {
  if (!quoted) expr <- substitute(expr)
  func <- shiny::exprToFunction(expr, env, quoted = TRUE)
  shiny::createRenderFunction(
    func,
    transform = function(value, session, name, ...) {
      if (!inherits(value, "shinycapabilities_direct_component")) {
        stop("Direct render expressions must return a direct component.", call. = FALSE)
      }
      list(component = value$component, payload = value$payload,
        revision = value$revision)
    },
    outputFunc = output_func
  )
}

#' Send a bounded direct-component update
#'
#' @param session Active Shiny session.
#' @param output_id Output id, without a module namespace.
#' @param component Registered component name.
#' @param payload Named update payload.
#' @param revision Optional monotonic revision.
#' @export
update_direct_component <- function(session = shiny::getDefaultReactiveDomain(),
                                    output_id, component, payload,
                                    revision = as.integer(Sys.time())) {
  if (is.null(session)) stop("A Shiny session is required.", call. = FALSE)
  if (!is.list(payload)) stop("payload must be a named list.", call. = FALSE)
  session$sendCustomMessage("shinycapabilities.direct.update", list(
    id = session$ns(output_id), component = as.character(component),
    payload = json_object_payload(payload), revision = as.integer(revision)
  ))
  invisible(NULL)
}
