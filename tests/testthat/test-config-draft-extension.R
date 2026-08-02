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

testthat::test_that("Shiny inputs publish drafts without a second browser bridge", {
  source <- paste(deparse(capability_canvas_server), collapse = "\n")
  testthat::expect_match(source, "input[[paste0(\"config__\", name)]]", fixed = TRUE)
  testthat::expect_false(grepl("analytics-input-draft", source, fixed = TRUE))
  testthat::expect_false(grepl("config_draft_event", source, fixed = TRUE))
  testthat::expect_match(source, "shiny::isolate(config_drafts())", fixed = TRUE)
  testthat::expect_match(source, "Discard changes", fixed = TRUE)
})
