pkgload::load_all(normalizePath(".", winslash = "/"))

gzip_size <- function(path) {
  output <- tempfile(fileext = ".gz")
  input <- file(path, "rb"); compressed <- gzfile(output, "wb")
  on.exit({ close(input); close(compressed); unlink(output) }, add = TRUE)
  repeat {
    bytes <- readBin(input, "raw", 1024L * 1024L)
    if (!length(bytes)) break
    writeBin(bytes, compressed)
  }
  close(input); close(compressed)
  on.exit(NULL, add = FALSE)
  size <- file.info(output)$size; unlink(output); as.numeric(size)
}

roots <- c("inst/htmlwidgets/lib", "inst/www/direct-transport")
files <- unlist(lapply(roots, function(root) list.files(root, "\\.js$", full.names = TRUE)))
results <- data.frame(
  file = basename(files),
  architecture = ifelse(grepl("direct-transport", files, fixed = TRUE), "direct", "htmlwidgets"),
  raw_bytes = as.numeric(file.info(files)$size),
  gzip_bytes = vapply(files, gzip_size, numeric(1)),
  stringsAsFactors = FALSE
)
results <- results[order(results$architecture, results$file), ]
print(results, row.names = FALSE)

tags <- htmltools::tagList(command_palette_direct_output("palette"),
  split_pane_direct_output("split"), persistent_ui_output("persistent"))
dependencies <- htmltools::resolveDependencies(htmltools::findDependencies(tags))
cat("\nResolved direct composition dependencies:\n")
print(data.frame(name = vapply(dependencies, `[[`, character(1), "name"),
  version = vapply(dependencies, `[[`, character(1), "version"),
  scripts = vapply(dependencies, function(x) paste(x$script %||% character(), collapse = ","), character(1))),
  row.names = FALSE)

output <- Sys.getenv("SC_SHARED_RUNTIME_AUDIT_OUTPUT", tempfile("shared-runtime-", fileext = ".csv"))
utils::write.csv(results, output, row.names = FALSE)
message("Wrote runtime audit: ", output)
