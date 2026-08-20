split_pane_dependency <- function() {
  htmltools::htmlDependency("shinycapabilities-split-pane", "1.0.0",
    src = c(file = "htmlwidgets/lib"), package = "shinycapabilities",
    script = "split-pane.js", stylesheet = "split-pane.css")
}

normalize_split_vector <- function(x, ids, name, default = NULL, logical = FALSE) {
  if (is.null(x)) return(stats::setNames(rep(list(default), length(ids)), ids))
  if (length(x) == 1L) x <- rep(x, length(ids))
  if (length(x) != length(ids)) stop(name, " must have length one or match the pane count.", call. = FALSE)
  if (!is.null(names(x)) && all(nzchar(names(x)))) x <- x[ids]
  if (any(vapply(as.list(x), is.null, logical(1)))) stop(name, " does not define every pane.", call. = FALSE)
  values <- if (logical) lapply(x, isTRUE) else lapply(x, function(value) {
    if (is.numeric(value)) paste0(value, "%") else as.character(value)
  })
  stats::setNames(values, ids)
}

normalize_split_pane_model <- function(panes, direction, sizes, min_sizes, max_sizes,
                                       collapsible, collapsed, reset_on_double_click) {
  if (length(panes) < 2L) stop("split_pane requires at least two panes.", call. = FALSE)
  ids <- names(panes)
  if (is.null(ids) || any(!nzchar(ids))) ids <- paste0("pane_", seq_along(panes))
  if (anyDuplicated(ids) || any(!grepl("^[A-Za-z][A-Za-z0-9_-]*$", ids))) stop("Pane names must be unique CSS-safe identifiers.", call. = FALSE)
  direction <- match.arg(direction, c("horizontal", "vertical"))
  sizes <- normalize_split_vector(sizes %||% rep(100 / length(ids), length(ids)), ids, "sizes")
  min_sizes <- normalize_split_vector(min_sizes, ids, "min_sizes", "10%")
  max_sizes <- normalize_split_vector(max_sizes, ids, "max_sizes", "100%")
  collapsible <- normalize_split_vector(collapsible, ids, "collapsible", FALSE, logical = TRUE)
  collapsed <- as.character(collapsed %||% character())
  if (length(setdiff(collapsed, ids))) stop("collapsed contains an unknown pane id.", call. = FALSE)
  list(ids = ids, direction = direction, sizes = sizes, minSizes = min_sizes,
    maxSizes = max_sizes, collapsible = collapsible, collapsed = collapsed,
    resetOnDoubleClick = isTRUE(reset_on_double_click))
}

#' Accessible resizable split pane
#'
#' Arrange arbitrary Shiny UI in two or more resizable panels. Named `...`
#' arguments become deterministic pane identifiers. Resize state is published
#' only after pointer or keyboard interaction completes.
#'
#' @param input_id Shiny input identifier.
#' @param ... Two or more named Shiny UI objects.
#' @param direction Horizontal or vertical panel arrangement.
#' @param sizes,min_sizes,max_sizes Length-one or pane-length percentage values.
#'   Character values with CSS units are also accepted.
#' @param collapsible Length-one or pane-length logical vector.
#' @param collapsed Pane ids initially collapsed.
#' @param reset_on_double_click Reset by double-clicking a separator.
#' @param height,width CSS dimensions.
#' @export
split_pane <- function(input_id, ..., direction = c("horizontal", "vertical"),
                       sizes = NULL, min_sizes = NULL, max_sizes = NULL,
                       collapsible = FALSE, collapsed = character(),
                       reset_on_double_click = TRUE, height = "520px", width = "100%") {
  panes <- list(...)
  model <- normalize_split_pane_model(panes, direction, sizes, min_sizes, max_sizes,
    collapsible, collapsed, reset_on_double_click)
  names(panes) <- model$ids
  dependencies <- unlist(lapply(panes, htmltools::findDependencies), recursive = FALSE)
  model$html <- stats::setNames(lapply(panes, function(content) htmltools::renderTags(content)$html), model$ids)
  model_json <- jsonlite::toJSON(model, auto_unbox = TRUE, null = "null")
  model_json <- gsub("</script>", "<\\/script>", model_json, fixed = TRUE)
  tag <- htmltools::tags$div(id = input_id, class = "sc-split-pane shiny-input-container",
    style = paste0("width:", width, ";height:", height),
    htmltools::tags$div(class = "sc-split-pane-mount"),
    htmltools::tags$script(type = "application/json", `data-for` = input_id,
      htmltools::HTML(model_json)))
  htmltools::attachDependencies(tag, c(list(split_pane_dependency()), dependencies), append = FALSE)
}

#' Update an accessible split pane
#' @param session Active Shiny session.
#' @param input_id Split-pane input identifier.
#' @param sizes Optional named or ordered percentage layout.
#' @param collapse,expand Pane ids to collapse or expand.
#' @param reset Restore initial sizes.
#' @export
update_split_pane <- function(session = shiny::getDefaultReactiveDomain(), input_id,
                              sizes = NULL, collapse = NULL, expand = NULL, reset = FALSE) {
  message <- list()
  if (!is.null(sizes)) message$sizes <- sizes
  if (!is.null(collapse)) message$collapse <- as.character(collapse)
  if (!is.null(expand)) message$expand <- as.character(expand)
  if (isTRUE(reset)) message$reset <- TRUE
  session$sendInputMessage(input_id, message)
  invisible(NULL)
}

#' Run the accessible split-pane demo
#' @param ... Arguments passed to [shiny::runApp()].
#' @export
run_split_pane_demo <- function(...) shiny::runApp(system.file("examples", "split-pane", package = "shinycapabilities"), ...)
