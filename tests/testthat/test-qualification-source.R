testthat::test_that("qualification snapshot preserves complete exact R source", {
  fixture <- testthat::test_path("qualification-source")
  manifest <- utils::read.csv(file.path(fixture, "manifest.csv"), stringsAsFactors = FALSE)
  snapshot <- file.path(fixture, "R")
  files <- sort(list.files(snapshot, recursive = TRUE, all.files = TRUE, no.. = TRUE))
  files <- files[!dir.exists(file.path(snapshot, files))]
  testthat::expect_identical(files, manifest$path)
  # Normalize only line endings, exactly as the existing readLines assertions do.
  text_hash <- function(paths) vapply(paths, function(path)
    digest::digest(paste(readLines(path, warn = FALSE), collapse = "\n"),
      algo = "sha256", serialize = FALSE), character(1), USE.NAMES = FALSE)
  testthat::expect_identical(text_hash(file.path(snapshot, files)), manifest$sha256)
  # In source execution this also rejects stale or incomplete snapshots. Under
  # installation the same checks validate the retained, hash-identified evidence.
  inspected <- qualification_path("R")
  actual <- sort(list.files(inspected, recursive = TRUE, all.files = TRUE, no.. = TRUE))
  actual <- actual[!dir.exists(file.path(inspected, actual))]
  testthat::expect_identical(actual, manifest$path)
  testthat::expect_identical(text_hash(file.path(inspected, actual)), manifest$sha256)
})
