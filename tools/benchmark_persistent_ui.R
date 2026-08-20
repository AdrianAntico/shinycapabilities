pkgload::load_all(normalizePath(".", winslash = "/"))

make_schema <- function(n, revision = 1L, hidden = FALSE, extra = FALSE) {
  sections <- lapply(seq_len(ceiling(n / 10)), function(i) list(id = paste0("s", i), type = "section", label = paste("Section", i), order = i))
  rows <- lapply(seq_len(n), function(i) list(id = paste0("r", i), type = "row", parent_id = paste0("s", 1L + (i - 1L) %/% 10L), order = i,
    children = list(list(id = paste0("t", i), type = "text", value = paste("Metric", i)),
      list(id = paste0("v", i), type = "value", label = "Value", value = revision * 1000L + i),
      list(id = paste0("b", i), type = "badge", label = "Ready", status = "success", visible = !hidden || i %% 3L != 0L),
      list(id = paste0("f", i), type = "field", label = "Note", value = paste("Draft", i)),
      list(id = paste0("a", i), type = "action", label = "Inspect"))))
  out <- c(sections, rows)
  if (extra) out <- c(out, list(list(id = "extra", type = "text", value = "New finding", order = 9999)))
  out
}
traditional_html <- function(nodes) {
  records <- shinycapabilities:::normalize_persistent_ui_nodes(nodes)
  htmltools::renderTags(htmltools::tagList(lapply(records, function(node) htmltools::tags$div(
    id = node$id, class = paste0("traditional-", node$type), node$label, node$value))))$html
}
diff_payload <- function(old, current) {
  old <- shinycapabilities:::normalize_persistent_ui_nodes(old); current <- shinycapabilities:::normalize_persistent_ui_nodes(current)
  old <- stats::setNames(old, vapply(old, `[[`, character(1), "id")); current <- stats::setNames(current, vapply(current, `[[`, character(1), "id"))
  changed <- names(current)[vapply(names(current), function(id) is.null(old[[id]]) || !identical(old[[id]], current[[id]]), logical(1))]
  list(upsert = unname(current[changed]), remove = unname(setdiff(names(old), names(current))))
}
measure <- function(fun, repetitions = 15L) {
  values <- replicate(repetitions, system.time(fun())[["elapsed"]]) * 1000
  c(median_ms = stats::median(values), p95_ms = unname(stats::quantile(values, .95)))
}
results <- do.call(rbind, lapply(c(10L, 50L, 100L, 250L), function(n) {
  old <- make_schema(n); value <- make_schema(n, 2L); visibility <- make_schema(n, hidden = TRUE); structure <- make_schema(n, extra = TRUE)
  cases <- list(value = value, visibility = visibility, structure = structure)
  do.call(rbind, lapply(names(cases), function(kind) {
    current <- cases[[kind]]; full <- traditional_html(current); patch <- diff_payload(old, current)
    patch_json <- jsonlite::toJSON(patch, auto_unbox = TRUE, null = "null", digits = NA)
    rbind(data.frame(rows = n, workload = kind, approach = "renderUI_full_html",
      t(measure(function() traditional_html(current))), bytes = nchar(full, type = "bytes"), messages = 1L),
      data.frame(rows = n, workload = kind, approach = "persistent_patch",
        t(measure(function() diff_payload(old, current))), bytes = nchar(patch_json, type = "bytes"), messages = 1L))
  }))
}))
print(results, row.names = FALSE)
output <- Sys.getenv("SC_PERSISTENT_BENCHMARK_OUTPUT", tempfile("persistent-ui-", fileext = ".csv"))
utils::write.csv(results, output, row.names = FALSE); message("Wrote benchmark: ", output)
