testthat::test_that("palette has one guarded semantic insertion owner", {
  registry <- capability_registry()
  capability_registry_add(registry, register_capability(
    "forecasting", "1.0.0", "Forecasting",
    outputs = list(forecast = port_type("forecast"))
  ))
  html <- paste(as.character(capability_canvas_ui("flow", registry)), collapse = "\n")

  testthat::expect_match(html, "__shinycapPaletteDispatcher", fixed = TRUE)
  testthat::expect_match(html, "roots:new WeakSet()", fixed = TRUE)
  testthat::expect_match(html, "new MutationObserver", fixed = TRUE)
  testthat::expect_match(html,
    "closest('.sc-palette-density [data-palette-density]')", fixed = TRUE)
  testthat::expect_false(grepl("closest('[data-palette-density]')", html, fixed = TRUE))
  testthat::expect_identical(length(gregexpr("root.addEventListener('click'", html,
    fixed = TRUE)[[1L]]), 1L)
  testthat::expect_identical(length(gregexpr("shinycapabilities:v1:insert", html, fixed = TRUE)[[1L]]), 1L)
  testthat::expect_match(html, "commandId:commandId()", fixed = TRUE)
  testthat::expect_false(grepl("e.key==='Enter'", html, fixed = TRUE))
  testthat::expect_false(grepl("paletteClickReady", html, fixed = TRUE))
})

testthat::test_that("canvas insertion command identities are idempotent across remounts", {
  source <- paste(readLines(testthat::test_path("..", "..", "inst", "htmlwidgets", "src", "widget.jsx"),
    warn = FALSE), collapse = "\n")
  testthat::expect_match(source, "processedInsertCommands", fixed = TRUE)
  testthat::expect_match(source,
    "processedInsertCommands.current.has(commandId)", fixed = TRUE)
  testthat::expect_match(source,
    "{ nodeId: id, capabilityId, commandId }", fixed = TRUE)
})

testthat::test_that("one output supports deterministic three-way fan-out and restoration", {
  registry <- capability_registry()
  capability_registry_add(registry, register_capability(
    "dataset", "1.0.0", "Dataset",
    outputs = list(bundle = port_type("analytical_bundle"))
  ))
  for (id in c("profile", "forecast", "reconcile")) {
    capability_registry_add(registry, register_capability(
      id, "1.0.0", id,
      inputs = list(bundle = port_type("analytical_bundle"))
    ))
  }
  graph <- list(nodes = c(list(list(id = "dataset", capability_id = "dataset")),
    lapply(c("profile", "forecast", "reconcile"), function(id)
      list(id = id, capability_id = id))), edges = list())

  for (target in c("profile", "forecast", "reconcile")) {
    edge <- list(id = paste0("dataset_", target), source = "dataset",
      source_port = "bundle", target = target, target_port = "bundle")
    result <- validate_connection(registry, graph, edge)
    testthat::expect_true(result$valid, info = target)
    graph$edges <- c(graph$edges, list(edge))
  }

  restored <- normalize_workflow_graph(unserialize(serialize(graph, NULL)))
  testthat::expect_length(restored$edges, 3L)
  testthat::expect_identical(unique(vapply(restored$edges, `[[`, character(1),
    "source")), "dataset")
  testthat::expect_identical(unique(vapply(restored$edges, `[[`, character(1),
    "source_port")), "bundle")
  testthat::expect_length(unique(vapply(restored$edges, `[[`, character(1),
    "target")), 3L)
  testthat::expect_false(validate_connection(registry, restored,
    restored$edges[[1L]])$valid)
})
