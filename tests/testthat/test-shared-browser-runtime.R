testthat::test_that("shared runtime has deterministic identity and ordering", {
  palette <- htmltools::htmlDependencies(command_palette_direct_output("palette"))
  split <- htmltools::htmlDependencies(split_pane_direct_output("split"))
  testthat::expect_identical(vapply(palette, `[[`, character(1), "name"), c(
    "shinycapabilities-browser-runtime", "shinycapabilities-direct-transport",
    "shinycapabilities-direct-command-palette-direct"))
  testthat::expect_identical(vapply(split, `[[`, character(1), "name"), c(
    "shinycapabilities-browser-runtime", "shinycapabilities-direct-transport",
    "shinycapabilities-direct-split-pane-direct"))
  combined <- htmltools::resolveDependencies(c(palette, split))
  testthat::expect_identical(sum(vapply(combined, `[[`, character(1), "name") ==
    "shinycapabilities-browser-runtime"), 1L)
  testthat::expect_identical(sum(vapply(combined, `[[`, character(1), "name") ==
    "shinycapabilities-direct-transport"), 1L)
})

testthat::test_that("non-React persistent UI stays runtime-free", {
  dependencies <- htmltools::htmlDependencies(persistent_ui_output("persistent"))
  testthat::expect_false("shinycapabilities-browser-runtime" %in%
    vapply(dependencies, `[[`, character(1), "name"))
})

testthat::test_that("specialized engines do not attach the shared React runtime", {
  grid <- data_grid(data.frame(id = 1:2, value = c("a", "b")), row_id = "id")
  graph <- relationship_graph(list(list(id = "a", label = "A", type = "dataset")), list(),
    show_minimap = FALSE)
  for (widget in list(grid, graph)) {
    names <- vapply(htmltools::findDependencies(widget), `[[`, character(1), "name")
    testthat::expect_false("shinycapabilities-browser-runtime" %in% names)
  }
})

testthat::test_that("direct split pane preserves normalized split semantics", {
  component <- split_pane_direct(list(left = htmltools::div("Left"),
    right = htmltools::div("Right")), sizes = c(35, 65), collapsible = c(TRUE, FALSE))
  testthat::expect_s3_class(component, "shinycapabilities_direct_component")
  testthat::expect_identical(component$component, "split_pane_direct")
  testthat::expect_identical(component$payload$ids, c("left", "right"))
  testthat::expect_identical(component$payload$sizes$left, "35%")
  testthat::expect_match(component$payload$html$left, "Left", fixed = TRUE)
})

testthat::test_that("direct split updates are bounded namespaced messages", {
  fake <- new.env(parent = emptyenv()); fake$ns <- function(id) paste0("module-", id)
  fake$sendCustomMessage <- function(type, message) { fake$type <- type; fake$message <- message }
  update_split_pane_direct(fake, "layout", sizes = c(left = 40, right = 60),
    collapse = "right", revision = 8L)
  testthat::expect_identical(fake$message$id, "module-layout")
  testthat::expect_identical(fake$message$component, "split_pane_direct")
  testthat::expect_identical(fake$message$revision, 8L)
  testthat::expect_identical(fake$message$payload$collapse, "right")
})

testthat::test_that("runtime sources enforce compatibility and specialized isolation", {
  root <- system.file("www", "direct-transport", package = "shinycapabilities")
  runtime <- paste(readLines(file.path(root, "src", "direct-react-vendor.jsx"), warn = FALSE), collapse = "\n")
  transport <- paste(readLines(file.path(root, "src", "direct-transport.js"), warn = FALSE), collapse = "\n")
  split <- paste(readLines(file.path(root, "src", "split-pane-direct.jsx"), warn = FALSE), collapse = "\n")
  testthat::expect_match(runtime, "identity", fixed = TRUE)
  testthat::expect_match(runtime, "assertCompatible", fixed = TRUE)
  testthat::expect_match(transport, "runtimeMajor", fixed = TRUE)
  testthat::expect_match(split, "react-resizable-panels", fixed = TRUE)
  testthat::expect_false(grepl("AG Grid|XYFlow|dagre", runtime, ignore.case = TRUE))
})

testthat::test_that("shared runtime assets and composition demo ship", {
  root <- system.file("www", "direct-transport", package = "shinycapabilities")
  files <- c("browser-runtime-v1.js", "direct-transport.js", "command-palette-direct.js",
    "split-pane-direct.js", "split-pane-direct.css")
  testthat::expect_true(all(file.exists(file.path(root, files))))
  testthat::expect_lt(file.info(file.path(root, "command-palette-direct.js"))$size, 20000)
  testthat::expect_lt(file.info(file.path(root, "split-pane-direct.js"))$size, 60000)
  testthat::expect_true(file.exists(system.file("examples", "shared-runtime", "app.R",
    package = "shinycapabilities")))
})
