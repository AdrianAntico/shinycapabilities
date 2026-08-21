library(shiny)
library(shinycapabilities)

samples <- list(
  r = "fit <- lm(mpg ~ wt + hp, data = mtcars)\nsummary(fit)",
  julia = "using Statistics\nx = [1, 2, 3]\nmean(x)",
  python = "import statistics\nvalues = [1, 2, 3]\nprint(statistics.mean(values))",
  sql = "SELECT segment, AVG(revenue) AS mean_revenue\nFROM sales\nGROUP BY segment;",
  json = '{\n  "module": "forecasting",\n  "enabled": true\n}',
  yaml = "module: forecasting\nenabled: true",
  markdown = "# Analysis\n\nThe result is ready for review."
)

ui <- fluidPage(
  tags$head(tags$style(HTML("body{background:#f4f6f8}.demo{max-width:1400px;margin:auto;padding:16px}.controls{display:flex;gap:8px;align-items:end;flex-wrap:wrap}.events{max-height:180px;overflow:auto}"))),
  div(class = "demo",
    h2("Monaco Editor 1.0"),
    p("Draft locally, apply explicitly, inspect diagnostics, and compare revisions without a second execution system."),
    div(class = "controls",
      selectInput("language", "Language", names(samples), selected = "r"),
      actionButton("host_update", "Push host update"),
      actionButton("diagnostic", "Set diagnostic"),
      selectInput("stress_lines", "Stress document", c("10,000" = 10000, "50,000" = 50000)),
      actionButton("large", "Load stress document")
    ),
    split_pane("editor_layout",
      editor = div(style = "height:100%;padding:8px", code_editor_output("editor", height = "100%")),
      inspector = div(style = "height:100%;padding:12px;background:#fff", h4("Bounded events"),
        verbatimTextOutput("events")),
      sizes = c(72, 28), min_sizes = c(40, 18), height = "600px"
    ),
    h3("Diff viewer"),
    code_editor_output("diff", height = "360px"),
    h3("Read-only reference"),
    code_editor_output("readonly", height = "260px")
  )
)

server <- function(input, output, session) {
  revision <- reactiveVal(1L)
  document <- reactiveVal(samples$r)
  output$editor <- render_code_editor(code_editor(
    samples$r, "r", document_id = "demo-main", host_revision = 1L,
    title = "Analysis code", completion_enabled = TRUE
  ))
  output$diff <- render_code_editor(code_editor(
    mode = "diff", language = "r", original_value = samples$r,
    modified_value = paste(samples$r, "# Reviewed", sep = "\n"),
    document_id = "demo-diff", title = "Revision comparison"
  ))
  output$readonly <- render_code_editor(code_editor(
    samples$sql, language = "sql", read_only = TRUE,
    document_id = "demo-readonly", title = "Governed SQL reference"
  ))
  observeEvent(input$language, {
    revision(revision() + 1L); document(samples[[input$language]])
    update_code_editor(session, "editor", value = document(), language = input$language,
      host_revision = revision(), revision = revision())
  }, ignoreInit = TRUE)
  observeEvent(input$host_update, {
    revision(revision() + 1L)
    value <- paste(document(), "# Host revision", revision())
    document(value)
    update_code_editor(session, "editor", value = value,
      host_revision = revision(), revision = revision())
  })
  observeEvent(input$diagnostic, update_code_editor(session, "editor", diagnostics = list(
    list(severity = "warning", line = 1L, column = 1L,
      message = "Example host-supplied diagnostic", source = "demo")
  )))
  observeEvent(input$large, {
    revision(revision() + 1L)
    n <- as.integer(if (is.null(input$stress_lines)) 10000L else input$stress_lines)
    value <- paste(sprintf("value_%05d <- %d", seq_len(n), seq_len(n)), collapse = "\n")
    document(value)
    update_code_editor(session, "editor", value = value, language = "r",
      host_revision = revision(), revision = revision())
  })
  observeEvent(input$editor_completion_request, {
    request <- input$editor_completion_request
    update_code_editor(session, "editor", completions = list(
      list(label = "artifact_result", insertText = "artifact_result", kind = "Variable",
        detail = "Host completion", documentation = "A bounded host-supplied completion.")
    ), completion_request_id = request$requestId)
  })
  output$events <- renderPrint(list(
    state = input$editor_state, applied = input$editor_apply,
    conflict = input$editor_conflict, completion = input$editor_completion_request
  ))
}

shinyApp(ui, server)
