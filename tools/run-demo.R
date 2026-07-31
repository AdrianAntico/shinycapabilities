devtools::load_all(
  ".",
  quiet = TRUE
)
shiny::runApp(
  "inst/examples/workflow",
  host = "127.0.0.1",
  port = 4376,
  launch.browser = FALSE
)
