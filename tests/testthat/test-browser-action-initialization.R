testthat::test_that("browser actions do not publish a synthetic initial click", {
  asset <- system.file("www", "browser-controls", "browser-controls.js",
    package = "shinycapabilities")
  if (!nzchar(asset)) {
    asset <- testthat::test_path("..", "..", "inst", "www", "browser-controls",
      "browser-controls.js")
  }
  source <- paste(readLines(asset, warn = FALSE), collapse = "\n")
  testthat::expect_match(source,
    "actionCounts.has(button) ? actionCounts.get(button) : null", fixed = TRUE)
  testthat::expect_false(grepl("actions.getValue = (button) => actionCounts.get(button) || 0",
    source, fixed = TRUE))
})
