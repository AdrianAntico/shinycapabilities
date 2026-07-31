`%||%` <- function(value, fallback) {
  if (is.null(value) || !length(value)) fallback else value
}

stable_json <- function(value) {
  jsonlite::toJSON(value, auto_unbox = TRUE, null = "null", digits = NA)
}

stable_hash <- function(value) {
  digest::digest(stable_json(value), algo = "sha256", serialize = FALSE)
}

as_named_list <- function(value) {
  if (is.null(value)) return(list())
  if (!is.list(value)) stop("Expected a list.", call. = FALSE)
  value
}

