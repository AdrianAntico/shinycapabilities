args <- commandArgs(trailingOnly = TRUE)
isolated_library <- if (length(args)) args[[1L]] else
  file.path(tempdir(), "shinycapabilities-no-htmlwidgets")
package_archive <- if (length(args) >= 2L) args[[2L]] else
  "shinycapabilities_0.1.0.tar.gz"

dir.create(isolated_library, recursive = TRUE, showWarnings = FALSE)
installed <- utils::installed.packages()
roots <- c("callr", "digest", "htmltools", "jsonlite", "shiny")
dependencies <- unique(c(roots, unlist(tools::package_dependencies(
  roots, db = installed, recursive = TRUE), use.names = FALSE)))
base_packages <- rownames(installed)[!is.na(installed[, "Priority"])]
dependencies <- setdiff(dependencies, c("htmlwidgets", base_packages))

for (package in dependencies) {
  source <- find.package(package, quiet = TRUE)
  if (nzchar(source) && !dir.exists(file.path(isolated_library, package))) {
    file.copy(source, isolated_library, recursive = TRUE)
  }
}

if (!dir.exists(file.path(isolated_library, "shinycapabilities"))) {
  status <- system2(file.path(R.home("bin"), "R"),
    c("CMD", "INSTALL", "-l", shQuote(isolated_library), shQuote(package_archive)))
  if (!identical(status, 0L)) stop("Isolated package installation failed.")
}

.libPaths(c(isolated_library, .Library))
stopifnot(!requireNamespace("htmlwidgets", quietly = TRUE))
library(shinycapabilities)

component <- data_grid(data.frame(id = 1L, value = "qualified"), row_id = "id")
markup <- htmltools::renderTags(htmltools::as.tags(component))
stopifnot(inherits(component, "shinycapabilities_direct_component"))
stopifnot(grepl("data_grid", markup$html, fixed = TRUE))
stopifnot(file.exists(system.file("examples", "component-composition", "app.R",
  package = "shinycapabilities")))

cat("Isolated qualification passed. htmlwidgets available: FALSE\n")
