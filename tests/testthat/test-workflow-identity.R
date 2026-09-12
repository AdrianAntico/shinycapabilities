identity_fixture <- function() {
  r <- capability_registry()
  cap <- register_capability("identity.source", "1.0.0", "Source",
    implementation_fingerprint = "qualified-implementation-sha",
    resource_hints = list(owner = list(package = "Owner", version = "1.0.0", sha = "exact-sha")),
    execute = function(...) stop("ANALYTICAL_REPLAY_FORBIDDEN"))
  capability_registry_add(r, cap)
  node <- list(id = "source", capability_id = cap$id,
    config = list(dataset_revision = "input-r1", a = 1, nested = list(z = TRUE, a = "text")))
  graph <- normalize_workflow_graph(list(nodes = list(node), edges = list()))
  node <- graph$nodes[[1]]
  cache <- list(source = list(status = "succeeded", signature = legacy_node_signature(node, cap, setNames(list(), character())),
    outputs = list(native = list(value = c(NA_real_, 3), alternatives = c("a", "b"))),
    completed_at = "retained-original-time"))
  authority <- list(project_id = "p1", workflow_id = "w1", input_revision = "r1", owners = list(cap$resource_hints$owner))
  witness <- list(graph = graph, cache = cache, capabilities = setNames(list(cap[c("id", "version", "implementation_fingerprint", "resource_hints", "execution_contract")]), cap$id),
    authority = authority, provenance = list(artifact_revision = "immutable-r1"))
  # Fixture models an immutable store: altered records cannot authenticate.
  saved <- serialize(witness, NULL)
  verify <- function(x) identical(serialize(x, NULL), saved)
  list(registry = r, graph = graph, node = node, cap = cap, witness = witness,
    authority = authority, verify = verify)
}

test_that("canonical signatures distinguish maps, sequences and scalar types", {
  x <- identity_fixture(); sig <- function(config) { n <- x$node; n$config <- config; node_signature(n, x$cap) }
  c <- x$node$config
  expect_identical(sig(c), sig(c[rev(seq_along(c))]))
  d <- c; d$nested <- d$nested[c("a", "z")]
  expect_identical(sig(c), sig(d))
  expect_identical(sig(list(a = 1L)), sig(list(a = 1)))
  values <- list(1, "1", TRUE, NULL, factor("1"), list(1), c(1, 2), c(2, 1))
  expect_length(unique(vapply(values, sig, "")), length(values))
  expect_false(identical(sig(list(1, 2)), sig(list(2, 1))))
  expect_false(identical(sig(c), sig(modifyList(c, list(a = 2)))))
  expect_false(identical(sig(c), sig(modifyList(c, list(dataset_revision = "input-r2")))))
  expect_error(sig(setNames(list(1, 2), c("a", "a"))), "AMBIGUOUS_NAMES")
  expect_false(identical(sig(NA_real_), sig(NA_character_)))
  expect_false(identical(sig(c(a = 1)), sig(list(a = 1))))
  expect_false(identical(sig(factor("a", levels = c("a", "b"))),
    sig(factor("a", levels = c("b", "a")))))
})

test_that("capability, implementation, owner and node identities remain exact", {
  x <- identity_fixture(); original <- node_signature(x$node, x$cap)
  for (field in c("id", "version", "implementation_fingerprint")) {
    cap <- x$cap; cap[[field]] <- paste0(cap[[field]], "-changed")
    expect_false(identical(original, node_signature(x$node, cap)))
  }
  cap <- x$cap; cap$resource_hints$owner$sha <- "other"
  expect_false(identical(original, node_signature(x$node, cap)))
  node <- x$node; node$id <- "other"
  expect_false(identical(original, node_signature(node, x$cap)))
  expect_false(identical(node_signature(x$node, x$cap, list(input = "r1")),
    node_signature(x$node, x$cap, list(input = "r2"))))
})

test_that("authenticated legacy migration preserves native results without replay", {
  x <- identity_fixture(); graph <- x$graph
  graph$nodes[[1]]$config <- graph$nodes[[1]]$config[c("nested", "a", "dataset_revision")]
  graph$nodes[[1]]$config$nested <- graph$nodes[[1]]$config$nested[c("a", "z")]
  graph$nodes[[1]]$config$a <- 1L
  result <- migrate_workflow_cache(x$registry, graph, x$witness, x$authority, x$verify)
  expect_true(result$ok)
  expect_identical(result$cache$source$outputs, x$witness$cache$source$outputs)
  expect_identical(result$cache$source$completed_at, x$witness$cache$source$completed_at)
  expect_identical(result$cache$source$signature, x$witness$cache$source$signature)
  original <- result$cache$source; attr(original, "workflow_identity_migration") <- NULL
  expect_identical(original, x$witness$cache$source)
  expect_identical(result$legacy, x$witness)
  expect_identical(result$audit$source$legacy_signature, x$witness$cache$source$signature)
  expect_identical(result$analytical_execution_count, 0L)
  expect_identical(plan_workflow(x$registry, graph, cache = result$cache)$steps[[1]]$action, "skipped/current")
  restored <- unserialize(serialize(result, NULL))
  expect_identical(restored, result)
  tampered <- result$cache; tampered$source$outputs$native$value <- 42
  expect_identical(plan_workflow(x$registry, graph, cache = tampered)$steps[[1]]$action, "execute")
  stripped <- result$cache; attr(stripped$source, "workflow_identity_migration") <- NULL
  expect_identical(plan_workflow(x$registry, graph, cache = stripped)$steps[[1]]$action, "execute")
})

test_that("changed or unverifiable legacy execution fails closed", {
  x <- identity_fixture()
  run <- function(graph = x$graph, witness = x$witness, authority = x$authority, verify = x$verify)
    migrate_workflow_cache(x$registry, graph, witness, authority, verify)
  expect_false(run(verify = NULL)$ok)
  changed <- x$graph; changed$nodes[[1]]$config$a <- 2
  expect_identical(run(graph = changed)$code, "LEGACY_INPUTS_CHANGED")
  authority <- x$authority; authority$workflow_id <- "foreign-session-workflow"
  expect_identical(run(authority = authority)$code, "LEGACY_AUTHORITY_CHANGED")
  witness <- x$witness; witness$cache$source$outputs$native$value <- 99
  expect_identical(run(witness = witness)$code, "LEGACY_PROVENANCE_UNVERIFIABLE")
  cap <- x$cap; cap$implementation_fingerprint <- "changed"
  capability_registry_add(x$registry, cap)
  expect_identical(run()$code, "LEGACY_IMPLEMENTATION_CHANGED_OR_UNVERIFIABLE")
})


