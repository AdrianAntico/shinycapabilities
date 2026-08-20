library(shiny)
library(shinycapabilities)

base_time <- as.POSIXct("2026-08-20 09:00:00", tz = "UTC")
event_kinds <- c("started", "capability", "evidence", "artifact", "state_transition",
  "failure", "intervention", "retry", "review", "completed")

make_history <- function(n = 36L) {
  events <- lapply(seq_len(n), function(i) {
    kind <- if (n <= 50L) event_kinds[pmin(length(event_kinds),
      ceiling(i / max(1, n / length(event_kinds))))] else event_kinds[(i - 1L) %% length(event_kinds) + 1L]
    list(event_id = sprintf("event-%05d", i), sequence = i,
      occurred_at = format(base_time + i * if (n > 100L) 2 else 45, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
      event_type = kind, actor_id = c("investigator", "validator", "reviewer")[(i - 1L) %% 3L + 1L],
      source = c("analysis", "validation", "human_review")[(i - 1L) %% 3L + 1L],
      status = if (kind == "failure") "failed" else if (kind == "completed") "completed" else "running",
      summary = switch(kind, started = "Execution started", capability = "Analytical capability completed",
        evidence = "Evidence record produced", artifact = "Report artifact produced",
        state_transition = "Workflow state advanced", failure = "Validation failed on sparse segment",
        intervention = "Human supplied a bounded correction", retry = "Validation retried with corrected input",
        review = "Reviewer accepted the corrected evidence", completed = "Execution completed"),
      entity_ids = "workflow:demo", artifact_ids = if (kind == "artifact") paste0("artifact:", i) else character(),
      evidence_ids = if (kind == "evidence") paste0("evidence:", i) else character(),
      metadata = list(stage = kind, secret = "removed"))
  })
  snapshot_points <- unique(pmax(1L, round(seq(1L, n, length.out = min(8L, n)))))
  snapshots <- lapply(seq_along(snapshot_points), function(i) list(
    snapshot_id = paste0("snapshot-", i), sequence = snapshot_points[[i]],
    occurred_at = events[[snapshot_points[[i]]]]$occurred_at, entity_id = "workflow:demo",
    state = c("queued", "running", "investigating", "validating", "blocked", "retrying", "reviewing", "completed")[[pmin(i, 8L)]],
    version = paste0("v", i), fingerprint = sprintf("sha256:%08x", i * 101L),
    metadata = list(stage_index = i)))
  related <- list(
    list(record_id = "evidence:profile", record_type = "evidence", label = "Data profile", sequence = max(2L, round(n * .2)), status = "ready", entity_id = "workflow:demo", fingerprint = "ev-001"),
    list(record_id = "failure:sparse", record_type = "failure", label = "Sparse segment validation", sequence = max(3L, round(n * .55)), status = "failed", entity_id = "workflow:demo", related_ids = "evidence:profile"),
    list(record_id = "intervention:1", record_type = "intervention", label = "Human correction", sequence = max(4L, round(n * .65)), status = "supplied", entity_id = "workflow:demo", related_ids = "failure:sparse"),
    list(record_id = "review:1", record_type = "review", label = "Evidence review", sequence = max(5L, round(n * .82)), status = "accepted", entity_id = "workflow:demo", related_ids = c("intervention:1", "evidence:profile")),
    list(record_id = "artifact:report", record_type = "artifact", label = "Completed analytical report", sequence = n, status = "ready", entity_id = "workflow:demo", related_ids = "review:1", fingerprint = "artifact-final"))
  list(events = events, snapshots = snapshots, related = related)
}

execution <- list(execution_id = "execution-demo", label = "Revenue investigation",
  type = "analytical_workflow", started_at = format(base_time, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
  ended_at = format(base_time + 36 * 45, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
  status = "completed", source_mode = "synthetic_demo", metadata = list(project = "Replay QA"))

ui <- fluidPage(tags$head(tags$style(HTML("body{background:#eef2f6}.demo{max-width:1550px;margin:auto;padding:14px}.panel{height:100%;background:#fff;padding:8px}"))),
  div(class = "demo", h2("Execution Replay 1.0"),
    p("Read-only historical projection. Playback changes visualization position only."),
    div(style = "display:flex;gap:8px;margin-bottom:8px",
      actionButton("append", "Append live event"), actionButton("stress", "Load 5,000 events"),
      actionButton("restore", "Restore narrative")),
    tabsetPanel(
      tabPanel("Standalone", execution_replay_output("replay", height = "760px")),
      tabPanel("Shared host records", split_pane("shared",
        replay = div(class = "panel", execution_replay_output("replay_composed", height = "100%")),
        records = div(class = "panel", h4("Same host event records"), data_grid_output("ledger", height = "100%")),
        sizes = c(70, 30), min_sizes = c(45, 20), height = "760px")),
      tabPanel("Intents", verbatimTextOutput("intents")))))

server <- function(input, output, session) {
  state <- reactiveValues(history = make_history(), live = 0L)
  replay_widget <- reactive(execution_replay(execution, state$history$events,
    state$history$snapshots, state$history$related, max_events = 10000L, height = "100%"))
  output$replay <- render_execution_replay(replay_widget())
  output$replay_composed <- render_execution_replay(replay_widget())
  output$ledger <- render_data_grid({
    events <- state$history$events
    data_grid(data.frame(sequence = vapply(events, `[[`, integer(1), "sequence"),
      event_id = vapply(events, `[[`, character(1), "event_id"),
      type = vapply(events, `[[`, character(1), "event_type"),
      summary = vapply(events, `[[`, character(1), "summary")), row_id = "event_id", height = "100%")
  })
  observeEvent(input$append, {
    state$live <- state$live + 1L
    sequence <- length(state$history$events) + 1L
    event <- list(event_id = paste0("live-", state$live), sequence = sequence,
      occurred_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
      event_type = "artifact", actor_id = "investigator", source = "live_demo",
      status = "completed", summary = paste("New host event", state$live),
      artifact_ids = paste0("artifact:live-", state$live))
    state$history$events <- c(state$history$events, list(event))
    update_execution_replay(session, "replay", events = list(event), mode = "append")
    update_execution_replay(session, "replay_composed", events = list(event), mode = "append")
  })
  observeEvent(input$stress, { state$history <- make_history(5000L) })
  observeEvent(input$restore, { state$history <- make_history() })
  output$intents <- renderPrint(list(position = input$replay_position,
    event = input$replay_event_selection, entity = input$replay_entity_selection,
    latest = input$replay_return_to_latest))
}

shinyApp(ui, server)
