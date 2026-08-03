testthat::test_that("client insertion selects deterministic non-overlapping positions", {
  source <- paste(readLines(
    testthat::test_path("..", "..", "tools", "javascript", "src", "widget.jsx"),
    warn = FALSE
  ), collapse = "\n")

  testthat::expect_match(source, "const nextInsertPosition =", fixed = TRUE)
  testthat::expect_match(source, "const anchor = current.length ? current[0].position : requested;", fixed = TRUE)
  testthat::expect_match(source, "const position = nextInsertPosition(requestedPosition, current);", fixed = TRUE)
  testthat::expect_match(source, "INSERT_NODE_WIDTH + INSERT_NODE_GAP", fixed = TRUE)
  testthat::expect_match(source, "serialize(next, edges)", fixed = TRUE)
  testthat::expect_match(source, "flow.fitView({ nodes: next", fixed = TRUE)
})

testthat::test_that("generic browser handlers guard non-Element event targets", {
  widget_source <- paste(readLines(
    testthat::test_path("..", "..", "tools", "javascript", "src", "widget.jsx"),
    warn = FALSE
  ), collapse = "\n")
  module_source <- paste(readLines(
    testthat::test_path("..", "..", "R", "module.R"), warn = FALSE
  ), collapse = "\n")

  testthat::expect_match(
    widget_source,
    "if (!isElementTarget(event.target)) return;",
    fixed = TRUE
  )
  guarded_handlers <- length(strsplit(
    module_source, "typeof e.target.closest!=='function'", fixed = TRUE
  )[[1L]]) - 1L
  testthat::expect_gte(guarded_handlers, 3L)
})

testthat::test_that("server accepts and retains client node positions", {
  registry <- capability_registry()
  capability_registry_add(registry, register_capability(
    "position.source", "1.0.0", "Position source"
  ))

  shiny::testServer(capability_canvas_server, args = list(
    registry = registry,
    initial_graph = list(nodes = list(), edges = list())
  ), {
    accepted <- list(
      list(
        id = "node-a", capability_id = "position.source",
        position = list(x = 120, y = 160), config = list()
      ),
      list(
        id = "node-b", capability_id = "position.source",
        position = list(x = 412, y = 160), config = list()
      ),
      list(
        id = "node-c", capability_id = "position.source",
        position = list(x = 704, y = 160), config = list()
      )
    )
    session$setInputs(canvas_event = list(
      type = "capability_dropped",
      graph = list(nodes = accepted, edges = list())
    ))
    session$flushReact()
    before <- session$returned$graph()

    session$setInputs(canvas_event = list(type = "node_selected", nodeId = "node-b"))
    session$flushReact()
    after <- session$returned$graph()

    testthat::expect_identical(
      lapply(after$nodes, `[[`, "position"),
      lapply(before$nodes, `[[`, "position")
    )
  })
})
