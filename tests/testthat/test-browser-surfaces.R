surface_html <- function(x) as.character(htmltools::renderTags(x)$html)

test_that("overlay surfaces expose accessible semantics", {
  tip <- surface_html(browser_tooltip("tip", "Help", "Explanation"))
  pop <- surface_html(browser_popover("pop", "Details", "Body", "Title"))
  menu <- surface_html(browser_context_menu("menu", "Target", list(list(id = "open", label = "Open"))))
  expect_match(tip, 'role="tooltip"', fixed = TRUE)
  expect_match(pop, 'aria-expanded="false"', fixed = TRUE)
  expect_match(pop, 'role="dialog"', fixed = TRUE)
  expect_match(menu, 'role="menu"', fixed = TRUE)
  expect_match(menu, 'role="menuitem"', fixed = TRUE)
})

test_that("dialog family uses native dialog and bounded actions", {
  html <- surface_html(browser_confirmation_dialog("confirm", "Remove?", "Cannot be undone", destructive = TRUE))
  expect_match(html, "<dialog", fixed = TRUE)
  expect_match(html, 'aria-labelledby="confirm-title"', fixed = TRUE)
  expect_match(html, 'data-sc-event="confirm"', fixed = TRUE)
  expect_match(html, "is-destructive", fixed = TRUE)
})

test_that("notifications are bounded and encoded as data", {
  html <- surface_html(notification_center("notice", list(list(id = "n1", title = "Ready", message = "Done")), 3, 20))
  expect_match(html, 'aria-live="polite"', fixed = TRUE)
  expect_match(html, 'data-max-visible="3"', fixed = TRUE)
  expect_match(html, 'data-max-history="20"', fixed = TRUE)
  expect_match(html, '"id":"n1"', fixed = TRUE)
})

test_that("navigation uses native accessible semantics", {
  tabs <- surface_html(browser_tabs("tabs", list(list(id = "a", label = "A", content = "One"), list(id = "b", label = "B", content = "Two"))))
  accordion <- surface_html(browser_accordion("acc", list(list(id = "a", title = "A", content = "Body"))))
  crumbs <- surface_html(browser_breadcrumbs("crumbs", list(list(id = "home", label = "Home"), list(id = "current", label = "Current"))))
  expect_match(tabs, 'role="tablist"', fixed = TRUE)
  expect_equal(length(gregexpr('role="tab"', tabs, fixed = TRUE)[[1]]), 2)
  expect_match(accordion, "<details", fixed = TRUE)
  expect_match(crumbs, 'aria-current="page"', fixed = TRUE)
  expect_match(surface_html(browser_pagination("page", 1, 3)), "Page 1 of 3", fixed = TRUE)
})

test_that("file and download surfaces preserve Shiny transport seams", {
  upload <- surface_html(browser_file_upload("upload", multiple = TRUE, accept = ".csv"))
  download <- surface_html(browser_download_action("download", filename = "report.html"))
  expect_match(upload, "shiny-input-container", fixed = TRUE)
  expect_match(upload, 'type="file"', fixed = TRUE)
  expect_match(upload, "sc-file-transport", fixed = TRUE)
  expect_match(download, "shiny-download-link", fixed = TRUE)
  expect_match(download, 'download="report.html"', fixed = TRUE)
})

test_that("output shells expose states and presentation actions", {
  ready <- surface_html(output_shell("out", "Body", title = "Output"))
  loading <- surface_html(output_shell("load", title = "Loading", state = "loading"))
  error <- surface_html(output_shell("bad", title = "Error", state = "error"))
  expect_match(ready, 'data-sc-event="fullscreen"', fixed = TRUE)
  expect_match(ready, 'data-sc-event="spotlight"', fixed = TRUE)
  expect_match(loading, 'role="status"', fixed = TRUE)
  expect_match(error, 'role="alert"', fixed = TRUE)
  expect_match(surface_html(report_outline("outline", list(list(id = "a", label = "A")))), 'aria-label="Report outline"', fixed = TRUE)
})

test_that("surface update APIs are namespace aware", {
  messages <- list()
  session <- list(ns = function(x) paste0("mod-", x), sendCustomMessage = function(type, message) messages[[type]] <<- message)
  update_browser_surface(session, "dialog", "open")
  expect_equal(messages[["shinycapabilities:surface"]]$id, "mod-dialog")
  expect_equal(messages[["shinycapabilities:surface"]]$action, "open")
  update_notification_center(session, "notice", list(list(id = "x")), "append")
  expect_equal(messages[["shinycapabilities:surface"]]$payload$mode, "append")
})

test_that("browser assets include lifecycle accessibility and stress contracts", {
  js <- paste(readLines(test_path("..", "..", "inst", "www", "browser-surfaces", "browser-surfaces.js"), warn = FALSE), collapse = "\n")
  css <- paste(readLines(test_path("..", "..", "inst", "www", "browser-surfaces", "browser-surfaces.css"), warn = FALSE), collapse = "\n")
  expect_match(js, "MutationObserver", fixed = TRUE)
  expect_match(js, "ResizeObserver", fixed = TRUE)
  expect_match(js, "maxHistory", fixed = TRUE)
  expect_match(js, "requestFullscreen", fixed = TRUE)
  expect_match(js, "previousFocus", fixed = TRUE)
  expect_match(js, 'tab.closest(".sc-tabs") === root', fixed = TRUE)
  expect_match(css, "prefers-reduced-motion", fixed = TRUE)
  expect_match(css, "forced-colors", fixed = TRUE)
  expect_false(grepl("React|htmlwidgets", js))
})

test_that("installed gallery is present", {
  path <- system.file("examples", "browser-surfaces", "app.R", package = "shinycapabilities")
  if (!nzchar(path)) path <- test_path("..", "..", "inst", "examples", "browser-surfaces", "app.R")
  expect_true(file.exists(path))
})
