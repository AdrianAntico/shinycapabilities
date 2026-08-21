testthat::test_that("package has no htmlwidgets dependency or implementation", {
  description <- read.dcf(testthat::test_path("..", "..", "DESCRIPTION"))
  imports <- strsplit(description[1, "Imports"], ",")[[1L]]
  testthat::expect_false(any(trimws(imports) == "htmlwidgets"))
  roots <- c(testthat::test_path("..", "..", "R"),
    testthat::test_path("..", "..", "inst", "www", "direct-transport"))
  files <- unlist(lapply(roots, list.files, recursive = TRUE, full.names = TRUE), use.names = FALSE)
  files <- files[!grepl("/assets/|\\\\assets\\\\", files)]
  source <- paste(vapply(files, function(path) paste(readLines(path, warn = FALSE), collapse = "\n"), character(1)), collapse = "\n")
  testthat::expect_false(grepl("htmlwidgets::|createWidget\\(|shinyWidgetOutput|shinyRenderWidget|HTMLWidgets\\.widget", source))
  testthat::expect_false(dir.exists(testthat::test_path("..", "..", "inst", "htmlwidgets")))
})

testthat::test_that("migrated public constructors use direct transport", {
  registry <- default_capability_catalog()
  values <- list(
    capability_canvas(registry),
    virtual_tree_browser(list(list(id = "a", label = "A"))),
    command_palette(list(list(id = "a", label = "A"))),
    data_grid(data.frame(id = 1L), row_id = "id"),
    agent_activity_monitor(list(), list()),
    relationship_graph(list(list(id = "a", label = "A", type = "artifact")), list()),
    execution_replay(list(execution_id = "x", label = "X", type = "analysis",
      status = "running", source_mode = "fixture"), list())
  )
  testthat::expect_true(all(vapply(values, inherits, logical(1), "shinycapabilities_direct_component")))
  testthat::expect_true(all(vapply(values, function(value) !inherits(value, "htmlwidget"), logical(1))))
})

testthat::test_that("composition fixture is installed", {
  testthat::expect_true(file.exists(system.file("examples", "component-composition", "app.R",
    package = "shinycapabilities")))
})
