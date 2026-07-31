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

# The public icon vocabulary is renderer-neutral. Shiny 1.11 ships Font
# Awesome 6, while the original alpha renderer used Bootstrap 3 glyphicon
# classes. Bootstrap 5 hosts do not ship that font, so translate the stable
# neutral identifiers deterministically at this rendering boundary.
shinycapabilities_fontawesome_icon <- function(icon_id) {
  icon_id <- normalize_shinycapabilities_icon(icon_id)
  aliases <- c(
    "adjust" = "sliders", "ban-circle" = "ban", "cog" = "gear",
    "dashboard" = "gauge", "edit" = "pen", "eye-open" = "eye",
    "flash" = "bolt", "hdd" = "hard-drive", "list-alt" = "rectangle-list",
    "map-marker" = "location-dot", "move" = "up-down-left-right",
    "ok-circle" = "circle-check", "picture" = "image", "pushpin" = "thumbtack",
    "random" = "shuffle", "refresh" = "rotate", "saved" = "floppy-disk",
    "search" = "magnifying-glass", "send" = "paper-plane", "stats" = "chart-column",
    "tasks" = "list-check", "th" = "table-cells", "th-large" = "table-cells-large",
    "th-list" = "list", "time" = "clock", "tower" = "tower-broadcast",
    "transfer" = "right-left", "tree-deciduous" = "tree",
    "tree-conifer" = "tree", "warning-sign" = "triangle-exclamation",
    "zoom-in" = "magnifying-glass-plus"
  )
  rendered <- unname(aliases[icon_id])
  if (length(rendered) && !is.na(rendered) && nzchar(rendered)) rendered else icon_id
}

shinycapabilities_icon_tag <- function(icon_id, class = NULL) {
  icon_id <- normalize_shinycapabilities_icon(icon_id)
  icon <- shiny::icon(
    shinycapabilities_fontawesome_icon(icon_id),
    class = paste(c(class, "sc-rendered-icon"), collapse = " ")
  )
  icon$attribs$role <- NULL
  icon$attribs$`aria-label` <- NULL
  icon$attribs$`aria-hidden` <- "true"
  icon$attribs$`data-shinycap-icon` <- icon_id
  icon
}
