library(shiny)
library(shinycapabilities)

make_grid_data <- function(n) {
  set.seed(42)
  data.frame(
    row_key = sprintf("transaction-%07d", seq_len(n)),
    date = as.Date("2025-01-01") + sample.int(595L, n, replace = TRUE),
    channel = sample(c("Direct", "Email", "Search", "Social", "Affiliate"), n, replace = TRUE),
    category = sample(sprintf("Category %02d", 1:24), n, replace = TRUE),
    spend = round(stats::rgamma(n, 5, rate = 0.04), 2),
    revenue = round(stats::rgamma(n, 7, rate = 0.025), 2),
    conversion_rate = stats::rbeta(n, 3, 35),
    flagged = sample(c(TRUE, FALSE), n, replace = TRUE, prob = c(0.06, 0.94)),
    stringsAsFactors = FALSE
  )
}

ui <- fluidPage(
  tags$head(tags$style(HTML("body{background:#eef2f6;color:#18212f}.demo-shell{max-width:1500px;margin:0 auto;padding:18px}.demo-controls{display:flex;align-items:end;gap:10px;margin-bottom:10px}.demo-event{padding:10px;border:1px solid #d7dde5;background:#fff;font:12px ui-monospace,monospace;white-space:pre-wrap}"))),
  div(class = "demo-shell",
    h2("AG Grid Community analytical grid"),
    p("Virtualized rows, typed filters, stable identities, bounded Shiny events, and no Enterprise modules."),
    div(class = "demo-controls",
      selectInput("size", "Rows", choices = c("1,000" = 1000L, "10,000" = 10000L, "100,000" = 100000L), selected = 10000L),
      actionButton("replace", "Replace data"),
      actionButton("select", "Select first three")
    ),
    data_grid_output("grid", height = "650px"),
    h3("Latest structured event"),
    div(class = "demo-event", verbatimTextOutput("event"))
  )
)

server <- function(input, output, session) {
  data <- reactiveVal(make_grid_data(10000L))
  observeEvent(input$replace, data(make_grid_data(as.integer(input$size))))
  output$grid <- render_data_grid({
    data_grid(data(), row_id = "row_key", columns = list(
      row_key = list(header_name = "Transaction", pinned = "left", min_width = 170),
      date = list(format = "date", min_width = 130),
      channel = list(), category = list(),
      spend = list(format = "currency", currency = "USD", digits = 2),
      revenue = list(format = "currency", currency = "USD", digits = 2),
      conversion_rate = list(header_name = "Conversion", format = "percent", digits = 1),
      flagged = list(header_name = "Flagged")
    ), options = list(selection = "multiple", density = "compact"), height = "100%")
  })
  observeEvent(input$select, {
    update_data_grid(session, "grid", selected_rows = head(data()$row_key, 3L))
  })
  latest <- reactiveVal("Select or double-click a row.")
  observeEvent(input$grid_selection, latest(jsonlite::toJSON(input$grid_selection, auto_unbox = TRUE, pretty = TRUE)))
  observeEvent(input$grid_action, latest(jsonlite::toJSON(input$grid_action, auto_unbox = TRUE, pretty = TRUE)))
  observeEvent(input$grid_state, latest(jsonlite::toJSON(input$grid_state, auto_unbox = TRUE, pretty = TRUE)))
  output$event <- renderText(latest())
}

shinyApp(ui, server)
