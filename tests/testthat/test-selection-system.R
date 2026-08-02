testthat::test_that("Selection System renders one generic Shiny input contract", {
  control <- selection_input("choice", "Choice", list(Group = c(a = "A", b = "B")),
    selected = "a", applied = "b", multiple = FALSE, virtual_threshold = 200L)
  html <- as.character(control)
  testthat::expect_match(html, "sc-selection", fixed = TRUE)
  testthat::expect_identical(htmltools::htmlDependencies(control)[[1]]$name,
    "shinycapabilities-selection-system")
  testthat::expect_match(html, "virtualThreshold", fixed = TRUE)
  testthat::expect_match(html, '"searchable":false', fixed = TRUE)
  testthat::expect_match(html, '"scope":"clear"', fixed = TRUE)
  testthat::expect_false(grepl("selectize", html, ignore.case = TRUE))
})

testthat::test_that("Selection System supports small multi and demanding schema modes", {
  small <- selection_input("small", "Small", c("One", "Two"), multiple = TRUE)
  large <- selection_input("large", "Large",
    list(Numeric = stats::setNames(sprintf("field_%05d", 1:25000), sprintf("field_%05d", 1:25000))),
    multiple = TRUE, ordered = TRUE, commands = list(list(id = "all", label = "All eligible")))
  testthat::expect_match(as.character(small), '"multiple":true', fixed = TRUE)
  testthat::expect_match(as.character(large), '"ordered":true', fixed = TRUE)
  testthat::expect_match(as.character(large), "field_25000", fixed = TRUE)
})

testthat::test_that("Selection System contract scales across qualification sizes", {
  for (size in c(25L, 250L, 2500L, 25000L)) {
    fields <- sprintf("field_%05d", seq_len(size))
    control <- selection_input(paste0("size_", size), paste(size, "fields"),
      list(Numeric = stats::setNames(fields, fields)), multiple = TRUE)
    testthat::expect_match(as.character(control), fields[[size]], fixed = TRUE)
  }
})

testthat::test_that("bundled Selection System has one lifecycle owner", {
  source <- paste(readLines(system.file("htmlwidgets", "lib", "selection-system.js",
    package = "shinycapabilities"), warn = FALSE), collapse = "\n")
  testthat::expect_equal(length(gregexpr("Shiny.inputBindings.register", source, fixed = TRUE)[[1]]), 1L)
  testthat::expect_match(source, "shinycapabilities.selectionInput", fixed = TRUE)
  testthat::expect_false(grepl("virtualSelect", source, ignore.case = TRUE))
})
