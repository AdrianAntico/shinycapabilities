library(shiny)
library(shinycapabilities)

examples <- list(
  diagnostics = list(model = list(id = "m-42", type = "binary", fitted_at = as.POSIXct("2026-08-20 12:30:00", tz = "UTC")),
    metrics = list(auc = 0.9134, logloss = 0.281, converged = TRUE),
    warnings = c("Sparse segment: west", "Calibration drift detected")),
  artifact = list(artifact_id = "plot-17", artifact_type = "plot", section = "Model Diagnostics",
    provenance = list(generator = "model_assessment", evidence_ids = c("ev-1", "ev-2")), visible = TRUE),
  configuration = list(module = "forecasting", parameters = list(horizon = 12L, frequency = "month",
    regressors = c("spend", "clicks")), enabled = TRUE, note = NA_character_),
  redacted = list(session_id = "s-123", user = "analyst", api_token = "MUST_NOT_REACH_BROWSER",
    nested = list(password = "MUST_NOT_REACH_BROWSER", safe = "visible"))
)
large_object <- function(n) setNames(as.list(seq_len(n)), sprintf("field_%05d", seq_len(n)))

ui <- fluidPage(
  tags$head(tags$style(HTML("body{background:#f4f6f8}.demo{max-width:1400px;margin:auto;padding:16px}.controls{display:flex;gap:8px;align-items:end;flex-wrap:wrap}.pane{height:100%;padding:8px;background:#fff}"))),
  div(class = "demo", h2("Structured Object Inspector 1.0"),
    p("A persistent, typed, redaction-safe projection over host-owned structured data."),
    div(class = "controls", selectInput("scenario", "Object", names(examples)),
      actionButton("replace", "Replace object"), actionButton("patch", "Patch metric"),
      actionButton("focus", "Focus /metrics/auc"),
      selectInput("stress", "Stress nodes", c("1,000" = 1000, "10,000" = 10000, "50,000" = 50000)),
      actionButton("load_stress", "Load stress object")),
    split_pane("layout",
      inspector = div(class = "pane", object_inspector_output("inspector", height = "100%")),
      events = div(class = "pane", h4("Bounded events"), verbatimTextOutput("events")),
      sizes = c(72, 28), min_sizes = c(40, 18), height = "640px"),
    h3("Empty and error states"),
    fluidRow(column(6, object_inspector_output("empty", height = "220px")),
      column(6, object_inspector_output("error", height = "220px")))
  )
)

server <- function(input, output, session) {
  revision <- reactiveVal(1L)
  output$inspector <- render_object_inspector(object_inspector(examples$diagnostics,
    expanded_paths = c("", "/model", "/metrics"), title = "Analytical object", revision = 1L))
  output$empty <- render_object_inspector(object_inspector(state = "empty", message = "Select an object to inspect."))
  output$error <- render_object_inspector(object_inspector(state = "error", message = "The supplied object could not be loaded."))
  observeEvent(input$replace, {
    revision(revision() + 1L)
    update_object_inspector(session, "inspector", examples[[input$scenario]], revision = revision())
  })
  observeEvent(input$patch, {
    revision(revision() + 1L)
    update_object_inspector(session, "inspector", patches = list(
      list(operation = "set", path = "/metrics/auc", value = 0.947)
    ), revision = revision())
  })
  observeEvent(input$focus, {
    revision(revision() + 1L)
    update_object_inspector(session, "inspector", focus_path = "/metrics/auc", revision = revision())
  })
  observeEvent(input$load_stress, {
    revision(revision() + 1L)
    update_object_inspector(session, "inspector", large_object(as.integer(input$stress)),
      max_nodes = 50001L, revision = revision())
  })
  output$events <- renderPrint(list(selection = input$inspector_selection,
    copy = input$inspector_copy))
}

shinyApp(ui, server)
