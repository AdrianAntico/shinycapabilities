library(shiny)
library(shinycapabilities)

# Reuse the public equipment dataset, linked selection, and fitted UI contracts.
equipment <- new.env()
sys.source(system.file("examples", "equipment-review", "app.R",
  package = "shinycapabilities"), envir = equipment)
commands <- list(command_record("review", "Request review", payload = list(scope = "selected")),
  command_record("export", "Export approved records", enabled = FALSE,
    disabled_reason = "No approved records", payload = list(format = "csv")))
body <- tagList(
  fluidRow(column(6, selectInput("theme", "Theme", c("auto", "light", "dark"))),
    column(6, selectInput("density", "Density", c("compact", "comfortable", "dense")))),
  application_frame("review_app", header = h2("Equipment maintenance review"),
    navigation = browser_breadcrumbs("trail", list(list(id = "review", label = "Maintenance"))),
    context = tagList(browser_date_field("due", "Due date", "2026-10-01", required = TRUE),
      browser_datetime_field("appointment", "Local appointment", "2026-10-01T09:30"),
      browser_text_field("note", "Review note", warning = "Awaiting inspection evidence"),
      selection_input("priority", "Priority", c("Routine service" = "routine", "Urgent repair" = "urgent"), "routine")),
    work = equipment$ui,
    output = command_palette_output("review_commands", height = "360px"),
    actions = tagList(lapply(commands, command_button), browser_action_button("open_review", "Review details"),
      browser_dialog("review_details", "Review details", NULL,
        tagList(browser_popover("nested", "Evidence notes", "Inspection remains pending."),
          selection_input("assignee", "Assignee", c("Service team" = "service", "Safety team" = "safety"), "service")))),
    status = verbatimTextOutput("command_status"), commands = commands))
ui <- if (requireNamespace("bslib", quietly = TRUE)) bslib::page_fluid(body,
  theme = bslib::bs_theme(version = 5, primary = "#176b58")) else fluidPage(body)
server <- function(input, output, session) {
  equipment$server(input, output, session)
  output$review_commands <- render_command_palette(command_palette(commands, shortcut = FALSE))
  observeEvent(list(input$theme, input$density), update_application_frame(session,
    "review_app", theme = input$theme, density = input$density))
  observeEvent(input$open_review, update_browser_surface(session, "review_details", "open"))
  output$command_status <- renderPrint(list(last_invocation = input$review_app_command,
    execution = "Not executed", priority = input$priority, due = input$due))
}
shinyApp(ui, server)
