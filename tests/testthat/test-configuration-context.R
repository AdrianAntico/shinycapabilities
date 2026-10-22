context_fixture <- function(unit = "unit") {
  registry <- capability_registry()
  capability_registry_add(registry, register_capability(
    "neutral.context", "1.0.0", "Context", "UI isolation", "Neutral",
    config = list(unit = config_field("text", "Unit"),
      acknowledge = config_field("checkbox", "Acknowledge")),
    execute = function(...) stop("No execution is permitted in context qualification")))
  graph <- list(nodes = list(list(id = "effect", capability_id = "neutral.context",
    config = list(unit = unit, acknowledge = FALSE), position = list(x = 0, y = 0))), edges = list())
  list(registry = registry, graph = graph)
}

testthat::test_that("checkpoint activation rejects old fields and actions before applying one new field", {
  fixture <- context_fixture()
  shiny::testServer(capability_canvas_server,
    args = list(registry = fixture$registry, initial_graph = fixture$graph), {
      put <- function(key, value) do.call(session$setInputs, setNames(list(value), key))
      select <- function() session$setInputs(canvas_event = list(type = "node_selected", nodeId = "effect"))
      ctx <- list(project = "P", workflow = "W1", revision = "R1")
      original <- session$returned$graph()
      saved_cache <- list(effect = list(signature = "retained", result = list(native = 42)))
      session$returned$set_cache(saved_cache)
      session$returned$set_configuration_context(ctx)
      select()
      session$flushReact()
      first <- configuration_node_key("effect")
      put("inspector_owner", first)
      put(config_input_key(first, "unit"), "unit")
      put(paste0(config_input_key(first, "unit"), "_change"), list(value = "unit", nonce = "first-change"))
      session$flushReact()
      second_graph <- original
      second_graph$nodes[[1]]$config$unit <- "one_unit"
      session$returned$set_configuration_context(list(project = "P", workflow = "W2", revision = "R2"))
      session$returned$set_graph(second_graph)
      session$returned$set_config_drafts(list())
      select()
      session$flushReact()
      second <- configuration_node_key("effect")
      testthat::expect_false(identical(first, second))
      testthat::expect_identical(session$returned$cache(), saved_cache)
      testthat::expect_identical(session$returned$config_drafts(), list())
      testthat::expect_identical(session$returned$graph()$nodes[[1]]$config$unit, "one_unit")
      put(paste0("save_config__", first), 1L)
      put("save_config", 1L)
      put(paste0("discard_config__", first), 1L)
      session$flushReact()
      testthat::expect_identical(session$returned$config_drafts(), list())
      testthat::expect_identical(session$returned$graph()$nodes[[1]]$config$unit, "one_unit")
      put("inspector_owner", second)
      put(config_input_key(second, "acknowledge"), TRUE)
      session$flushReact()
      testthat::expect_identical(session$returned$config_drafts()$effect$acknowledge, TRUE)
      testthat::expect_null(session$returned$config_drafts()$effect$unit)
      put(configuration_action_key("save_config"), 1L)
      session$flushReact()
      testthat::expect_identical(session$returned$graph()$nodes[[1]]$config$unit, "one_unit")
      testthat::expect_identical(session$returned$graph()$nodes[[1]]$config$acknowledge, TRUE)
      # Same-context History activation must invalidate even a recently active form.
      session$returned$set_configuration_context(list(project = "P", workflow = "W2", revision = "R2"))
      session$returned$set_graph(second_graph)
      session$returned$set_config_drafts(list(effect = list(unit = "history_draft")))
      select()
      session$flushReact()
      third <- configuration_node_key("effect")
      testthat::expect_false(identical(second, third))
      put(paste0(config_input_key(second, "unit"), "_change"), list(value = "late_old_value", nonce = "late-change"))
      put(paste0("save_config__", second), 2L)
      put(paste0("discard_config__", second), 2L)
      session$flushReact()
      testthat::expect_identical(session$returned$config_drafts()$effect$unit, "history_draft")
      testthat::expect_identical(session$returned$graph()$nodes[[1]]$config, second_graph$nodes[[1]]$config)
      # Matching generation without matching owner handshake cannot apply.
      put(configuration_action_key("save_config"), 1L)
      session$flushReact()
      testthat::expect_identical(session$returned$graph()$nodes[[1]]$config$unit, "one_unit")
      put("inspector_owner", third)
      put(configuration_action_key("save_config"), 2L)
      session$flushReact()
      testthat::expect_identical(session$returned$graph()$nodes[[1]]$config$unit, "history_draft")
    })
})

testthat::test_that("selection activation and independent sessions never share form authority", {
  fixture <- context_fixture()
  other <- fixture$graph$nodes[[1]]
  other$id <- "other"
  fixture$graph$nodes[[2]] <- other
  captured <- character()
  for (session_index in seq_len(2L)) {
    shiny::testServer(capability_canvas_server,
      args = list(registry = fixture$registry, initial_graph = fixture$graph), {
        session$returned$set_configuration_context(list(project = "P", workflow = "W", revision = "R"))
        session$setInputs(canvas_event = list(type = "node_selected", nodeId = "effect"))
        first <- configuration_node_key("effect")
        session$setInputs(canvas_event = list(type = "node_selected", nodeId = "other"))
        session$setInputs(canvas_event = list(type = "node_selected", nodeId = "effect"))
        session$flushReact()
        testthat::expect_false(identical(first, configuration_node_key("effect")))
        testthat::expect_identical(session$returned$config_drafts(), list())
        testthat::expect_identical(session$returned$graph()$nodes[[1]]$config$unit, "unit")
        session$returned$set_config_drafts(list(effect = list(unit = paste0("session", session_index))))
        captured[[session_index]] <<- session$returned$config_drafts()$effect$unit
        before <- session$returned$graph()
        testthat::expect_error(session$returned$set_configuration_context(list(workflow = NA_character_)), "identities")
        testthat::expect_identical(session$returned$graph(), before)
      })
  }
  testthat::expect_identical(captured, c("session1", "session2"))
})
