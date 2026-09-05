library(shinycapabilities)
for (n in c(10L, 1000L, 10000L, 100000L)) {
  data <- data.frame(id = paste0('asset-', seq_len(n)),
    site = rep(c('North', 'South', 'West'), length.out = n),
    hours = 800 + (seq_len(n) * 137) %% 5000, downtime = (seq_len(n) * 17) %% 90)
  construction <- system.time(value <- data_grid(data, row_id = 'id'))[['elapsed']]
  serialization <- system.time(payload <- jsonlite::toJSON(list(component = value$component,
    payload = value$payload, revision = value$revision), auto_unbox = TRUE,
    null = 'null', digits = NA, force = TRUE))[['elapsed']]
  cat(sprintf('rows=%d construction_s=%.3f serialization_s=%.3f json_bytes=%d\n',
    n, construction, serialization, nchar(payload, type = 'bytes')))
}
