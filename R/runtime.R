runtime_now <- function() as.numeric(Sys.time())

runtime_timestamp <- function(value = Sys.time()) {
  format(value, tz = "UTC", usetz = TRUE)
}

runtime_failure <- function(type, message, node_id, capability_id,
                            retryable = FALSE, details = list()) {
  structure(list(
    type = type,
    message = as.character(message),
    node_id = node_id,
    capability_id = capability_id,
    retryable = isTRUE(retryable),
    details = details
  ), class = c("shinycap_runtime_failure", "list"))
}

runtime_worker <- function(capability, context, config, inputs) {
  validation <- if (is.function(capability$validate)) {
    capability$validate(context, config, inputs)
  } else {
    list(valid = TRUE)
  }
  if (identical(validation$valid, FALSE)) {
    return(list(ok = FALSE, validation = TRUE, error = validation))
  }
  result <- tryCatch(
    capability$execute(context, config, inputs),
    error = function(error) error
  )
  if (inherits(result, "error")) {
    return(list(ok = FALSE, validation = FALSE, error = conditionMessage(result)))
  }
  outputs <- if (is.list(result) && !is.null(result$outputs)) {
    result$outputs
  } else {
    result
  }
  list(
    ok = TRUE,
    outputs = outputs,
    summary = if (is.function(capability$summarize)) {
      capability$summarize(outputs)
    } else {
      NULL
    }
  )
}

runtime_descendants <- function(graph, node_ids) {
  closure <- unique(node_ids)
  repeat {
    children <- unique(vapply(
      Filter(function(edge) edge$source %in% closure, graph$edges),
      `[[`, character(1), "target"
    ))
    next_closure <- unique(c(closure, children))
    if (setequal(next_closure, closure)) break
    closure <- next_closure
  }
  closure
}

runtime_inputs <- function(runtime, node_id) {
  edges <- Filter(function(edge) identical(edge$target, node_id), runtime$graph$edges)
  stats::setNames(lapply(edges, function(edge) {
    runtime$results[[edge$source]]$outputs[[edge$source_port]]
  }), vapply(edges, `[[`, character(1), "target_port"))
}

runtime_set_lifecycle <- function(runtime, node_id, state, message = NULL,
                                  failure = NULL) {
  current <- runtime$lifecycle[[node_id]]
  now <- runtime_now()
  if (identical(state, "running") && is.null(current$started_at)) {
    current$started_at <- runtime_timestamp()
    current$started_clock <- now
  }
  if (state %in% c("succeeded", "failed", "cancelled", "blocked", "reused")) {
    current$completed_at <- runtime_timestamp()
    current$completed_clock <- now
  }
  current$state <- state
  current$progress_message <- message %||% current$progress_message
  current$failure <- failure
  current$elapsed_seconds <- if (!is.null(current$started_clock)) {
    round(max(0, now - current$started_clock), 3)
  } else {
    0
  }
  runtime$lifecycle[[node_id]] <- current
  runtime$events <- append(runtime$events, list(list(
    node_id = node_id, state = state, at = runtime_timestamp(),
    message = current$progress_message
  )))
  invisible(current)
}

runtime_finalize_success <- function(runtime, node_id, outcome) {
  step <- runtime$steps[[node_id]]
  runtime$results[[node_id]] <- list(
    status = "succeeded",
    outputs = outcome$outputs,
    signature = step$signature,
    completed_at = runtime_timestamp(),
    summary = outcome$summary
  )
  runtime_set_lifecycle(runtime, node_id, "succeeded", "Completed")
}

runtime_finalize_failure <- function(runtime, node_id, type, message,
                                     retryable = FALSE, details = list()) {
  step <- runtime$steps[[node_id]]
  failure <- runtime_failure(
    type, message, node_id, step$capability_id, retryable, details
  )
  runtime$results[[node_id]] <- list(
    status = "failed", error = failure, signature = step$signature
  )
  runtime_set_lifecycle(runtime, node_id, "failed", failure$message, failure)
}

runtime_kill_job <- function(runtime, node_id) {
  job <- runtime$jobs[[node_id]]
  if (is.null(job)) return(invisible(FALSE))
  if (isTRUE(job$process$is_alive())) {
    try(job$process$kill_tree(), silent = TRUE)
    try(job$process$wait(timeout = 2000), silent = TRUE)
  }
  unlink(c(job$stdout_file, job$stderr_file), force = TRUE)
  runtime$jobs[[node_id]] <- NULL
  invisible(TRUE)
}

runtime_poll_jobs <- function(runtime) {
  for (node_id in names(runtime$jobs)) {
    job <- runtime$jobs[[node_id]]
    if (is.null(job)) next
    lifecycle <- runtime$lifecycle[[node_id]]
    elapsed <- runtime_now() - lifecycle$started_clock
    lifecycle$elapsed_seconds <- round(max(0, elapsed), 3)
    runtime$lifecycle[[node_id]] <- lifecycle
    if (elapsed > job$timeout) {
      runtime_set_lifecycle(runtime, node_id, "cancelling", "Timeout reached; stopping owned process")
      runtime_kill_job(runtime, node_id)
      runtime_finalize_failure(
        runtime, node_id, "timeout",
        sprintf("Capability exceeded its %.1f second timeout.", job$timeout),
        retryable = TRUE
      )
      next
    }
    if (job$process$is_alive()) next
    outcome <- tryCatch(
      job$process$get_result(),
      error = function(error) structure(
        list(message = conditionMessage(error)), class = "shinycap_worker_error"
      )
    )
    unlink(c(job$stdout_file, job$stderr_file), force = TRUE)
    runtime$jobs[[node_id]] <- NULL
    if (inherits(outcome, "shinycap_worker_error")) {
      runtime_finalize_failure(
        runtime, node_id, "worker_crash", outcome$message, retryable = TRUE
      )
    } else if (!isTRUE(outcome$ok)) {
      message <- if (is.list(outcome$error)) {
        outcome$error$message %||% paste(unlist(outcome$error), collapse = " ")
      } else {
        outcome$error %||% "Capability execution failed."
      }
      runtime_finalize_failure(
        runtime, node_id,
        if (isTRUE(outcome$validation)) "validation" else "execution",
        message
      )
    } else {
      runtime_finalize_success(runtime, node_id, outcome)
    }
  }
}

runtime_block_unrunnable <- function(runtime) {
  terminal_bad <- c("failed", "cancelled", "blocked")
  for (node_id in runtime$order) {
    state <- runtime$lifecycle[[node_id]]$state
    if (!state %in% c("pending", "queued")) next
    dependencies <- runtime$steps[[node_id]]$dependencies
    bad <- dependencies[vapply(dependencies, function(id) {
      runtime$lifecycle[[id]]$state %in% terminal_bad
    }, logical(1))]
    if (length(bad)) {
      runtime$results[[node_id]] <- list(
        status = "blocked", signature = runtime$steps[[node_id]]$signature,
        error = runtime_failure(
          "upstream_unavailable",
          paste("Blocked by upstream:", paste(bad, collapse = ", ")),
          node_id, runtime$steps[[node_id]]$capability_id,
          details = list(upstream = bad)
        )
      )
      runtime_set_lifecycle(
        runtime, node_id, "blocked",
        paste("Blocked by", paste(bad, collapse = ", "))
      )
    }
  }
}

runtime_ready_nodes <- function(runtime) {
  Filter(function(node_id) {
    identical(runtime$lifecycle[[node_id]]$state, "pending") &&
      all(vapply(runtime$steps[[node_id]]$dependencies, function(id) {
        runtime$lifecycle[[id]]$state %in% c("succeeded", "reused")
      }, logical(1)))
  }, runtime$order)
}

runtime_active_count <- function(runtime, profile = NULL) {
  ids <- names(runtime$jobs)
  if (is.null(profile)) return(length(ids))
  sum(vapply(ids, function(id) {
    identical(runtime$jobs[[id]]$profile, profile)
  }, logical(1)))
}

runtime_profile_limit <- function(runtime, profile) {
  if (identical(profile, "network")) runtime$limits$network else
    runtime$limits$background_r
}

runtime_start_inline <- function(runtime, node_id, capability, node) {
  runtime_set_lifecycle(
    runtime, node_id, "running",
    if (identical(capability$execution_profile, "planning_only")) {
      "Producing bounded plan"
    } else {
      "Executing host-owned operation"
    }
  )
  outcome <- runtime_worker(
    capability, runtime$context, node$config, runtime_inputs(runtime, node_id)
  )
  if (!isTRUE(outcome$ok)) {
    message <- if (is.list(outcome$error)) {
      outcome$error$message %||% paste(unlist(outcome$error), collapse = " ")
    } else {
      outcome$error %||% "Capability execution failed."
    }
    runtime_finalize_failure(
      runtime, node_id,
      if (isTRUE(outcome$validation)) "validation" else "execution",
      message
    )
  } else {
    runtime_finalize_success(runtime, node_id, outcome)
  }
}

runtime_start_background <- function(runtime, node_id, capability, node) {
  profile <- capability$execution_profile
  limit <- min(
    runtime_profile_limit(runtime, profile),
    capability$maximum_concurrency %||% Inf
  )
  if (runtime_active_count(runtime, profile) >= limit) return(FALSE)
  runtime_set_lifecycle(
    runtime, node_id, "running",
    if (identical(profile, "network")) {
      "Running bounded host-owned network request"
    } else {
      "Preparing data and running isolated R computation"
    }
  )
  stdout_file <- tempfile(paste0("shinycap-", node_id, "-"), fileext = ".out")
  stderr_file <- tempfile(paste0("shinycap-", node_id, "-"), fileext = ".err")
  process <- tryCatch(
    callr::r_bg(
      runtime_worker,
      args = list(
        capability = capability,
        context = runtime$context,
        config = node$config,
        inputs = runtime_inputs(runtime, node_id)
      ),
      supervise = TRUE,
      stdout = stdout_file,
      stderr = stderr_file
    ),
    error = function(error) error
  )
  if (inherits(process, "error")) {
    unlink(c(stdout_file, stderr_file), force = TRUE)
    runtime_finalize_failure(
      runtime, node_id, "worker_start", conditionMessage(process), retryable = TRUE
    )
    return(TRUE)
  }
  runtime$jobs[[node_id]] <- list(
    process = process, profile = profile, timeout = capability$timeout,
    stdout_file = stdout_file, stderr_file = stderr_file
  )
  TRUE
}

#' Create a bounded non-blocking workflow runtime
#'
#' The runtime owns only callr child processes it starts. Call `tick()` from a
#' Shiny invalidation loop or use `run_workflow_runtime()` in synchronous tests.
#' @param registry Capability registry.
#' @param graph Workflow graph.
#' @param plan A valid plan from `plan_workflow()`.
#' @param context Host context containing process-portable values/functions.
#' @param cache Existing successful result cache.
#' @param max_background Maximum concurrent background R workers.
#' @param max_network Maximum concurrent network workers.
#' @export
workflow_runtime <- function(registry, graph, plan, context = list(), cache = list(),
                             max_background = 2L, max_network = 1L) {
  if (!isTRUE(plan$valid)) stop("Cannot start an invalid plan.", call. = FALSE)
  graph <- expand_workflow_composites(graph)
  if (any(vapply(graph$nodes, function(node) {
    identical(node$metadata$proposal_status %||% "", "proposed")
  }, logical(1)))) {
    stop("Proposed nodes must be accepted before execution.", call. = FALSE)
  }
  runtime <- new.env(parent = emptyenv())
  class(runtime) <- "shinycap_runtime"
  runtime$registry <- registry
  runtime$graph <- graph
  runtime$plan <- plan
  runtime$context <- context
  runtime$results <- cache
  runtime$order <- plan$order
  runtime$steps <- stats::setNames(plan$steps, vapply(
    plan$steps, `[[`, character(1), "node_id"
  ))
  runtime$nodes <- stats::setNames(graph$nodes, vapply(
    graph$nodes, `[[`, character(1), "id"
  ))
  runtime$limits <- list(
    background_r = max(1L, as.integer(max_background)),
    network = max(1L, as.integer(max_network))
  )
  runtime$jobs <- list()
  runtime$events <- list()
  runtime$cancelled <- FALSE
  runtime$lifecycle <- stats::setNames(lapply(plan$steps, function(step) {
    reused <- identical(step$action, "skipped/current")
    list(
      node_id = step$node_id,
      state = if (reused) "reused" else "pending",
      queued_at = runtime_timestamp(),
      started_at = NULL,
      completed_at = if (reused) runtime_timestamp() else NULL,
      started_clock = NULL,
      completed_clock = if (reused) runtime_now() else NULL,
      elapsed_seconds = 0,
      progress_message = if (reused) "Reused current cached result" else "Waiting for dependencies",
      upstream = step$dependencies,
      cache_status = if (reused) "reused" else "not_current",
      failure = NULL
    )
  }), vapply(plan$steps, `[[`, character(1), "node_id"))
  runtime
}

#' Advance a non-blocking workflow runtime
#' @param runtime Runtime returned by `workflow_runtime()`.
#' @export
tick_workflow_runtime <- function(runtime) {
  stopifnot(inherits(runtime, "shinycap_runtime"))
  runtime_poll_jobs(runtime)
  runtime_block_unrunnable(runtime)
  ready <- runtime_ready_nodes(runtime)
  for (node_id in ready) {
    capability <- capability_registry_get(
      runtime$registry, runtime$steps[[node_id]]$capability_id
    )
    node <- runtime$nodes[[node_id]]
    runtime_set_lifecycle(runtime, node_id, "queued", "Dependencies satisfied; queued")
    if (capability$execution_profile %in% c("inline", "planning_only")) {
      runtime_start_inline(runtime, node_id, capability, node)
    } else {
      started <- runtime_start_background(runtime, node_id, capability, node)
      if (!isTRUE(started)) {
        runtime_set_lifecycle(runtime, node_id, "pending", "Waiting for concurrency slot")
      }
    }
  }
  runtime_block_unrunnable(runtime)
  invisible(runtime)
}

#' Inspect serializable runtime state
#' @param runtime Runtime returned by `workflow_runtime()`.
#' @export
workflow_runtime_snapshot <- function(runtime) {
  stopifnot(inherits(runtime, "shinycap_runtime"))
  states <- vapply(runtime$lifecycle, `[[`, character(1), "state")
  completed <- states %in% c("succeeded", "failed", "cancelled", "blocked", "reused")
  list(
    lifecycle = runtime$lifecycle,
    results = runtime$results,
    active_jobs = runtime_active_count(runtime),
    total_nodes = length(states),
    completed_nodes = sum(completed),
    progress = if (length(states)) sum(completed) / length(states) else 1,
    complete = all(completed),
    cancelled = isTRUE(runtime$cancelled),
    events = runtime$events
  )
}

#' Cancel one running or queued node
#' @param runtime Runtime returned by `workflow_runtime()`.
#' @param node_id Node identifier.
#' @export
cancel_workflow_node <- function(runtime, node_id) {
  stopifnot(inherits(runtime, "shinycap_runtime"))
  if (!node_id %in% names(runtime$lifecycle)) return(invisible(FALSE))
  state <- runtime$lifecycle[[node_id]]$state
  if (state %in% c("succeeded", "reused", "failed", "cancelled", "blocked")) {
    return(invisible(FALSE))
  }
  runtime_set_lifecycle(runtime, node_id, "cancelling", "Cancelling owned work")
  runtime_kill_job(runtime, node_id)
  runtime$results[[node_id]] <- list(
    status = "cancelled", signature = runtime$steps[[node_id]]$signature,
    error = runtime_failure(
      "cancelled", "Cancelled by user.", node_id,
      runtime$steps[[node_id]]$capability_id, retryable = TRUE
    )
  )
  runtime_set_lifecycle(runtime, node_id, "cancelled", "Cancelled by user")
  runtime_block_unrunnable(runtime)
  invisible(TRUE)
}

#' Cancel a node and its dependent branch
#' @param runtime Runtime returned by `workflow_runtime()`.
#' @param node_id Branch root.
#' @export
cancel_workflow_branch <- function(runtime, node_id) {
  ids <- runtime_descendants(runtime$graph, node_id)
  for (id in intersect(runtime$order, ids)) cancel_workflow_node(runtime, id)
  invisible(ids)
}

#' Cancel every unfinished node in a workflow
#' @param runtime Runtime returned by `workflow_runtime()`.
#' @export
cancel_workflow_runtime <- function(runtime) {
  runtime$cancelled <- TRUE
  for (id in runtime$order) cancel_workflow_node(runtime, id)
  invisible(runtime)
}

#' Clean up only processes owned by a workflow runtime
#' @param runtime Runtime returned by `workflow_runtime()`.
#' @export
cleanup_workflow_runtime <- function(runtime) {
  for (id in names(runtime$jobs)) runtime_kill_job(runtime, id)
  invisible(runtime)
}

#' Run the non-blocking runtime to completion for tests and scripts
#' @param runtime Runtime returned by `workflow_runtime()`.
#' @param poll_interval Polling interval in seconds.
#' @param overall_timeout Overall test/helper timeout.
#' @export
run_workflow_runtime <- function(runtime, poll_interval = 0.02,
                                 overall_timeout = 600) {
  started <- runtime_now()
  repeat {
    tick_workflow_runtime(runtime)
    snapshot <- workflow_runtime_snapshot(runtime)
    if (isTRUE(snapshot$complete)) return(snapshot)
    if (runtime_now() - started > overall_timeout) {
      cancel_workflow_runtime(runtime)
      stop("Workflow runtime helper exceeded its overall timeout.", call. = FALSE)
    }
    Sys.sleep(poll_interval)
  }
}
