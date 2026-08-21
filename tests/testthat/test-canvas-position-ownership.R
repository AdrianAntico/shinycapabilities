widget_source_contract_path <- function() {
  candidates <- c(
    testthat::test_path("..", "..", "tools", "javascript", "src", "widget.jsx"),
    testthat::test_path("..", "..", "inst", "www", "direct-transport", "src", "widget.jsx"),
    system.file("www", "direct-transport", "src", "widget.jsx", package = "shinycapabilities")
  )
  path <- candidates[file.exists(candidates)][[1L]]
  testthat::expect_true(nzchar(path), info = "The packaged widget source contract is required.")
  path
}

testthat::test_that("client insertion selects deterministic non-overlapping positions", {
  source <- paste(readLines(
    widget_source_contract_path(),
    warn = FALSE
  ), collapse = "\n")

  testthat::expect_match(source, "const nextInsertPosition =", fixed = TRUE)
  testthat::expect_match(source, "const INSERT_VIEWPORT_INSET = 36;", fixed = TRUE)
  testthat::expect_match(source, "const reservedOverlayRects =", fixed = TRUE)
  testthat::expect_match(source, 'container.querySelectorAll(".react-flow__panel")', fixed = TRUE)
  testthat::expect_match(source, 'document.querySelectorAll("[data-shinycap-reserved-overlay]")', fixed = TRUE)
  testthat::expect_match(source, "flow.screenToFlowPosition", fixed = TRUE)
  testthat::expect_match(source, "const position = nextInsertPosition(requestedPosition, current, bounds?.width, reserved);", fixed = TRUE)
  testthat::expect_match(source, "const columns = Math.max(3", fixed = TRUE)
  testthat::expect_match(source, "anchor.x + (index % columns)", fixed = TRUE)
  testthat::expect_match(source, "INSERT_NODE_WIDTH + INSERT_NODE_GAP", fixed = TRUE)
  testthat::expect_match(source, "serialize(next, edges)", fixed = TRUE)
  testthat::expect_match(source, "!reserved.some((rect) => overlaps(candidate, rect))", fixed = TRUE)
  testthat::expect_match(source, "current.length + reserved.length + columns * 2", fixed = TRUE)
  testthat::expect_match(source, "index < searchLimit", fixed = TRUE)
  testthat::expect_match(source, "flow.setCenter(", fixed = TRUE)
  testthat::expect_match(source, "position.x + INSERT_NODE_WIDTH / 2", fixed = TRUE)
  testthat::expect_match(source, "position.y + INSERT_NODE_HEIGHT / 2", fixed = TRUE)
})

testthat::test_that("manual fit preserves a readable workstation scale", {
  source <- paste(readLines(
    widget_source_contract_path(),
    warn = FALSE
  ), collapse = "\n")

  fit_contract <- "flow.fitView({ padding: 0.18, maxZoom: 1, duration: 250 });"
  testthat::expect_equal(
    length(gregexpr(fit_contract, source, fixed = TRUE)[[1L]]),
    2L,
    info = "Both the visible Fit command and host command must cap automatic zoom."
  )
})

testthat::test_that("restored edges wait for initialized React Flow nodes", {
  source <- paste(readLines(
    widget_source_contract_path(),
    warn = FALSE
  ), collapse = "\n")

  testthat::expect_match(source, "useNodesInitialized", fixed = TRUE)
  testthat::expect_match(source, "const [edges, setEdges] = useState([]);", fixed = TRUE)
  testthat::expect_match(
    source,
    "const [pendingHydratedEdges, setPendingHydratedEdges] = useState(hydrated.edges);",
    fixed = TRUE
  )
  testthat::expect_match(source, "if (!nodesInitialized || pendingHydratedEdges === null) return;", fixed = TRUE)
  testthat::expect_match(source, "setEdges(pendingHydratedEdges);", fixed = TRUE)
})

testthat::test_that("generic browser handlers guard non-Element event targets", {
  widget_source <- paste(readLines(
    widget_source_contract_path(),
    warn = FALSE
  ), collapse = "\n")
  module_source <- paste(deparse(body(capability_canvas_ui)), collapse = "\n")

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

testthat::test_that("explicit connection removal preserves nodes and permits reconnection", {
  registry <- capability_registry()
  capability_registry_add(registry, register_capability(
    "edge.source", "1.0.0", "Edge source",
    outputs = list(data = port_type("dataset"))
  ))
  capability_registry_add(registry, register_capability(
    "edge.target", "1.0.0", "Edge target",
    inputs = list(data = port_type("dataset", required = TRUE))
  ))
  nodes <- list(
    list(id = "source", capability_id = "edge.source", position = list(x = 40, y = 80), config = list()),
    list(id = "target", capability_id = "edge.target", position = list(x = 420, y = 80), config = list())
  )
  edge <- list(id = "source__data__target__data", source = "source", source_port = "data", target = "target", target_port = "data")

  shiny::testServer(capability_canvas_server, args = list(
    registry = registry,
    initial_graph = list(nodes = nodes, edges = list(edge))
  ), {
    before <- session$returned$graph()
    session$setInputs(canvas_event = list(type = "node_selected", nodeId = "source", nonce = "initialize"))
    session$flushReact()
    session$setInputs(canvas_event = list(
      type = "connection_removed",
      edgeIds = list(edge$id),
      graph = list(nodes = nodes, edges = list()),
      nonce = "remove"
    ))
    session$flushReact()
    removed <- session$returned$graph()
    testthat::expect_length(removed$edges, 0L)
    testthat::expect_identical(removed$nodes, before$nodes)

    session$setInputs(canvas_event = list(
      type = "connection_accepted",
      graph = list(nodes = nodes, edges = list(edge)),
      nonce = "reconnect"
    ))
    session$flushReact()
    reconnected <- session$returned$graph()
    testthat::expect_length(reconnected$edges, 1L)
    testthat::expect_identical(reconnected$nodes, before$nodes)
  })
})

testthat::test_that("edge deletion is explicit, selected, and input-focus safe", {
  source <- paste(readLines(
    widget_source_contract_path(),
    warn = FALSE
  ), collapse = "\n")

  testthat::expect_match(source, "onEdgeClick={(event, edge) =>", fixed = TRUE)
  testthat::expect_match(source, "Remove connection", fixed = TRUE)
  testthat::expect_match(source, "selectedEdgeId && !isEditableTarget(event.target)", fixed = TRUE)
  testthat::expect_match(source, "input, textarea, select, [contenteditable='true']", fixed = TRUE)
  testthat::expect_match(source, "deleteKeyCode={null}", fixed = TRUE)
  testthat::expect_match(source, "edgeIds: [selectedEdgeId]", fixed = TRUE)
  testthat::expect_match(source, "event.target.closest('.react-flow__edge')", fixed = TRUE)
  testthat::expect_match(source, 'event.key === "Enter" || event.key === " "', fixed = TRUE)
  testthat::expect_match(source, 'event.key === "Escape" && selectedEdgeId', fixed = TRUE)
  testthat::expect_match(source, "selectedEdgeElement.current?.focus()", fixed = TRUE)
  testthat::expect_match(source, "const AccessibleEdge = memo", fixed = TRUE)
  testthat::expect_match(source, "interactionWidth={20}", fixed = TRUE)
  testthat::expect_match(source, "edgeTypes={EDGE_TYPES}", fixed = TRUE)
})

testthat::test_that("semantic multi-input handles have distinct stable hit regions", {
  source <- paste(readLines(widget_source_contract_path(), warn = FALSE), collapse = "\n")
  css <- paste(readLines(system.file("www", "direct-transport", "src", "widget.css",
    package = "shinycapabilities"), warn = FALSE), collapse = "\n")

  testthat::expect_match(source, "PORT_HANDLE_FIRST_OFFSET = 96", fixed = TRUE)
  testthat::expect_match(source, "PORT_HANDLE_PITCH = 30", fixed = TRUE)
  testthat::expect_match(source,
    "data-testid={`shinycap-handle-input-${id}-${name}`}", fixed = TRUE)
  testthat::expect_match(source,
    "top: PORT_HANDLE_FIRST_OFFSET + index * PORT_HANDLE_PITCH", fixed = TRUE)
  testthat::expect_match(css, "min-height: 30px", fixed = TRUE)
  testthat::expect_match(css, "box-sizing: border-box", fixed = TRUE)
  testthat::expect_match(source, 'className="nodrag nopan"', fixed = TRUE)
  testthat::expect_match(source, '"sc-node-connection-target"', fixed = TRUE)
  testthat::expect_match(css, ".react-flow__node.sc-node-connection-target", fixed = TRUE)
  testthat::expect_match(css, "z-index: 1000 !important", fixed = TRUE)
  testthat::expect_match(css, ".sc-connection-feedback", fixed = TRUE)
  testthat::expect_match(css, "pointer-events: none", fixed = TRUE)
})
