testthat::test_that("embedded canvas UI is bounded and capability identities are unique", {
  registry <- capability_registry()
  for (index in seq_len(100L)) {
    capability_registry_add(registry, register_capability(
      paste0("synthetic.", index), "1.0.0", paste("Capability", index),
      "Synthetic discovery entry.", "Explore"
    ))
  }
  html <- as.character(capability_canvas_ui("studio", registry, height = "100%", toolbar = FALSE))
  testthat::expect_equal(length(gregexpr("data-capability-id=", html, fixed = TRUE)[[1]]), 100L)
  testthat::expect_false(grepl("Run workflow", html, fixed = TRUE))
  testthat::expect_true(grepl("Search capabilities", html, fixed = TRUE))
  testthat::expect_true(grepl("data-palette-density=\"comfortable\"", html, fixed = TRUE))
  testthat::expect_true(grepl("data-palette-density=\"compact\"", html, fixed = TRUE))
  testthat::expect_true(grepl("data-palette-density=\"icon\"", html, fixed = TRUE))
  testthat::expect_true(grepl("sc-palette-category-body", html, fixed = TRUE))
  testthat::expect_true(grepl("Resize configuration inspector", html, fixed = TRUE))
  testthat::expect_true(grepl("height:100%", html, fixed = TRUE))
})
