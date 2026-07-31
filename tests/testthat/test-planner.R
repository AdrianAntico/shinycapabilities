test_registry <- function(fail_middle = FALSE) {
  registry <- capability_registry()
  capability_registry_add(registry, register_capability(
    "source.data", "1.0.0", "Source",
    outputs = list(dataset = port_type("dataset")),
    execute = function(context, config, inputs) list(dataset = data.frame(x = 1:3))
  ))
  capability_registry_add(registry, register_capability(
    "prepare.data", "1.0.0", "Prepare",
    inputs = list(dataset = port_type("dataset")),
    outputs = list(dataset = port_type("dataset")),
    execute = function(context, config, inputs) {
      if (fail_middle) stop("planned failure")
      list(dataset = inputs$dataset)
    }
  ))
  capability_registry_add(registry, register_capability(
    "profile.data", "1.0.0", "Profile",
    inputs = list(dataset = port_type("dataset")),
    outputs = list(profile = port_type("data_profile")),
    execute = function(context, config, inputs) list(profile = summary(inputs$dataset))
  ))
  registry
}

test_graph <- function() list(
  nodes = list(
    list(id = "source", capability_id = "source.data", state = "ready"),
    list(id = "prepare", capability_id = "prepare.data", state = "ready"),
    list(id = "profile", capability_id = "profile.data", state = "ready")
  ),
  edges = list(
    list(id = "a", source = "source", source_port = "dataset", target = "prepare", target_port = "dataset"),
    list(id = "b", source = "prepare", source_port = "dataset", target = "profile", target_port = "dataset")
  )
)

test_that("planner orders the transitive dependency closure", {
  plan <- plan_workflow(test_registry(), test_graph(), target = "profile")
  expect_true(plan$valid)
  expect_equal(plan$order, c("source", "prepare", "profile"))
})

test_that("planner detects cycles", {
  registry <- capability_registry()
  for (id in c("cycle.a", "cycle.b")) {
    capability_registry_add(registry, register_capability(
      id, "1.0.0", id,
      inputs = list(value = port_type("dataset")),
      outputs = list(value = port_type("dataset")),
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
  expect_equal(failed$results$prepare$status, "failed")
  expect_equal(failed$results$profile$status, "blocked")
  expect_equal(failed$results$source$status, "succeeded")
})
