library(shiny)
library(shinycapabilities)
ui <- fluidPage(
  tags$style(".edge { position:fixed; bottom:8px; right:8px; width:min(310px,calc(100vw - 16px)); }"),
  h2("Selection viewport reachability"),
  p("Open the bottom-right picker. Search, keyboard selection and Close remain within the viewport."),
  verbatimTextOutput("selected"),
  div(class="edge",selection_input("edge", "Edge choice",
    groups=list(Choices=stats::setNames(sprintf("choice%02d",1:80),sprintf("Choice %02d",1:80))),
    selected="choice01",search=TRUE,virtual_threshold=12L))
)
server <- function(input,output,session) {
  output$selected <- renderText(paste("Selected:",paste(input$edge,collapse=", ")))
}
shinyApp(ui,server)
