testthat::test_that("data grid infers typed columns and deterministic identities", {
  data <- data.frame(
    label = c("A", "B"), amount = c(1.25, NA_real_), active = c(TRUE, FALSE),
    day = as.Date(c("2026-01-01", "2026-01-02"))
  )
  widget <- data_grid(data)
  testthat::expect_s3_class(widget, "shinycapabilities_direct_component")
  testthat::expect_s3_class(widget, "data_grid")
  testthat::expect_identical(vapply(widget$x$columns, `[[`, character(1), "scType"),
    c("text", "number", "logical", "date"))
  testthat::expect_identical(widget$x$rows[[".sc_row_id"]][[1]], "row_000000001")
  testthat::expect_true(is.na(widget$x$rows$amount[[2]]))
})

testthat::test_that("data grid validates identity, columns, and options", {
  data <- data.frame(id = c("a", "b"), value = 1:2)
  widget <- data_grid(data, row_id = "id", columns = list(
    id = list(pinned = "left"), value = list(format = "compact", digits = 2L)
  ), options = list(selection = "multiple", accessibility_mode = "paginated"))
  testthat::expect_identical(widget$x$rows[[".sc_row_id"]][[2]], "b")
  testthat::expect_identical(widget$x$columns[[2]]$format, "compact")
  testthat::expect_identical(widget$x$options$selection, "multiple")
  testthat::expect_error(data_grid(data.frame(id = c("a", "a")), row_id = "id"), "unique")
  testthat::expect_error(data_grid(data, columns = list(value = list(renderer = "unsafe"))), "Unsupported")
  testthat::expect_error(data_grid(data, options = list(arbitrary_javascript = TRUE)), "Unsupported")
})

testthat::test_that("data grid ships bounded event and accessibility contracts", {
  source <- paste(readLines(system.file("www", "direct-transport", "src", "data-grid.js",
    package = "shinycapabilities"), warn = FALSE), collapse = "\n")
  css <- paste(readLines(system.file("www", "direct-transport", "src", "data-grid.css",
    package = "shinycapabilities"), warn = FALSE), collapse = "\n")
  testthat::expect_match(source, 'publish(element, "selection"', fixed = TRUE)
  testthat::expect_match(source, 'publish(element, "action"', fixed = TRUE)
  testthat::expect_match(source, 'publish(element, "state"', fixed = TRUE)
  testthat::expect_false(grepl('publish(element, "scroll"', source, fixed = TRUE))
  testthat::expect_match(source, "getRowId", fixed = TRUE)
  testthat::expect_match(source, "ensureDomOrder", fixed = TRUE)
  testthat::expect_match(css, ":focus-visible", fixed = TRUE)
  testthat::expect_match(css, "forced-colors", fixed = TRUE)
})

testthat::test_that("data grid dependency and demo are installable", {
  testthat::expect_true(file.exists(system.file("www", "direct-transport", "data-grid.js",
    package = "shinycapabilities")))
  testthat::expect_true(file.exists(system.file("www", "direct-transport", "data-grid.css",
    package = "shinycapabilities")))
  testthat::expect_true(file.exists(system.file("examples", "data-grid", "app.R",
    package = "shinycapabilities")))
})

testthat::test_that("empty and large data preserve a columnar payload", {
  empty <- data_grid(data.frame(id = character(), value = numeric()), row_id = "id")
  testthat::expect_identical(length(empty$x$rows$id), 0L)
  large <- data_grid(data.frame(id = sprintf("id-%06d", 1:100000), value = 1:100000),
    row_id = "id")
  testthat::expect_identical(length(large$x$rows$id), 100000L)
  testthat::expect_identical(large$x$rows[[".sc_row_id"]][[100000]], "id-100000")
})

testthat::test_that("programmatic updates apply the supplied session namespace", {
  captured <- new.env(parent = emptyenv())
  session <- list(
    ns = function(id) paste0("module-", id),
    sendCustomMessage = function(type, message) {
      captured$type <- type
      captured$message <- message
    }
  )
  update_data_grid(session, "grid", data = data.frame(id = c("a", "b"), value = 1:2),
    row_id = "id", selected_rows = "b", quick_filter = "two", loading = FALSE)
  testthat::expect_identical(captured$type, "shinycapabilities.direct.update")
  testthat::expect_identical(captured$message$id, "module-grid")
  testthat::expect_identical(captured$message$component, "data_grid")
  testthat::expect_identical(captured$message$payload$selectedRows, "b")
  testthat::expect_length(captured$message$payload$rows$id, 2L)
})
