library(shiny)
library(shinycapabilities)

registry <- default_capability_catalog()
initial_graph <- list(
  nodes = list(
    list(
      id = "dataset_source_1", capability_id = "dataset.source",
      position = list(x = 40, y = 190), state = "ready",
      config = list(label = "Customer activity", notes = "Governed demo dataset")
    ),
    list(
      id = "eda_profile_1", capability_id = "eda.profile",
      position = list(x = 380, y = 100), state = "ready",
      config = list(label = "Profile data", notes = "")
    ),
    list(
      id = "visualize_compose_1", capability_id = "visualize.compose",
      position = list(x = 380, y = 340), state = "ready",
      config = list(label = "Explain distribution", notes = "")
    )
  ),
  edges = list(
    list(
      id = "source_to_eda", source = "dataset_source_1", source_port = "dataset",
      target = "eda_profile_1", target_port = "dataset"
    ),
    list(
      id = "source_to_visual", source = "dataset_source_1", source_port = "dataset",
      target = "visualize_compose_1", target_port = "dataset"
    )
  )
)

ui <- fluidPage(
  tags$head(tags$title("Capability Workflow Studio")),
  capability_canvas_ui("workflow", registry)
)

server <- function(input, output, session) {
  capability_canvas_server(
    "workflow", registry, initial_graph,
    context = list(project_id = "demo_project")
  )
}

shinyApp(ui, server)

