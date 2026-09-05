code_editor_languages <- function() {
  c("r", "julia", "python", "sql", "json", "yaml", "markdown")
}

normalize_code_editor_language <- function(language) {
  language <- tolower(as.character(language))
  if (length(language) != 1L || !language %in% code_editor_languages()) {
    stop("language must be one of: ",
      paste(code_editor_languages(), collapse = ", "), ".", call. = FALSE)
  }
  language
}

normalize_code_editor_diagnostics <- function(diagnostics) {
  if (is.null(diagnostics)) return(list())
  if (is.data.frame(diagnostics)) {
    diagnostics <- lapply(seq_len(nrow(diagnostics)), function(i) as.list(diagnostics[i, , drop = FALSE]))
  }
  if (!is.list(diagnostics)) stop("diagnostics must be a list or data frame.", call. = FALSE)
  allowed <- c("error", "warning", "information", "info", "hint")
  lapply(diagnostics, function(item) {
    if (!is.list(item)) stop("Each diagnostic must be a named list.", call. = FALSE)
    severity <- tolower(as.character(item$severity %||% "error"))
    if (length(severity) != 1L || !severity %in% allowed) {
      stop("Diagnostic severity must be error, warning, information, info, or hint.", call. = FALSE)
    }
    line <- max(1L, as.integer(item$line %||% item$startLineNumber %||% 1L))
    column <- max(1L, as.integer(item$column %||% item$startColumn %||% 1L))
    list(
      severity = severity,
      message = as.character(item$message %||% "Diagnostic"),
      startLineNumber = line,
      startColumn = column,
      endLineNumber = max(line, as.integer(item$endLineNumber %||% line)),
      endColumn = max(column + 1L, as.integer(item$endColumn %||% (column + 1L))),
      source = as.character(item$source %||% "host"),
      code = if (is.null(item$code)) NULL else as.character(item$code)
    )
  })
}

#' Monaco code editor
#'
#' A direct-transport Monaco editor for bounded, host-governed editing. Drafts
#' remain in the browser until the user explicitly applies them. Host updates
#' received during a dirty draft become an explicit conflict rather than
#' silently replacing user work.
#'
#' @param value Initial or applied document value.
#' @param language Document language. Supported values are `r`, `julia`,
#'   `python`, `sql`, `json`, `yaml`, and `markdown`.
#' @param mode Ordinary editor or diff editor.
#' @param original_value Baseline text for diff mode.
#' @param modified_value Modified text for diff mode. Defaults to `value`.
#' @param read_only Whether an ordinary editor is read-only.
#' @param modified_read_only Whether the modified side of a diff is read-only.
#' @param wrap,minimap,line_numbers Editor display options.
#' @param theme `auto`, `light`, or `dark`.
#' @param diagnostics Host-supplied marker records.
#' @param completion_enabled Whether bounded completion requests may be sent to
#'   the host. The host responds with [update_code_editor()].
#' @param document_id Stable host document identifier.
#' @param host_revision Monotonic host revision used for conflict detection.
#' @param title,aria_label Visible title and accessible editor label.
#' @param render_side_by_side Use side-by-side diff rendering when space allows.
#' @param tab_size,insert_spaces Indentation settings.
#' @param options Reserved named list of additional bounded component options.
#' @param element_id Optional id for static rendering.
#' @return A `shinycapabilities_direct_component`.
#' @export
code_editor <- function(value = "", language = "r",
                        mode = c("editor", "diff"), original_value = NULL,
                        modified_value = NULL, read_only = FALSE,
                        modified_read_only = TRUE, wrap = FALSE,
                        minimap = FALSE, theme = c("auto", "light", "dark"),
                        diagnostics = list(), completion_enabled = FALSE,
                        document_id = NULL, host_revision = 1L,
                        title = NULL, aria_label = "Code editor",
                        render_side_by_side = TRUE, line_numbers = TRUE,
                        tab_size = 2L, insert_spaces = TRUE,
                        options = list(), element_id = NULL) {
  mode <- match.arg(mode)
  theme <- match.arg(theme)
  language <- normalize_code_editor_language(language)
  if (!is.list(options)) stop("options must be a named list.", call. = FALSE)
  if (mode == "diff" && is.null(original_value)) {
    stop("original_value is required in diff mode.", call. = FALSE)
  }
  payload <- c(list(
    value = as.character(value %||% ""), language = language, mode = mode,
    originalValue = if (is.null(original_value)) NULL else as.character(original_value),
    modifiedValue = if (is.null(modified_value)) as.character(value %||% "") else as.character(modified_value),
    readOnly = isTRUE(read_only), modifiedReadOnly = isTRUE(modified_read_only),
    wrap = isTRUE(wrap), minimap = isTRUE(minimap), theme = theme,
    diagnostics = normalize_code_editor_diagnostics(diagnostics),
    completionEnabled = isTRUE(completion_enabled),
    documentId = as.character(document_id %||% element_id %||% "document"),
    hostRevision = as.integer(host_revision), title = as.character(title %||% "Editor"),
    ariaLabel = as.character(aria_label), renderSideBySide = isTRUE(render_side_by_side),
    lineNumbers = isTRUE(line_numbers), tabSize = max(1L, as.integer(tab_size)),
    insertSpaces = isTRUE(insert_spaces)
  ), options)
  value <- new_direct_component("code_editor", payload, element_id)
  value$revision <- as.integer(host_revision)
  value
}

#' @rdname code_editor
#' @param output_id Shiny output id.
#' @param width,height CSS dimensions.
#' @export
code_editor_output <- function(output_id, width = "100%", height = "520px") {
  direct_component_output(output_id, "code_editor", width, height)
}

#' @rdname code_editor
#' @param expr Expression returning [code_editor()].
#' @param env Evaluation environment.
#' @param quoted Whether `expr` is quoted.
#' @export
render_code_editor <- function(expr, env = parent.frame(), quoted = FALSE) {
  if (!quoted) expr <- substitute(expr)
  render_direct_component(expr, code_editor_output, env, quoted = TRUE)
}

#' @rdname code_editor
#' @param session Active Shiny session.
#' @param completions Bounded completion records returned for a request.
#' @param completion_request_id Request id received from
#'   `input$<output_id>_completion_request`.
#' @param revision Direct-transport update revision.
#' @export
update_code_editor <- function(session = shiny::getDefaultReactiveDomain(),
                               output_id, value = NULL, original_value = NULL,
                               language = NULL, read_only = NULL,
                               diagnostics = NULL, completions = NULL,
                               completion_request_id = NULL,
                               host_revision = NULL,
                               revision = as.integer(Sys.time())) {
  payload <- list()
  if (!is.null(value)) payload$value <- as.character(value)
  if (!is.null(original_value)) payload$originalValue <- as.character(original_value)
  if (!is.null(language)) payload$language <- normalize_code_editor_language(language)
  if (!is.null(read_only)) payload$readOnly <- isTRUE(read_only)
  if (!is.null(diagnostics)) payload$diagnostics <- normalize_code_editor_diagnostics(diagnostics)
  if (!is.null(completions)) payload$completions <- completions
  if (!is.null(completion_request_id)) payload$completionRequestId <- as.character(completion_request_id)
  if (!is.null(host_revision)) payload$hostRevision <- as.integer(host_revision)
  update_direct_component(session, output_id, "code_editor", payload, revision)
}

#' Run the Monaco Editor 1.0 demo
#' @param ... Arguments passed to [shiny::runApp()].
#' @export
run_code_editor_demo <- function(...) {
  shiny::runApp(system.file("examples", "code-editor", package = "shinycapabilities"), ...)
}
