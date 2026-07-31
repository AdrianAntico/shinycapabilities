alpha_registry <- function() {
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
    execute = function(context, config, inputs) list(value = inputs$value)
  ))
  capability_registry_add(registry, register_capability(
    "summarize.value", "1.0.0", "Summarize",
    inputs = list(value = port_type("value")),
    outputs = list(summary = port_type("summary")),
    execute = function(context, config, inputs) list(summary = length(inputs$value))
  ))
  registry
}

alpha_graph <- function() list(
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

test_that("composites preserve and transparently execute their internal graph", {
  registry <- alpha_registry()
  graph <- alpha_graph()
  collapsed <- collapse_workflow(graph, c("transform", "summary"), "grouped", "Grouped")
  expect_equal(sort(vapply(collapsed$nodes, `[[`, character(1), "id")), c("grouped", "source"))
  expect_true(plan_workflow(registry, collapsed)$valid)
  restored <- expand_workflow_composite(collapsed, "grouped")
  expect_equal(graph_fingerprint(restored), graph_fingerprint(graph))
})

test_that("proposal acceptance is selective and visibly recorded", {
  proposal <- workflow_proposal(
    "proposal-1", alpha_graph(), list(summary = "Summarize the value."),
    connection_explanations = list(a = "Use the source value."),
    overall_rationale = "Create a bounded summary.",
    unresolved_requirements = list("No additional input is required."),
    recommended_execution_order = c("source", "transform", "summary")
  )
  accepted <- accept_workflow_proposal(proposal, node_ids = c("source", "transform"))
  expect_equal(sort(vapply(accepted$nodes, `[[`, character(1), "id")), c("source", "transform"))
  expect_true(all(vapply(accepted$nodes, function(node) {
    identical(node$metadata$proposal_status, "accepted")
  }, logical(1))))
  expect_equal(proposal$recommended_execution_order, c("source", "transform", "summary"))
})

test_that("workflow documents keep output layout separate and restore composites", {
  collapsed <- collapse_workflow(alpha_graph(), c("transform", "summary"), "grouped")
  document <- workflow_document(collapsed, list(output_placement("output:1", position = 2)))
  restored <- restore_workflow_document(serialize_workflow_document(document))
  expect_equal(graph_fingerprint(restored$graph), graph_fingerprint(collapsed))
  expect_equal(restored$output_placements[[1]]$artifact_id, "output:1")
})

test_that("numeric controls tolerate an unspecified step", {
  field <- config_field("numeric", "Result limit", 4L, minimum = 1L, maximum = 10L)
  control <- config_control(identity, "limit", field, 4L)
  expect_s3_class(control, "shiny.tag")
})
