library(shiny)
library(shinycapabilities)

# Deterministic demonstration data, not a predictive model.
equipment <- data.frame(id = sprintf("asset-%03d", 1:120),
  site = rep(c("North", "South", "West"), each = 40),
  hours = 800 + ((1:120 * 137) %% 5000), downtime = ((1:120 * 17) %% 90))
nodes <- lapply(unique(equipment$site), function(site) list(id = site, label = site,
  children = lapply(which(equipment$site == site), function(i)
    list(id = equipment$id[i], label = equipment$id[i]))))
commands <- lapply(seq_len(nrow(equipment)), function(i) list(id = equipment$id[i],
  label = paste("Inspect", equipment$id[i]), group = equipment$site[i]))

ui <- fluidPage(
  tags$style(HTML(".equipment-layout{display:grid;grid-template-columns:minmax(230px,1fr) minmax(0,3fr);gap:16px}.equipment-layout>*{min-width:0;display:flex;flex-direction:column;gap:16px}@media(max-width:900px){.equipment-layout{grid-template-columns:1fr}}")),
  h2("Equipment review"),
  div(class = "equipment-layout",
    div(command_palette_output("find", height = "240px"),
      virtual_tree_browser_output("sites", height = "340px"),
      parameter_workbench_ui("threshold", title = "Review criteria", height = "240px")),
    div(data_grid_output("equipment", height = "360px"),
      split_pane("details", record = object_inspector_output("record", height = "100%"),
        distribution = plotOutput("distribution", height = "100%"),
        sizes = c(45, 55), height = "330px"),
      browser_action_button("review", "Mark inspected"), textOutput("status"))))

server <- function(input, output, session) {
  selected <- reactiveVal(equipment$id[1])
  inspected <- reactiveVal(character())
  threshold <- reactiveVal(45)
  parameters <- parameter_workbench_server("threshold", list(list(
    key = "downtime", label = "Downtime threshold", type = "numeric",
    default = 45, min = 0, max = 90, required = TRUE)))
  select_record <- function(id) {
    if (length(id) == 1L && id %in% equipment$id) selected(id)
  }
  observeEvent(input$sites_selection, select_record(input$sites_selection$id))
  observeEvent(input$find_command, select_record(input$find_command$id))
  observeEvent(input$equipment_selection, {
    if (length(input$equipment_selection$rowIds)) select_record(input$equipment_selection$rowIds[[1]])
  })
  observeEvent(parameters$apply_event(), {
    req(parameters$valid())
    threshold(parameters$applied()$downtime)
  })
  observeEvent(input$review, inspected(union(inspected(), selected())), ignoreInit = TRUE)
  output$sites <- render_virtual_tree_browser(virtual_tree_browser(nodes, expanded = "North"))
  output$find <- render_command_palette(command_palette(commands, placeholder = "Find equipment"))
  output$equipment <- render_data_grid(data_grid(equipment, row_id = "id"))
  observeEvent(selected(), update_data_grid(session, "equipment", selected_rows = selected()))
  output$record <- render_object_inspector(object_inspector(list(
    equipment = equipment[equipment$id == selected(), ],
    inspected = selected() %in% inspected(), applied_threshold = threshold())))
  output$distribution <- renderPlot({
    plot(equipment$hours, equipment$downtime, xlab = "Operating hours", ylab = "Downtime hours",
      pch = 19, col = ifelse(equipment$id == selected(), "#b83548", "#237b82"))
    abline(h = threshold(), lty = 2)
  })
  output$status <- renderText(sprintf("%s selected. %d inspected. %d above the applied threshold.",
    selected(), length(inspected()), sum(equipment$downtime > threshold())))
}
shinyApp(ui, server)
