pkgload::load_all(normalizePath(".", winslash = "/"))
shiny::runApp("inst/examples/shared-runtime", host = "127.0.0.1",
  port = as.integer(Sys.getenv("SC_SHARED_RUNTIME_PORT", "8768")), launch.browser = FALSE)
