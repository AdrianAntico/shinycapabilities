testthat::test_that("capabilities expose normalized product knowledge", {
  capability <- register_capability(
    "test.knowledge", "1.0.0", "Knowledge test",
    "Run the existing AutoQuant analysis in R.",
    knowledge = list(
      use_when = "A governed comparison is needed.",
      limitations = "Requires compatible input."
    )
  )

  testthat::expect_identical(
    capability$knowledge$purpose,
    "Run the existing governed analysis."
  )
  testthat::expect_identical(
    capability$knowledge$use_when,
    "A governed comparison is needed."
  )
  testthat::expect_identical(capability$knowledge$related_capabilities, character())
})

testthat::test_that("capability knowledge rejects unknown metadata", {
  testthat::expect_error(
    register_capability("test.invalid", "1.0.0", "Invalid",
      knowledge = list(hidden_prompt = "no")),
    "Unknown capability knowledge metadata"
  )
})
