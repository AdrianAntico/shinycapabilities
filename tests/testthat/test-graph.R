test_that("graph normalization is deterministic", {
  graph <- list(
    nodes = list(
      list(id = "b", capability_id = "data.prepare", position = list(x = 2, y = 3)),
      list(id = "a", capability_id = "dataset.source", position = list(x = 0, y = 1))
    ),
    edges = list()
  )
  expect_equal(vapply(normalize_workflow_graph(graph)$nodes, `[[`, character(1), "id"), c("a", "b"))
  expect_identical(graph_fingerprint(graph), graph_fingerprint(graph))
})

test_that("connection validation enforces port types", {
  registry <- capability_registry()
  capability_registry_add(registry, register_capability(
    "source.data", "1.0.0", "Source",
    outputs = list(dataset = port_type("dataset")),
    execute = function(...) list()
  ))
  capability_registry_add(registry, register_capability(
    "consume.model", "1.0.0", "Consumer",
    inputs = list(model = port_type("model")),
    execute = function(...) list()
  ))
  graph <- list(nodes = list(
    list(id = "source", capability_id = "source.data"),
    list(id = "consumer", capability_id = "consume.model")
  ))
  result <- validate_connection(registry, graph, list(
    source = "source", source_port = "dataset",
    target = "consumer", target_port = "model"
  ))
  expect_false(result$valid)
  expect_equal(result$code, "type_mismatch")
})

