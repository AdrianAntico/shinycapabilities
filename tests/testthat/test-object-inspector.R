testthat::test_that("object inspector creates explicit typed envelopes", {
  value <- list(text = "x", integer = 2L, number = 2.5, flag = TRUE,
    null = NULL, missing = NA_character_, date = as.Date("2026-08-20"),
    array = c("a", "b"), nested = list(value = 1))
  model <- normalize_object_inspector_object(value)
  children <- stats::setNames(lapply(model$root$children, `[[`, "node"),
    vapply(model$root$children, `[[`, character(1), "key"))
  testthat::expect_identical(children$text$valueType, "string")
  testthat::expect_identical(children$integer$valueType, "integer")
  testthat::expect_identical(children$number$valueType, "number")
  testthat::expect_identical(children$flag$valueType, "boolean")
  testthat::expect_identical(children$null$valueType, "null")
  testthat::expect_identical(children$missing$valueType, "missing")
  testthat::expect_identical(children$date$valueType, "date")
  testthat::expect_identical(children$array$nodeType, "array")
  testthat::expect_identical(children$nested$nodeType, "object")
})

testthat::test_that("redaction occurs recursively before serialization", {
  secret <- "SHOULD_NEVER_APPEAR_92741"
  component <- object_inspector(list(user = "safe", api_token = secret,
    nested = list(password = secret, visible = "yes")), element_id = "redacted")
  json <- jsonlite::toJSON(component$payload, auto_unbox = TRUE, null = "null")
  testthat::expect_false(grepl(secret, json, fixed = TRUE))
  testthat::expect_equal(lengths(regmatches(json, gregexpr("redacted", json, fixed = TRUE))), 2L)
  testthat::expect_match(json, "visible", fixed = TRUE)
})

testthat::test_that("JSON pointer identity escapes duplicate path characters", {
  model <- normalize_object_inspector_object(list("a/b" = list("x~y" = 1L)))
  first <- model$root$children[[1]]
  testthat::expect_identical(object_inspector_path("", first$key), "/a~1b")
  testthat::expect_identical(object_inspector_path("/a~1b", first$node$children[[1]]$key), "/a~1b/x~0y")
})

testthat::test_that("limits, states, and malformed contracts are deterministic", {
  limited <- object_inspector(as.list(1:20), max_nodes = 5L)
  testthat::expect_gt(limited$payload$truncated, 0L)
  testthat::expect_identical(object_inspector(state = "loading")$payload$state, "loading")
  testthat::expect_identical(object_inspector(state = "error", message = "bad")$payload$message, "bad")
  testthat::expect_s3_class(object_inspector(types = list()), "shinycapabilities_direct_component")
  testthat::expect_error(object_inspector(types = list("date")), "types must be a named list")
  testthat::expect_error(update_object_inspector(new.env(), "x", patches = "bad"), "patches must be")
})

testthat::test_that("dependency is scoped and uses the shared runtime", {
  deps <- htmltools::htmlDependencies(object_inspector_output("inspect"))
  testthat::expect_identical(vapply(deps, `[[`, character(1), "name"), c(
    "shinycapabilities-browser-runtime", "shinycapabilities-direct-transport",
    "shinycapabilities-direct-object-inspector"))
  root <- system.file("www", "direct-transport", package = "shinycapabilities")
  testthat::expect_true(all(file.exists(file.path(root,
    c("object-inspector.js", "object-inspector.css", "src/object-inspector.jsx")))))
  testthat::expect_lt(file.info(file.path(root, "object-inspector.js"))$size, 12000)
})

testthat::test_that("updates are namespaced, revisioned, and normalize patches", {
  fake <- new.env(parent = emptyenv()); fake$ns <- function(id) paste0("mod-", id)
  fake$sendCustomMessage <- function(type, message) { fake$type <- type; fake$message <- message }
  update_object_inspector(fake, "inspect", patches = list(
    list(operation = "set", path = "/metric", value = 0.9)
  ), focus_path = "/metric", revision = 8L)
  testthat::expect_identical(fake$message$id, "mod-inspect")
  testthat::expect_identical(fake$message$revision, 8L)
  testthat::expect_identical(fake$message$payload$patches[[1]]$value$valueType, "number")
  testthat::expect_identical(fake$message$payload$focusPath, "/metric")
})

testthat::test_that("demo and public component contract exist", {
  testthat::expect_true(file.exists(system.file("examples", "object-inspector", "app.R",
    package = "shinycapabilities")))
  testthat::expect_s3_class(object_inspector(list(a = 1)), "shinycapabilities_direct_component")
})
