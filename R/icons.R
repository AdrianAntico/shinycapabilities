#' Allowed neutral icon identifiers
#' @return A character vector of locally rendered icon identifiers.
#' @export
shinycapabilities_icon_allowlist <- function() {
  c("adjust", "asterisk", "ban-circle", "barcode", "bell", "book", "bookmark",
    "briefcase", "bullhorn", "calendar", "camera", "certificate", "check", "cloud",
    "cog", "comment", "dashboard", "edit", "eye-open", "file", "filter", "fire",
    "flag", "flash", "folder-open", "globe", "hdd", "heart", "inbox", "leaf",
    "link", "list-alt", "lock", "magnet", "map-marker", "move", "ok-circle",
    "paperclip", "picture", "pushpin", "qrcode", "random", "refresh", "repeat",
    "road", "saved", "search", "send", "signal", "sort", "stats", "tag", "tasks",
    "th", "th-large", "th-list", "time", "tower", "transfer", "tree-deciduous",
    "tree-conifer", "user", "warning-sign", "wrench", "zoom-in")
}

normalize_shinycapabilities_icon <- function(icon_id) {
  if (is.character(icon_id) && length(icon_id) == 1L &&
      icon_id %in% shinycapabilities_icon_allowlist()) icon_id else "asterisk"
}

shinycapabilities_icon_tag <- function(icon_id, class = NULL) {
  icon_id <- normalize_shinycapabilities_icon(icon_id)
  htmltools::tags$span(
    class = paste(c(class, "glyphicon", paste0("glyphicon-", icon_id)), collapse = " "),
    `data-shinycap-icon` = icon_id, `aria-hidden` = "true"
  )
}
