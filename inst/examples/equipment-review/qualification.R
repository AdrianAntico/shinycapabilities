# Run from the package root after loading shinycapabilities.
fixture <- new.env()
sys.source("app.R", envir = fixture)
ui <- htmltools::tagAppendChildren(fixture$ui,
  browser_action_button("host_refresh", "Refresh host criteria"),
  browser_action_button("open_details", "Open details"),
  browser_popover("help", "Context help", "Equipment records are demonstration data."),
  browser_context_menu("record_menu", shiny::tags$button("Record actions"),
    list(list(id = "inspect", label = "Inspect record"))),
  browser_dialog("detail_dialog", "Record details", NULL,
    browser_popover("nested_help", "Nested help", "Context inside a dialog.")),
  notification_center("notifications", list(list(id = "ready", title = "Review ready",
    message = "Demonstration fixture loaded", status = "info"))))
server <- function(input, output, session) {
  fixture$server(input, output, session)
  shiny::observeEvent(input$host_refresh, {
    update_parameter_workbench(session, "threshold", values = list(downtime = 35),
      conflict_policy = "preserve")
  })
  shiny::observeEvent(input$open_details, update_browser_surface(session, "detail_dialog", "open"))
}
shiny::shinyApp(ui, server)
