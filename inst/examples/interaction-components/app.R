library(shiny)
library(shinycapabilities)

tree_nodes <- c(
  list(
    list(id = "datasets", label = "Datasets", description = "Available analytical data", badge = "2", children = list(
      list(id = "transactions", label = "Transactions", description = "10,000 rows · 9 columns", status = "Ready", children = list(
        list(id = "date", label = "Date", description = "Date · 2024-01-01 to 2026-08-19", badge = "date"),
        list(id = "channel", label = "Channel", description = "Character · 5 levels", badge = "categorical"),
        list(id = "revenue", label = "Revenue", description = "Numeric · 0 missing", badge = "measure")
      )),
      list(id = "customers", label = "Customers", description = "2,400 rows · 14 columns", status = "Warning")
    )),
    list(id = "artifacts", label = "Artifacts", description = "Generated evidence", badge = "3", children = list(
      list(id = "eda", label = "EDA Report", description = "AutoQuant EDA · ready", status = "Ready"),
      list(id = "importance", label = "Feature Importance", description = "Plot · Model Insights", status = "Ready"),
      list(id = "drift", label = "Drift Diagnostics", description = "Table · 4 warnings", status = "Warning")
    )),
    list(id = "runs", label = "Runs", description = "Execution history", children = lapply(seq_len(2500), function(index) {
      list(id = sprintf("run-%04d", index), label = sprintf("Analysis run %04d", index),
        description = if (index %% 7L) "Completed successfully" else "Completed with warnings",
        status = if (index %% 7L) "Ready" else "Warning",
        metadata = list(run_id = index))
    }))
  )
)

commands <- c(
  list(
    list(id = "open-data", label = "Open Data", group = "Navigate", description = "Inspect the active dataset", shortcut = "G D", keywords = c("dataset", "schema")),
    list(id = "open-artifacts", label = "Open Artifact Library", group = "Navigate", description = "Browse durable analytical evidence", shortcut = "G A", keywords = c("evidence", "outputs")),
    list(id = "run-eda", label = "Run Exploratory Data Analysis", group = "Analyze", description = "Generate a comprehensive EDA artifact collection", keywords = c("autoquant", "profile")),
    list(id = "run-readiness", label = "Run Model Readiness", group = "Analyze", description = "Assess data before model training", keywords = c("target", "leakage")),
    list(id = "export-report", label = "Export Active Report", group = "Export", description = "Render the current report plan", shortcut = "Ctrl E"),
    list(id = "restricted", label = "Publish to Production", group = "Governance", description = "Unavailable in this local demo", disabled = TRUE)
  ),
  lapply(seq_len(1500), function(index) {
    list(id = sprintf("capability-%04d", index), label = sprintf("Capability %04d", index),
      group = sprintf("Catalog %02d", ((index - 1L) %% 12L) + 1L),
      description = "Virtualized catalog entry for scale qualification",
      keywords = c("catalog", sprintf("item-%d", index)), metadata = list(index = index))
  })
)

ui <- fluidPage(
  tags$head(tags$style(HTML("body{background:#eef2f6;color:#18212f}.demo-shell{max-width:1280px;margin:0 auto;padding:22px}.demo-grid{display:grid;grid-template-columns:minmax(0,1fr) minmax(0,1fr);gap:16px}.demo-event{margin-top:12px;padding:10px;border:1px solid #d7dde5;background:#fff;font-family:ui-monospace,monospace;font-size:12px;white-space:pre-wrap}@media(max-width:800px){.demo-grid{grid-template-columns:1fr}}"))),
  div(class = "demo-shell",
    h2("shinycapabilities interaction lab"),
    p("Two host-neutral components using bundled React and TanStack Virtual. No Node.js is required at package runtime."),
    div(class = "demo-grid",
      div(h3("Virtualized hierarchy"), virtual_tree_browser_output("tree", height = "570px")),
      div(h3("Command palette"), command_palette_output("commands", height = "570px"))
    ),
    h3("Event contract"),
    div(class = "demo-event", verbatimTextOutput("events"))
  )
)

server <- function(input, output, session) {
  output$tree <- render_virtual_tree_browser({
    virtual_tree_browser(tree_nodes, expanded = c("datasets", "transactions", "artifacts", "runs"), height = "100%")
  })
  output$commands <- render_command_palette({
    command_palette(commands, server_search = TRUE, height = "100%")
  })
  latest <- reactiveVal("Interact with either component.")
  observeEvent(input$tree_selection, latest(paste("tree_selection", jsonlite::toJSON(input$tree_selection, auto_unbox = TRUE, pretty = TRUE))))
  observeEvent(input$tree_activate, latest(paste("tree_activate", jsonlite::toJSON(input$tree_activate, auto_unbox = TRUE, pretty = TRUE))))
  observeEvent(input$tree_toggle, latest(paste("tree_toggle", jsonlite::toJSON(input$tree_toggle, auto_unbox = TRUE, pretty = TRUE))))
  observeEvent(input$commands_command, latest(paste("commands_command", jsonlite::toJSON(input$commands_command, auto_unbox = TRUE, pretty = TRUE))))
  output$events <- renderText(latest())
}

shinyApp(ui, server)
