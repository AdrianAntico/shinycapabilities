execution_replay_forbidden_keys <- function() {
  c("thinking", "scratchpad", "hidden_reasoning", "chain_of_thought", "cot",
    "tool_trace", "hidden_trace", "raw_prompt", "raw_response", "credentials",
    "credential", "password", "token", "secret")
}

execution_replay_records <- function(x, name) {
  if (is.null(x)) return(list())
  if (is.data.frame(x)) {
    return(lapply(seq_len(nrow(x)), function(i) lapply(x, function(column) column[[i]])))
  }
  if (!is.list(x) || (length(x) && !is.list(x[[1L]]))) {
    stop(name, " must be a data frame or list of records.", call. = FALSE)
  }
  unname(x)
}

execution_replay_scalar <- function(x, field, required = FALSE, default = "") {
  value <- as.character(x %||% default)
  if (!length(value) || (!required && is.na(value))) value <- as.character(default)
  if (length(value) != 1L || is.na(value)) stop(field, " must be a non-missing scalar.", call. = FALSE)
  value <- trimws(value)
  if (required && !nzchar(value)) stop(field, " must be non-empty.", call. = FALSE)
  value
}

execution_replay_metadata <- function(x, max_fields = 24L, depth = 0L) {
  if (is.null(x)) return(list())
  if (!is.list(x)) return(substr(as.character(x)[[1L]], 1L, 1200L))
  if (depth >= 4L) return("[nested metadata omitted]")
  keys <- names(x)
  if (!is.null(keys)) {
    forbidden <- paste(execution_replay_forbidden_keys(), collapse = "|")
    x <- x[!grepl(forbidden, tolower(keys))]
  }
  x <- utils::head(x, max(1L, as.integer(max_fields)))
  lapply(x, execution_replay_metadata, max_fields = max_fields, depth = depth + 1L)
}

execution_replay_sequence <- function(x, field, fallback = NULL) {
  if (is.null(x) || !length(x) || is.na(x)) {
    if (is.null(fallback)) stop(field, " must be supplied.", call. = FALSE)
    return(as.integer(fallback))
  }
  value <- suppressWarnings(as.integer(x[[1L]]))
  if (is.na(value) || value < 0L) stop(field, " must be a non-negative integer.", call. = FALSE)
  value
}

normalize_execution_replay_execution <- function(execution, max_metadata_fields = 24L) {
  if (!is.list(execution)) stop("execution must be a named list.", call. = FALSE)
  list(
    execution_id = execution_replay_scalar(execution$execution_id, "execution_id", TRUE),
    label = execution_replay_scalar(execution$label, "execution label", TRUE),
    type = execution_replay_scalar(execution$type, "execution type", TRUE),
    started_at = execution_replay_scalar(execution$started_at, "execution started_at"),
    ended_at = execution_replay_scalar(execution$ended_at, "execution ended_at"),
    status = execution_replay_scalar(execution$status, "execution status", TRUE),
    source_mode = execution_replay_scalar(execution$source_mode, "source_mode", default = "host_supplied"),
    metadata = execution_replay_metadata(execution$metadata %||% list(), max_metadata_fields)
  )
}

normalize_execution_replay_events <- function(events, max_events = 10000L,
    max_metadata_fields = 24L) {
  records <- execution_replay_records(events, "events")
  result <- lapply(seq_along(records), function(i) {
    x <- records[[i]]
    list(
      event_id = execution_replay_scalar(x$event_id, "event_id", TRUE),
      sequence = execution_replay_sequence(x$sequence, "event sequence", i),
      occurred_at = execution_replay_scalar(x$occurred_at, "event occurred_at"),
      event_type = execution_replay_scalar(x$event_type, "event_type", TRUE),
      actor_id = execution_replay_scalar(x$actor_id, "event actor_id"),
      source = execution_replay_scalar(x$source, "event source"),
      status = execution_replay_scalar(x$status, "event status"),
      summary = execution_replay_scalar(x$summary, "event summary", TRUE),
      entity_ids = unique(as.character(x$entity_ids %||% character())),
      artifact_ids = unique(as.character(x$artifact_ids %||% character())),
      evidence_ids = unique(as.character(x$evidence_ids %||% character())),
      metadata = execution_replay_metadata(x$metadata %||% list(), max_metadata_fields)
    )
  })
  ids <- vapply(result, `[[`, character(1), "event_id")
  if (anyDuplicated(ids)) stop("event_id values must be unique.", call. = FALSE)
  if (length(result)) {
    result <- result[order(vapply(result, `[[`, integer(1), "sequence"),
      vapply(result, `[[`, character(1), "occurred_at"), ids)]
  }
  maximum <- max(1L, as.integer(max_events))
  truncated <- max(0L, length(result) - maximum)
  list(records = utils::tail(result, maximum), truncated = truncated)
}

normalize_execution_replay_snapshots <- function(snapshots, max_metadata_fields = 24L) {
  records <- execution_replay_records(snapshots, "snapshots")
  result <- lapply(seq_along(records), function(i) {
    x <- records[[i]]
    list(
      snapshot_id = execution_replay_scalar(x$snapshot_id, "snapshot_id", TRUE),
      sequence = execution_replay_sequence(x$sequence, "snapshot sequence", i),
      occurred_at = execution_replay_scalar(x$occurred_at, "snapshot occurred_at"),
      entity_id = execution_replay_scalar(x$entity_id, "snapshot entity_id", TRUE),
      state = execution_replay_scalar(x$state, "snapshot state", TRUE),
      version = execution_replay_scalar(x$version, "snapshot version"),
      fingerprint = execution_replay_scalar(x$fingerprint, "snapshot fingerprint"),
      metadata = execution_replay_metadata(x$metadata %||% list(), max_metadata_fields)
    )
  })
  ids <- vapply(result, `[[`, character(1), "snapshot_id")
  if (anyDuplicated(ids)) stop("snapshot_id values must be unique.", call. = FALSE)
  if (length(result)) result <- result[order(vapply(result, `[[`, integer(1), "sequence"), ids)]
  result
}

normalize_execution_replay_related <- function(related_records, max_metadata_fields = 24L) {
  records <- execution_replay_records(related_records, "related_records")
  result <- lapply(seq_along(records), function(i) {
    x <- records[[i]]
    list(
      record_id = execution_replay_scalar(x$record_id, "related record_id", TRUE),
      record_type = execution_replay_scalar(x$record_type, "related record_type", TRUE),
      label = execution_replay_scalar(x$label, "related record label", TRUE),
      sequence = execution_replay_sequence(x$sequence, "related record sequence", i),
      occurred_at = execution_replay_scalar(x$occurred_at, "related record occurred_at"),
      entity_id = execution_replay_scalar(x$entity_id, "related record entity_id"),
      status = execution_replay_scalar(x$status, "related record status"),
      fingerprint = execution_replay_scalar(x$fingerprint, "related record fingerprint"),
      related_ids = unique(as.character(x$related_ids %||% character())),
      metadata = execution_replay_metadata(x$metadata %||% list(), max_metadata_fields)
    )
  })
  ids <- vapply(result, `[[`, character(1), "record_id")
  if (anyDuplicated(ids)) stop("related record_id values must be unique.", call. = FALSE)
  if (length(result)) result <- result[order(vapply(result, `[[`, integer(1), "sequence"), ids)]
  result
}

execution_replay_diagnostics <- function(events, snapshots, related, truncated = 0L) {
  diagnostics <- character()
  known <- unique(c(vapply(snapshots, `[[`, character(1), "entity_id"),
    vapply(related, `[[`, character(1), "record_id"),
    vapply(related, `[[`, character(1), "entity_id")))
  known <- known[nzchar(known)]
  event_refs <- unique(unlist(lapply(events, function(x) c(x$entity_ids, x$artifact_ids, x$evidence_ids))))
  missing <- setdiff(event_refs[nzchar(event_refs)], known)
  if (length(missing)) diagnostics <- c(diagnostics,
    paste(length(missing), "event reference(s) are not represented by supplied snapshots or related records."))
  related_ids <- vapply(related, `[[`, character(1), "record_id")
  invalid_links <- setdiff(unique(unlist(lapply(related, `[[`, "related_ids"))),
    unique(c(related_ids, known)))
  if (length(invalid_links)) diagnostics <- c(diagnostics,
    paste(length(invalid_links), "related-record relationship(s) reference unknown identities."))
  if (truncated > 0L) diagnostics <- c(diagnostics,
    paste(truncated, "oldest event(s) were omitted by max_events."))
  unique(diagnostics)
}

execution_replay_state_at <- function(snapshots, related_records, sequence) {
  sequence <- as.integer(sequence)
  available <- Filter(function(x) x$sequence <= sequence, snapshots)
  entities <- unique(vapply(available, `[[`, character(1), "entity_id"))
  state <- lapply(entities, function(id) {
    candidates <- Filter(function(x) identical(x$entity_id, id), available)
    candidates[[which.max(vapply(candidates, `[[`, integer(1), "sequence"))]]
  })
  list(state = state,
    related = Filter(function(x) x$sequence <= sequence, related_records))
}

execution_replay_model <- function(execution, events, snapshots = NULL,
    related_records = NULL, selected_event_id = NULL, max_events = 10000L,
    max_metadata_fields = 24L, playback_interval = 1000L) {
  execution <- normalize_execution_replay_execution(execution, max_metadata_fields)
  event_result <- normalize_execution_replay_events(events, max_events, max_metadata_fields)
  snapshots <- normalize_execution_replay_snapshots(snapshots, max_metadata_fields)
  related <- normalize_execution_replay_related(related_records, max_metadata_fields)
  event_ids <- vapply(event_result$records, `[[`, character(1), "event_id")
  if (!is.null(selected_event_id) && !as.character(selected_event_id)[[1L]] %in% event_ids) {
    stop("selected_event_id must reference a retained event.", call. = FALSE)
  }
  list(execution = execution, events = event_result$records, snapshots = snapshots,
    relatedRecords = related,
    selectedEventId = if (is.null(selected_event_id)) NULL else as.character(selected_event_id)[[1L]],
    diagnostics = execution_replay_diagnostics(event_result$records, snapshots, related,
      event_result$truncated),
    options = list(maxEvents = max(1L, as.integer(max_events)),
      maxMetadataFields = max(1L, as.integer(max_metadata_fields)),
      playbackInterval = max(250L, as.integer(playback_interval))))
}

#' Read-only execution replay
#'
#' Inspect host-supplied historical events, state snapshots, and related records
#' without executing or mutating work. State-at-time includes only records whose
#' sequence is at or before the selected event.
#'
#' @param execution Named execution record with identity, label, type, status,
#'   optional timestamps, source mode, and bounded metadata.
#' @param events Event records with identity, deterministic sequence, type, and summary.
#' @param snapshots Optional state snapshot records.
#' @param related_records Optional artifact, evidence, failure, retry, intervention,
#'   review, or provenance records.
#' @param selected_event_id Initially selected retained event.
#' @param max_events Maximum events retained in the browser payload.
#' @param max_metadata_fields Maximum metadata fields retained per object and level.
#' @param playback_interval Milliseconds between positions during visual playback.
#' @param width,height Widget dimensions.
#' @param element_id Optional HTML element ID.
#' @export
execution_replay <- function(execution, events, snapshots = NULL,
    related_records = NULL, selected_event_id = NULL, max_events = 10000L,
    max_metadata_fields = 24L, playback_interval = 1000L, width = NULL,
    height = "720px", element_id = NULL) {
  new_direct_component("execution_replay",
    execution_replay_model(execution, events, snapshots, related_records,
      selected_event_id, max_events, max_metadata_fields, playback_interval),
    element_id, width, height)
}

#' @rdname execution_replay
#' @param output_id Shiny output identifier.
#' @export
execution_replay_output <- function(output_id, width = "100%", height = "720px") {
  direct_component_output(output_id, "execution_replay", width, height)
}

#' @rdname execution_replay
#' @param expr Expression returning an execution replay widget.
#' @param env Evaluation environment.
#' @param quoted Whether `expr` is quoted.
#' @export
render_execution_replay <- function(expr, env = parent.frame(), quoted = FALSE) {
  if (!quoted) expr <- substitute(expr)
  render_direct_component(expr, execution_replay_output, env, quoted = TRUE)
}

#' Update an execution replay
#'
#' Replace or append host history. Historical selection is preserved in the
#' browser; new events advance the position only when the user was already at latest.
#'
#' @param session Active Shiny session.
#' @param output_id Replay output identifier.
#' @inheritParams execution_replay
#' @param mode Replace supplied history or append it to existing browser history.
#' @param revision Optional monotonic transport revision.
#' @export
update_execution_replay <- function(session, output_id, execution = NULL,
    events = NULL, snapshots = NULL, related_records = NULL,
    selected_event_id = NULL, mode = c("replace", "append"),
    max_events = 10000L, max_metadata_fields = 24L,
    revision = as.integer(Sys.time())) {
  mode <- match.arg(mode)
  payload <- list(mode = mode,
    maxEvents = max(1L, as.integer(max_events)))
  if (!is.null(execution)) payload$execution <- normalize_execution_replay_execution(execution, max_metadata_fields)
  if (!is.null(events)) payload$events <- normalize_execution_replay_events(events, max_events, max_metadata_fields)$records
  if (!is.null(snapshots)) payload$snapshots <- normalize_execution_replay_snapshots(snapshots, max_metadata_fields)
  if (!is.null(related_records)) payload$relatedRecords <- normalize_execution_replay_related(related_records, max_metadata_fields)
  if (!is.null(selected_event_id)) payload$selectedEventId <- as.character(selected_event_id)[[1L]]
  update_direct_component(session, output_id, "execution_replay", payload, revision)
  invisible(NULL)
}

#' Run the Execution Replay demo
#' @param ... Arguments passed to [shiny::runApp()].
#' @export
run_execution_replay_demo <- function(...) {
  shiny::runApp(system.file("examples", "execution-replay", package = "shinycapabilities"), ...)
}
