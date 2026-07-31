alpha_registry <- function() {
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
    execute = function(context, config, inputs) list(dataset = inputs$dataset)
  ))
  capability_registry_add(registry, register_capability(
    "profile.data", "1.0.0", "Profile",
    inputs = list(dataset = port_type("dataset")),
    outputs = list(profile = port_type("data_profile")),
    execute = function(context, config, inputs) list(profile = summary(inputs$dataset))
  ))
  registry
}

alpha_graph <- function() list(
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

test_that("composites preserve and transparently execute their internal graph", {
  registry <- alpha_registry()
  graph <- alpha_graph()
  collapsed <- collapse_workflow(graph, c("prepare", "profile"), "explore", "Explore")
  expect_equal(sort(vapply(collapsed$nodes, `[[`, character(1), "id")), c("explore", "source"))
  expect_true(plan_workflow(registry, collapsed)$valid)
  restored <- expand_workflow_composite(collapsed, "explore")
  expect_equal(graph_fingerprint(restored), graph_fingerprint(graph))
})

test_that("proposal acceptance is selective and visibly recorded", {
  proposal <- workflow_proposal(
    "ai-1", alpha_graph(), list(profile = "Summarize the data."),
    connection_explanations = list(a = "Use the source dataset."),
    overall_rationale = "Profile governed data.",
    missing_evidence = list("No external research."),
    recommended_execution_order = c("source", "prepare", "profile")
  )
  accepted <- accept_workflow_proposal(proposal, node_ids = c("source", "prepare"))
  expect_equal(sort(vapply(accepted$nodes, `[[`, character(1), "id")), c("prepare", "source"))
  expect_true(all(vapply(accepted$nodes, function(node) {
    identical(node$metadata$proposal_status, "accepted")
  }, logical(1))))
  expect_equal(proposal$recommended_execution_order, c("source", "prepare", "profile"))
})

test_that("workflow documents keep output layout separate and restore composites", {
  collapsed <- collapse_workflow(alpha_graph(), c("prepare", "profile"), "explore")
  document <- workflow_document(collapsed, list(output_placement("plot:1", position = 2)))
  restored <- restore_workflow_document(serialize_workflow_document(document))
  expect_equal(graph_fingerprint(restored$graph), graph_fingerprint(collapsed))
  expect_equal(restored$output_placements[[1]]$artifact_id, "plot:1")
})

test_that("numeric controls tolerate an unspecified step", {
  field <- config_field("numeric", "Result limit", 4L, minimum = 1L, maximum = 10L)
  control <- config_control(identity, "limit", field, 4L)
  expect_s3_class(control, "shiny.tag")
})
