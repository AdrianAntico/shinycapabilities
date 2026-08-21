testthat::test_that("foundational controls render semantic native contracts", {
  controls <- list(
    browser_text_field("text", "Text", "value", required = TRUE),
    browser_numeric_field("number", "Number", 3, min = 0, max = 10),
    browser_secret_field("secret", "Secret"),
    browser_textarea("notes", "Notes", "hello"),
    browser_checkbox("check", "Check", TRUE),
    browser_switch("switch", "Switch", TRUE),
    browser_radio_group("radio", "Radio", c(A = "a", B = "b"), "b"),
    browser_segmented_control("segment", "Segment", c(A = "a", B = "b")),
    browser_slider("range", "Range", 5, 0, 10)
  )
  html <- vapply(controls, as.character, character(1))
  testthat::expect_true(all(grepl("sc-browser-control", html, fixed = TRUE)))
  testthat::expect_match(html[[1]], "required", fixed = TRUE)
  testthat::expect_match(html[[3]], 'type="password"', fixed = TRUE)
  testthat::expect_match(html[[4]], "textarea", fixed = TRUE)
  testthat::expect_match(html[[6]], 'role="switch"', fixed = TRUE)
  testthat::expect_match(html[[7]], 'type="radio"', fixed = TRUE)
  testthat::expect_match(html[[9]], 'type="range"', fixed = TRUE)
})

testthat::test_that("validation and field states are accessible", {
  invalid <- browser_text_field("field", "Field", error = "Required", help = "Help")
  disabled <- browser_numeric_field("disabled", "Disabled", 1, disabled = TRUE)
  readonly <- browser_text_field("readonly", "Read only", "fixed", readonly = TRUE)
  testthat::expect_match(as.character(invalid), 'aria-invalid="true"', fixed = TRUE)
  testthat::expect_match(as.character(invalid), 'role="alert"', fixed = TRUE)
  testthat::expect_match(as.character(disabled), "disabled", fixed = TRUE)
  testthat::expect_match(as.character(readonly), "readonly", fixed = TRUE)
})

testthat::test_that("actions and displays expose semantic roles", {
  primary <- browser_action_button("run", "Run", variant = "primary")
  loading <- browser_action_button("wait", "Wait", loading = TRUE)
  alert <- browser_alert("Problem", "Inspect this", "error")
  progress <- browser_progress(3, 10, "Progress")
  skeleton <- browser_skeleton(2)
  testthat::expect_match(as.character(primary), 'type="button"', fixed = TRUE)
  testthat::expect_match(as.character(loading), 'aria-busy="true"', fixed = TRUE)
  testthat::expect_match(as.character(alert), 'role="alert"', fixed = TRUE)
  testthat::expect_match(as.character(progress), "<progress", fixed = TRUE)
  testthat::expect_equal(length(gregexpr("sc-skeleton-line", as.character(skeleton), fixed = TRUE)[[1]]), 2L)
})

testthat::test_that("actions remain available for the Shiny input binding", {
  html <- as.character(browser_action_button("run", "Run"))
  testthat::expect_match(html, 'data-sc-action="true"', fixed = TRUE)
  testthat::expect_false(grepl("shiny-bound-input", html, fixed = TRUE))
})

testthat::test_that("updates namespace through the standard Shiny input channel", {
  captured <- new.env(parent = emptyenv())
  session <- list(sendInputMessage = function(id, message) {
    captured$id <- id; captured$message <- message
  })
  update_browser_control(session, "field", value = "next", disabled = TRUE)
  testthat::expect_identical(captured$id, "field")
  testthat::expect_identical(captured$message$value, "next")
  testthat::expect_true(captured$message$disabled)
})

testthat::test_that("browser assets implement bounded lifecycle and native behavior", {
  js <- paste(readLines(testthat::test_path("..", "..", "inst", "www", "browser-controls", "browser-controls.js"), warn = FALSE), collapse = "\n")
  css <- paste(readLines(testthat::test_path("..", "..", "inst", "www", "browser-controls", "browser-controls.css"), warn = FALSE), collapse = "\n")
  testthat::expect_match(js, "Shiny.InputBinding", fixed = TRUE)
  testthat::expect_match(js, "unsubscribe", fixed = TRUE)
  testthat::expect_match(js, "removeEventListener", fixed = TRUE)
  testthat::expect_match(css, "prefers-reduced-motion", fixed = TRUE)
  testthat::expect_match(css, "forced-colors", fixed = TRUE)
  testthat::expect_false(grepl("React|htmlwidgets", js))
})

testthat::test_that("gallery is included in installed package", {
  testthat::expect_true(file.exists(system.file("examples", "browser-controls", "app.R",
    package = "shinycapabilities")))
})
