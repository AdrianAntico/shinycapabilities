runtime_test_registry <- function(delay = 0.15, timeout = 5) {
  registry <- capability_registry()
  add <- function(id, profile = "background_r", fail = FALSE, duration = delay) {
    capability_registry_add(registry, register_capability(
      id, "1.0.0", id,
      outputs = list(value = port_type("number")),
      inputs = if (identical(id, "test.join")) {
        list(left = port_type("number"), right = port_type("number"))
      } else {
        list()
      },
      execute = local({
        owned_fail <- fail
        owned_duration <- duration
        owned_id <- id
        function(context, config, inputs) {
          Sys.sleep(owned_duration)
          if (owned_fail) stop("bounded fixture failure")
          list(value = if (identical(owned_id, "test.join")) {
            inputs$left + inputs$right
          } else {
            config$value %||% 1
          })
        }
      }),
      execution_profile = profile,
      cancellation = profile %in% c("background_r", "network"),
      timeout = timeout,
      implementation_fingerprint = paste(id, fail, duration)
    ))
  }
  add("test.left")
  add("test.right")
  add("test.join", "inline", duration = 0)
  registry
}

runtime_test_graph <- function() {
  list(
    nodes = list(
      list(id = "left", capability_id = "test.left", state = "ready",
        position = list(x = 0, y = 0), config = list(value = 2)),
      list(id = "right", capability_id = "test.right", state = "ready",
        position = list(x = 0, y = 100), config = list(value = 3)),
      list(id = "join", capability_id = "test.join", state = "ready",
        position = list(x = 200, y = 50), config = list())
    ),
    edges = list(
      list(id = "left_join", source = "left", source_port = "value",
        target = "join", target_port = "left"),
      list(id = "right_join", source = "right", source_port = "value",
        target = "join", target_port = "right")
    )
  )
}

test_that("execution profiles validate and retain conservative defaults", {
  capability <- register_capability(
    "test.default", "1.0.0", "Default", execute = function(...) list()
  )
  expect_identical(capability$execution_profile, "inline")
  expect_identical(capability$progress_support, "phase")
  expect_identical(capability$retry_policy, "none")
  expect_false(capability$cancellation)
  expect_error(
    register_capability(
      "test.bad", "1.0.0", "Bad", execute = function(...) list(),
      execution_profile = "cluster"
    )
  )
})

test_that("independent branches run concurrently and join after success", {
  registry <- runtime_test_registry(delay = 0.4)
  graph <- runtime_test_graph()
  runtime <- workflow_runtime(
    registry, graph, plan_workflow(registry, graph), max_background = 2
  )
  tick_workflow_runtime(runtime)
  expect_identical(workflow_runtime_snapshot(runtime)$active_jobs, 2L)
  started <- Sys.time()
  result <- run_workflow_runtime(runtime)
  elapsed <- as.numeric(difftime(Sys.time(), started, units = "secs"))
  expect_true(result$complete)
  expect_lt(elapsed, 3)
  expect_identical(result$results$join$outputs$value, 5)
  expect_true(all(vapply(
    result$lifecycle, function(item) item$state == "succeeded", logical(1)
  )))
})

test_that("admission establishes real worker ownership before reporting active", {
  registry <- runtime_test_registry(delay = 0.2)
  graph <- runtime_test_graph()
  runtime <- workflow_runtime(
    registry, graph, plan_workflow(registry, graph), max_background = 2
  )
  admitted <- admit_workflow_runtime(runtime)
  expect_true(admitted$active)
  expect_false(admitted$terminal)
  expect_gt(admitted$snapshot$active_jobs, 0L)
  result <- run_workflow_runtime(runtime)
  expect_true(result$complete)
  expect_identical(result$active_jobs, 0L)
})

test_that("admission terminalizes stalled dispatch without phantom ownership", {
  registry <- runtime_test_registry(delay = 0.1)
  graph <- runtime_test_graph()
  runtime <- workflow_runtime(registry, graph, plan_workflow(registry, graph))
  runtime$limits$background_r <- 0L
  admitted <- admit_workflow_runtime(runtime)
  expect_false(admitted$active)
  expect_true(admitted$terminal)
  expect_identical(admitted$state, "failed")
  expect_identical(admitted$snapshot$active_jobs, 0L)
  failures <- Filter(function(item) {
    identical(item$failure$type %||% "", "dispatch_not_established")
  }, admitted$snapshot$lifecycle)
  expect_gt(length(failures), 0L)

  retry <- workflow_runtime(registry, graph, plan_workflow(registry, graph))
  retry_admitted <- admit_workflow_runtime(retry)
  expect_true(retry_admitted$active)
  cleanup_workflow_runtime(retry)
})

test_that("profile concurrency limits are enforced", {
  registry <- runtime_test_registry(delay = 0.4)
  graph <- runtime_test_graph()
  runtime <- workflow_runtime(
    registry, graph, plan_workflow(registry, graph), max_background = 1
  )
  tick_workflow_runtime(runtime)
  expect_identical(workflow_runtime_snapshot(runtime)$active_jobs, 1L)
  cleanup_workflow_runtime(runtime)
  expect_identical(workflow_runtime_snapshot(runtime)$active_jobs, 0L)
})

test_that("cancellation contains a branch and preserves unrelated success", {
  registry <- runtime_test_registry(delay = 1)
  graph <- runtime_test_graph()
  runtime <- workflow_runtime(
    registry, graph, plan_workflow(registry, graph), max_background = 2
  )
  tick_workflow_runtime(runtime)
  expect_true(workflow_runtime_snapshot(runtime)$active_jobs == 2L)
  expect_true(cancel_workflow_node(runtime, "left"))
  result <- run_workflow_runtime(runtime)
  expect_identical(result$lifecycle$left$state, "cancelled")
  expect_identical(result$lifecycle$join$state, "blocked")
  expect_identical(result$lifecycle$right$state, "succeeded")
  expect_null(result$results$left$outputs)
  expect_identical(result$active_jobs, 0L)
})

test_that("timeouts are typed and never register partial outputs", {
  registry <- runtime_test_registry(delay = 0.4, timeout = 0.05)
  graph <- runtime_test_graph()
  runtime <- workflow_runtime(
    registry, graph, plan_workflow(registry, graph), max_background = 2
  )
  result <- run_workflow_runtime(runtime)
  expect_identical(result$results$left$error$type, "timeout")
  expect_identical(result$results$right$error$type, "timeout")
  expect_null(result$results$left$outputs)
  expect_identical(result$lifecycle$join$state, "blocked")
})

test_that("failure containment and correction reuse successful branches", {
  registry <- runtime_test_registry(delay = 0.05)
  failing <- register_capability(
    "test.left", "1.0.0", "test.left",
    outputs = list(value = port_type("number")),
    execute = function(context, config, inputs) stop("intentional branch failure"),
    execution_profile = "background_r", cancellation = TRUE,
    implementation_fingerprint = "failing-left"
  )
  capability_registry_add(registry, failing)
  graph <- runtime_test_graph()
  first <- run_workflow_runtime(workflow_runtime(
    registry, graph, plan_workflow(registry, graph)
  ))
  expect_identical(first$lifecycle$left$state, "failed")
  expect_identical(first$lifecycle$right$state, "succeeded")
  expect_identical(first$lifecycle$join$state, "blocked")

  fixed <- runtime_test_registry(delay = 0.05)
  next_plan <- plan_workflow(fixed, graph, cache = first$results)
  actions <- setNames(
    vapply(next_plan$steps, `[[`, character(1), "action"),
    vapply(next_plan$steps, `[[`, character(1), "node_id")
  )
  expect_identical(actions[["right"]], "skipped/current")
  expect_identical(actions[["left"]], "execute")
  second <- run_workflow_runtime(workflow_runtime(
    fixed, graph, next_plan, cache = first$results
  ))
  expect_identical(second$lifecycle$right$state, "reused")
  expect_identical(second$results$join$outputs$value, 5)
})

test_that("saved documents exclude live runtime and restored running nodes become stale", {
  graph <- runtime_test_graph()
  graph$nodes[[1]]$state <- "running"
  document <- workflow_document(graph)
  restored <- restore_workflow_document(serialize_workflow_document(document))
  expect_false(any(names(restored) %in% c("jobs", "processes", "runtime")))
  left <- Filter(function(node) node$id == "left", restored$graph$nodes)[[1]]
  expect_identical(left$state, "stale")
})

test_that("proposed nodes fail closed before scheduling", {
  registry <- runtime_test_registry()
  graph <- runtime_test_graph()
  graph$nodes[[1]]$metadata <- list(proposal_status = "proposed")
  plan <- plan_workflow(registry, graph)
  expect_true(plan$valid)
  expect_error(
    workflow_runtime(registry, graph, plan),
    "Proposed nodes must be accepted"
  )
  expect_error(
    execute_workflow_plan(registry, graph, plan),
    "Proposed nodes must be accepted"
  )
})
