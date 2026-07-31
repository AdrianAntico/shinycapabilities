testthat::test_that("compatibility manifest closes the additive contract", {
  manifest <- shinycapabilities_compatibility_manifest()
  testthat::expect_identical(manifest$package_api_contract, "1.0.0")
  testthat::expect_identical(manifest$browser_bridge, "1.0.0")
  testthat::expect_identical(manifest$workflow_document$readable, "1.0.0")
  testthat::expect_identical(manifest$workflow_document$writable, "1.0.0")
})

testthat::test_that("module return fields remain additive and controls are versioned", {
  registry <- default_capability_catalog()
  shiny::testServer(
    capability_canvas_server,
    args = list(
      registry = registry,
      initial_graph = list(nodes = list(), edges = list()),
      bind_internal_controls = FALSE
    ),
    {
      returned <- session$returned
      legacy <- c(
        "graph", "cache", "selection", "plan", "runtime", "is_running",
        "run_plan", "cancel_workflow", "set_graph", "set_cache"
      )
      controls <- c(
        "run_selected", "run_with_dependencies", "run_workflow",
        "cancel_node", "cancel_branch", "cancel_workflow", "force_run",
        "clear_cache", "reset_failed", "inspect_plan", "fit_view",
        "replace_graph", "replace_cache", "selection", "runtime"
      )
      testthat::expect_true(all(legacy %in% names(returned)))
      testthat::expect_identical(returned$contract_version, "1.0.0")
      testthat::expect_true(all(controls %in% names(returned$controls)))
      testthat::expect_identical(
        returned$controls$contract_version, "1.0.0"
      )
    }
  )
})

testthat::test_that("neutral presentation uses only registered vocabulary", {
  registry <- capability_registry()
  capability_registry_add(registry, register_capability(
    "neutral.step", "1.0.0", "Neutral step",
    category = "Host group",
    inputs = list(source_value = port_type("source_value")),
    outputs = list(result_value = port_type("result_value")),
    execute = function(context, config, inputs) list(result_value = inputs$source_value)
  ))
  payload <- shinycapabilities:::registry_payload(registry)[[1]]
  testthat::expect_identical(payload$presentation$category, "Host group")
  testthat::expect_identical(payload$presentation$icon, "\u25c7")
  testthat::expect_identical(payload$inputs$source_value$displayLabel, "source value")
})

testthat::test_that("host presentation metadata owns groups icons and port labels", {
  registry <- capability_registry()
  capability_registry_add(registry, register_capability(
    "host.review", "1.0.0", "Review",
    inputs = list(item = port_type("item")),
    outputs = list(outcome = port_type("outcome")),
    execute = function(context, config, inputs) list(outcome = TRUE),
    presentation = list(
      group_id = "review", group_label = "Review", group_order = 20,
      display_order = 3, icon_id = "check", short_summary = "Review an item.",
      compact_summary = "Review", input_port_labels = list(item = "Submission"),
      output_port_labels = list(outcome = "Outcome"),
      emphasis = "consequential", accessibility_label = "Review submission"
    )
  ))
  payload <- shinycapabilities:::registry_payload(registry)[[1]]
  testthat::expect_identical(payload$presentation$group_id, "review")
  testthat::expect_identical(payload$icon, "check")
  testthat::expect_identical(payload$inputs$item$displayLabel, "Submission")
  testthat::expect_identical(payload$outputs$outcome$displayLabel, "Outcome")
})

testthat::test_that("palette visible identities are unique within each category", {
  registry <- capability_registry()
  make_capability <- function(id, label, group) register_capability(
    id, "1.0.0", label, presentation = list(
      group_id = tolower(group), group_label = group
    )
  )
  capability_registry_add(registry, make_capability("host.first", "Final summary", "Publish"))
  capability_registry_add(registry, make_capability("host.second", " final   summary ", "Publish"))

  result <- validate_capability_palette(registry)
  testthat::expect_false(result$valid)
  testthat::expect_identical(result$findings[[1]]$code, "ambiguous_palette_identity")
  testthat::expect_identical(
    result$findings[[1]]$capability_ids,
    c("host.first", "host.second")
  )
  testthat::expect_error(
    shinycapabilities:::palette_ui(
      shiny::NS("test"), registry
    ),
    "multiple capabilities labeled"
  )

  other_group <- make_capability("host.third", "Final summary", "Review")
  capability_registry_add(registry, other_group)
  capability_registry_add(registry, register_capability(
    "host.second", "1.0.0", "Short summary",
    presentation = list(group_id = "publish", group_label = "Publish")
  ))
  testthat::expect_true(
    validate_capability_palette(registry)$valid
  )
})

testthat::test_that("workflow schema validation preserves 1.0.0 bytes", {
  document <- workflow_document(
    list(nodes = list(), edges = list()),
    list(output_placement("artifact:one"))
  )
  serialized <- serialize_workflow_document(document)
  testthat::expect_true(validate_workflow_document(serialized)$valid)
  testthat::expect_identical(
    serialize_workflow_document(restore_workflow_document(serialized)),
    serialized
  )
  invalid <- jsonlite::fromJSON(serialized, simplifyVector = FALSE)
  invalid$schema_version <- "2.0.0"
  testthat::expect_false(validate_workflow_document(invalid)$valid)
  testthat::expect_identical(
    validate_workflow_document(1)$findings[[1]]$code, "invalid_document"
  )
  invalid <- jsonlite::fromJSON(serialized, simplifyVector = FALSE)
  invalid$unknown <- TRUE
  testthat::expect_identical(
    validate_workflow_document(invalid)$findings[[1]]$code,
    "unknown_document_field"
  )
})

testthat::test_that("the default catalog has no package-owned domain vocabulary", {
  registry <- default_capability_catalog()
  testthat::expect_length(capability_registry_list(registry), 0L)
})

testthat::test_that("versioned and legacy browser bridge aliases are bundled", {
  bundle <- system.file(
    "htmlwidgets", "lib", "shinycapabilities.js",
    package = "shinycapabilities"
  )
  source <- paste(readLines(
    bundle, warn = FALSE
  ), collapse = "\n")
  for (name in c(
    "shinycapabilities:set-graph", "shinycapabilities:v1:set-graph",
    "shinycapabilities:connection-result",
    "shinycapabilities:v1:connection-result",
    "shinycapabilities:insert", "shinycapabilities:v1:insert",
    "application/x-shinycapability",
    "application/vnd.shinycapabilities.capability+json;version=1"
  )) testthat::expect_match(source, name, fixed = TRUE)
})

testthat::test_that("core contains no host-domain compatibility vocabulary", {
  roots <- c(
    "R", file.path("inst", "htmlwidgets"), file.path("inst", "examples"),
    file.path("tests", "testthat")
  )
  files <- unlist(lapply(roots, function(root) {
    list.files(root, recursive = TRUE, full.names = TRUE)
  }), use.names = FALSE)
  files <- files[file.info(files)$isdir %in% FALSE]
  contents <- paste(vapply(files, function(path) {
    paste(readLines(path, warn = FALSE), collapse = "\n")
  }, character(1)), collapse = "\n")
  prohibited <- c(
    paste0("ana", "lytics."),
    paste0("legacy_", "analytical"),
    paste0("example_", "analytical_catalog"),
    paste0("dataset", ".source"),
    paste0("eda", ".profile"),
    paste0("model", ".train"),
    paste0("forecast", ".fit"),
    paste0("causal", ".estimate"),
    paste0("research", ".collect"),
    paste0("report", ".generate"),
    paste0('port_type("', "dataset", '")'),
    paste0('config_field("', "dataset", '")'),
    paste0('config_field("', "column", '")'),
    paste0('config_field("', "formula", '")')
  )
  testthat::expect_false(any(vapply(
    prohibited, grepl, logical(1), x = contents, fixed = TRUE
  )))
})

testthat::test_that("configuration selectors are neutral host primitives", {
  for (type in c("resource", "property", "expression")) {
    field <- config_field(type, paste(type, "value"), "example")
    testthat::expect_identical(field$type, type)
    testthat::expect_s3_class(
      shinycapabilities:::config_control(identity, type, field, "example"),
      "shiny.tag"
    )
  }
  for (retired in c("dataset", "column", "formula")) {
    testthat::expect_error(config_field(retired, "Retired"), "Unsupported")
  }
})

testthat::test_that("Shiny owns the rendered canvas output identity", {
  module_source <- paste(deparse(body(capability_canvas_server)), collapse = "\n")
  testthat::expect_false(grepl(
    "capability_canvas(registry, graph(), element_id = session$ns(\"canvas\"))",
    module_source,
    fixed = TRUE
  ))
})
