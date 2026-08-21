testthat::test_that("optional example owns a minimal neutral workflow", {
  example <- system.file("examples", "workflow", "app.R", package = "shinycapabilities")
  if (!nzchar(example)) {
    example <- testthat::test_path("..", "..", "inst", "examples", "workflow", "app.R")
  }
  source <- paste(readLines(
    example, warn = FALSE, encoding = "UTF-8"
  ), collapse = "\n")
  for (label in c("Prepare item", "Review item")) {
    testthat::expect_match(source, label, fixed = TRUE)
  }
  testthat::expect_match(source, 'port_type("work_item"', fixed = TRUE)
  testthat::expect_match(source, "capability_canvas_server", fixed = TRUE)
  testthat::expect_false(grepl("Order workflow|drawer", source, ignore.case = TRUE))
})

testthat::test_that("bundled widget exposes connection and resize quality contracts", {
  asset <- function(name) {
    path <- system.file("www", "direct-transport", name, package = "shinycapabilities")
    if (nzchar(path)) return(path)
    testthat::test_path("..", "..", "inst", "www", "direct-transport", name)
  }
  javascript <- paste(readLines(
    asset("shinycapabilities.js"), warn = FALSE
  ), collapse = "\n")
  css <- paste(readLines(
    asset("shinycapabilities.css"), warn = FALSE
  ), collapse = "\n")
  for (value in c(
    "Checking connection with the R workflow authority",
    "Drag from an output handle to a compatible input handle",
    "sc-handle-compatible", "resize_completed"
  )) testthat::expect_match(javascript, value, fixed = TRUE)
  for (value in c(
    ".sc-node{", "display:flex", "width:100%", "height:100%",
    ".sc-node-port-grid", "grid-template-columns:minmax(0,1fr)minmax(0,1fr)",
    ".sc-handle-compatible", ".sc-connection-feedback"
  )) testthat::expect_match(gsub("\\s+", "", css), gsub("\\s+", "", value), fixed = TRUE)
})
