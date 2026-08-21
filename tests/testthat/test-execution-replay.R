replay_fixture <- function(n = 6L) {
  execution <- list(execution_id = "run-1", label = "QA execution", type = "analysis",
    status = "completed", source_mode = "fixture", metadata = list(owner = "qa"))
  events <- lapply(seq_len(n), function(i) list(event_id = paste0("e", i), sequence = i,
    occurred_at = sprintf("2026-01-01T00:00:%02dZ", i),
    event_type = c("started", "evidence", "failure", "retry", "review", "completed")[(i - 1L) %% 6L + 1L],
    actor_id = if (i == 5L) "human" else "agent", source = "fixture",
    status = if (i == 3L) "failed" else "completed", summary = paste("Event", i),
    entity_ids = "workflow", metadata = list(step = i)))
  snapshots <- list(
    list(snapshot_id = "s1", sequence = 1L, entity_id = "workflow", state = "running", version = "v1"),
    list(snapshot_id = "s2", sequence = 3L, entity_id = "workflow", state = "blocked", version = "v2"),
    list(snapshot_id = "s3", sequence = 4L, entity_id = "workflow", state = "retrying", version = "v3"),
    list(snapshot_id = "s4", sequence = 6L, entity_id = "workflow", state = "completed", version = "v4"))
  related <- list(
    list(record_id = "ev1", record_type = "evidence", label = "Evidence", sequence = 2L, entity_id = "workflow"),
    list(record_id = "fail1", record_type = "failure", label = "Failure", sequence = 3L, entity_id = "workflow", related_ids = "ev1"),
    list(record_id = "review1", record_type = "review", label = "Review", sequence = 5L, entity_id = "workflow", related_ids = "fail1"))
  list(execution = execution, events = events, snapshots = snapshots, related = related)
}

testthat::test_that("execution replay normalizes deterministic identity and order", {
  f <- replay_fixture()
  widget <- execution_replay(f$execution, rev(f$events), f$snapshots, f$related)
  testthat::expect_s3_class(widget, "execution_replay")
  testthat::expect_identical(widget$x$execution$execution_id, "run-1")
  testthat::expect_identical(vapply(widget$x$events, `[[`, integer(1), "sequence"), 1:6)
  testthat::expect_identical(widget$x$events[[3]]$event_type, "failure")
})

testthat::test_that("duplicate and malformed records fail deterministically", {
  f <- replay_fixture()
  testthat::expect_error(execution_replay(f$execution, c(f$events, f$events[1])), "event_id values must be unique")
  bad <- f$events; bad[[1]]$sequence <- -1L
  testthat::expect_error(execution_replay(f$execution, bad), "non-negative integer")
  bad <- f$snapshots; bad[[1]]$entity_id <- ""
  testthat::expect_error(execution_replay(f$execution, f$events, bad), "snapshot entity_id must be non-empty")
})

testthat::test_that("state at time never projects future state backward", {
  f <- replay_fixture()
  normalized <- execution_replay_model(f$execution, f$events, f$snapshots, f$related)
  at_two <- execution_replay_state_at(normalized$snapshots, normalized$relatedRecords, 2L)
  at_four <- execution_replay_state_at(normalized$snapshots, normalized$relatedRecords, 4L)
  testthat::expect_identical(at_two$state[[1]]$state, "running")
  testthat::expect_identical(vapply(at_two$related, `[[`, character(1), "record_id"), "ev1")
  testthat::expect_identical(at_four$state[[1]]$state, "retrying")
  testthat::expect_false("review1" %in% vapply(at_four$related, `[[`, character(1), "record_id"))
})

testthat::test_that("history is bounded and retains latest deterministic events", {
  f <- replay_fixture(5000L)
  widget <- execution_replay(f$execution, f$events, max_events = 500L)
  testthat::expect_length(widget$x$events, 500L)
  testthat::expect_identical(widget$x$events[[1]]$event_id, "e4501")
  testthat::expect_true(any(grepl("oldest event", widget$x$diagnostics)))
})

testthat::test_that("recursive redaction removes private and credential fields", {
  f <- replay_fixture(); f$events[[1]]$metadata <- list(safe = "yes", raw_prompt = "private",
    nested = list(chain_of_thought = "private", result = "bounded"), api_token = "private")
  widget <- execution_replay(f$execution, f$events)
  metadata <- widget$x$events[[1]]$metadata
  testthat::expect_identical(metadata$safe, "yes")
  testthat::expect_false(any(c("raw_prompt", "api_token") %in% names(metadata)))
  testthat::expect_identical(metadata$nested$result, "bounded")
  testthat::expect_false("chain_of_thought" %in% names(metadata$nested))
})

testthat::test_that("missing telemetry stays absent and references become diagnostics", {
  f <- replay_fixture(); f$events[[1]]$artifact_ids <- "missing-artifact"
  widget <- execution_replay(f$execution, f$events, f$snapshots, f$related)
  testthat::expect_null(widget$x$events[[1]]$metadata$progress)
  testthat::expect_true(any(grepl("not represented", widget$x$diagnostics)))
})

testthat::test_that("update messages are namespaced and mode explicit", {
  f <- replay_fixture(); captured <- new.env(parent = emptyenv())
  session <- list(ns = function(id) paste0("module-", id),
    sendCustomMessage = function(type, message) { captured$type <- type; captured$message <- message })
  update_execution_replay(session, "replay", events = f$events[6], snapshots = f$snapshots[4],
    related_records = f$related[3], mode = "append")
  testthat::expect_identical(captured$type, "shinycapabilities.direct.update")
  testthat::expect_identical(captured$message$id, "module-replay")
  testthat::expect_identical(captured$message$component, "execution_replay")
  testthat::expect_identical(captured$message$payload$mode, "append")
  testthat::expect_identical(captured$message$payload$events[[1]]$event_id, "e6")
})

testthat::test_that("assets, demo, and public widget helpers are installable", {
  testthat::expect_true(file.exists(system.file("www", "direct-transport", "execution-replay.js", package = "shinycapabilities")))
  testthat::expect_true(file.exists(system.file("www", "direct-transport", "execution-replay.css", package = "shinycapabilities")))
  demo <- system.file("examples", "execution-replay", "app.R", package = "shinycapabilities")
  testthat::expect_true(file.exists(demo))
  testthat::expect_true(all(vapply(c(execution_replay, execution_replay_output,
    render_execution_replay, update_execution_replay), is.function, logical(1))))
})
