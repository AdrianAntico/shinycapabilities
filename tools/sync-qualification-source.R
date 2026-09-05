# Run from the package root before qualification when R source changes.
source_dir <- "R"
target <- "tests/testthat/qualification-source"
files <- sort(list.files(source_dir, recursive = TRUE, all.files = TRUE,
  no.. = TRUE, full.names = FALSE))
files <- files[!dir.exists(file.path(source_dir, files))]
dir.create(file.path(target, "R"), recursive = TRUE, showWarnings = FALSE)
for (name in files) {
  destination <- file.path(target, "R", name)
  dir.create(dirname(destination), recursive = TRUE, showWarnings = FALSE)
  stopifnot(file.copy(file.path(source_dir, name), destination, overwrite = TRUE))
}
text_hash <- function(paths) vapply(paths, function(path)
  digest::digest(paste(readLines(path, warn = FALSE), collapse = "\n"),
    algo = "sha256", serialize = FALSE), character(1), USE.NAMES = FALSE)
manifest <- data.frame(path = files, sha256 = text_hash(file.path(source_dir, files)))
write.csv(manifest, file.path(target, "manifest.csv"), row.names = FALSE)
stopifnot(identical(text_hash(file.path(target, "R", files)), manifest$sha256))
