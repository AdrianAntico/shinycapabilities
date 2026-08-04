widget_protocol_source <- function() {
  candidates <- c(
    testthat::test_path("..", "..", "tools", "javascript", "src", "widget.jsx"),
    testthat::test_path("..", "..", "inst", "htmlwidgets", "src", "widget.jsx"),
    system.file("htmlwidgets", "src", "widget.jsx", package = "shinycapabilities")
  )
  path <- candidates[file.exists(candidates)][[1L]]
  paste(readLines(path, warn = FALSE), collapse = "\n")
}

testthat::test_that("authoritative graph revisions advance monotonically", {
  registry <- capability_registry()
  capability_registry_add(registry, register_capability(
    "protocol.source", "1.0.0", "Protocol source",
    outputs = list(data = port_type("dataset"))
  ))
  capability_registry_add(registry, register_capability(
    "protocol.target", "1.0.0", "Protocol target",
    inputs = list(data = port_type("dataset", required = TRUE))
  ))
  nodes <- list(
    list(id = "source", capability_id = "protocol.source", position = list(x = 20, y = 30), config = list()),
    list(id = "target", capability_id = "protocol.target", position = list(x = 320, y = 30), config = list())
  )
  edge <- list(id = "source__data__target__data", source = "source", source_port = "data",
    target = "target", target_port = "data")

  shiny::testServer(capability_canvas_server, args = list(
    registry = registry, initial_graph = list(nodes = list(), edges = list())
  ), {
    testthat::expect_identical(session$returned$graph_revision(), 0L)
    session$setInputs(canvas_event = list(
      type = "node_selected", nodeId = NULL, mutationId = "initialize"
    ))
    session$flushReact()
    session$setInputs(canvas_event = list(
      type = "capability_dropped", mutationId = "mutation-1",
      graph = list(nodes = nodes, edges = list())
    ))
    session$flushReact()
    testthat::expect_identical(session$returned$graph_revision(), 1L)
    testthat::expect_length(session$returned$graph()$nodes, 2L)

    session$setInputs(canvas_event = list(
      type = "node_selected", nodeId = "target", mutationId = "selection-1"
    ))
    session$flushReact()
    testthat::expect_identical(session$returned$graph_revision(), 1L)
    testthat::expect_identical(session$returned$selection(), "target")

    session$setInputs(canvas_event = list(
      type = "connection_accepted", mutationId = "mutation-2",
      graph = list(nodes = nodes, edges = list(edge))
    ))
    session$flushReact()
    testthat::expect_identical(session$returned$graph_revision(), 2L)
    testthat::expect_identical(session$returned$graph()$edges[[1L]]$id, edge$id)

    session$returned$set_graph(list(nodes = nodes, edges = list()))
    session$flushReact()
    testthat::expect_identical(session$returned$graph_revision(), 3L)
  })
})

testthat::test_that("client rejects stale publications and exposes semantic readiness", {
  source <- widget_protocol_source()

  testthat::expect_match(source, "baseGraphRevision", fixed = TRUE)
  testthat::expect_match(source, "pendingGraphMutations", fixed = TRUE)
  testthat::expect_match(source, "revision < protocol.current.serverRevision", fixed = TRUE)
  testthat::expect_match(source, "pendingGraphMutations.has(ack)", fixed = TRUE)
  testthat::expect_match(source, "shinycapRestorationReady", fixed = TRUE)
  testthat::expect_match(source, "shinycapSelectedNodeId", fixed = TRUE)
  testthat::expect_match(source, "shinycapInspectorRevision", fixed = TRUE)
  testthat::expect_match(source, "data-shinycap-capability-id", fixed = TRUE)
})
