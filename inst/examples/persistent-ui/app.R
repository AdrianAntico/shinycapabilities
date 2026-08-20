library(shiny)
library(shinycapabilities)

make_nodes <- function(n, revision = 1L, hidden = FALSE, reverse = FALSE, extra = FALSE) {
  rows <- lapply(seq_len(n), function(i) list(id = paste0("row_", i), type = "row",
    parent_id = paste0("section_", 1L + (i - 1L) %/% 10L), order = if (reverse) -i else i,
    selected = i == 1L, children = list(
      list(id = paste0("label_", i), type = "text", value = paste("Metric", i)),
      list(id = paste0("value_", i), type = "value", label = "Value", value = revision * 1000L + i),
      list(id = paste0("status_", i), type = "badge", label = if (i %% 7L) "Ready" else "Review",
        status = if (i %% 7L) "success" else "warning", visible = !hidden || i %% 3L != 0L),
      list(id = paste0("draft_", i), type = "field", label = "Analyst note", value = paste("Draft", i)),
      list(id = paste0("action_", i), type = "action", label = "Inspect", metadata = list(row = i)))))
  sections <- lapply(seq_len(ceiling(n / 10)), function(i) list(id = paste0("section_", i), type = "section",
    label = paste("Analytical section", i), order = i, expanded = TRUE))
  nodes <- c(sections, rows)
  if (extra) nodes <- c(nodes, list(list(id = "late_section", type = "section", label = "New findings", order = 999,
    children = list(list(id = "late_text", type = "text", value = "Added without replacing the persistent root.")))))
  nodes
}

traditional_tags <- function(nodes) {
  normalized <- shinycapabilities:::normalize_persistent_ui_nodes(nodes)
  parents <- vapply(normalized, `[[`, character(1), "parentId"); parents[!nzchar(parents)] <- "__root__"
  children <- split(normalized, parents)
  build <- function(node) {
    nested <- lapply(if (is.null(children[[node$id]])) list() else children[[node$id]], build)
    switch(node$type,
      section = tags$details(open = node$expanded, tags$summary(node$label), nested),
      row = tags$div(class = "traditional-row", nested), text = tags$p(node$value),
      value = tags$div(tags$small(node$label), tags$strong(node$value)),
      badge = if (node$visible) tags$span(class = paste("label", paste0("label-", if (node$status == "success") "success" else "warning")), node$label),
      field = textInput(paste0("traditional_", node$id), node$label, node$value),
      action = actionButton(paste0("traditional_", node$id), node$label))
  }
  tagList(lapply(children[["__root__"]], build))
}

persistent_probe_ui <- function(id) {
  ns <- NS(id)
  persistent_ui_output(ns("panel"), height = "220px")
}

persistent_probe_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    output$panel <- render_persistent_ui({
      persistent_ui(list(
        list(id = "probe_section", type = "section", label = "Namespaced module instance", expanded = TRUE,
          children = list(
            list(id = "probe_value", type = "value", label = "Namespace", value = session$ns("panel")),
            list(id = "probe_action", type = "action", label = "Module action")
          ))
      ), revision = 1L)
    })
  })
}

ui <- fluidPage(
  tags$head(tags$script(src = "benchmark.js")),
  tags$style(".traditional-panel{height:520px;overflow:auto;border:1px solid #ccd4df;padding:10px}.traditional-row{display:grid;grid-template-columns:repeat(auto-fit,minmax(130px,1fr));gap:8px;border-bottom:1px solid #ddd;padding:7px}"),
  titlePanel("Persistent Dynamic UI 1.0"),
  fluidRow(column(12, selectInput("complexity", "Rows", c(10, 50, 100, 250), selected = 50),
    actionButton("value", "Value update"), actionButton("visibility", "Visibility update"),
    actionButton("structure", "Add/remove"), actionButton("reorder", "Reorder"), actionButton("burst", "200 updates"),
    actionButton("stale", "Send stale update"), actionButton("hide", "Hide/show persistent"),
    actionButton("mount", "Remove/remount persistent"),
    verbatimTextOutput("metrics"))),
  fluidRow(column(6, h3("Traditional renderUI"), uiOutput("traditional")),
    column(6, h3("Persistent keyed UI"), uiOutput("persistent_slot"))),
  fluidRow(column(6, h3("Composition boundary"), p("Direct components remain specialized siblings; the persistent schema does not embed arbitrary Shiny UI."),
    command_palette_direct_output("palette", height = "260px")),
    column(6, h3("Persistent events"), verbatimTextOutput("events"))),
  fluidRow(column(6, h3("Namespaced second instance"), persistent_probe_ui("probe")),
    column(6, h3("Browser diagnostics"), tags$pre(id = "browser_metrics", "Waiting for browser instrumentation..."))))

server <- function(input, output, session) {
  state <- reactiveValues(revision = 1L, hidden = FALSE, reverse = FALSE, extra = FALSE,
    mounted = TRUE, persistent_hidden = FALSE,
    prior = NULL, persistent_ms = NA_real_, persistent_bytes = NA_integer_, traditional_ms = NA_real_, traditional_bytes = NA_integer_)
  current <- reactive(make_nodes(as.integer(input$complexity), state$revision, state$hidden, state$reverse, state$extra))
  output$traditional <- renderUI({
    started <- proc.time()[["elapsed"]]; tags <- traditional_tags(current()); rendered <- htmltools::renderTags(tags)$html
    state$traditional_ms <- (proc.time()[["elapsed"]] - started) * 1000; state$traditional_bytes <- nchar(rendered, type = "bytes")
    div(class = "traditional-panel", tags)
  })
  output$persistent <- render_persistent_ui({
    persistent_ui(isolate(current()), revision = isolate(state$revision))
  })
  output$persistent_slot <- renderUI({
    if (!state$mounted) return(div(id = "persistent_unmounted", "Persistent component removed."))
    div(style = if (state$persistent_hidden) "display:none" else NULL,
      persistent_ui_output("persistent"))
  })
  output$palette <- render_command_palette_direct(command_palette_direct(list(
    list(id = "inspect", label = "Inspect selected row"), list(id = "export", label = "Export evidence"))))
  send <- function(nodes) {
    started <- proc.time()[["elapsed"]]
    normalized <- shinycapabilities:::normalize_persistent_ui_nodes(nodes)
    prior <- state$prior
    state$prior <- update_persistent_ui(session, "persistent", nodes, state$revision, previous_nodes = prior)
    state$persistent_ms <- (proc.time()[["elapsed"]] - started) * 1000
    payload <- if (is.null(prior)) normalized else {
      old <- setNames(shinycapabilities:::normalize_persistent_ui_nodes(prior), vapply(prior, `[[`, character(1), "id"))
      now <- setNames(normalized, vapply(normalized, `[[`, character(1), "id")); changed <- names(now)[vapply(names(now), function(id) is.null(old[[id]]) || !identical(old[[id]], now[[id]]), logical(1))]
      list(upsert = unname(now[changed]), remove = setdiff(names(old), names(now)))
    }
    state$persistent_bytes <- nchar(jsonlite::toJSON(payload, auto_unbox = TRUE, null = "null", digits = NA), type = "bytes")
  }
  observeEvent(current(), { state$prior <- current() }, once = TRUE)
  mutate <- function(kind) { state$revision <- state$revision + 1L
    if (kind == "visibility") state$hidden <- !state$hidden
    if (kind == "structure") state$extra <- !state$extra
    if (kind == "reorder") state$reverse <- !state$reverse
    send(current()) }
  observeEvent(input$value, mutate("value")); observeEvent(input$visibility, mutate("visibility"))
  observeEvent(input$structure, mutate("structure")); observeEvent(input$reorder, mutate("reorder"))
  observeEvent(input$complexity, { state$revision <- state$revision + 1L; send(current()) }, ignoreInit = TRUE)
  observeEvent(input$burst, for (i in seq_len(200L)) { state$revision <- state$revision + 1L; send(current()) })
  observeEvent(input$stale, {
    update_persistent_ui(session, "persistent", current(), max(0L, state$revision - 1L), previous_nodes = state$prior)
  })
  observeEvent(input$hide, { state$persistent_hidden <- !state$persistent_hidden })
  observeEvent(input$mount, { state$mounted <- !state$mounted })
  observeEvent(input$persistent_event, {
    if (identical(input$persistent_event$type, "draft")) {
      state$revision <- state$revision + 1L
      send(current())
    }
  }, ignoreInit = TRUE)
  output$metrics <- renderPrint(list(revision = state$revision, traditional_render_ms = state$traditional_ms,
    traditional_html_bytes = state$traditional_bytes, persistent_r_ms = state$persistent_ms,
    persistent_patch_bytes = state$persistent_bytes))
  output$events <- renderPrint(input$persistent_event)
  persistent_probe_server("probe")
}
shinyApp(ui, server)
