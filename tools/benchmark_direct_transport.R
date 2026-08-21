library(shinycapabilities)
make_items <- function(n) lapply(seq_len(n), function(i) list(id = paste0("c", i), label = paste("Command", i),
  group = paste0("G", i %% 10L), description = "Comparable payload", keywords = c("analysis", paste0("k", i)), metadata = list(index = i)))
measure <- function(fun, iterations = 25L) { times <- replicate(iterations, system.time(fun())[["elapsed"]]);
  c(median_ms = stats::median(times) * 1000, p95_ms = unname(stats::quantile(times, .95)) * 1000) }
rows <- lapply(c(100L, 1000L, 10000L), function(n) { items <- make_items(n); alias <- command_palette(items); direct <- command_palette_direct(items)
  alias_json <- jsonlite::toJSON(alias$payload, auto_unbox = TRUE, null = "null", digits = NA)
  direct_json <- jsonlite::toJSON(list(component = direct$component, payload = direct$payload, revision = direct$revision), auto_unbox = TRUE, null = "null", digits = NA)
  rbind(data.frame(n, transport = "compatibility_alias", t(measure(function() command_palette(items))), bytes = nchar(alias_json, type = "bytes")),
    data.frame(n, transport = "direct", t(measure(function() command_palette_direct(items))), bytes = nchar(direct_json, type = "bytes"))) })
result <- do.call(rbind, rows); print(result, row.names = FALSE)
output <- Sys.getenv("SC_DIRECT_BENCHMARK_OUTPUT", tempfile("direct-transport-", fileext = ".csv"))
utils::write.csv(result, output, row.names = FALSE); message("Wrote benchmark: ", output)
