library(shiny)
library(shinycapabilities)

large_fields <- sprintf("field_%05d", seq_len(25000))
large_groups <- list(
  `Date and time` = stats::setNames(large_fields[1:250], large_fields[1:250]),
  Numeric = stats::setNames(large_fields[251:12500], large_fields[251:12500]),
  Logical = stats::setNames(large_fields[12501:13000], large_fields[12501:13000]),
  `Text and categorical` = stats::setNames(large_fields[13001:25000], large_fields[13001:25000])
)

ui <- fluidPage(
  tags$head(tags$link(rel = "icon", href = "data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg'/>")),
  tags$style(HTML("body{background:#07111f;color:#eaf2ff}.gallery{display:grid;grid-template-columns:repeat(auto-fit,minmax(300px,1fr));gap:20px}.sc-selection{--sc-selection-bg:#111c33;--sc-selection-panel:#0b1326;--sc-selection-text:#eaf2ff;--sc-selection-muted:#8ea0ba;--sc-selection-border:#52627a;--sc-selection-accent:#60a5fa;--sc-selection-hover:#152540}")),
  h1("Analytics Selection System 1.0"),
  div(class = "gallery",
    selection_input("small_single", "Small single", c("Automatic", "Manual", "Strict"), selected = "Automatic"),
    selection_input("small_multi", "Small multiple", c("Mean", "Median", "Mode"), selected = c("Mean", "Mode"), multiple = TRUE),
    selection_input("large", "25,000 categorized fields", large_groups, multiple = TRUE, ordered = TRUE,
      commands = list(list(id = "numeric", label = "All numeric", values = large_fields[251:12500]),
        list(id = "visible", label = "All visible", scope = "visible"), list(id = "clear", label = "Clear", scope = "clear")))
  ), verbatimTextOutput("values")
)
server <- function(input, output, session) output$values <- renderPrint(list(
  small_single = input$small_single, small_multi = input$small_multi,
  large_count = length(input$large), large_head = head(input$large)
))
shinyApp(ui, server)
