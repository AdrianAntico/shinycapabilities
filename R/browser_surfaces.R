browser_surfaces_dependency <- function() {
  htmltools::htmlDependency(
    name = "shinycapabilities-browser-surfaces", version = "1.0.0",
    src = c(file = "www/browser-surfaces"), package = "shinycapabilities",
    script = "browser-surfaces.js", stylesheet = "browser-surfaces.css"
  )
}

surface_scalar <- function(value, name) {
  if (length(value) != 1L || is.na(value) || !nzchar(as.character(value))) {
    stop(name, " must be one non-empty value.", call. = FALSE)
  }
  as.character(value)
}

surface_tag <- function(tag) htmltools::attachDependencies(tag, browser_surfaces_dependency())

surface_actions <- function(actions) {
  if (is.null(actions) || !length(actions)) return(NULL)
  lapply(seq_along(actions), function(i) {
    action <- actions[[i]]
    if (is.character(action)) action <- list(id = action, label = action)
    id <- surface_scalar(action$id %||% paste0("action_", i), "action id")
    htmltools::tags$button(
      type = "button",
      class = paste("sc-surface-action", paste0("is-", action$kind %||% "secondary")),
      `data-sc-event` = id,
      disabled = if (isTRUE(action$disabled)) "disabled" else NULL,
      action$label %||% id
    )
  })
}

#' Browser-native tooltip
#' @param id Stable component identifier.
#' @param trigger Trigger content.
#' @param content Tooltip content.
#' @param placement Preferred placement.
#' @export
browser_tooltip <- function(id, trigger, content, placement = "top") {
  id <- surface_scalar(id, "id")
  surface_tag(htmltools::tags$span(
    id = id, class = "sc-overlay-anchor sc-tooltip-anchor",
    `data-sc-surface` = "tooltip", `data-placement` = placement,
    htmltools::tags$span(class = "sc-overlay-trigger", tabindex = "0", trigger),
    htmltools::tags$span(class = "sc-tooltip", role = "tooltip", content)
  ))
}

#' Browser-native anchored popover
#' @inheritParams browser_tooltip
#' @param title Optional accessible heading.
#' @export
browser_popover <- function(id, trigger, content, title = NULL, placement = "bottom-start") {
  id <- surface_scalar(id, "id")
  title_id <- paste0(id, "-title")
  surface_tag(htmltools::tags$span(
    id = id, class = "sc-overlay-anchor", `data-sc-surface` = "popover",
    `data-placement` = placement,
    htmltools::tags$button(type = "button", class = "sc-overlay-trigger sc-surface-action is-secondary",
      `aria-expanded` = "false", `aria-controls` = paste0(id, "-panel"), trigger),
    htmltools::tags$div(id = paste0(id, "-panel"), class = "sc-popover", hidden = "hidden",
      role = "dialog", `aria-labelledby` = if (!is.null(title)) title_id else NULL,
      if (!is.null(title)) htmltools::tags$strong(id = title_id, title), content)
  ))
}

#' Browser-native context menu
#' @inheritParams browser_tooltip
#' @param items List of menu items with id, label, disabled, and destructive.
#' @export
browser_context_menu <- function(id, trigger, items) {
  id <- surface_scalar(id, "id")
  menu_items <- lapply(items, function(item) {
    if (is.character(item)) item <- list(id = item, label = item)
    htmltools::tags$button(type = "button", role = "menuitem",
      class = paste("sc-menu-item", if (isTRUE(item$destructive)) "is-destructive"),
      `data-sc-event` = surface_scalar(item$id, "item id"),
      disabled = if (isTRUE(item$disabled)) "disabled" else NULL,
      item$label %||% item$id)
  })
  surface_tag(htmltools::tags$div(
    id = id, class = "sc-context-anchor", `data-sc-surface` = "context-menu",
    tabindex = "0", trigger,
    htmltools::tags$div(class = "sc-context-menu", role = "menu", hidden = "hidden", menu_items)
  ))
}

#' Browser-native dialog, drawer, or sheet
#' @param id Stable component identifier.
#' @param title,description Accessible copy.
#' @param ... Body content.
#' @param actions Bounded action definitions.
#' @param variant One of dialog, drawer, side_sheet, or bottom_sheet.
#' @param open Whether initially open.
#' @param dismissible Whether Escape/backdrop may request close.
#' @export
browser_dialog <- function(id, title, description = NULL, ..., actions = NULL,
    variant = c("dialog", "drawer", "side_sheet", "bottom_sheet"), open = FALSE,
    dismissible = TRUE) {
  id <- surface_scalar(id, "id")
  variant <- match.arg(variant)
  surface_tag(htmltools::tags$dialog(
    id = id, class = paste("sc-dialog", paste0("is-", variant)),
    `data-sc-surface` = "dialog", `data-dismissible` = tolower(as.character(isTRUE(dismissible))),
    `aria-labelledby` = paste0(id, "-title"),
    `aria-describedby` = if (!is.null(description)) paste0(id, "-description") else NULL,
    open = if (isTRUE(open)) "open" else NULL,
    htmltools::tags$div(class = "sc-dialog-frame",
      htmltools::tags$header(class = "sc-dialog-header",
        htmltools::tags$div(htmltools::tags$h2(id = paste0(id, "-title"), title),
          if (!is.null(description)) htmltools::tags$p(id = paste0(id, "-description"), description)),
        htmltools::tags$button(type = "button", class = "sc-icon-action", `data-sc-dialog-close` = "true",
          `aria-label` = "Close", "\u00d7")),
      htmltools::tags$div(class = "sc-dialog-body", ...),
      if (length(actions)) htmltools::tags$footer(class = "sc-dialog-actions", surface_actions(actions))
    )
  ))
}

#' Browser-native confirmation dialog
#' @inheritParams browser_dialog
#' @param confirm_label,cancel_label Action labels.
#' @param destructive Whether confirmation is destructive.
#' @export
browser_confirmation_dialog <- function(id, title, description, confirm_label = "Confirm",
    cancel_label = "Cancel", destructive = FALSE, open = FALSE) {
  browser_dialog(id, title, description, actions = list(
    list(id = "cancel", label = cancel_label, kind = "secondary"),
    list(id = "confirm", label = confirm_label, kind = if (destructive) "destructive" else "primary")
  ), open = open)
}

#' Browser-native notification center
#' @param id Stable component identifier.
#' @param notifications List of notification records.
#' @param max_visible Maximum visible toast count.
#' @param max_history Maximum retained history count.
#' @export
notification_center <- function(id, notifications = list(), max_visible = 4L, max_history = 100L) {
  id <- surface_scalar(id, "id")
  payload <- jsonlite::toJSON(notifications, auto_unbox = TRUE, null = "null")
  surface_tag(htmltools::tags$section(
    id = id, class = "sc-notification-center", `data-sc-surface` = "notifications",
    `data-max-visible` = max(1L, as.integer(max_visible)),
    `data-max-history` = max(1L, as.integer(max_history)),
    `aria-label` = "Notifications",
    htmltools::tags$div(class = "sc-toast-region", `aria-live` = "polite", `aria-relevant` = "additions text"),
    htmltools::tags$script(type = "application/json", class = "sc-notification-data",
      htmltools::HTML(payload))
  ))
}

#' Browser-native tab navigation
#' @param id Stable component identifier.
#' @param tabs Named list or list of id, label, content records.
#' @param selected Initially selected id.
#' @export
browser_tabs <- function(id, tabs, selected = NULL) {
  id <- surface_scalar(id, "id")
  if (!length(tabs)) stop("tabs must not be empty.", call. = FALSE)
  records <- lapply(seq_along(tabs), function(i) {
    x <- tabs[[i]]
    if (!is.list(x) || is.null(x$id)) x <- list(id = names(tabs)[i] %||% paste0("tab_", i), label = names(tabs)[i], content = x)
    x$label <- x$label %||% x$id
    x
  })
  selected <- selected %||% records[[1]]$id
  surface_tag(htmltools::tags$section(id = id, class = "sc-tabs", `data-sc-surface` = "tabs",
    htmltools::tags$div(role = "tablist", `aria-label` = "Sections", class = "sc-tab-list",
      lapply(records, function(x) htmltools::tags$button(type = "button", role = "tab",
        id = paste0(id, "-tab-", x$id), `data-tab-id` = x$id,
        `aria-controls` = paste0(id, "-panel-", x$id),
        `aria-selected` = tolower(as.character(identical(x$id, selected))),
        tabindex = if (identical(x$id, selected)) "0" else "-1", x$label))),
    lapply(records, function(x) htmltools::tags$div(role = "tabpanel",
      id = paste0(id, "-panel-", x$id), class = "sc-tab-panel",
      `aria-labelledby` = paste0(id, "-tab-", x$id),
      hidden = if (!identical(x$id, selected)) "hidden" else NULL, x$content))
  ))
}

#' Browser-native disclosure group
#' @param id Stable component identifier.
#' @param sections List of id, title, content, and open records.
#' @param multiple Whether multiple sections may remain open.
#' @export
browser_accordion <- function(id, sections, multiple = TRUE) {
  id <- surface_scalar(id, "id")
  surface_tag(htmltools::tags$section(id = id, class = "sc-accordion",
    `data-sc-surface` = "accordion", `data-multiple` = tolower(as.character(isTRUE(multiple))),
    lapply(seq_along(sections), function(i) {
      x <- sections[[i]]; x$id <- x$id %||% paste0("section_", i)
      htmltools::tags$details(`data-section-id` = x$id, open = if (isTRUE(x$open)) "open" else NULL,
        htmltools::tags$summary(x$title %||% x$id), htmltools::tags$div(class = "sc-accordion-body", x$content))
    })))
}

#' Browser-native breadcrumbs
#' @param id Stable component identifier.
#' @param items List of id and label records.
#' @export
browser_breadcrumbs <- function(id, items) {
  id <- surface_scalar(id, "id")
  surface_tag(htmltools::tags$nav(id = id, class = "sc-breadcrumbs", `data-sc-surface` = "breadcrumbs",
    `aria-label` = "Breadcrumb", htmltools::tags$ol(lapply(seq_along(items), function(i) {
      x <- items[[i]]; if (is.character(x)) x <- list(id = x, label = x)
      htmltools::tags$li(if (i == length(items)) htmltools::tags$span(`aria-current` = "page", x$label)
        else htmltools::tags$button(type = "button", `data-sc-event` = x$id, x$label))
    }))))
}

#' Browser-native pagination
#' @param id Stable component identifier.
#' @param page,pages Current and total pages.
#' @param label Accessible label.
#' @export
browser_pagination <- function(id, page = 1L, pages = 1L, label = "Pagination") {
  id <- surface_scalar(id, "id"); page <- as.integer(page); pages <- max(1L, as.integer(pages))
  surface_tag(htmltools::tags$nav(id = id, class = "sc-pagination", `data-sc-surface` = "pagination",
    `data-page` = page, `data-pages` = pages, `aria-label` = label,
    htmltools::tags$button(type = "button", `data-sc-page` = "previous", disabled = if (page <= 1L) "disabled", "Previous"),
    htmltools::tags$output(`aria-live` = "polite", paste("Page", page, "of", pages)),
    htmltools::tags$button(type = "button", `data-sc-page` = "next", disabled = if (page >= pages) "disabled", "Next")))
}

#' Browser-native file upload presentation
#' @param input_id Shiny file input identifier.
#' @param label,help Presentation copy.
#' @param multiple,accept File picker constraints.
#' @param max_size Optional client-side byte limit.
#' @param disabled Disabled state.
#' @export
browser_file_upload <- function(input_id, label = "Choose files", help = "Drop files here or browse.",
    multiple = FALSE, accept = NULL, max_size = NULL, disabled = FALSE) {
  input_id <- surface_scalar(input_id, "input_id")
  transport <- shiny::fileInput(input_id, label = NULL, multiple = multiple, accept = accept,
    buttonLabel = "Browse", placeholder = "No file selected")
  surface_tag(htmltools::tags$section(id = paste0(input_id, "-surface"), class = "sc-file-upload",
    `data-sc-surface` = "file-upload", `data-input-id` = input_id,
    `data-max-size` = max_size, `data-disabled` = tolower(as.character(isTRUE(disabled))),
    htmltools::tags$div(class = "sc-file-drop", tabindex = if (disabled) "-1" else "0",
      role = "button", `aria-disabled` = tolower(as.character(isTRUE(disabled))),
      htmltools::tags$strong(label), htmltools::tags$span(help)),
    htmltools::tags$div(class = "sc-file-list", `aria-live` = "polite"),
    htmltools::tags$button(type = "button", class = "sc-file-clear", `data-sc-file-clear` = "true",
      disabled = "disabled", "Clear"),
    htmltools::tags$div(class = "sc-file-error", role = "alert"),
    htmltools::tags$div(class = "sc-file-transport", `aria-hidden` = "true", transport)))
}

#' Browser-native download action
#' @param output_id Shiny download output identifier.
#' @param label,filename,file_type,size Presentation metadata.
#' @param state preparing, ready, error, or unavailable.
#' @param disabled Disabled state.
#' @export
browser_download_action <- function(output_id, label = "Download", filename = NULL,
    file_type = NULL, size = NULL, state = c("ready", "preparing", "error", "unavailable"), disabled = FALSE) {
  output_id <- surface_scalar(output_id, "output_id"); state <- match.arg(state)
  surface_tag(htmltools::tags$div(class = paste("sc-download-action", paste0("is-", state)),
    `data-sc-surface` = "download", `data-state` = state,
    htmltools::tags$a(id = output_id, class = "shiny-download-link sc-download-link",
      href = "", download = filename, `aria-disabled` = tolower(as.character(disabled || state != "ready")),
      tabindex = if (disabled || state != "ready") "-1" else "0", label),
    htmltools::tags$span(class = "sc-download-meta", paste(Filter(nzchar, c(filename, file_type, size)), collapse = " \u00b7 ")),
    htmltools::tags$span(class = "sc-download-state", state)))
}

#' Resize-aware analytical output shell
#' @param id Stable shell identifier.
#' @param ... Host-supplied output content.
#' @param title,subtitle Heading copy.
#' @param metadata,status Optional output metadata.
#' @param actions Bounded toolbar action definitions.
#' @param state ready, loading, empty, or error.
#' @param message State message.
#' @param fullscreen,spotlight Enable presentation actions.
#' @export
output_shell <- function(id, ..., title = NULL, subtitle = NULL, metadata = NULL,
    status = NULL, actions = NULL, state = c("ready", "loading", "empty", "error"),
    message = NULL, fullscreen = TRUE, spotlight = TRUE) {
  id <- surface_scalar(id, "id"); state <- match.arg(state)
  built_actions <- c(actions %||% list(),
    if (isTRUE(spotlight)) list(list(id = "spotlight", label = "Focus", kind = "ghost")),
    if (isTRUE(fullscreen)) list(list(id = "fullscreen", label = "Fullscreen", kind = "ghost")))
  surface_tag(htmltools::tags$article(id = id, class = paste("sc-output-shell", paste0("is-", state)),
    `data-sc-surface` = "output-shell", `data-state` = state,
    htmltools::tags$header(class = "sc-output-header",
      htmltools::tags$div(class = "sc-output-heading",
        if (!is.null(title)) htmltools::tags$h2(title),
        if (!is.null(subtitle)) htmltools::tags$p(subtitle),
        if (!is.null(metadata)) htmltools::tags$small(metadata)),
      if (!is.null(status)) htmltools::tags$span(class = "sc-output-status", status),
      if (length(built_actions)) htmltools::tags$div(class = "sc-output-toolbar", surface_actions(built_actions))),
    htmltools::tags$div(class = "sc-output-body",
      if (state == "loading") htmltools::tags$div(class = "sc-output-state", role = "status", message %||% "Loading output...")
      else if (state == "empty") htmltools::tags$div(class = "sc-output-state", message %||% "No output available.")
      else if (state == "error") htmltools::tags$div(class = "sc-output-state", role = "alert", message %||% "Output could not be rendered.")
      else htmltools::tags$div(class = "sc-output-content", ...))))
}

#' Host-neutral report outline
#' @param id Stable component identifier.
#' @param sections List of id, label, status, and level records.
#' @param selected Initially selected section id.
#' @export
report_outline <- function(id, sections, selected = NULL) {
  id <- surface_scalar(id, "id"); selected <- selected %||% sections[[1]]$id
  surface_tag(htmltools::tags$nav(id = id, class = "sc-report-outline", `data-sc-surface` = "report-outline",
    `aria-label` = "Report outline", htmltools::tags$ol(lapply(sections, function(x) htmltools::tags$li(
      `data-level` = x$level %||% 1L, htmltools::tags$button(type = "button", `data-sc-event` = x$id,
        `aria-current` = if (identical(x$id, selected)) "location" else NULL,
        htmltools::tags$span(x$label %||% x$id),
        if (!is.null(x$status)) htmltools::tags$small(x$status)))))))
}

#' Update a browser surface
#' @param session Shiny session.
#' @param id Surface identifier.
#' @param action Bounded update action.
#' @param ... Action payload.
#' @export
update_browser_surface <- function(session = shiny::getDefaultReactiveDomain(), id, action, ...) {
  if (is.null(session)) stop("A Shiny session is required.", call. = FALSE)
  session$sendCustomMessage("shinycapabilities:surface", list(id = session$ns(id), action = action, payload = list(...)))
  invisible(id)
}

#' Update the notification center
#' @inheritParams update_browser_surface
#' @param notifications Notification records.
#' @param mode replace, append, or dismiss.
#' @export
update_notification_center <- function(session = shiny::getDefaultReactiveDomain(), id,
    notifications = list(), mode = c("replace", "append", "dismiss")) {
  update_browser_surface(session, id, "notifications", notifications = notifications, mode = match.arg(mode))
}

#' Run the complete browser surface gallery
#' @param launch.browser Passed to [shiny::runApp()].
#' @export
run_browser_surface_gallery <- function(launch.browser = interactive()) {
  app <- system.file("examples", "browser-surfaces", package = "shinycapabilities")
  if (!nzchar(app)) app <- file.path("inst", "examples", "browser-surfaces")
  shiny::runApp(app, launch.browser = launch.browser)
}
