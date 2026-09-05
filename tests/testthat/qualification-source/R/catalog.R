#' Create an empty host-neutral capability catalog
#'
#' Domain capabilities belong to host applications or optional examples. The
#' package does not install an authoritative domain catalog.
#' @export
default_capability_catalog <- function() {
  capability_registry()
}
