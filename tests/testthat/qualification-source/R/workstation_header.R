#' Define a workstation header command
#'
#' @param id Stable command identifier.
#' @param label Human-readable command label.
#' @param group Identifier of the owning command group.
#' @param icon Optional text or icon markup.
#' @param priority Ordering priority within the group.
#' @param enabled Whether the command can be invoked.
#' @param disabled_reason Optional explanation when disabled.
#' @param visible Whether the command is rendered.
#' @param contextual Whether the command applies in the current context.
#' @param active Whether the command is currently active.
#' @param shortcut Optional keyboard-shortcut label.
#' @param payload Domain-neutral event payload.
#' @param overflow Whether the command may move to overflow.
#' @param overflow_only Whether the command appears only in overflow.
#' @param compact Whether the command may use compact presentation.
#' @param preferred_row Preferred header row, one or two.
#' @export
workstation_header_command <- function(id, label, group, icon = NULL, priority = 50L,
    enabled = TRUE, disabled_reason = NULL, visible = TRUE, contextual = TRUE,
    active = FALSE, shortcut = NULL, payload = list(), overflow = TRUE,
    overflow_only = FALSE, compact = TRUE, preferred_row = 1L) {
  stopifnot(is.character(id), length(id) == 1L, nzchar(id), is.character(label),
    length(label) == 1L, nzchar(label), is.character(group), length(group) == 1L)
  list(id = id, label = label, group = group, icon = icon, priority = as.integer(priority),
    enabled = isTRUE(enabled), disabled_reason = disabled_reason, visible = isTRUE(visible),
    contextual = isTRUE(contextual), active = isTRUE(active), shortcut = shortcut,
    payload = payload, overflow = isTRUE(overflow), overflow_only = isTRUE(overflow_only),
    compact = isTRUE(compact),
    preferred_row = max(1L, min(2L, as.integer(preferred_row))))
}

#' Define a workstation header command group
#'
#' @param id Stable group identifier.
#' @param label Human-readable group label.
#' @param priority Ordering priority among groups.
#' @param preferred_row Preferred header row, one or two.
#' @param visible Whether the group is rendered.
#' @param contextual Whether the group applies in the current context.
#' @param weight Relative available-space weight.
#' @export
workstation_header_group <- function(id, label, priority = 50L, preferred_row = 1L,
    visible = TRUE, contextual = TRUE, weight = 1) {
  stopifnot(is.character(id), length(id) == 1L, nzchar(id))
  list(id = id, label = label, priority = as.integer(priority),
    preferred_row = max(1L, min(2L, as.integer(preferred_row))),
    visible = isTRUE(visible), contextual = isTRUE(contextual),
    weight = max(0.25, as.numeric(weight)))
}

workstation_header_dependency <- function() {
  htmltools::htmlDependency("shinycapabilities-workstation-header", "1.0.0",
    src = c(file = system.file("www", package = "shinycapabilities")),
    stylesheet = "workstation-header.css", script = "workstation-header.js")
}

#' Render a reusable workstation command header
#'
#' @param id Shiny module identifier.
#' @param title Accessible header title.
#' @param groups List of command-group definitions.
#' @param commands List of command definitions.
#' @param context Optional compact context label.
#' @param rows Number of command rows, one or two.
#' @param class Optional additional CSS class.
#' @export
workstation_header_ui <- function(id, title, groups, commands, context = NULL,
    rows = 1L, class = NULL) {
  ns <- shiny::NS(id)
  rows <- max(1L, min(2L, as.integer(rows)))
  groups <- Filter(function(group) isTRUE(group$visible) && isTRUE(group$contextual), groups)
  commands <- Filter(function(command) isTRUE(command$visible) && isTRUE(command$contextual), commands)
  command_tag <- function(command, overflow = FALSE) {
    reason <- command$disabled_reason %||% if (!isTRUE(command$enabled)) "Unavailable" else NULL
    htmltools::tags$button(type = "button",
      class = paste("sc-workstation-command", if (isTRUE(command$active)) "is-active",
        if (overflow) "is-overflow-command"),
      `data-sc-command-id` = command$id, `data-priority` = command$priority,
      `data-overflow-eligible` = tolower(as.character(command$overflow)),
      `data-overflow-only` = tolower(as.character(command$overflow_only)),
      `data-compact-eligible` = tolower(as.character(command$compact)),
      `data-payload` = jsonlite::toJSON(command$payload, auto_unbox = TRUE, null = "null"),
      disabled = if (!isTRUE(command$enabled)) "disabled" else NULL,
      title = reason %||% paste(command$label, command$shortcut %||% ""),
      `aria-label` = command$label, `aria-pressed` = if (isTRUE(command$active)) "true" else NULL,
      if (!is.null(command$icon)) htmltools::tags$span(class = "sc-workstation-command-icon",
        `aria-hidden` = "true", command$icon),
      htmltools::tags$span(class = "sc-workstation-command-label", command$label),
      if (!is.null(command$shortcut)) htmltools::tags$kbd(command$shortcut),
      if (!is.null(reason) && overflow) htmltools::tags$small(reason))
  }
  group_tag <- function(group) {
    owned <- Filter(function(command) identical(command$group, group$id), commands)
    if (!length(owned)) return(NULL)
    owned <- owned[order(vapply(owned, `[[`, integer(1), "priority"))]
    htmltools::tags$section(class = "sc-workstation-command-group",
      `data-group-id` = group$id, `data-priority` = group$priority,
      `data-preferred-row` = group$preferred_row,
      style = sprintf("--sc-wh-group-grow:%s", format(group$weight, scientific = FALSE)),
      htmltools::tags$div(class = "sc-workstation-command-group-body", lapply(owned, command_tag)),
      htmltools::tags$span(class = "sc-workstation-command-group-label", group$label))
  }
  htmltools::attachDependencies(htmltools::tags$header(id = ns("root"),
    class = paste("sc-workstation-header", class), `data-rows` = rows,
    style = sprintf("--sc-wh-row-count:%d", rows),
    `data-command-input` = ns("command"), role = "toolbar", `aria-label` = paste(title, "commands"),
    htmltools::tags$div(class = "sc-workstation-header-context",
      htmltools::tags$strong(title), if (!is.null(context)) htmltools::tags$small(context)),
    htmltools::tags$div(class = "sc-workstation-header-rows", lapply(seq_len(rows), function(row) {
      htmltools::tags$div(class = "sc-workstation-header-row", `data-row` = row,
        lapply(Filter(function(group) identical(group$preferred_row, row), groups), group_tag))
    })),
    htmltools::tags$details(class = "sc-workstation-overflow",
      htmltools::tags$summary(`aria-label` = "More commands", title = "More commands", "..."),
      htmltools::tags$div(class = "sc-workstation-overflow-menu", role = "menu"))),
    workstation_header_dependency())
}
