test_that("explicit capability refusals survive inline and worker transport", {
  refusal <- list(ok = FALSE, code = "invalid_spec", owner = "ExampleOwner",
    input_identity = "input-v1", message = "Confidence is invalid.")
  cap <- list(validate = function(...) list(valid = TRUE),
    execute = function(...) stop(structure(list(message = refusal$message,
      call = NULL, refusal = refusal),
      class = c("shinycap_capability_refusal", "error", "condition"))))
  outcome <- runtime_worker(cap, list(), list(), list())
  expect_false(outcome$ok)
  expect_identical(outcome$details$owner_refusal, refusal)
  expect_null(outcome$outputs)
  rt <- new.env()
  rt$graph <- list(edges = list())
  rt$context <- list()
  rt$steps <- list(risk = list(signature = "s1", capability_id = "example.risk"))
  rt$lifecycle <- list(risk = list(state = "pending"))
  rt$results <- list(); rt$events <- list()
  runtime_start_inline(rt, "risk", cap, list(config = list()))
  expect_identical(rt$results$risk$status, "failed")
  expect_identical(rt$results$risk$error$details$owner_refusal, refusal)
  # Same serialized worker result is consumed by the background path.
  rt$jobs <- list(risk = list(process = list(is_alive = function() FALSE,
    get_result = function() unserialize(serialize(outcome, NULL))),
    stdout_file = character(), stderr_file = character(), timeout = Inf))
  runtime_poll_jobs(rt)
  expect_identical(rt$results$risk$error$details$owner_refusal, refusal)
  registry <- capability_registry()
  capability_registry_add(registry, register_capability("example.risk", "1.0.0",
    "Risk", execute = cap$execute))
  graph <- list(nodes = list(list(id = "risk", capability_id = "example.risk",
    state = "ready", config = list())), edges = list())
  result <- execute_workflow_plan(registry, graph, plan_workflow(registry, graph))
  expect_identical(result$results$risk$status, "failed")
  expect_identical(result$results$risk$error$details$owner_refusal, refusal)
  cap$execute <- function(...) stop("ordinary error")
  expect_identical(runtime_worker(cap, list(), list(), list())$details, list())
})
