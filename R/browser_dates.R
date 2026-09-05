#' Browser-native calendar date field
#' @inheritParams browser_text_field
#' @param min,max ISO date or local datetime bounds, matching the control type.
#' @return A native field. Date values are ISO strings, not timezone conversions.
#' @examples
#' browser_date_field("day", "Delivery date", "2026-10-01")
#' @export
browser_date_field <- function(input_id, label, value = NULL, min = NULL, max = NULL,
    help = NULL, error = NULL, required = FALSE, disabled = FALSE, readonly = FALSE,
    warning = NULL, loading = FALSE) {
  browser_control_shell(input_id, label, htmltools::tags$input(type = "date",
    class = "sc-control-input", value = as.character(value), min = min, max = max),
    help, error, required, disabled, readonly, warning = warning, loading = loading)
}

#' Browser-native local datetime field
#' @inheritParams browser_date_field
#' @param step Seconds between permitted values; defaults to one minute.
#' @return A local wall-clock ISO string. The host must resolve timezone and DST.
#' @examples
#' browser_datetime_field("time", "Local appointment", "2026-10-01T09:30")
#' @export
browser_datetime_field <- function(input_id, label, value = NULL, min = NULL, max = NULL,
    step = 60, help = NULL, error = NULL, required = FALSE, disabled = FALSE,
    readonly = FALSE, warning = NULL, loading = FALSE) {
  browser_control_shell(input_id, label, htmltools::tags$input(type = "datetime-local",
    class = "sc-control-input", value = as.character(value), min = min, max = max, step = step),
    help, error, required, disabled, readonly, warning = warning, loading = loading)
}
