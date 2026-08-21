# A small, bounded comparison of typed transport and recursively rendered HTML.
pkgload::load_all(".", quiet = TRUE)

make_object <- function(n) {
  stats::setNames(lapply(seq_len(n), function(i) {
    list(value = i, label = paste("Metric", i), active = i %% 2L == 0L)
  }), paste0("item_", seq_len(n)))
}

render_nested <- function(x) {
  if (!is.list(x)) return(htmltools::tags$span(as.character(x)))
  htmltools::tags$ul(lapply(names(x), function(key) {
    htmltools::tags$li(htmltools::tags$strong(key), render_nested(x[[key]]))
  }))
}

result <- do.call(rbind, lapply(c(100L, 1000L), function(n) {
  object <- make_object(n)
  transport_time <- system.time({
    component <- object_inspector(object, max_nodes = 100000L)
    payload <- jsonlite::toJSON(component$payload, auto_unbox = TRUE, null = "null")
  })[["elapsed"]]
  render_time <- system.time({
    html <- htmltools::renderTags(render_nested(object))$html
  })[["elapsed"]]
  data.frame(
    records = n,
    transport_seconds = transport_time,
    recursive_html_seconds = render_time,
    transport_bytes = nchar(payload, type = "bytes"),
    recursive_html_bytes = nchar(html, type = "bytes")
  )
}))

print(result, row.names = FALSE)
