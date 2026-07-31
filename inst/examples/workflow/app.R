library(shiny)
library(shinycapabilities)

registry <- default_capability_catalog()
graph <- list(
  nodes = list(
    list(
      id = "intake", capability_id = "document.intake",
      position = list(x = 40, y = 120), state = "ready",
      config = list(label = "Document intake")
    ),
    list(
      id = "cleanup", capability_id = "document.cleanup",
      position = list(x = 360, y = 120), state = "ready",
      config = list(label = "Text cleanup")
    ),
    list(
      id = "approval", capability_id = "document.approval",
      position = list(x = 680, y = 120), state = "ready",
      config = list(label = "Human approval")
    ),
    list(
      id = "publish", capability_id = "document.publish",
      position = list(x = 1000, y = 120), state = "ready",
      config = list(label = "Publication")
    )
  ),
  edges = list(
    list(
      id = "intake_cleanup", source = "intake", source_port = "document",
      target = "cleanup", target_port = "document"
    ),
    list(
      id = "cleanup_approval", source = "cleanup", source_port = "document",
      target = "approval", target_port = "document"
    ),
    list(
      id = "approval_publish", source = "approval", source_port = "approved",
      target = "publish", target_port = "approved"
    )
  )
)

ui <- fluidPage(capability_canvas_ui("workflow", registry))
server <- function(input, output, session) {
  capability_canvas_server(
    "workflow", registry, graph,
    context = list(text = "  Neutral document example  ")
  )
}
shinyApp(ui, server)
