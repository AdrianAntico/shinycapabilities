library(shiny)
library(shinycapabilities)

now <- as.POSIXct("2026-08-20 12:00:00", tz = "UTC")
actors <- data.frame(actor_id = c("analyst", "reviewer"), title = c("Analyst", "Reviewer"),
  role_id = c("analysis", "review"), actor_type = c("agent", "human"),
  status = c("running", "waiting"), raw_status = c("RUNNING", "AWAITING_REVIEW"),
  current_work_id = c("work-1", "work-2"),
  last_activity_at = format(now, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"))
work <- list(
  list(work_id = "work-1", label = "Analyze evidence", kind = "job", status = "running",
    raw_status = "RUNNING", actor_id = "analyst", parent_id = "", dependency_ids = character(),
    attention = "none", progress_label = "Reviewing evidence", source_contract = "demo"),
  list(work_id = "work-2", label = "Review finding", kind = "review", status = "waiting",
    raw_status = "AWAITING_REVIEW", actor_id = "reviewer", parent_id = "work-1",
    dependency_ids = "work-1", attention = "needs_review", progress_label = "Waiting",
    source_contract = "demo"))
events <- lapply(1:8, function(i) list(event_id = paste0("event-", i), sequence = i,
  occurred_at = format(now + i, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
  event_type = if (i == 8) "review" else "capability", actor_id = "analyst",
  source = "demo", status = "running", summary = paste("Bounded event", i),
  work_id = "work-1", severity = "info"))
execution <- list(execution_id = "execution-1", label = "Runtime qualification",
  type = "analysis", started_at = format(now, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
  status = "running", source_mode = "demo", metadata = list())
nodes <- list(list(id = "data", label = "Data", type = "dataset", status = "ready"),
  list(id = "artifact", label = "Artifact", type = "artifact", status = "ready"))
edges <- list(list(id = "edge-1", source = "data", target = "artifact", type = "PRODUCES"))

ui <- fluidPage(
  tags$style("body{background:#eef2f6}.runtime-grid{display:grid;grid-template-columns:1fr 1fr;gap:12px}.runtime-card{background:white;padding:10px;min-width:0}"),
  h2("Shared Browser Runtime 1.0"),
  p("One versioned runtime, one transport, lazy component and specialized bundles."),
  actionButton("update", "Update direct components"), actionButton("remount", "Remove/remount direct surfaces"),
  uiOutput("direct_slot"),
  tabsetPanel(
    tabPanel("AG Grid", data_grid_output("grid", height = "420px")),
    tabPanel("Relationship Graph", relationship_graph_output("graph", height = "420px")),
    tabPanel("Agent Monitor", agent_activity_monitor_output("monitor", height = "520px")),
    tabPanel("Execution Replay", execution_replay_output("replay", height = "520px")))
)

server <- function(input, output, session) {
  mounted <- reactiveVal(TRUE); revision <- reactiveVal(1L)
  output$direct_slot <- renderUI({
    if (!mounted()) return(div(id = "direct_removed", "Direct surfaces removed."))
    div(class = "runtime-grid",
      div(class = "runtime-card", h3("Command Palette"), command_palette_direct_output("palette", height = "280px")),
      div(class = "runtime-card", h3("Persistent UI"), persistent_ui_output("persistent", height = "280px")),
      div(class = "runtime-card", style = "grid-column:1/-1", h3("Shared-runtime Split Pane"),
        split_pane_direct_output("split", height = "300px")))
  })
  output$palette <- render_command_palette_direct(command_palette_direct(list(
    list(id = "inspect", label = "Inspect evidence"), list(id = "publish", label = "Publish artifact"))))
  output$persistent <- render_persistent_ui(persistent_ui(list(
    list(id = "summary", type = "section", label = "Runtime summary", children = list(
      list(id = "status", type = "badge", label = "Compatible", status = "success"),
      list(id = "revision", type = "value", label = "Revision", value = revision()),
      list(id = "note", type = "field", label = "Local draft", value = "Preserved"))))))
  output$split <- render_split_pane_direct(split_pane_direct(list(
    overview = div(h4("Overview"), p("Shared React; component-local panel kernel.")),
    detail = div(h4("Detail"), p("Independent resize and teardown."))), sizes = c(55, 45)))
  observeEvent(input$update, {
    revision(revision() + 1L)
    update_command_palette_direct(session, "palette", items = list(
      list(id = "inspect", label = paste("Inspect revision", revision())),
      list(id = "publish", label = "Publish artifact")), revision = revision())
    update_persistent_ui(session, "persistent", list(
      list(id = "summary", type = "section", label = "Runtime summary", children = list(
        list(id = "status", type = "badge", label = "Compatible", status = "success"),
        list(id = "revision", type = "value", label = "Revision", value = revision()),
        list(id = "note", type = "field", label = "Local draft", value = "Preserved")))), revision())
    update_split_pane_direct(session, "split", sizes = c(45, 55), revision = revision())
  })
  observeEvent(input$remount, mounted(!mounted()))
  output$grid <- render_data_grid(data_grid(data.frame(id = 1:20, value = letters[1:20]), row_id = "id"))
  output$graph <- render_relationship_graph(relationship_graph(nodes, edges, show_minimap = FALSE))
  output$monitor <- render_agent_activity_monitor(agent_activity_monitor(actors, work, events,
    summary = list(active = 1L, queued = 1L)))
  output$replay <- render_execution_replay(execution_replay(execution, events, max_events = 100L))
}

shinyApp(ui, server)
