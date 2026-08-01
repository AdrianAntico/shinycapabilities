library(shiny)
library(shinycapabilities)

registry <- capability_registry()
capability_registry_add(registry, register_capability(
  id = "example.prepare",
  version = "1.0.0",
  display_name = "Prepare item",
  outputs = list(item = port_type("work_item")),
  execute = function(context, config, inputs) list(item = list(status = "ready")),
  implementation_fingerprint = "neutral-prepare-1"
))
capability_registry_add(registry, register_capability(
  id = "example.review",
  version = "1.0.0",
  display_name = "Review item",
  inputs = list(item = port_type("work_item")),
  outputs = list(item = port_type("work_item")),
  execute = function(context, config, inputs) list(item = inputs$item),
  implementation_fingerprint = "neutral-review-1"
))

graph <- list(
  nodes = list(
    list(id = "prepare", capability_id = "example.prepare", position = list(x = 80, y = 100), config = list()),
    list(id = "review", capability_id = "example.review", position = list(x = 420, y = 100), config = list())
  ),
  edges = list(list(
    id = "prepare-review",
    source = "prepare",
    source_port = "item",
    target = "review",
    target_port = "item"
  ))
)

ui <- fluidPage(
  tags$h1("Workflow example"),
  tags$p("A minimal two-step capability workflow."),
  capability_canvas_ui("workflow", registry, height = "620px")
)

server <- function(input, output, session) {
  capability_canvas_server("workflow", registry, graph)
}

shinyApp(ui, server)
