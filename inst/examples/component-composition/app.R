library(shiny)
library(shinycapabilities)

actors <- list(list(actor_id = "a1", title = "Analyst", role_id = "analyst",
  actor_type = "agent", status = "running", raw_status = "running"))
work <- list(list(work_id = "w1", label = "Inspect evidence", kind = "task",
  status = "running", actor_id = "a1", dependency_ids = character(),
  attention = "none", source_contract = "fixture"))
events <- list(list(event_id = "e1", occurred_at = "2026-08-20T12:00:00Z",
  event_type = "started", summary = "Inspection started", work_id = "w1",
  actor_id = "a1", severity = "info"))
graph_nodes <- list(list(id = "data", label = "Dataset", type = "dataset", status = "ready"),
  list(id = "artifact", label = "Artifact", type = "artifact", status = "ready"))
graph_edges <- list(list(id = "e1", source = "data", target = "artifact", type = "PRODUCES"))
execution <- list(execution_id = "run-1", label = "Qualification run", type = "analysis",
  status = "running", source_mode = "fixture")
replay_events <- list(list(event_id = "r1", sequence = 1L,
  occurred_at = "2026-08-20T12:00:00Z", event_type = "started", actor_id = "a1",
  source = "fixture", status = "running", summary = "Run started", entity_ids = "run-1"))
tree_nodes <- list(list(id = "root", label = "Artifacts", children = list(
  list(id = "plot", label = "Diagnostic plot"), list(id = "table", label = "Metrics table"))))
commands <- list(list(id = "inspect", label = "Inspect artifact", group = "Artifacts"),
  list(id = "export", label = "Export report", group = "Report"))
workbench_schema <- list(
  list(key = "name", label = "Name", type = "text", default = "analysis", required = TRUE),
  list(key = "iterations", label = "Iterations", type = "integer", default = 100L, min = 1, max = 1000))

ui <- fluidPage(
  tags$style(HTML(".qa-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:12px}.qa-cell{min-height:320px;border:1px solid #ccd3da;padding:8px}.qa-wide{grid-column:1/-1}@media(max-width:900px){.qa-grid{grid-template-columns:1fr}}")),
  h2("Direct component composition qualification"),
  div(class = "qa-actions",
    actionButton("update_components", "Send revisioned updates"),
    actionButton("toggle_monitor", "Remove / reinsert monitor")),
  selection_input("selection", "Artifact", c("Plot", "Table", "Text")),
  div(class = "qa-grid",
    div(class = "qa-cell", virtual_tree_browser_output("tree", height = "300px")),
    div(class = "qa-cell", command_palette_output("palette", height = "300px")),
    div(class = "qa-cell qa-wide", data_grid_output("grid", height = "360px")),
    div(class = "qa-cell", parameter_workbench_ui("parameters", height = "300px")),
    div(class = "qa-cell", persistent_ui_output("persistent", height = "300px")),
    div(class = "qa-cell qa-wide", split_pane("split",
      monitor = uiOutput("dynamic_monitor"),
      inspector = object_inspector_output("inspector", height = "100%"),
      sizes = c(62, 38), height = "580px")),
    div(class = "qa-cell qa-wide", relationship_graph_output("relationships", height = "520px")),
    div(class = "qa-cell qa-wide", execution_replay_output("replay", height = "560px")),
    div(class = "qa-cell qa-wide", code_editor_output("editor", height = "360px")),
    div(class = "qa-cell qa-wide", capability_canvas_output("canvas", height = "480px"))
  )
)

server <- function(input, output, session) {
  monitor_visible <- reactiveVal(TRUE)
  observeEvent(input$toggle_monitor, monitor_visible(!monitor_visible()))
  output$dynamic_monitor <- renderUI({
    if (monitor_visible()) agent_activity_monitor_output("monitor", height = "100%")
  })
  parameter_workbench_server("parameters", workbench_schema)
  output$tree <- render_virtual_tree_browser(virtual_tree_browser(tree_nodes, expanded = "root"))
  output$palette <- render_command_palette(command_palette(commands))
  output$grid <- render_data_grid(data_grid(data.frame(id = 1:100, metric = seq_len(100),
    status = rep(c("ready", "warning"), 50)), row_id = "id"))
  output$persistent <- render_persistent_ui(persistent_ui(list(
    list(id = "summary", type = "section", label = "Summary", children = list(
      list(id = "status", type = "badge", label = "Status", value = "Ready", status = "success"))))))
  output$monitor <- render_agent_activity_monitor(agent_activity_monitor(actors, work, events))
  output$inspector <- render_object_inspector(object_inspector(list(run = execution,
    evidence = list(id = "ev-1", status = "ready")), expanded_paths = ""))
  output$relationships <- render_relationship_graph(relationship_graph(graph_nodes, graph_edges))
  output$replay <- render_execution_replay(execution_replay(execution, replay_events))
  output$editor <- render_code_editor(code_editor("summary(data)", language = "r"))
  output$canvas <- render_capability_canvas(capability_canvas(default_capability_catalog()))
  observeEvent(input$update_components, {
    revision <- as.integer(input$update_components)
    update_data_grid(session, "grid", quick_filter = "ready", revision = revision)
    update_agent_activity_monitor(session, "monitor",
      summary = list(active = revision, queued = 0L), revision = revision)
    update_relationship_graph(session, "relationships",
      selected_id = "artifact", revision = revision)
    update_execution_replay(session, "replay",
      selected_event_id = "r1", revision = revision)
  })
}

shinyApp(ui, server)
