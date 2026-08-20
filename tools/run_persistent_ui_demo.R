pkgload::load_all(normalizePath(".", winslash = "/"))
shiny::runApp("inst/examples/persistent-ui", host = "127.0.0.1",
  port = as.integer(Sys.getenv("SC_PERSISTENT_PORT", "8767")), launch.browser = FALSE)
