node_signature <- function(node, capability, dependency_results = list()) {
  stable_hash(list(
    capability_id = capability$id,
    capability_version = capability$version,
    implementation = capability$implementation_fingerprint,
    config = node$config,
    dependencies = dependency_results
  ))
}

topological_order <- function(graph, subset_ids = NULL) {
  ids <- vapply(graph$nodes, `[[`, character(1), "id")
  if (!is.null(subset_ids)) ids <- intersect(ids, subset_ids)
  incoming <- setNames(integer(length(ids)), ids)
  adjacency <- setNames(vector("list", length(ids)), ids)
  for (edge in graph$edges) {
    if (edge$source %in% ids && edge$target %in% ids) {
      incoming[[edge$target]] <- incoming[[edge$target]] + 1L
      adjacency[[edge$source]] <- c(adjacency[[edge$source]], edge$target)
    }
  }
  queue <- sort(names(incoming)[incoming == 0L])
  result <- character()
  while (length(queue)) {
    current <- queue[[1]]
    queue <- queue[-1]
    result <- c(result, current)
    for (target in sort(unique(adjacency[[current]]))) {
      incoming[[target]] <- incoming[[target]] - 1L
      if (incoming[[target]] == 0L) queue <- sort(c(queue, target))
    }
  }
  if (length(result) != length(ids)) stop("workflow_cycle_detected", call. = FALSE)
  result
}

upstream_closure <- function(graph, node_ids) {
  closure <- unique(node_ids)
  repeat {
    parents <- unique(vapply(
      Filter(function(edge) edge$target %in% closure, graph$edges),
      `[[`, character(1), "source"
    ))
    next_closure <- unique(c(closure, parents))
    if (setequal(next_closure, closure)) break
    closure <- next_closure
  }
  closure
}

#' Build an executable workflow plan
#' @param registry Capability registry.
#' @param graph Workflow graph.
#' @param target Optional target node identifier.
#' @param cache Existing result cache.
#' @param force Whether to rerun current nodes.
#' @export
plan_workflow <- function(registry, graph, target = NULL, cache = list(), force = FALSE) {
  graph <- expand_workflow_composites(graph)
  validation <- validate_workflow(registry, graph)
  if (!validation$valid) return(list(valid = FALSE, findings = validation$findings, steps = list()))
  node_ids <- vapply(graph$nodes, `[[`, character(1), "id")
  required <- if (is.null(target)) node_ids else upstream_closure(graph, target)
  order <- tryCatch(topological_order(graph, required), error = function(error) error)
  if (inherits(order, "error")) {
    return(list(valid = FALSE, findings = list(list(code = "cycle", message = conditionMessage(order))), steps = list()))
  }
  nodes <- setNames(graph$nodes, node_ids)
  signatures <- list()
  steps <- lapply(order, function(id) {
    node <- nodes[[id]]
    cap <- capability_registry_get(registry, node$capability_id)
    dependencies <- Filter(function(edge) identical(edge$target, id), graph$edges)
    dependency_signatures <- setNames(
      lapply(dependencies, function(edge) signatures[[edge$source]] %||% NA_character_),
      vapply(dependencies, `[[`, character(1), "source")
    )
    signature <- node_signature(node, cap, dependency_signatures)
    signatures[[id]] <<- signature
    cached <- cache[[id]]
    current <- !isTRUE(force) && identical(cap$cache_policy, "reuse_current") &&
      !is.null(cached) && identical(cached$status, "succeeded") &&
      identical(cached$signature, signature)
    list(
      node_id = id, capability_id = cap$id,
      action = if (current) "skipped/current" else "execute",
      reason = if (current) "cache_current" else if (is.null(cached)) "never_run" else "stale_or_failed",
      signature = signature, dependencies = names(dependency_signatures)
    )
  })
  list(
    valid = TRUE, target = target, force = isTRUE(force), order = order,
    steps = steps, findings = list(), fingerprint = stable_hash(steps)
  )
}

#' Execute a planned workflow in R
#' @param registry Capability registry.
#' @param graph Workflow graph.
#' @param plan Valid execution plan.
#' @param context Host execution context.
#' @param cache Existing result cache.
#' @export
execute_workflow_plan <- function(registry, graph, plan, context = list(), cache = list()) {
  if (!isTRUE(plan$valid)) stop("Cannot execute an invalid plan.", call. = FALSE)
  graph <- expand_workflow_composites(graph)
  if (any(vapply(graph$nodes, function(node) {
    identical(node$metadata$proposal_status %||% "", "proposed")
  }, logical(1)))) {
    stop("Proposed nodes must be accepted before execution.", call. = FALSE)
  }
  nodes <- setNames(graph$nodes, vapply(graph$nodes, `[[`, character(1), "id"))
  results <- cache
  events <- list()
  for (step in plan$steps) {
    id <- step$node_id
    if (identical(step$action, "skipped/current")) {
      events <- append(events, list(list(node_id = id, state = "skipped/current")))
      next
    }
    dependency_failures <- Filter(
      function(dep) !identical(results[[dep]]$status %||% NULL, "succeeded"),
      step$dependencies
    )
    if (length(dependency_failures)) {
      results[[id]] <- list(status = "blocked", signature = step$signature)
      events <- append(events, list(list(node_id = id, state = "blocked")))
      next
    }
    node <- nodes[[id]]
    cap <- capability_registry_get(registry, node$capability_id)
    input_edges <- Filter(function(edge) identical(edge$target, id), graph$edges)
    inputs <- setNames(lapply(input_edges, function(edge) {
      results[[edge$source]]$outputs[[edge$source_port]]
    }), vapply(input_edges, `[[`, character(1), "target_port"))
    validation <- if (is.function(cap$validate)) cap$validate(context, node$config, inputs) else list(valid = TRUE)
    if (identical(validation$valid, FALSE)) {
      results[[id]] <- list(status = "failed", error = validation, signature = step$signature)
      events <- append(events, list(list(node_id = id, state = "failed")))
      next
    }
    events <- append(events, list(list(node_id = id, state = "running")))
    outcome <- tryCatch(
      cap$execute(context, node$config, inputs),
      error = function(error) structure(list(message = conditionMessage(error)), class = "shinycap_error")
    )
    if (inherits(outcome, "shinycap_error")) {
      results[[id]] <- list(status = "failed", error = outcome$message, signature = step$signature)
      events <- append(events, list(list(node_id = id, state = "failed")))
    } else {
      outputs <- if (is.list(outcome) && !is.null(outcome$outputs)) outcome$outputs else outcome
      results[[id]] <- list(
        status = "succeeded", outputs = outputs, signature = step$signature,
        completed_at = format(Sys.time(), tz = "UTC", usetz = TRUE),
        summary = if (is.function(cap$summarize)) cap$summarize(outputs) else NULL
      )
      events <- append(events, list(list(node_id = id, state = "succeeded")))
    }
  }
  list(results = results, events = events, plan = plan)
}
