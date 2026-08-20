library(shiny)
library(shinycapabilities)

make_items <- function(n = 1000L, version = 1L) lapply(seq_len(n), function(i) list(
  id = paste0("command_", i), label = paste("Command", i, "v", version),
  group = paste("Group", 1L + (i - 1L) %% 12L), description = paste("Direct transport command", i),
  keywords = c("analysis", paste0("item", i)), metadata = list(index = i)
))

ui <- fluidPage(titlePanel("Direct Component Transport 1.0"),
  fluidRow(column(12, actionButton("update", "Update direct"), actionButton("stress", "100 updates"),
    actionButton("toggle", "Hide/show"), actionButton("remove", "Remove/remount"),
    verbatimTextOutput("events", placeholder = TRUE))),
  fluidRow(column(6, h3("Qualified htmlwidgets palette"), command_palette_output("widget")),
    column(6, h3("Parallel direct palette"), uiOutput("direct_slot"))),
  fluidRow(column(6, h3("Namespaced instance"), command_palette_direct_output("nested", height = "300px")),
    column(6, h3("Second direct instance"), command_palette_direct_output("direct_two"))))

server <- function(input, output, session) {
  version <- reactiveVal(1L); visible <- reactiveVal(TRUE); mounted <- reactiveVal(TRUE)
  output$widget <- render_command_palette(command_palette(make_items(), server_search = TRUE))
  output$direct_slot <- renderUI(if (!mounted()) tags$div(class = "text-muted", "Direct component removed.") else
    div(style = if (visible()) NULL else "display:none", command_palette_direct_output("direct")))
  output$direct <- render_command_palette_direct(command_palette_direct(make_items(), server_search = TRUE))
  output$nested <- render_command_palette_direct(command_palette_direct(make_items(100L)))
  output$direct_two <- render_command_palette_direct(command_palette_direct(make_items(250L)))
  observeEvent(input$update, { version(version() + 1L); update_command_palette_direct(session, "direct", make_items(1000L, version()), revision = version()) })
  observeEvent(input$stress, for (i in seq_len(100L)) update_command_palette_direct(session, "direct", make_items(100L, i), revision = 1000L + i))
  observeEvent(input$toggle, visible(!visible()))
  observeEvent(input$remove, mounted(!mounted()))
  output$events <- renderPrint(list(direct = input$direct_command, query = input$direct_query,
    second = input$direct_two_command, nested = input$nested_command))
}
shinyApp(ui, server)
