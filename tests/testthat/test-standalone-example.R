testthat::test_that("optional example owns a closed connectable order fixture", {
  example <- system.file("examples", "workflow", "app.R", package = "shinycapabilities")
  if (!nzchar(example)) {
    example <- testthat::test_path("..", "..", "inst", "examples", "workflow", "app.R")
  }
  source <- paste(readLines(
    example, warn = FALSE, encoding = "UTF-8"
  ), collapse = "\n")
  for (label in c(
    "Receive order", "Check inventory", "Approve packing", "Dispatch shipment"
  )) testthat::expect_match(source, label, fixed = TRUE)
  testthat::expect_match(source, 'port_type("work_item"', fixed = TRUE)
  testthat::expect_false(grepl("palette_density_controls = TRUE", source, fixed = TRUE))
  testthat::expect_match(source, "Load connected example", fixed = TRUE)
  testthat::expect_match(source, "Start blank", fixed = TRUE)
})

testthat::test_that("bundled widget exposes connection and resize quality contracts", {
  asset <- function(name) {
    path <- system.file("htmlwidgets", "lib", name, package = "shinycapabilities")
    if (nzchar(path)) return(path)
    testthat::test_path("..", "..", "inst", "htmlwidgets", "lib", name)
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
    ".sc-handle-compatible", ".sc-connection-feedback"
  )) testthat::expect_match(gsub("\\s+", "", css), gsub("\\s+", "", value), fixed = TRUE)
})
