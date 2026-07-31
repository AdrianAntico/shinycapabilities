test_registry <- function(fail_middle = FALSE) {
  registry <- capability_registry()
  capability_registry_add(registry, register_capability(
    "source.value", "1.0.0", "Source",
    outputs = list(value = port_type("value")),
    execute = function(context, config, inputs) list(value = 1:3)
  ))
  capability_registry_add(registry, register_capability(
    "transform.value", "1.0.0", "Transform",
    inputs = list(value = port_type("value")),
    outputs = list(value = port_type("value")),
    execute = function(context, config, inputs) {
      if (fail_middle) stop("planned failure")
      list(value = inputs$value)
    }
  ))
  capability_registry_add(registry, register_capability(
    "summarize.value", "1.0.0", "Summarize",
    inputs = list(value = port_type("value")),
    outputs = list(summary = port_type("summary")),
    execute = function(context, config, inputs) list(summary = length(inputs$value))
  ))
  registry
}

test_graph <- function() list(
  nodes = list(
    list(id = "source", capability_id = "source.value", state = "ready"),
    list(id = "transform", capability_id = "transform.value", state = "ready"),
    list(id = "summary", capability_id = "summarize.value", state = "ready")
  ),
  edges = list(
    list(id = "a", source = "source", source_port = "value", target = "transform", target_port = "value"),
    list(id = "b", source = "transform", source_port = "value", target = "summary", target_port = "value")
  )
)

test_that("planner orders the transitive dependency closure", {
  plan <- plan_workflow(test_registry(), test_graph(), target = "summary")
  expect_true(plan$valid)
  expect_equal(plan$order, c("source", "transform", "summary"))
})

test_that("planner detects cycles", {
  registry <- capability_registry()
  for (id in c("cycle.a", "cycle.b")) {
    capability_registry_add(registry, register_capability(
      id, "1.0.0", id,
      inputs = list(value = port_type("value")),
      outputs = list(value = port_type("value")),
      execute = function(context, config, inputs) list(value = inputs$value)
    ))
  }
  graph <- list(
    nodes = list(
      list(id = "a", capability_id = "cycle.a"),
      list(id = "b", capability_id = "cycle.b")
    ),
    edges = list(
      list(id = "ab", source = "a", source_port = "value", target = "b", target_port = "value"),
      list(id = "ba", source = "b", source_port = "value", target = "a", target_port = "value")
    )
  )
  plan <- plan_workflow(registry, graph)
  expect_false(plan$valid)
  expect_equal(plan$findings[[1]]$code, "cycle")
})

test_that("execution reuses current cache and blocks dependents after failure", {
  registry <- test_registry()
  graph <- test_graph()
  first <- execute_workflow_plan(registry, graph, plan_workflow(registry, graph))
  second_plan <- plan_workflow(registry, graph, cache = first$results)
  expect_true(all(vapply(second_plan$steps, function(step) step$action == "skipped/current", logical(1))))

  failing <- test_registry(TRUE)
  failed <- execute_workflow_plan(failing, graph, plan_workflow(failing, graph))
  expect_equal(failed$results$transform$status, "failed")
  expect_equal(failed$results$summary$status, "blocked")
  expect_equal(failed$results$source$status, "succeeded")
})
