test_that("JSON object payloads convert named atomic vectors without changing arrays", {
  value <- list(
    choices = c("Visible A" = "a", "Visible B" = "b"),
    selected = c("a", "b"),
    nested = list(state = c(current = "ready"))
  )

  normalized <- json_object_payload(value)

  expect_type(normalized$choices, "list")
  expect_identical(names(normalized$choices), c("Visible A", "Visible B"))
  expect_identical(normalized$selected, c("a", "b"))
  expect_type(normalized$nested$state, "list")
  expect_silent(jsonlite::toJSON(normalized, auto_unbox = TRUE, null = "null"))
})
