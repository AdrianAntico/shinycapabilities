testthat::test_that("code editor validates and normalizes its public contract", {
  editor <- code_editor("x <- 1", language = "R", diagnostics = list(
    list(severity = "warning", line = 1, column = 1, message = "Check x")
  ), element_id = "editor-a")
  testthat::expect_s3_class(editor, "shinycapabilities_direct_component")
  testthat::expect_identical(editor$component, "code_editor")
  testthat::expect_identical(editor$payload$language, "r")
  testthat::expect_identical(editor$payload$diagnostics[[1]]$startLineNumber, 1L)
  testthat::expect_error(code_editor(language = "sas"), "language must be one of")
  testthat::expect_error(code_editor(mode = "diff"), "original_value is required")
})

testthat::test_that("editor dependency is scoped, modular, and installable", {
  tag <- code_editor_output("code", height = "500px")
  deps <- htmltools::htmlDependencies(tag)
  testthat::expect_identical(vapply(deps, `[[`, character(1), "name"), c(
    "shinycapabilities-direct-transport", "shinycapabilities-direct-code-editor"))
  script <- deps[[2]]$script
  testthat::expect_identical(script$src, "code-editor.js")
  testthat::expect_identical(script$type, "module")
  root <- system.file("www", "direct-transport", package = "shinycapabilities")
  testthat::expect_true(all(file.exists(file.path(root, c(
    "direct-transport.js", "code-editor.js", "code-editor.css")))))
  testthat::expect_true(any(grepl("editor.worker", list.files(file.path(root, "assets")))))
})

testthat::test_that("editor source owns drafts, conflicts, markers, diff, and completions", {
  root <- system.file("www", "direct-transport", package = "shinycapabilities")
  source <- paste(readLines(file.path(root, "src", "code-editor.js"), warn = FALSE), collapse = "\n")
  for (marker in c("createDiffEditor", "setModelMarkers", "registerCompletionItemProvider",
      "pendingHost", "applyDraft", "hostRevision", "onDidChangeContent")) {
    testthat::expect_match(source, marker, fixed = TRUE)
  }
  testthat::expect_false(grepl("CodeMirror", source, fixed = TRUE))
})

testthat::test_that("editor updates are namespaced and deterministic", {
  fake <- new.env(parent = emptyenv())
  fake$ns <- function(id) paste0("module-", id)
  fake$sendCustomMessage <- function(type, message) { fake$type <- type; fake$message <- message }
  update_code_editor(fake, "code", value = "x <- 2", language = "r",
    diagnostics = list(list(message = "Issue", line = 1)), host_revision = 9L,
    revision = 10L)
  testthat::expect_identical(fake$message$id, "module-code")
  testthat::expect_identical(fake$message$component, "code_editor")
  testthat::expect_identical(fake$message$payload$hostRevision, 9L)
  testthat::expect_identical(fake$message$revision, 10L)
})

testthat::test_that("editor language inventory and demo are complete", {
  testthat::expect_identical(code_editor_languages(),
    c("r", "julia", "python", "sql", "json", "yaml", "markdown"))
  testthat::expect_true(file.exists(system.file("examples", "code-editor", "app.R",
    package = "shinycapabilities")))
})
