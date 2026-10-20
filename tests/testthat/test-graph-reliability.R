testthat::test_that("Apply is not replayed by host node state or publication changes", {
  registry <- capability_registry()
  capability_registry_add(registry, register_capability("test.consumer", "1.0.0", "Consumer",
    inputs = list(bundle = port_type("dataset", required = TRUE)),
    config = list(field = config_field("text", "Field"))))
  initial <- list(nodes = list(list(id = "consumer", capability_id = "test.consumer",
    config = list(field = "x"), state = "blocked")), edges = list())
  shiny::testServer(capability_canvas_server, args = list(registry = registry, initial_graph = initial), {
    session$flushReact()
    session$returned$set_configuration_context(list(project = "P", workflow = "W", revision = "R"))
    session$setInputs(canvas_event = list(type = "node_selected", nodeId = "consumer"))
    key <- configuration_node_key("consumer")
    session$setInputs(inspector_owner = key)
    do.call(session$setInputs, setNames(list(1L), paste0("save_config__", key)))
    testthat::expect_identical(session$returned$graph()$nodes[[1]]$state, "ready")
    before <- session$returned$graph_revision()
    blocked <- session$returned$graph(); blocked$nodes[[1]]$state <- "blocked"
    session$returned$set_graph(blocked); session$flushReact()
    testthat::expect_identical(session$returned$graph()$nodes[[1]]$state, "blocked")
    testthat::expect_identical(session$returned$graph_revision(), before + 1L)
    for (i in seq_len(4L)) { session$returned$set_graph(blocked); session$flushReact() }
    testthat::expect_identical(session$returned$graph_revision(), before + 1L)
    testthat::expect_identical(session$returned$graph(), blocked)
  })
})

testthat::test_that("graph receipts admit, refuse, deduplicate and reject stale edits", {
  registry <- capability_registry()
  capability_registry_add(registry, register_capability("test.source", "1.0.0", "Source"))
  shiny::testServer(capability_canvas_server, args = list(registry = registry), {
    receipts <- list()
    root_session <- session$rootScope()
    root_session$sendCustomMessage <- function(type, message) {
      if (identical(type, "shinycapabilities:v1:set-graph")) receipts[[length(receipts)+1L]] <<- message
    }
    session$flushReact()
    latest <- function() tail(receipts, 1L)[[1L]]
    node <- list(id = "source", capability_id = "test.source", position = list(x = 10, y = 20))
    edit <- list(type = "capability_dropped", mutationId = "one", baseGraphRevision = 0L,
      graph = list(nodes = list(node), edges = list()))
    session$setInputs(canvas_event = edit)
    testthat::expect_true(latest()$mutationResult$accepted)
    testthat::expect_identical(latest()$ackMutationId, "one")
    testthat::expect_identical(session$returned$graph_revision(), 1L)
    accepted <- session$returned$graph()
    session$setInputs(canvas_event = edit)
    testthat::expect_identical(session$returned$graph(), accepted)
    testthat::expect_identical(session$returned$graph_revision(), 1L)
    testthat::expect_true(latest()$mutationResult$accepted)
    edit$mutationId <- "stale"; edit$graph$nodes <- list()
    session$setInputs(canvas_event = edit)
    testthat::expect_identical(latest()$mutationResult$code, "stale_graph_revision")
    testthat::expect_false(latest()$mutationResult$accepted)
    testthat::expect_identical(session$returned$graph(), accepted)
    edit$mutationId <- "bad"; edit$baseGraphRevision <- 1L
    edit$graph$nodes <- list(node,node)
    session$setInputs(canvas_event = edit)
    testthat::expect_identical(latest()$mutationResult$code, "invalid_graph_edit")
    testthat::expect_identical(session$returned$graph(), accepted)
    edit$mutationId <- "one"
    session$setInputs(canvas_event = edit)
    testthat::expect_identical(latest()$mutationResult$code, "mutation_identity_reused")
    edit$mutationId <- "missing-revision"; edit$baseGraphRevision <- NULL
    session$setInputs(canvas_event = edit)
    testthat::expect_identical(latest()$mutationResult$code, "invalid_graph_revision")
    edit$mutationId <- "move"; edit$baseGraphRevision <- 1L
    edit$type <- "move_completed"; edit$graph$nodes <- list(node)
    edit$graph$nodes[[1]]$position$x <- 80
    session$setInputs(canvas_event = edit)
    testthat::expect_true(latest()$mutationResult$accepted)
    testthat::expect_identical(session$returned$graph()$nodes[[1]]$position$x, 80)
    testthat::expect_identical(session$returned$graph_revision(), 2L)
  })
})

testthat::test_that("incomplete authoring is admitted but malformed identities and geometry are refused", {
  registry <- capability_registry()
  capability_registry_add(registry, register_capability("test.target", "1.0.0", "Target",
    inputs = list(bundle = port_type("dataset", required = TRUE))))
  node <- list(id = "n", capability_id = "test.target")
  event <- list(mutationId = "m", baseGraphRevision = 0L, graph = list(nodes = list(node), edges = list()))
  testthat::expect_true(admit_graph_mutation(registry, event, 0L)$accepted)
  for (bad in list(NA_real_, Inf, c(1,2))) {
    broken <- event; broken$graph$nodes[[1]]$position$x <- bad
    testthat::expect_false(admit_graph_mutation(registry, broken, 0L)$accepted)
  }
  broken <- event; broken$graph$nodes[[1]]$capability_id <- "missing"
  testthat::expect_false(admit_graph_mutation(registry, broken, 0L)$accepted)
  broken <- event; broken$graph <- "not a graph"
  testthat::expect_false(admit_graph_mutation(registry, broken, 0L)$accepted)
})
