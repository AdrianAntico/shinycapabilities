testthat::test_that("direct command palette preserves the qualified payload contract", {
  items <- list(list(id = "run", label = "Run", group = "Analyze", metadata = list(capability_id = "analysis.run")))
  direct <- command_palette_direct(items, server_search = TRUE, element_id = "direct-a")
  widget <- command_palette(items, server_search = TRUE)
  testthat::expect_s3_class(direct, "shinycapabilities_direct_component")
  testthat::expect_identical(direct$payload, widget$x)
  testthat::expect_identical(direct$element_id, "direct-a")
})

testthat::test_that("direct output attaches only its versioned dependencies", {
  tag <- command_palette_direct_output("palette")
  deps <- htmltools::htmlDependencies(tag)
  testthat::expect_identical(tag$attribs$id, "palette")
  testthat::expect_match(tag$attribs$class, "sc-direct-component-output")
  testthat::expect_length(deps, 1L)
  testthat::expect_identical(deps[[1]]$script, c("react-vendor-v1.js", "direct-transport.js", "command-palette-direct.js"))
})

testthat::test_that("static direct rendering carries a structured payload", {
  component <- command_palette_direct(list(list(id = "run", label = "Run")), element_id = "static-a")
  html <- as.character(htmltools::as.tags(component))
  testthat::expect_match(html, 'id="static-a"', fixed = TRUE)
  testthat::expect_match(html, "data-sc-direct-payload", fixed = TRUE)
  testthat::expect_match(html, '"component":"command_palette_direct"', fixed = TRUE)
})

testthat::test_that("direct source owns lifecycle and bounded events", {
  root <- system.file("www", "direct-transport", package = "shinycapabilities")
  source <- paste(readLines(file.path(root, "src", "direct-transport.js"), warn = FALSE), collapse = "\n")
  palette <- paste(readLines(file.path(root, "src", "command-palette-direct.jsx"), warn = FALSE), collapse = "\n")
  for (marker in c("Shiny.OutputBinding", "addCustomMessageHandler", "ResizeObserver", "MutationObserver", "destroy", "liveInstances", "16384"))
    testthat::expect_match(source, marker, fixed = TRUE)
  testthat::expect_match(palette, "ShinyCapabilitiesReactVendorV1", fixed = TRUE)
  testthat::expect_match(palette, 'role="combobox"', fixed = TRUE)
  testthat::expect_match(palette, "root.unmount", fixed = TRUE)
})

testthat::test_that("direct assets are installable without React duplication", {
  root <- system.file("www", "direct-transport", package = "shinycapabilities")
  files <- c("react-vendor-v1.js", "direct-transport.js", "command-palette-direct.js", "command-palette-direct.css")
  testthat::expect_true(all(file.exists(file.path(root, files))))
  testthat::expect_lt(file.info(file.path(root, "command-palette-direct.js"))$size, 20000)
  testthat::expect_true(file.exists(system.file("examples", "direct-transport", "app.R", package = "shinycapabilities")))
})

testthat::test_that("direct updates are namespaced and revisioned", {
  fake <- new.env(parent = emptyenv()); fake$ns <- function(id) paste0("mod-", id)
  fake$sendCustomMessage <- function(type, message) { fake$type <- type; fake$message <- message }
  update_direct_component(fake, "palette", "command_palette_direct", list(items = list()), revision = 7L)
  testthat::expect_identical(fake$type, "shinycapabilities.direct.update")
  testthat::expect_identical(fake$message$id, "mod-palette")
  testthat::expect_identical(fake$message$revision, 7L)
})
