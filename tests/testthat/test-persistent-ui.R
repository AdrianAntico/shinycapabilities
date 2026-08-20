testthat::test_that("persistent UI normalizes bounded nested schemas", {
  component <- persistent_ui(list(list(id = "summary", type = "section", label = "Summary", children = list(
    list(id = "row", type = "row", children = list(
      list(id = "value", type = "value", label = "Rows", value = 100L),
      list(id = "status", type = "badge", label = "Ready", status = "success"),
      list(id = "note", type = "field", label = "Note", value = "Draft"),
      list(id = "inspect", type = "action", label = "Inspect")))))))
  testthat::expect_s3_class(component, "shinycapabilities_direct_component")
  testthat::expect_identical(component$component, "persistent_ui")
  testthat::expect_length(component$payload$nodes, 6L)
  testthat::expect_identical(component$payload$nodes[[2]]$parentId, "summary")
  testthat::expect_identical(component$payload$nodes[[3]]$parentId, "row")
})

testthat::test_that("persistent UI rejects ambiguous structure", {
  testthat::expect_error(persistent_ui(list(list(id = "x"), list(id = "x"))), "unique")
  testthat::expect_error(persistent_ui(list(list(id = "x", parent_id = "missing"))), "Unknown")
  testthat::expect_error(persistent_ui(list(list(id = "text", type = "text"),
    list(id = "child", parent_id = "text"))), "contain children")
  testthat::expect_error(persistent_ui(list(list(id = "a", type = "section", parent_id = "b"),
    list(id = "b", type = "section", parent_id = "a"))), "cycle")
})

testthat::test_that("persistent UI uses a React-free lazy dependency", {
  tag <- persistent_ui_output("panel")
  dependencies <- htmltools::htmlDependencies(tag)
  testthat::expect_identical(vapply(dependencies, function(x) x$script[[1]], character(1)),
    c("direct-transport.js", "persistent-ui.js"))
  testthat::expect_identical(dependencies[[2]]$stylesheet, "persistent-ui.css")
  testthat::expect_false(any(grepl("react", unlist(lapply(dependencies, `[[`, "script")), ignore.case = TRUE)))
})

testthat::test_that("persistent updates send compact deterministic diffs", {
  old <- list(list(id = "a", type = "value", label = "A", value = 1),
    list(id = "gone", type = "text", value = "remove"))
  current <- list(list(id = "a", type = "value", label = "A", value = 2),
    list(id = "new", type = "badge", label = "Ready", status = "success"))
  fake <- new.env(parent = emptyenv()); fake$ns <- function(id) paste0("mod-", id)
  fake$sendCustomMessage <- function(type, message) { fake$type <- type; fake$message <- message }
  result <- update_persistent_ui(fake, "panel", current, 9L, previous_nodes = old)
  testthat::expect_identical(fake$message$id, "mod-panel")
  testthat::expect_identical(fake$message$revision, 9L)
  testthat::expect_identical(fake$message$payload$patch$remove, "gone")
  testthat::expect_identical(vapply(fake$message$payload$patch$upsert, `[[`, character(1), "id"), c("a", "new"))
  testthat::expect_length(result, 2L)
})

testthat::test_that("persistent source owns keyed patch and accessibility contracts", {
  root <- system.file("www", "direct-transport", package = "shinycapabilities")
  source <- paste(readLines(file.path(root, "src", "persistent-ui.js"), warn = FALSE), collapse = "\n")
  css <- paste(readLines(file.path(root, "src", "persistent-ui.css"), warn = FALSE), collapse = "\n")
  for (marker in c("scPersistentId", "local.elements", "container.insertBefore(element",
      "scrollTop", "local.drafts", "aria-expanded")) {
    testthat::expect_match(source, marker, fixed = TRUE)
  }
  testthat::expect_match(source, "patchModel.patch", fixed = TRUE)
  testthat::expect_match(source, "source: \"user\"", fixed = TRUE)
  testthat::expect_match(css, ":focus-visible", fixed = TRUE)
  testthat::expect_match(css, "forced-colors", fixed = TRUE)
})

testthat::test_that("persistent assets and demo ship in source packages", {
  root <- system.file("www", "direct-transport", package = "shinycapabilities")
  testthat::expect_true(all(file.exists(file.path(root, c("persistent-ui.js", "persistent-ui.css",
    "src/persistent-ui.js", "src/persistent-ui.css")))))
  testthat::expect_true(file.exists(system.file("examples", "persistent-ui", "app.R", package = "shinycapabilities")))
})
