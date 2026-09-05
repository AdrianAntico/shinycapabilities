foundation_dependency <- function() {
  htmltools::htmlDependency("shinycapabilities-foundation", "0.3.0",
    src = c(file = "www/foundation"), package = "shinycapabilities",
    script = "foundation.js", stylesheet = "foundation.css")
}

#' Compose named application regions without owning application state
#' @param id Stable frame identifier, namespaced by the caller when appropriate.
#' @param work Main work area, containing ordinary Shiny tags or outputs.
#' @param header,navigation,context,inspector,parameters,output,actions,status Optional regions.
#' @param theme Presentation theme: auto inherits Bootstrap variables; light/dark are explicit.
#' @param density Presentation spacing only: comfortable, compact, or dense.
#' @param tokens Named CSS custom-property overrides, such as `c("--sc-primary" = "#146b52")`.
#' @param commands List of [command_record()] values. Invocation is not authorization.
#' @return A Shiny tag with named regions, token scope, and a shared overlay root.
#' @details The frame is not a router, state store, scheduler, or session manager.
#'   All commands remain inspectable via `ShinyCapabilitiesFoundation.commands(id)`.
#'   Invocations publish `input[[paste0(id, "_command")]]`; hosts must authorize them.
#' @examples
#' application_frame("app", work = browser_text_field("name", "Name"),
#'   status = "Ready", density = "compact")
#' @export
application_frame <- function(id, work, header = NULL, navigation = NULL,
    context = NULL, inspector = NULL, parameters = NULL, output = NULL,
    actions = NULL, status = NULL, theme = c("auto", "light", "dark"),
    density = c("compact", "comfortable", "dense"), tokens = NULL, commands = list()) {
  id <- browser_control_scalar(as.character(id), "id")
  theme <- match.arg(theme); density <- match.arg(density)
  if (length(tokens) && (is.null(names(tokens)) ||
      any(!grepl("^--sc-[a-z0-9-]+$", names(tokens))) ||
      any(grepl("[;{}<>]", tokens)))) stop("Invalid token overrides.", call. = FALSE)
  if (length(commands) && !all(vapply(commands, inherits, logical(1), "sc_command_record")))
    stop("commands must contain command_record values.", call. = FALSE)
  ids <- vapply(commands, `[[`, character(1), "id")
  if (anyDuplicated(ids)) stop("Command ids must be unique.", call. = FALSE)
  regions <- list(header = header, navigation = navigation, context = context,
    work = work, inspector = inspector, parameters = parameters, output = output,
    actions = actions, status = status)
  regions <- Map(function(content, name) {
    if (is.null(content)) return(NULL)
    htmltools::tags$div(class = paste("sc-region", paste0("sc-region-", name)),
      `data-sc-region` = name, content)
  }, regions, names(regions))
  htmltools::attachDependencies(htmltools::tags$div(id = id,
    class = "sc-application-frame", `data-sc-theme` = theme, `data-sc-density` = density,
    style = if (length(tokens)) paste(paste(names(tokens), tokens, sep = ":"), collapse = ";"),
    regions, htmltools::tags$div(class = "sc-overlay-layer", `data-sc-overlay-layer` = "true"),
    htmltools::tags$script(type = "application/json", `data-sc-commands` = "true",
      htmltools::HTML(gsub("<", "\\u003c", jsonlite::toJSON(unname(commands),
        auto_unbox = TRUE, null = "null"), fixed = TRUE)))),
    foundation_dependency())
}

#' Update frame presentation without changing application state
#' @param session Active Shiny session.
#' @param id Frame identifier.
#' @param theme,density Optional presentation settings accepted by [application_frame()].
#' @return Invisibly sends a presentation-only message.
#' @export
update_application_frame <- function(session = shiny::getDefaultReactiveDomain(), id,
    theme = NULL, density = NULL) {
  if (!is.null(theme)) theme <- match.arg(theme, c("auto", "light", "dark"))
  if (!is.null(density)) density <- match.arg(density, c("comfortable", "compact", "dense"))
  session$sendCustomMessage("shinycapabilities:frame", list(id = session$ns(id),
    theme = theme, density = density))
}

#' A host-neutral command record
#' @param id Stable command identity.
#' @param label Human-readable label; never replaces `id`.
#' @param description Optional explanation.
#' @param source Origin identifier supplied by the host.
#' @param enabled Availability, not execution authority.
#' @param disabled_reason Explanation retained even when the command is disabled.
#' @param group,priority,shortcut Presentation/discovery metadata.
#' @param payload Structured host payload.
#' @return A plain list with class `sc_command_record`, usable in a palette or frame.
#' @examples
#' command_record("inspect", "Inspect record", payload = list(record_id = "a"))
#' @export
command_record <- function(id, label, description = NULL, source = "host", enabled = TRUE,
    disabled_reason = NULL, group = "Commands", priority = 100, shortcut = NULL, payload = list()) {
  id <- browser_control_scalar(as.character(id), "id")
  if (!nzchar(id)) stop("id must not be empty.", call. = FALSE)
  label <- browser_control_scalar(as.character(label), "label")
  if (!is.list(payload)) stop("payload must be a list.", call. = FALSE)
  structure(list(id = id, label = label, description = description, source = source,
    enabled = isTRUE(enabled), disabled = !isTRUE(enabled), disabled_reason = disabled_reason,
    group = group, priority = priority, shortcut = shortcut, payload = payload,
    metadata = list(source = source, payload = payload, disabled_reason = disabled_reason)),
    class = c("sc_command_record", "list"))
}

#' Present a command without authorizing or executing it
#' @param command A [command_record()].
#' @return A button that emits a structured invocation through its enclosing frame.
#' @export
command_button <- function(command) {
  stopifnot(inherits(command, "sc_command_record"))
  htmltools::tags$button(type = "button", class = "sc-action-button",
    `data-sc-command` = command$id, disabled = if (!command$enabled) "disabled",
    title = command$disabled_reason %||% command$description, command$label)
}
