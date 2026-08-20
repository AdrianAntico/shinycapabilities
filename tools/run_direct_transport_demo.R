pkgload::load_all(normalizePath(".", winslash = "/"))
shiny::runApp("inst/examples/direct-transport", host = "127.0.0.1",
  port = as.integer(Sys.getenv("SC_DIRECT_PORT", "8765")), launch.browser = FALSE)
