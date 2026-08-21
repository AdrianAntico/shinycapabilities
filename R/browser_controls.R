browser_controls_dependency <- function() {
  htmltools::htmlDependency(
    name = "shinycapabilities-browser-controls", version = "1.0.0",
    src = c(file = "www/browser-controls"), package = "shinycapabilities",
    script = "browser-controls.js", stylesheet = "browser-controls.css"
  )
}

browser_control_scalar <- function(value, name) {
  if (length(value) != 1L || is.na(value)) {
    stop(name, " must be a non-missing scalar.", call. = FALSE)
  }
  value
}

browser_control_shell <- function(input_id, label, control, help = NULL,
    error = NULL, required = FALSE, disabled = FALSE, readonly = FALSE,
    class = NULL, attributes = list()) {
  input_id <- browser_control_scalar(as.character(input_id), "input_id")
  label_id <- paste0(input_id, "-label")
  help_id <- paste0(input_id, "-help")
  error_id <- paste0(input_id, "-error")
  described <- paste(c(if (!is.null(help)) help_id, if (!is.null(error)) error_id), collapse = " ")
  control$attribs$id <- paste0(input_id, "-control")
  control$attribs$disabled <- if (isTRUE(disabled)) "disabled" else NULL
  control$attribs$readonly <- if (isTRUE(readonly)) "readonly" else NULL
  control$attribs$required <- if (isTRUE(required)) "required" else NULL
  control$attribs$`aria-labelledby` <- label_id
  control$attribs$`aria-describedby` <- if (nzchar(described)) described else NULL
  control$attribs$`aria-invalid` <- if (!is.null(error)) "true" else NULL
  shell <- do.call(htmltools::tags$div, c(list(
    id = input_id,
    class = paste(c("sc-browser-control", "shiny-input-container", class,
      if (!is.null(error)) "is-invalid"), collapse = " "),
    `data-sc-control` = "true",
    `data-disabled` = tolower(as.character(isTRUE(disabled))),
    `data-readonly` = tolower(as.character(isTRUE(readonly))),
    htmltools::tags$label(id = label_id, `for` = control$attribs$id,
      class = "sc-control-label", label,
      if (isTRUE(required)) htmltools::tags$span(class = "sc-required", `aria-hidden` = "true", " *")),
    control,
    if (!is.null(help)) htmltools::tags$div(id = help_id, class = "sc-control-help", help),
    if (!is.null(error)) htmltools::tags$div(id = error_id, class = "sc-control-error", role = "alert", error)
  ), attributes))
  htmltools::attachDependencies(shell, browser_controls_dependency())
}

#' Browser-native text field
#' @param input_id Shiny input identifier.
#' @param label Accessible label.
#' @param value Initial value.
#' @param placeholder Optional placeholder.
#' @param help,error Optional help and validation text.
#' @param required,disabled,readonly Field states.
#' @param autocomplete Browser autocomplete token.
#' @export
browser_text_field <- function(input_id, label, value = "", placeholder = NULL,
    help = NULL, error = NULL, required = FALSE, disabled = FALSE,
    readonly = FALSE, autocomplete = "off") {
  browser_control_shell(input_id, label,
    htmltools::tags$input(type = "text", class = "sc-control-input",
      value = as.character(value %||% ""), placeholder = placeholder,
      autocomplete = autocomplete), help, error, required, disabled, readonly)
}

#' Browser-native numeric field
#' @inheritParams browser_text_field
#' @param min,max,step Native numeric constraints.
#' @export
browser_numeric_field <- function(input_id, label, value = NULL, min = NULL,
    max = NULL, step = "any", placeholder = NULL, help = NULL, error = NULL,
    required = FALSE, disabled = FALSE, readonly = FALSE) {
  browser_control_shell(input_id, label,
    htmltools::tags$input(type = "number", class = "sc-control-input",
      value = value, min = min, max = max, step = step, placeholder = placeholder),
    help, error, required, disabled, readonly)
}

#' Browser-native secret field
#' @inheritParams browser_text_field
#' @export
browser_secret_field <- function(input_id, label, value = "", placeholder = NULL,
    help = NULL, error = NULL, required = FALSE, disabled = FALSE,
    readonly = FALSE, autocomplete = "current-password") {
  browser_control_shell(input_id, label,
    htmltools::tags$input(type = "password", class = "sc-control-input",
      value = as.character(value %||% ""), placeholder = placeholder,
      autocomplete = autocomplete), help, error, required, disabled, readonly)
}

#' Browser-native multiline field
#' @inheritParams browser_text_field
#' @param rows Initial visible row count.
#' @export
browser_textarea <- function(input_id, label, value = "", rows = 5L,
    placeholder = NULL, help = NULL, error = NULL, required = FALSE,
    disabled = FALSE, readonly = FALSE) {
  browser_control_shell(input_id, label,
    htmltools::tags$textarea(class = "sc-control-input sc-control-textarea",
      rows = max(2L, as.integer(rows)), placeholder = placeholder,
      as.character(value %||% "")), help, error, required, disabled, readonly)
}

browser_binary_control <- function(input_id, label, value, help, disabled,
    variant = c("checkbox", "switch")) {
  variant <- match.arg(variant)
  input_id <- browser_control_scalar(as.character(input_id), "input_id")
  control_id <- paste0(input_id, "-control")
  tag <- htmltools::tags$div(id = input_id,
    class = paste("sc-browser-control sc-binary-control shiny-input-container", paste0("is-", variant)),
    `data-sc-control` = "true", `data-disabled` = tolower(as.character(isTRUE(disabled))),
    htmltools::tags$label(class = "sc-binary-label", `for` = control_id,
      htmltools::tags$input(id = control_id, type = "checkbox",
        role = if (variant == "switch") "switch" else NULL,
        checked = if (isTRUE(value)) "checked" else NULL,
        disabled = if (isTRUE(disabled)) "disabled" else NULL),
      htmltools::tags$span(class = "sc-binary-indicator", `aria-hidden` = "true"),
      htmltools::tags$span(class = "sc-binary-text", label)),
    if (!is.null(help)) htmltools::tags$div(class = "sc-control-help", help))
  htmltools::attachDependencies(tag, browser_controls_dependency())
}

#' Browser-native checkbox
#' @param input_id Shiny input identifier.
#' @param label Accessible label.
#' @param value Initial logical value.
#' @param help Optional help text.
#' @param disabled Disabled state.
#' @export
browser_checkbox <- function(input_id, label, value = FALSE, help = NULL, disabled = FALSE) {
  browser_binary_control(input_id, label, value, help, disabled, "checkbox")
}

#' Browser-native switch
#' @inheritParams browser_checkbox
#' @export
browser_switch <- function(input_id, label, value = FALSE, help = NULL, disabled = FALSE) {
  browser_binary_control(input_id, label, value, help, disabled, "switch")
}

normalize_browser_choices <- function(choices) {
  values <- unname(as.character(choices))
  labels <- names(choices) %||% values
  unname(Map(function(value, label) list(value = value, label = as.character(label)), values, labels))
}

browser_choice_control <- function(input_id, label, choices, selected = NULL,
    help = NULL, error = NULL, disabled = FALSE, segmented = FALSE) {
  input_id <- browser_control_scalar(as.character(input_id), "input_id")
  records <- normalize_browser_choices(choices)
  selected <- as.character(selected %||% (if (length(records)) records[[1L]]$value else ""))
  options <- Map(function(option, index) {
    option_id <- paste0(input_id, "-option-", index)
    htmltools::tags$label(class = "sc-choice-option", `for` = option_id,
      htmltools::tags$input(id = option_id, type = "radio", name = paste0(input_id, "-group"),
        value = option$value, checked = if (identical(option$value, selected)) "checked" else NULL,
        disabled = if (isTRUE(disabled)) "disabled" else NULL),
      htmltools::tags$span(option$label))
  }, records, seq_along(records))
  tag <- htmltools::tags$fieldset(id = input_id,
    class = paste("sc-browser-control sc-choice-control shiny-input-container",
      if (segmented) "is-segmented", if (!is.null(error)) "is-invalid"),
    `data-sc-control` = "true", disabled = if (isTRUE(disabled)) "disabled" else NULL,
    htmltools::tags$legend(class = "sc-control-label", label),
    htmltools::tags$div(class = "sc-choice-options", options),
    if (!is.null(help)) htmltools::tags$div(class = "sc-control-help", help),
    if (!is.null(error)) htmltools::tags$div(class = "sc-control-error", role = "alert", error))
  htmltools::attachDependencies(tag, browser_controls_dependency())
}

#' Browser-native radio group
#' @param input_id,label,choices,selected,help,error,disabled Choice field contract.
#' @export
browser_radio_group <- function(input_id, label, choices, selected = NULL,
    help = NULL, error = NULL, disabled = FALSE) {
  browser_choice_control(input_id, label, choices, selected, help, error, disabled, FALSE)
}

#' Browser-native segmented choice
#' @inheritParams browser_radio_group
#' @export
browser_segmented_control <- function(input_id, label, choices, selected = NULL,
    help = NULL, error = NULL, disabled = FALSE) {
  browser_choice_control(input_id, label, choices, selected, help, error, disabled, TRUE)
}

#' Browser-native range slider
#' @param input_id,label,value,min,max,step,help,disabled Range field contract.
#' @export
browser_slider <- function(input_id, label, value, min, max, step = 1,
    help = NULL, disabled = FALSE) {
  input_id <- browser_control_scalar(as.character(input_id), "input_id")
  control_id <- paste0(input_id, "-control")
  tag <- htmltools::tags$div(id = input_id,
    class = "sc-browser-control sc-range-control shiny-input-container",
    `data-sc-control` = "true", `data-disabled` = tolower(as.character(isTRUE(disabled))),
    htmltools::tags$div(class = "sc-range-header",
      htmltools::tags$label(id = paste0(input_id, "-label"), `for` = control_id,
        class = "sc-control-label", label),
      htmltools::tags$output(class = "sc-range-value", `for` = control_id, value)),
    htmltools::tags$input(id = control_id, type = "range", class = "sc-control-range",
      value = value, min = min, max = max, step = step,
      disabled = if (isTRUE(disabled)) "disabled" else NULL),
    if (!is.null(help)) htmltools::tags$div(class = "sc-control-help", help))
  htmltools::attachDependencies(tag, browser_controls_dependency())
}

#' Browser-native action button
#' @param input_id Shiny input identifier.
#' @param label Button label.
#' @param icon Optional decorative or textual icon tag.
#' @param variant Action hierarchy: primary, secondary, success, danger, or ghost.
#' @param disabled,loading Button states.
#' @param title Optional accessible tooltip text.
#' @export
browser_action_button <- function(input_id, label, icon = NULL,
    variant = c("primary", "secondary", "success", "danger", "ghost"),
    disabled = FALSE, loading = FALSE, title = NULL) {
  variant <- match.arg(variant)
  tag <- htmltools::tags$button(id = input_id, type = "button",
    class = paste("sc-browser-action shiny-bound-input", paste0("is-", variant),
      if (isTRUE(loading)) "is-loading"), `data-sc-action` = "true",
    disabled = if (isTRUE(disabled) || isTRUE(loading)) "disabled" else NULL,
    `aria-busy` = tolower(as.character(isTRUE(loading))), title = title,
    if (isTRUE(loading)) htmltools::tags$span(class = "sc-action-spinner", `aria-hidden` = "true"),
    icon, htmltools::tags$span(label))
  htmltools::attachDependencies(tag, browser_controls_dependency())
}

#' Browser-native action link
#' @inheritParams browser_action_button
#' @export
browser_action_link <- function(input_id, label, icon = NULL, disabled = FALSE,
    title = NULL) {
  browser_action_button(input_id, label, icon, "ghost", disabled, FALSE, title)
}

#' Update a browser-native control
#' @param session Active Shiny session.
#' @param input_id Input identifier.
#' @param ... Bounded control fields such as value, disabled, readonly, error,
#'   label, min, max, or step.
#' @export
update_browser_control <- function(session = shiny::getDefaultReactiveDomain(), input_id, ...) {
  if (is.null(session)) stop("A Shiny session is required.", call. = FALSE)
  session$sendInputMessage(input_id, list(...))
  invisible(NULL)
}

#' Browser-native scalar display
#' @param value Value to display.
#' @param label Optional label.
#' @param description Optional supporting text.
#' @param format Semantic format marker.
#' @export
browser_value_display <- function(value, label = NULL, description = NULL,
    format = c("text", "number", "percent", "currency", "code")) {
  format <- match.arg(format)
  htmltools::attachDependencies(htmltools::tags$div(class = "sc-value-display",
    if (!is.null(label)) htmltools::tags$div(class = "sc-value-label", label),
    htmltools::tags$output(class = paste("sc-value", paste0("is-", format)), value),
    if (!is.null(description)) htmltools::tags$div(class = "sc-value-description", description)),
    browser_controls_dependency())
}

#' Browser-native status badge
#' @param label Badge label.
#' @param status Status tone.
#' @export
browser_status_badge <- function(label, status = c("neutral", "info", "success", "warning", "error")) {
  status <- match.arg(status)
  htmltools::attachDependencies(htmltools::tags$span(class = paste("sc-status-badge", paste0("is-", status)),
    htmltools::tags$span(class = "sc-status-dot", `aria-hidden` = "true"), label),
    browser_controls_dependency())
}

#' Browser-native progress indicator
#' @param value Current value; `NULL` creates indeterminate progress.
#' @param max Maximum value.
#' @param label Accessible label.
#' @param description Optional supporting text.
#' @export
browser_progress <- function(value = NULL, max = 100, label = "Progress", description = NULL) {
  htmltools::attachDependencies(htmltools::tags$div(class = "sc-progress-block",
    htmltools::tags$div(class = "sc-progress-header", htmltools::tags$span(label),
      if (!is.null(value)) htmltools::tags$span(sprintf("%s%%", round(100 * value / max)))),
    htmltools::tags$progress(class = "sc-progress", value = value, max = max,
      `aria-label` = label),
    if (!is.null(description)) htmltools::tags$div(class = "sc-control-help", description)),
    browser_controls_dependency())
}

#' Browser-native inline alert
#' @param title Alert title.
#' @param message Alert message.
#' @param status Alert tone.
#' @export
browser_alert <- function(title, message = NULL,
    status = c("info", "success", "warning", "error")) {
  status <- match.arg(status)
  htmltools::attachDependencies(htmltools::tags$div(
    class = paste("sc-inline-alert", paste0("is-", status)),
    role = if (status == "error") "alert" else "status",
    htmltools::tags$strong(title), if (!is.null(message)) htmltools::tags$div(message)),
    browser_controls_dependency())
}

#' Browser-native loading skeleton
#' @param lines Number of placeholder lines.
#' @param label Accessible loading label.
#' @export
browser_skeleton <- function(lines = 3L, label = "Loading") {
  htmltools::attachDependencies(htmltools::tags$div(class = "sc-skeleton", role = "status",
    `aria-label` = label, htmltools::tags$span(class = "visually-hidden", label),
    lapply(seq_len(max(1L, as.integer(lines))), function(index) {
      htmltools::tags$span(class = "sc-skeleton-line",
        style = if (index == lines) "width:68%" else NULL)
    })), browser_controls_dependency())
}

#' Run the browser controls gallery
#' @param ... Arguments passed to [shiny::runApp()].
#' @export
run_browser_controls_gallery <- function(...) {
  shiny::runApp(system.file("examples", "browser-controls", package = "shinycapabilities"), ...)
}
