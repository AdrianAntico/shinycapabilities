sizes <- c(1000L, 10000L, 100000L)
pkgload::load_all(".", quiet = TRUE)
make_data <- function(n) data.frame(
  id = sprintf("row-%09d", seq_len(n)),
  category = rep(sprintf("Category %02d", 1:25), length.out = n),
  value = seq_len(n) / 7,
  date = as.Date("2020-01-01") + (seq_len(n) %% 2000L),
  flag = seq_len(n) %% 2L == 0L
)
results <- lapply(sizes, function(n) {
  data <- make_data(n)
  gc()
  elapsed <- system.time(widget <- data_grid(data, row_id = "id"))[["elapsed"]]
  serialized <- jsonlite::toJSON(widget$x, auto_unbox = TRUE, dataframe = "rows", null = "null")
  data.frame(rows = n, constructor_seconds = elapsed,
    payload_megabytes = nchar(serialized, type = "bytes") / 1024^2)
})
print(do.call(rbind, results), row.names = FALSE)
