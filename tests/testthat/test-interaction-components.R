testthat::test_that("virtual tree browser normalizes nested and flat records", {
  widget <- virtual_tree_browser(list(
    list(id = "root", label = "Root", children = list(
      list(id = "child", label = "Child", badge = "table", metadata = list(rows = 10L))
    ))
  ), expanded = "root")
  testthat::expect_s3_class(widget, "shinycapabilities_direct_component")
  testthat::expect_s3_class(widget, "virtual_tree_browser")
  testthat::expect_length(widget$x$nodes, 2L)
  testthat::expect_identical(widget$x$nodes[[2]]$parentId, "root")
  testthat::expect_identical(widget$x$nodes[[2]]$metadata$rows, 10L)

  flat <- virtual_tree_browser(data.frame(
    id = c("a", "b"), parent_id = c("", "a"), label = c("A", "B")
  ))
  testthat::expect_length(flat$x$nodes, 2L)
  testthat::expect_identical(flat$x$nodes[[2]]$parentId, "a")
})

testthat::test_that("tree browser rejects ambiguous identity and parent contracts", {
  testthat::expect_error(virtual_tree_browser(list(
    list(id = "a", label = "A"), list(id = "a", label = "Again")
  )), "unique")
  testthat::expect_error(virtual_tree_browser(list(
    list(id = "a", parent_id = "missing", label = "A")
  )), "Unknown tree parent")
  testthat::expect_error(virtual_tree_browser(list(
    list(id = "a", parent_id = "a", label = "A")
  )), "own parent")
  testthat::expect_error(virtual_tree_browser(list(
    list(id = "a", parent_id = "b", label = "A"),
    list(id = "b", parent_id = "a", label = "B")
  )), "cycle")
})

testthat::test_that("command palette preserves bounded host metadata", {
  widget <- command_palette(list(
    list(id = "run", label = "Run analysis", group = "Analyze",
      keywords = c("execute", "module"), shortcut = "Ctrl R",
      metadata = list(capability_id = "analytics.run"))
  ), server_search = TRUE)
  testthat::expect_s3_class(widget, "shinycapabilities_direct_component")
  testthat::expect_s3_class(widget, "command_palette")
  testthat::expect_true(widget$x$options$serverSearch)
  testthat::expect_identical(widget$x$items[[1]]$metadata$capability_id, "analytics.run")
  testthat::expect_error(command_palette(list(
    list(id = "run", label = "Run"), list(id = "run", label = "Run again")
  )), "unique")
})

testthat::test_that("interaction component sources expose semantic accessibility contracts", {
  source <- paste(readLines(system.file("www", "direct-transport", "src", "interaction-components.jsx",
    package = "shinycapabilities"), warn = FALSE), collapse = "\n")
  css <- paste(readLines(system.file("www", "direct-transport", "src", "interaction-components.css",
    package = "shinycapabilities"), warn = FALSE), collapse = "\n")
  testthat::expect_match(source, 'role="tree"', fixed = TRUE)
  testthat::expect_match(source, 'role="treeitem"', fixed = TRUE)
  testthat::expect_match(source, 'role="combobox"', fixed = TRUE)
  testthat::expect_match(source, "aria-activedescendant", fixed = TRUE)
  testthat::expect_match(source, "useVirtualizer", fixed = TRUE)
  testthat::expect_match(source, 'publish(element, "selection"', fixed = TRUE)
  testthat::expect_match(source, 'publish(element, "command"', fixed = TRUE)
  testthat::expect_match(css, ":focus-visible", fixed = TRUE)
  testthat::expect_match(css, "prefers-reduced-motion", fixed = TRUE)
  testthat::expect_match(css, "forced-colors", fixed = TRUE)
})

testthat::test_that("interaction components ship installable bundled dependencies", {
  root <- system.file("www", "direct-transport", package = "shinycapabilities")
  testthat::expect_true(file.exists(file.path(root, "interaction-components.js")))
  testthat::expect_true(file.exists(file.path(root, "command-palette-direct.js")))
  testthat::expect_true(file.exists(system.file("examples", "interaction-components", "app.R",
    package = "shinycapabilities")))
})
