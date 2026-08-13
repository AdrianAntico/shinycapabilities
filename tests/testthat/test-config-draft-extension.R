testthat::test_that("configuration fields preserve uninterpreted host metadata", {
  field <- config_field("property", "Field", metadata = list(widget = "host_picker", role = "opaque"))
  testthat::expect_identical(field$metadata$widget, "host_picker")
  testthat::expect_identical(field$metadata$role, "opaque")
})

testthat::test_that("canvas exposes generic draft restoration controls", {
  registry <- capability_registry()
  capability_registry_add(registry, register_capability(
    "neutral.edit", "1.0.0", "Editable", "Neutral edit", "Neutral",
    config = list(value = config_field("text", "Value")), execute = function(...) list()))
  graph <- list(nodes = list(list(id = "edit", capability_id = "neutral.edit",
    position = list(x = 0, y = 0), config = list(value = "applied"), state = "ready")), edges = list())
  shiny::testServer(capability_canvas_server, args = list(registry = registry, initial_graph = graph), {
    session$returned$set_config_drafts(list(edit = list(value = "pending")))
    testthat::expect_identical(session$returned$config_drafts()$edit$value, "pending")
    testthat::expect_identical(session$returned$graph()$nodes[[1]]$config$value, "applied")
  })
})

testthat::test_that("inspector apply preserves host-owned configuration", {
  registry <- capability_registry()
  capability_registry_add(registry, register_capability(
    "neutral.edit", "1.0.0", "Editable", "Neutral edit", "Neutral",
    config = list(value = config_field("text", "Value")), execute = function(...) list()))
  graph <- list(nodes = list(list(id = "edit", capability_id = "neutral.edit",
    position = list(x = 0, y = 0),
    config = list(value = "applied", host_binding = "exact-resource-v1"),
    state = "ready")), edges = list())
  shiny::testServer(capability_canvas_server,
    args = list(registry = registry, initial_graph = graph), {
      session$setInputs(canvas_event = list(type = "node_selected", nodeId = "edit"))
      session$flushReact()
      session$setInputs(inspector_owner = "edit")
      session$flushReact()
      do.call(session$setInputs, setNames(list("revised"), "node__edit__config__value"))
      session$flushReact()
      session$setInputs(save_config = 1L)
      config <- session$returned$graph()$nodes[[1L]]$config
      testthat::expect_identical(config$host_binding, "exact-resource-v1")
    })
})

testthat::test_that("inspector subtree identity follows the selected node", {
  source <- paste(deparse(capability_canvas_server), collapse = "\n")
  testthat::expect_match(source, "inspector_node__", fixed = TRUE)
  testthat::expect_match(source, "node$id", fixed = TRUE)
  testthat::expect_match(source, "inspector_owner", fixed = TRUE)
  testthat::expect_match(source, "config_input_key(node$id, name)", fixed = TRUE)
  testthat::expect_match(source,
    "identical(input$inspector_owner %||% \"\", node$id)", fixed = TRUE)
})

testthat::test_that("Shiny inputs publish drafts without a second browser bridge", {
  source <- paste(deparse(capability_canvas_server), collapse = "\n")
  testthat::expect_match(source, "input[[config_input_key(node$id, name)]]", fixed = TRUE)
  testthat::expect_false(grepl("analytics-input-draft", source, fixed = TRUE))
  testthat::expect_false(grepl("config_draft_event", source, fixed = TRUE))
  testthat::expect_match(source, "shiny::isolate(config_drafts())", fixed = TRUE)
  testthat::expect_match(source, "Discard changes", fixed = TRUE)
  testthat::expect_match(source, "had_draft <- length(node_draft) > 0L", fixed = TRUE)
  testthat::expect_match(source, "if (!had_draft || any(refresh))", fixed = TRUE)
  testthat::expect_match(source, "inspector_revision(inspector_revision() + 1L)", fixed = TRUE)
})

testthat::test_that("configurable inspectors expose one state-aware sticky action region", {
  source <- paste(deparse(capability_canvas_server), collapse = "\n")
  css <- paste(readLines(system.file("htmlwidgets", "src", "widget.css",
    package = "shinycapabilities"), warn = FALSE), collapse = "\n")
  testthat::expect_match(source, "sc-inspector-sticky-actions", fixed = TRUE)
  testthat::expect_equal(length(gregexpr("Apply configuration", source, fixed = TRUE)[[1]]), 1L)
  testthat::expect_equal(length(gregexpr("Discard changes", source, fixed = TRUE)[[1]]), 1L)
  testthat::expect_match(source, 'disabled = "disabled"', fixed = TRUE)
  testthat::expect_match(css, "position: sticky", fixed = TRUE)
  testthat::expect_match(css, "background: color-mix(in srgb, var(--sc-panel) 96%, var(--sc-bg))", fixed = TRUE)
  testthat::expect_match(css, "flex-wrap: wrap", fixed = TRUE)
  testthat::expect_match(css, ".sc-inspector > .shiny-html-output { overflow: visible !important; }", fixed = TRUE)
})
