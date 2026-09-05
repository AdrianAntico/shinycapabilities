test_that("frame is presentation-only and commands remain complete", {
  commands <- list(command_record("a", "Action", payload = list(x = 1)),
    command_record("b", "Expert", enabled = FALSE, disabled_reason = "Unavailable"))
  for (density in c("comfortable", "compact", "dense")) {
    html <- as.character(application_frame("frame", "Work", density = density, commands = commands))
    expect_match(html, paste0('data-sc-density="', density, '"'), fixed = TRUE)
    expect_match(html, '"id":"a"', fixed = TRUE)
    expect_match(html, '"id":"b"', fixed = TRUE)
    expect_match(html, '"enabled":false', fixed = TRUE)
  }
  expect_error(application_frame("frame", "Work", commands = rep(commands, 2)), "unique")
  expect_error(application_frame("frame", "Work", tokens = c(bad = "red")), "token")
  safe <- as.character(application_frame("frame", "Work", commands = list(
    command_record("safe", "</script><script>alert(1)</script>"))))
  expect_false(grepl("</script><script>", safe, fixed = TRUE))
  payload <- sub(".*data-sc-commands=\"true\">(.*?)</script>.*", "\\1", safe)
  expect_identical(jsonlite::fromJSON(payload)$label, "</script><script>alert(1)</script>")
})
test_that("selection labels are not values", {
  groups <- normalize_selection_groups(c("Human label" = "canonical"))
  expect_identical(groups[[1]]$options[[1]]$label, "Human label")
  expect_identical(groups[[1]]$options[[1]]$value, "canonical")
})
test_that("ordinary fields retain independent error warning and busy state", {
  html <- as.character(browser_date_field("date", "Date", "2026-10-01", warning = "Review",
    error = "Invalid", loading = TRUE, readonly = TRUE))
  expect_match(html, 'type="date"', fixed = TRUE)
  expect_match(html, 'aria-busy="true"', fixed = TRUE)
  expect_match(html, "Review", fixed = TRUE)
  expect_match(html, "Invalid", fixed = TRUE)
  expect_match(html, "readonly", fixed = TRUE)
  expect_match(as.character(browser_datetime_field("time", "Time")), 'type="datetime-local"', fixed = TRUE)
})
