test_that("graph normalization is deterministic", {
  graph <- list(
    nodes = list(
      list(id = "b", capability_id = "value.transform", position = list(x = 2, y = 3)),
      list(id = "a", capability_id = "value.source", position = list(x = 0, y = 1))
    ),
    edges = list()
  )
  expect_equal(vapply(normalize_workflow_graph(graph)$nodes, `[[`, character(1), "id"), c("a", "b"))
  expect_identical(graph_fingerprint(graph), graph_fingerprint(graph))
})

test_that("connection validation enforces port types", {
  registry <- capability_registry()
  capability_registry_add(registry, register_capability(
    "source.value", "1.0.0", "Source",
    outputs = list(value = port_type("value")),
    execute = function(...) list()
  ))
  capability_registry_add(registry, register_capability(
    "consume.package", "1.0.0", "Consumer",
    inputs = list(package = port_type("package")),
    execute = function(...) list()
  ))
  graph <- list(nodes = list(
    list(id = "source", capability_id = "source.value"),
    list(id = "consumer", capability_id = "consume.package")
  ))
  result <- validate_connection(registry, graph, list(
    source = "source", source_port = "value",
    target = "consumer", target_port = "package"
  ))
  expect_false(result$valid)
  expect_equal(result$code, "type_mismatch")
})
