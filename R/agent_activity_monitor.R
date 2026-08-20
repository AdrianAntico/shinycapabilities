agent_activity_monitor_statuses <- function() {
  c("idle", "queued", "ready", "planning", "running", "waiting",
    "awaiting_human", "paused", "completed", "warning", "blocked",
    "failed", "interrupted", "cancelled", "cancelling", "skipped", "replaying")
}

agent_activity_monitor_forbidden_keys <- function() {
  c("thinking", "scratchpad", "hidden_reasoning", "chain_of_thought", "cot",
    "tool_trace", "hidden_trace", "raw_prompt", "raw_response", "credentials", "secret")
}

agent_activity_records <- function(x, name) {
  if (is.null(x)) return(list())
  if (is.data.frame(x)) {
    return(lapply(seq_len(nrow(x)), function(i) lapply(x, function(column) column[[i]])))
  }
  if (!is.list(x)) stop(name, " must be a data frame or list of records.", call. = FALSE)
  if (length(x) && !is.list(x[[1L]])) stop(name, " must contain record-like lists.", call. = FALSE)
  unname(x)
}

agent_activity_scalar <- function(x, field, required = FALSE, default = "") {
  value <- as.character(x %||% default)
  if (!length(value) || (!required && is.na(value))) value <- as.character(default)
  if (length(value) != 1L || is.na(value)) stop(field, " must be a non-missing scalar.", call. = FALSE)
  if (required && !nzchar(trimws(value))) stop(field, " must be non-empty.", call. = FALSE)
  value
}

agent_activity_redact <- function(x) {
  if (!is.list(x)) return(x)
  if (!is.null(names(x))) {
    pattern <- paste(agent_activity_monitor_forbidden_keys(), collapse = "|")
    keep <- !grepl(pattern, tolower(names(x)), fixed = FALSE)
    x <- x[keep]
  }
  lapply(x, agent_activity_redact)
}

normalize_agent_activity_actors <- function(actors) {
  records <- agent_activity_records(actors, "actors")
  result <- lapply(records, function(x) {
    id <- agent_activity_scalar(x$actor_id, "actor_id", TRUE)
    status <- agent_activity_scalar(x$status, "actor status", TRUE)
    if (!status %in% agent_activity_monitor_statuses()) stop("Unsupported actor status: ", status, call. = FALSE)
    type <- agent_activity_scalar(x$actor_type, "actor_type", TRUE)
    if (!type %in% c("agent", "reviewer", "adjudicator", "human", "service")) {
      stop("Unsupported actor_type: ", type, call. = FALSE)
    }
    list(actor_id = id, title = agent_activity_scalar(x$title, "actor title", TRUE),
      role_id = agent_activity_scalar(x$role_id, "role_id", TRUE), actor_type = type,
      status = status, raw_status = agent_activity_scalar(x$raw_status, "raw_status", default = status),
      current_work_id = agent_activity_scalar(x$current_work_id, "current_work_id"),
      last_activity_at = agent_activity_scalar(x$last_activity_at, "last_activity_at"),
      metadata = agent_activity_redact(x$metadata %||% list()))
  })
  ids <- vapply(result, `[[`, character(1), "actor_id")
  if (anyDuplicated(ids)) stop("actor_id values must be unique.", call. = FALSE)
  result
}

normalize_agent_activity_work <- function(work_items, actor_ids = character()) {
  records <- agent_activity_records(work_items, "work_items")
  result <- lapply(records, function(x) {
    id <- agent_activity_scalar(x$work_id, "work_id", TRUE)
    status <- agent_activity_scalar(x$status, "work status", TRUE)
    if (!status %in% agent_activity_monitor_statuses()) stop("Unsupported work status: ", status, call. = FALSE)
    actor_id <- agent_activity_scalar(x$actor_id, "actor_id")
    list(work_id = id, label = agent_activity_scalar(x$label, "work label", TRUE),
      kind = agent_activity_scalar(x$kind, "work kind", TRUE), status = status,
      raw_status = agent_activity_scalar(x$raw_status, "raw_status", default = status),
      actor_id = actor_id, parent_id = agent_activity_scalar(x$parent_id, "parent_id"),
      dependency_ids = unique(as.character(x$dependency_ids %||% character())),
      attention = agent_activity_scalar(x$attention, "attention", default = "none"),
      progress_label = agent_activity_scalar(x$progress_label, "progress_label"),
      progress_value = if (is.null(x$progress_value) || is.na(x$progress_value)) NULL else as.numeric(x$progress_value),
      capability_id = agent_activity_scalar(x$capability_id, "capability_id"),
      started_at = agent_activity_scalar(x$started_at, "started_at"),
      updated_at = agent_activity_scalar(x$updated_at, "updated_at"),
      ended_at = agent_activity_scalar(x$ended_at, "ended_at"),
      error_summary = agent_activity_scalar(x$error_summary, "error_summary"),
      retry_safe = if (is.null(x$retry_safe) || is.na(x$retry_safe)) NULL else isTRUE(x$retry_safe),
      output_ids = unique(as.character(x$output_ids %||% character())),
      source_contract = agent_activity_scalar(x$source_contract, "source_contract", TRUE),
      authority_ref = agent_activity_scalar(x$authority_ref, "authority_ref"),
      metadata = agent_activity_redact(x$metadata %||% list()))
  })
  ids <- vapply(result, `[[`, character(1), "work_id")
  if (anyDuplicated(ids)) stop("work_id values must be unique.", call. = FALSE)
  diagnostics <- character()
  for (i in seq_along(result)) {
    item <- result[[i]]
    if (!is.null(actor_ids) && nzchar(item$actor_id) && !item$actor_id %in% actor_ids) diagnostics <- c(diagnostics,
      paste("Unknown actor reference", item$actor_id, "on", item$work_id))
    if (nzchar(item$parent_id) && (!item$parent_id %in% ids || identical(item$parent_id, item$work_id))) {
      diagnostics <- c(diagnostics, paste("Invalid parent reference", item$parent_id, "on", item$work_id))
      result[[i]]$parent_id <- ""
    }
    invalid <- setdiff(item$dependency_ids, ids)
    self <- item$work_id %in% item$dependency_ids
    if (length(invalid) || self) diagnostics <- c(diagnostics,
      paste("Invalid dependency reference on", item$work_id))
    result[[i]]$dependency_ids <- setdiff(intersect(item$dependency_ids, ids), item$work_id)
    if (!is.null(item$progress_value) && (!is.finite(item$progress_value) || item$progress_value < 0 || item$progress_value > 1)) {
      stop("progress_value must be between 0 and 1 when supplied.", call. = FALSE)
    }
  }
  list(records = result, diagnostics = unique(diagnostics))
}

normalize_agent_activity_events <- function(events, max_events = 500L) {
  records <- agent_activity_records(events, "events")
  result <- lapply(records, function(x) list(
    event_id = agent_activity_scalar(x$event_id, "event_id", TRUE),
    occurred_at = agent_activity_scalar(x$occurred_at, "occurred_at", TRUE),
    event_type = agent_activity_scalar(x$event_type, "event_type", TRUE),
    summary = agent_activity_scalar(x$summary, "event summary", TRUE),
    work_id = agent_activity_scalar(x$work_id, "work_id"),
    actor_id = agent_activity_scalar(x$actor_id, "actor_id"),
    severity = agent_activity_scalar(x$severity, "severity", default = "info"),
    evidence_ids = unique(as.character(x$evidence_ids %||% character())),
    output_ids = unique(as.character(x$output_ids %||% character())),
    metadata = agent_activity_redact(x$metadata %||% list())
  ))
  ids <- vapply(result, `[[`, character(1), "event_id")
  if (anyDuplicated(ids)) stop("event_id values must be unique.", call. = FALSE)
  if (length(result)) {
    ordering <- order(vapply(result, `[[`, character(1), "occurred_at"), ids)
    result <- result[ordering]
  }
  utils::tail(result, max(0L, as.integer(max_events)))
}

normalize_agent_activity_summary <- function(summary) {
  if (is.null(summary)) return(list())
  if (!is.list(summary)) stop("summary must be a named list.", call. = FALSE)
  allowed <- c("active", "queued", "blocked", "failed", "awaiting_review", "completed",
    "throughput", "median_latency", "token_total", "cost_total")
  unknown <- setdiff(names(summary), allowed)
  if (length(unknown)) stop("Unsupported summary field: ", unknown[[1L]], call. = FALSE)
  summary
}

agent_activity_monitor_model <- function(actors, work_items, events = NULL,
    summary = NULL, selected_work_id = NULL, views = c("overview", "activity", "topology"),
    max_events = 500L) {
  actors <- normalize_agent_activity_actors(actors)
  work <- normalize_agent_activity_work(work_items,
    vapply(actors, `[[`, character(1), "actor_id"))
  views <- match.arg(views, c("overview", "activity", "topology"), several.ok = TRUE)
  list(actors = actors, workItems = work$records,
    events = normalize_agent_activity_events(events, max_events),
    summary = normalize_agent_activity_summary(summary),
    selectedWorkId = if (is.null(selected_work_id)) NULL else as.character(selected_work_id)[[1L]],
    diagnostics = work$diagnostics,
    options = list(views = unique(views), maxEvents = max(0L, as.integer(max_events))))
}

#' Read-only agent activity monitor
#'
#' Render host-supplied governed actors, work items, events, attention state,
#' and real dependency relationships. The widget never executes or mutates work.
#' It emits `<outputId>_selection`, `<outputId>_navigation`, and
#' `<outputId>_view_state` intents only.
#'
#' @param actors Actor records following the normalized monitor contract.
#' @param work_items Work records following the normalized monitor contract.
#' @param events Optional bounded event records.
#' @param summary Optional host-computed summary values.
#' @param selected_work_id Initially selected work identity.
#' @param views Enabled views: `overview`, `activity`, and/or `topology`.
#' @param max_events Maximum events retained in the browser payload.
#' @param width,height Widget dimensions.
#' @param element_id Optional HTML element ID.
#' @export
agent_activity_monitor <- function(actors, work_items, events = NULL, summary = NULL,
    selected_work_id = NULL, views = c("overview", "activity", "topology"),
    max_events = 500L, width = NULL, height = "640px", element_id = NULL) {
  htmlwidgets::createWidget("agent_activity_monitor",
    json_object_payload(agent_activity_monitor_model(actors, work_items, events,
      summary, selected_work_id, views, max_events)), width = width, height = height,
    package = "shinycapabilities", elementId = element_id)
}

#' @rdname agent_activity_monitor
#' @param output_id Shiny output identifier.
#' @export
agent_activity_monitor_output <- function(output_id, width = "100%", height = "640px") {
  htmlwidgets::shinyWidgetOutput(output_id, "agent_activity_monitor", width, height,
    package = "shinycapabilities")
}

#' @rdname agent_activity_monitor
#' @param expr Expression returning a monitor widget.
#' @param env Evaluation environment.
#' @param quoted Whether `expr` is quoted.
#' @export
render_agent_activity_monitor <- function(expr, env = parent.frame(), quoted = FALSE) {
  if (!quoted) expr <- substitute(expr)
  htmlwidgets::shinyRenderWidget(expr, agent_activity_monitor_output, env, quoted = TRUE)
}

#' Update an agent activity monitor
#'
#' Replaces only supplied projections and preserves browser selection/view state
#' where possible. Namespacing is applied through `session`.
#'
#' @param session Active Shiny session.
#' @param output_id Monitor output identifier.
#' @inheritParams agent_activity_monitor
#' @export
update_agent_activity_monitor <- function(session, output_id, actors = NULL,
    work_items = NULL, events = NULL, summary = NULL, selected_work_id = NULL,
    max_events = 500L) {
  message <- list(id = session$ns(output_id), maxEvents = max(0L, as.integer(max_events)))
  actor_records <- if (is.null(actors)) NULL else normalize_agent_activity_actors(actors)
  if (!is.null(actor_records)) message$actors <- actor_records
  if (!is.null(work_items)) {
    actor_ids <- if (is.null(actor_records)) NULL else
      vapply(actor_records, `[[`, character(1), "actor_id")
    normalized <- normalize_agent_activity_work(work_items, actor_ids)
    message$workItems <- normalized$records
    message$diagnostics <- normalized$diagnostics
  }
  if (!is.null(events)) message$events <- normalize_agent_activity_events(events, max_events)
  if (!is.null(summary)) message$summary <- normalize_agent_activity_summary(summary)
  if (!is.null(selected_work_id)) message$selectedWorkId <- as.character(selected_work_id)[[1L]]
  session$sendCustomMessage("shinycapabilities:agent-activity-monitor:update", message)
  invisible(NULL)
}

#' Run the Agent Activity Monitor demo
#' @param ... Arguments passed to [shiny::runApp()].
#' @export
run_agent_activity_monitor_demo <- function(...) {
  shiny::runApp(system.file("examples", "agent-activity-monitor", package = "shinycapabilities"), ...)
}
