# R installation removes raw R source. Retain exact qualification evidence rather
# than substituting deparsed functions for source-inspection assertions.
qualification_path <- function(...) {
  parts <- c(...)
  root <- testthat::test_path("..", "..")
  if (file.exists(file.path(root, "R", "module.R")))
    return(file.path(root, ...))
  if (parts[[1L]] == "R")
    return(file.path(testthat::test_path("qualification-source"), ...))
  if (parts[[1L]] == "inst") parts <- parts[-1L]
  do.call(file.path, as.list(c(system.file(package = "shinycapabilities"), parts)))
}
