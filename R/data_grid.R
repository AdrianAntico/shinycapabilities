data_grid_scalar <- function(x, name) {
  if (length(x) != 1L || is.na(x)) stop(name, " must be a non-missing scalar.", call. = FALSE)
  x
}

data_grid_records <- function(data, row_id = NULL) {
  if (!is.data.frame(data)) stop("data must be a data frame or data.table.", call. = FALSE)
  if (anyDuplicated(names(data)) || any(!nzchar(names(data)))) {
    stop("data must have unique, non-empty column names.", call. = FALSE)
  }
  if (".sc_row_id" %in% names(data)) {
    stop("data cannot contain the reserved column .sc_row_id.", call. = FALSE)
  }
  ids <- if (is.null(row_id)) {
    sprintf("row_%09d", seq_len(nrow(data)))
  } else {
    row_id <- data_grid_scalar(as.character(row_id), "row_id")
    if (!row_id %in% names(data)) stop("row_id must name a column in data.", call. = FALSE)
    as.character(data[[row_id]])
  }
  if (anyNA(ids) || any(!nzchar(ids)) || anyDuplicated(ids)) {
    stop("Row identities must be non-missing, non-empty, and unique.", call. = FALSE)
  }
  encode <- function(column) {
    if (inherits(column, "Date")) return(ifelse(is.na(column), NA_character_, format(column, "%Y-%m-%d")))
    if (inherits(column, c("POSIXct", "POSIXlt"))) {
      return(ifelse(is.na(column), NA_character_, format(column, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")))
    }
    if (is.factor(column)) return(as.character(column))
    unname(column)
  }
  records <- as.data.frame(lapply(data, encode), stringsAsFactors = FALSE,
    optional = TRUE, check.names = FALSE)
  records[[".sc_row_id"]] <- ids
  list(records = records, ids = ids)
}

infer_data_grid_type <- function(column) {
  if (inherits(column, "Date")) return("date")
  if (inherits(column, c("POSIXct", "POSIXlt"))) return("datetime")
  if (is.logical(column)) return("logical")
  if (is.integer(column)) return("integer")
  if (is.numeric(column)) return("number")
  "text"
}

normalize_data_grid_columns <- function(data, columns = NULL) {
  defaults <- lapply(names(data), function(field) list(
    field = field,
    headerName = field,
    scType = infer_data_grid_type(data[[field]])
  ))
  names(defaults) <- names(data)
  if (is.null(columns)) return(unname(defaults))
  if (is.character(columns)) {
    unknown <- setdiff(columns, names(data))
    if (length(unknown)) stop("Unknown grid column: ", unknown[[1]], call. = FALSE)
    return(unname(defaults[columns]))
  }
  if (!is.list(columns) || is.null(names(columns)) || any(!nzchar(names(columns)))) {
    stop("columns must be NULL, a character vector, or a named list.", call. = FALSE)
  }
  allowed <- c("header_name", "type", "format", "digits", "currency", "pinned",
    "width", "min_width", "max_width", "hide", "sortable", "filter", "resizable")
  unknown_columns <- setdiff(names(columns), names(data))
  if (length(unknown_columns)) stop("Unknown grid column: ", unknown_columns[[1]], call. = FALSE)
  result <- lapply(names(columns), function(field) {
    specification <- columns[[field]]
    if (is.null(specification)) specification <- list()
    if (!is.list(specification)) stop("Each column specification must be a list.", call. = FALSE)
    unknown <- setdiff(names(specification), allowed)
    if (length(unknown)) stop("Unsupported column option: ", unknown[[1]], call. = FALSE)
    output <- defaults[[field]]
    mapping <- c(header_name = "headerName", type = "scType", format = "format",
      digits = "digits", currency = "currency", pinned = "pinned", width = "width",
      min_width = "minWidth", max_width = "maxWidth", hide = "hide",
      sortable = "sortable", filter = "filter", resizable = "resizable")
    for (key in names(specification)) output[[mapping[[key]]]] <- specification[[key]]
    output
  })
  unname(result)
}

normalize_data_grid_options <- function(options) {
  if (!is.list(options)) stop("options must be a list.", call. = FALSE)
  allowed <- c("selection", "quick_filter", "column_controls", "copy_selected",
    "density", "row_height", "header_height", "publish_state", "accessibility_mode",
    "empty_message", "loading_message", "animate_rows")
  unknown <- setdiff(names(options), allowed)
  if (length(unknown)) stop("Unsupported grid option: ", unknown[[1]], call. = FALSE)
  output <- utils::modifyList(list(
    selection = "single", quick_filter = TRUE, column_controls = TRUE,
    copy_selected = TRUE, density = "compact", row_height = NULL,
    header_height = NULL, publish_state = TRUE, accessibility_mode = "virtualized",
    empty_message = "No rows to display.", loading_message = "Loading data...",
    animate_rows = FALSE
  ), options)
  output$selection <- match.arg(output$selection, c("none", "single", "multiple"))
  output$density <- match.arg(output$density, c("compact", "comfortable"))
  output$accessibility_mode <- match.arg(output$accessibility_mode,
    c("virtualized", "paginated"))
  output
}

#' Virtualized analytical data grid
#'
#' Create a host-neutral AG Grid Community widget for dense analytical tables.
#' Shiny publishes bounded structured events as `<outputId>_selection`,
#' `<outputId>_action`, and (when enabled) `<outputId>_state`. Scrolling never
#' publishes events. Enterprise-only AG Grid features are intentionally absent.
#'
#' @param data A data frame or data.table.
#' @param columns `NULL` for inferred columns, a character vector for visible
#'   column order, or a named list of validated column specifications.
#' @param row_id Optional name of a column containing stable unique row IDs.
#' @param options Validated grid options. See Details.
#' @param width,height Widget dimensions.
#' @param element_id Optional HTML element ID.
#'
#' @details Supported column options are `header_name`, `type`, `format`,
#' `digits`, `currency`, `pinned`, `width`, `min_width`, `max_width`, `hide`,
#' `sortable`, `filter`, and `resizable`. Formats include `raw`, `number`,
#' `compact`, `percent`, `currency`, `date`, and `datetime`.
#'
#' @export
data_grid <- function(data, columns = NULL, row_id = NULL, options = list(),
                      width = NULL, height = "560px", element_id = NULL) {
  rows <- data_grid_records(data, row_id)
  htmlwidgets::createWidget(
    name = "data_grid",
    x = json_object_payload(list(
      rows = rows$records,
      columns = normalize_data_grid_columns(data, columns),
      options = normalize_data_grid_options(options)
    )),
    width = width, height = height, package = "shinycapabilities",
    elementId = element_id
  )
}

#' @rdname data_grid
#' @param output_id Shiny output identifier.
#' @export
data_grid_output <- function(output_id, width = "100%", height = "560px") {
  htmlwidgets::shinyWidgetOutput(output_id, "data_grid", width, height,
    package = "shinycapabilities")
}

#' @rdname data_grid
#' @param expr Expression returning a grid widget.
#' @param env Evaluation environment.
#' @param quoted Whether `expr` is quoted.
#' @export
render_data_grid <- function(expr, env = parent.frame(), quoted = FALSE) {
  if (!quoted) expr <- substitute(expr)
  htmlwidgets::shinyRenderWidget(expr, data_grid_output, env, quoted = TRUE)
}

#' Update a rendered data grid
#'
#' @param session Active Shiny session.
#' @param output_id Grid output identifier. Module namespaces are applied with
#'   the supplied session.
#' @param data Optional replacement data frame or data.table.
#' @param row_id Optional stable ID column for replacement data.
#' @param selected_rows Optional character vector of row IDs to select.
#' @param quick_filter Optional quick-filter text.
#' @param loading Optional loading-overlay state.
#' @param column_state Optional AG Grid column-state records previously emitted
#'   by the widget.
#' @export
update_data_grid <- function(session, output_id, data = NULL, row_id = NULL,
                             selected_rows = NULL, quick_filter = NULL,
                             loading = NULL, column_state = NULL) {
  message <- list(id = session$ns(output_id))
  if (!is.null(data)) message$rows <- data_grid_records(data, row_id)$records
  if (!is.null(selected_rows)) message$selectedRows <- unname(as.character(selected_rows))
  if (!is.null(quick_filter)) message$quickFilter <- as.character(quick_filter)
  if (!is.null(loading)) message$loading <- isTRUE(loading)
  if (!is.null(column_state)) message$columnState <- column_state
  session$sendCustomMessage("shinycapabilities:data-grid:update", message)
  invisible(NULL)
}

#' Run the analytical data-grid demo
#' @param ... Arguments passed to [shiny::runApp()].
#' @export
run_data_grid_demo <- function(...) {
  shiny::runApp(system.file("examples", "data-grid", package = "shinycapabilities"), ...)
}
