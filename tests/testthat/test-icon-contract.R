testthat::test_that("host icons are closed and unknown values fall back safely", {
  testthat::expect_true(length(shinycapabilities_icon_allowlist()) >= 48L)
  testthat::expect_identical(shinycapabilities:::normalize_shinycapabilities_icon("stats"), "stats")
  testthat::expect_identical(
    shinycapabilities:::normalize_shinycapabilities_icon("<svg onload=alert(1) />"), "asterisk"
  )
  html <- as.character(shinycapabilities:::shinycapabilities_icon_tag("<script>"))
  testthat::expect_match(html, "fa-asterisk", fixed = TRUE)
  testthat::expect_match(html, "aria-hidden=\"true\"", fixed = TRUE)
  testthat::expect_false(grepl("script", html, fixed = TRUE))
  testthat::expect_false(grepl(">asterisk<", html, fixed = TRUE))
})

testthat::test_that("every neutral icon renders without visible identifier text", {
  icons <- shinycapabilities_icon_allowlist()
  html <- vapply(icons, function(icon) {
    as.character(shinycapabilities:::shinycapabilities_icon_tag(icon))
  }, character(1))

  testthat::expect_true(all(grepl("data-shinycap-icon", html, fixed = TRUE)))
  testthat::expect_true(all(grepl("aria-hidden=\"true\"", html, fixed = TRUE)))
  testthat::expect_false(any(grepl("glyphicon", html, fixed = TRUE)))
  testthat::expect_false(any(vapply(seq_along(icons), function(index) {
    grepl(paste0(">", icons[[index]], "<"), html[[index]], fixed = TRUE)
  }, logical(1))))
})
