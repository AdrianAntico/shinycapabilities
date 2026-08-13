testthat::test_that("workstation header exposes a generic declarative contract", {
  groups <- list(workstation_header_group("file", "File", weight = 2), workstation_header_group("view", "View", preferred_row = 2))
  commands <- list(
    workstation_header_command("open", "Open", "file", priority = 1, shortcut = "Ctrl+O", payload = list(action = "open"), overflow = FALSE),
    workstation_header_command("save", "Save", "file", enabled = FALSE, disabled_reason = "Nothing to save", overflow_only = TRUE),
    workstation_header_command("focus", "Focus", "view", active = TRUE, preferred_row = 2),
    workstation_header_command("context", "Context", "view", contextual = FALSE)
  )
  html <- as.character(workstation_header_ui("head", "Workbench", groups, commands, context = "Ready", rows = 2))
  testthat::expect_match(html, "sc-workstation-header", fixed = TRUE)
  testthat::expect_match(html, "data-rows=\"2\"", fixed = TRUE)
  testthat::expect_match(html, "Nothing to save", fixed = TRUE)
  testthat::expect_match(html, "aria-pressed=\"true\"", fixed = TRUE)
  testthat::expect_match(html, "Ctrl+O", fixed = TRUE)
  testthat::expect_match(html, "--sc-wh-group-grow:2", fixed = TRUE)
  testthat::expect_match(html, "data-overflow-only=\"true\"", fixed = TRUE)
  testthat::expect_false(grepl("Context</span>", html, fixed = TRUE))
})

testthat::test_that("workstation header assets implement responsive accessible overflow", {
  js <- paste(readLines(system.file("www/workstation-header.js", package = "shinycapabilities"), warn = FALSE), collapse = "\n")
  css <- paste(readLines(system.file("www/workstation-header.css", package = "shinycapabilities"), warn = FALSE), collapse = "\n")
  testthat::expect_match(js, "ResizeObserver", fixed = TRUE)
  testthat::expect_match(js, "layoutState", fixed = TRUE)
  testthat::expect_match(js, "overflowOnly", fixed = TRUE)
  testthat::expect_match(js, "shinycapabilities:workstation-header-layout", fixed = TRUE)
  testthat::expect_match(js, "ArrowLeft", fixed = TRUE)
  testthat::expect_match(js, "disabled", fixed = TRUE)
  testthat::expect_match(css, "var(--aq-surface", fixed = TRUE)
  testthat::expect_match(css, "focus-visible", fixed = TRUE)
  testthat::expect_match(css, "@media", fixed = TRUE)
})

testthat::test_that("workflow execution refuses unapplied configuration drafts", {
  module <- paste(deparse(capability_canvas_server), collapse = "\n")
  testthat::expect_match(module, "data-shinycap-config-dirty", fixed = TRUE)
  testthat::expect_match(module,
    "Apply or discard pending configuration changes before running the workflow.",
    fixed = TRUE)
  testthat::expect_match(module,
    "if (length(shiny::isolate(config_drafts())))", fixed = TRUE)
})
