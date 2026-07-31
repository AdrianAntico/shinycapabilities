testthat::test_that("host icons are closed and unknown values fall back safely", {
  testthat::expect_true(length(shinycapabilities_icon_allowlist()) >= 48L)
  testthat::expect_identical(shinycapabilities:::normalize_shinycapabilities_icon("stats"), "stats")
  testthat::expect_identical(
    shinycapabilities:::normalize_shinycapabilities_icon("<svg onload=alert(1) />"), "asterisk"
  )
  html <- as.character(shinycapabilities:::shinycapabilities_icon_tag("<script>"))
  testthat::expect_match(html, "glyphicon-asterisk", fixed = TRUE)
  testthat::expect_false(grepl("script", html, fixed = TRUE))
})
