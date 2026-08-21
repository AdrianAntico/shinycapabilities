parameter_workbench_dependency <- function() {
  list(browser_runtime_dependency(), htmltools::htmlDependency(
    "shinycapabilities-parameter-workbench", "1.0.0",
    src = c(file = "www/direct-transport"), package = "shinycapabilities",
    script = "parameter-workbench.js", stylesheet = "parameter-workbench.css"
  ))
}

parameter_workbench_types <- function() {
  c("text", "numeric", "integer", "boolean", "choice", "multi_choice",
    "slider", "range", "date", "datetime")
}

normalize_parameter_choices <- function(x, key) {
  if (is.null(x)) return(list())
  values <- if (is.list(x)) unlist(x, recursive = FALSE, use.names = TRUE) else x
  labels <- names(values)
  if (is.null(labels)) labels <- as.character(values)
  if (anyDuplicated(as.character(values))) stop("choices must be unique for field ", key, ".", call. = FALSE)
  unname(Map(function(value, label) list(value = value, label = label), values, labels))
}

normalize_parameter_condition <- function(condition, keys, key) {
  if (is.null(condition)) return(NULL)
  if (!is.list(condition) || is.null(condition$key)) {
    stop("condition must contain key and equals or in for field ", key, ".", call. = FALSE)
  }
  dependency <- as.character(condition$key)
  if (length(dependency) != 1L || !dependency %in% keys || dependency == key) {
    stop("condition references an invalid field for ", key, ".", call. = FALSE)
  }
  has_equals <- !is.null(condition$equals)
  has_in <- !is.null(condition[["in"]])
  if (has_equals == has_in) stop("condition must define exactly one of equals or in.", call. = FALSE)
  list(key = dependency, operator = if (has_equals) "equals" else "in",
    value = if (has_equals) condition$equals else unname(condition[["in"]]))
}

normalize_parameter_workbench_schema <- function(schema) {
  if (!is.list(schema) || !length(schema)) stop("schema must be a non-empty list of fields.", call. = FALSE)
  keys <- vapply(schema, function(field) as.character(field$key %||% ""), character(1))
  if (any(!nzchar(keys)) || anyDuplicated(keys)) stop("schema field keys must be non-empty and unique.", call. = FALSE)
  normalized <- Map(function(field, key) {
    if (!is.list(field)) stop("Each schema field must be a named list.", call. = FALSE)
    type <- match.arg(as.character(field$type %||% "text"), parameter_workbench_types())
    choices <- normalize_parameter_choices(field$choices, key)
    if (type %in% c("choice", "multi_choice") && !length(choices)) {
      stop("choices are required for field ", key, ".", call. = FALSE)
    }
    if (type %in% c("slider", "range") && (is.null(field$min) || is.null(field$max))) {
      stop("min and max are required for field ", key, ".", call. = FALSE)
    }
    if (!is.null(field$min) && !is.null(field$max) && field$min > field$max) {
      stop("min cannot exceed max for field ", key, ".", call. = FALSE)
    }
    default <- field$default
    if (is.null(default)) default <- switch(type, boolean = FALSE, multi_choice = character(), range = c(field$min, field$max), NULL)
    list(key = key, label = as.character(field$label %||% key), type = type,
      default = default, required = isTRUE(field$required),
      description = as.character(field$description %||% field$help %||% ""),
      choices = choices, min = field$min, max = field$max, step = field$step,
      readOnly = isTRUE(field$read_only), disabled = isTRUE(field$disabled),
      section = as.character(field$section %||% "Parameters"),
      condition = normalize_parameter_condition(field$condition, keys, key))
  }, schema, keys)
  dependencies <- stats::setNames(lapply(normalized, function(field) field$condition$key %||% character()), keys)
  visit <- function(key, path = character()) {
    if (key %in% path) stop("schema conditions must not contain cycles.", call. = FALSE)
    dependency <- dependencies[[key]]
    if (length(dependency)) visit(dependency, c(path, key))
    invisible(NULL)
  }
  lapply(keys, visit)
  unname(normalized)
}

parameter_workbench_defaults <- function(schema) {
  stats::setNames(lapply(schema, `[[`, "default"), vapply(schema, `[[`, character(1), "key"))
}

#' Typed Parameter Workbench UI
#'
#' Render a compact schema-driven analytical parameter editor. The server owns
#' the schema and applied value; the browser owns an unapplied draft.
#'
#' @param id Shiny module identifier.
#' @param title,subtitle Workbench heading text.
#' @param height CSS height or minimum height.
#' @param searchable Show section/parameter search for long schemas.
#' @export
parameter_workbench_ui <- function(id, title = "Parameters", subtitle = NULL,
                                   height = NULL, searchable = TRUE) {
  ns <- shiny::NS(id)
  model <- list(title = title, subtitle = subtitle, searchable = isTRUE(searchable))
  htmltools::attachDependencies(htmltools::tags$div(
    id = ns("workbench"), class = "sc-parameter-workbench shiny-input-container",
    style = if (!is.null(height)) paste0("min-height:", height) else NULL,
    htmltools::tags$div(class = "sc-parameter-workbench-mount"),
    htmltools::tags$script(type = "application/json", `data-for` = ns("workbench"),
      htmltools::HTML(jsonlite::toJSON(model, auto_unbox = TRUE, null = "null")))
  ), parameter_workbench_dependency())
}

#' Typed Parameter Workbench server
#'
#' @param id Shiny module identifier.
#' @param schema Reactive or static list of bounded field specifications.
#' @param value Reactive or static named list of initial/applied values.
#' @param conflict_policy Behavior when host values arrive over a dirty draft:
#'   preserve the draft and flag a conflict, or replace it.
#' @return A list of reactives: `draft`, `applied`, `valid`, `dirty`, `errors`,
#'   `conflict`, `apply_event`, and `reset_event`.
#' @export
parameter_workbench_server <- function(id, schema, value = list(),
                                       conflict_policy = c("preserve", "replace")) {
  conflict_policy <- match.arg(conflict_policy)
  shiny::moduleServer(id, function(input, output, session) {
    schema_rx <- if (shiny::is.reactive(schema)) schema else shiny::reactive(schema)
    value_rx <- if (shiny::is.reactive(value)) value else shiny::reactive(value)
    revision <- shiny::reactiveVal(0L)
    shiny::observeEvent(list(schema_rx(), value_rx()), {
      normalized <- normalize_parameter_workbench_schema(schema_rx())
      supplied <- value_rx() %||% list()
      values <- utils::modifyList(parameter_workbench_defaults(normalized), supplied)
      revision(revision() + 1L)
      session$sendInputMessage("workbench", list(schema = normalized, values = values,
        conflictPolicy = conflict_policy, revision = revision()))
    }, ignoreInit = FALSE)
    state <- shiny::reactive(input$workbench %||% list(
      draft = list(), applied = list(), valid = FALSE, dirty = FALSE,
      errors = list(), conflict = FALSE, event = NULL))
    apply_event <- shiny::reactiveVal(NULL)
    reset_event <- shiny::reactiveVal(NULL)
    last_nonce <- shiny::reactiveVal(NULL)
    shiny::observeEvent(state()$event, {
      event <- state()$event
      if (is.null(event$nonce) || identical(event$nonce, last_nonce())) return()
      last_nonce(event$nonce)
      if (identical(event$type, "apply")) apply_event(event)
      if (identical(event$type, "reset")) reset_event(event)
    }, ignoreNULL = TRUE)
    list(
      draft = shiny::reactive(state()$draft %||% list()),
      applied = shiny::reactive(state()$applied %||% list()),
      valid = shiny::reactive(isTRUE(state()$valid)),
      dirty = shiny::reactive(isTRUE(state()$dirty)),
      errors = shiny::reactive(state()$errors %||% list()),
      conflict = shiny::reactive(isTRUE(state()$conflict)),
      apply_event = apply_event,
      reset_event = reset_event
    )
  })
}

#' Update a Typed Parameter Workbench
#' @param session Parent Shiny session.
#' @param id Module identifier.
#' @param schema Optional replacement schema.
#' @param values Optional host-applied values.
#' @param enabled Optional overall enabled state.
#' @param conflict_policy Dirty-draft conflict policy.
#' @export
update_parameter_workbench <- function(session = shiny::getDefaultReactiveDomain(), id,
                                       schema = NULL, values = NULL, enabled = NULL,
                                       conflict_policy = c("preserve", "replace")) {
  conflict_policy <- match.arg(conflict_policy)
  message <- list(id = paste0(session$ns(id), "-workbench"), conflictPolicy = conflict_policy)
  if (!is.null(schema)) message$schema <- normalize_parameter_workbench_schema(schema)
  if (!is.null(values)) message$values <- values
  if (!is.null(enabled)) message$enabled <- isTRUE(enabled)
  session$sendCustomMessage("shinycapabilities:parameter-workbench:update", message)
  invisible(NULL)
}

#' Run the Typed Parameter Workbench demo
#' @param ... Arguments passed to [shiny::runApp()].
#' @export
run_parameter_workbench_demo <- function(...) {
  shiny::runApp(system.file("examples", "parameter-workbench", package = "shinycapabilities"), ...)
}
