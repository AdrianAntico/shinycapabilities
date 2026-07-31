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

test_that("connections fail closed for duplicate, occupied input, cycle, and self", {
  registry <- capability_registry()
  for (id in c("one", "two", "three")) {
    capability_registry_add(registry, register_capability(
      paste0("step.", id), "1.0.0", id,
      inputs = list(item = port_type("work_item", required = FALSE)),
      outputs = list(item = port_type("work_item"))
    ))
  }
  graph <- list(
    nodes = lapply(c("one", "two", "three"), function(id) list(
      id = id, capability_id = paste0("step.", id)
    )),
    edges = list(list(id = "one_two", source = "one", source_port = "item",
      target = "two", target_port = "item"))
  )
  propose <- function(source, target) validate_connection(registry, graph, list(
    source = source, source_port = "item", target = target, target_port = "item"
  ))
  expect_identical(propose("one", "two")$code, "duplicate_connection")
  expect_identical(propose("three", "two")$code, "input_occupied")
  expect_identical(propose("two", "one")$code, "cycle")
  expect_identical(propose("one", "one")$code, "self_connection")
  expect_true(propose("two", "three")$valid)
})
