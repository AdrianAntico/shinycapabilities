selection_system_dependency <- function() {
  list(browser_runtime_dependency(), htmltools::htmlDependency(
    name = "shinycapabilities-selection-system", version = "1.0.0",
    src = c(file = "www/direct-transport"), package = "shinycapabilities",
    script = "selection-system.js", stylesheet = "selection-system.css"
  ))
}

normalize_selection_groups <- function(groups) {
  if (is.null(groups)) return(list())
  if (is.character(groups)) groups <- list(Options = stats::setNames(groups, groups))
  Map(function(values, index) {
    if (is.list(values) && !is.null(values$options)) return(values)
    labels <- names(values) %||% as.character(values)
    group_names <- names(groups)
    group_label <- if (length(group_names) >= index && nzchar(group_names[[index]])) group_names[[index]] else "Options"
    list(id = paste0("group-", index), label = group_label,
      options = unname(Map(function(value, label) list(value = as.character(value), label = as.character(label)),
        unname(values), labels)))
  }, groups, seq_along(groups))
}

#' Analytics Selection System input
#' @param inputId Shiny input identifier.
#' @param label Accessible field label.
#' @param groups Named option groups or normalized group records.
#' @param selected Pending selection value.
#' @param applied Applied selection value, used to expose dirty state.
#' @param multiple Allow multiple values.
#' @param ordered Show the bounded generic order editor.
#' @param required Whether an empty selection is invalid for the host.
#' @param commands Host-defined bulk selection commands.
#' @param stale Values retained from an earlier option revision.
#' @param disabled,loading Noninteractive lifecycle states.
#' @param revision Host option/schema revision.
#' @param virtual_threshold Row count above which virtualization activates.
#' @param server_search Publish debounced search terms as `<inputId>_search`.
#' @param search Enable search; `NULL` enables it adaptively for more than ten choices.
#' @param labels Optional value-to-label mapping for closed summaries.
#' @param accessibility Host-specific accessible labels.
#' @export
selection_input <- function(inputId, label, groups, selected = character(), applied = selected,
                            multiple = FALSE, ordered = FALSE, required = FALSE,
                            commands = list(), stale = character(), disabled = FALSE,
                            loading = FALSE, revision = "1", virtual_threshold = 200L,
                            server_search = FALSE, search = NULL, labels = NULL, accessibility = list()) {
  groups <- unname(normalize_selection_groups(groups))
  commands <- unname(commands)
  if (!isTRUE(required) && !any(vapply(commands, function(command) identical(command$scope %||% "", "clear"), logical(1)))) {
    commands <- c(commands, list(list(id = "clear", label = "Clear", scope = "clear")))
  }
  choice_count <- sum(vapply(groups, function(group) length(group$options %||% list()), integer(1)))
  model <- c(list(label = label, groups = groups,
    value = unname(as.character(selected %||% character())),
    applied = unname(as.character(applied %||% character())), multiple = isTRUE(multiple),
    ordered = isTRUE(ordered), required = isTRUE(required), commands = commands,
    stale = unname(as.character(stale %||% character())), disabled = isTRUE(disabled),
    loading = isTRUE(loading), revision = as.character(revision),
    virtualThreshold = as.integer(virtual_threshold), serverSearch = isTRUE(server_search),
    searchable = if (is.null(search)) choice_count > 10L else isTRUE(search),
    labels = labels %||% list()), accessibility)
  htmltools::attachDependencies(htmltools::tags$div(
    id = inputId, class = "sc-selection shiny-input-container",
    htmltools::tags$div(class = "sc-selection-mount"),
    htmltools::tags$script(type = "application/json", `data-for` = inputId,
      htmltools::HTML(jsonlite::toJSON(model, auto_unbox = TRUE, null = "null")))
  ), selection_system_dependency())
}

#' Update an Analytics Selection System input
#' @param session Shiny session.
#' @param inputId Input identifier.
#' @param ... Public model fields to update.
#' @export
update_selection_input <- function(session = shiny::getDefaultReactiveDomain(), inputId, ...) {
  message <- list(...)
  if (!is.null(message$groups)) message$groups <- normalize_selection_groups(message$groups)
  if (!is.null(message$selected)) { message$value <- message$selected; message$selected <- NULL }
  session$sendInputMessage(inputId, message)
}

# Backward-readable schema alias; the implementation and lifecycle stay generic.
#' @rdname selection_input
#' @export
analytics_field_picker <- selection_input
