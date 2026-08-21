library(shiny)
library(shinycapabilities)

sample_notifications <- function(n = 1L) lapply(seq_len(n), function(i) list(
  id = paste0("notice-", i), severity = c("info", "success", "warning", "error")[(i - 1L) %% 4L + 1L],
  title = paste("Activity", i), message = "Host-supplied bounded operational message.",
  timeout = if (i %% 3L) 5000 else 0, persistent = i %% 3L == 0,
  actions = list(list(id = "inspect", label = "Inspect"))))

ui <- fluidPage(
  tags$head(tags$style(HTML("body{max-width:1440px;margin:auto;padding:20px;background:var(--sc-bg);color:var(--sc-text)}.gallery-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:14px}.gallery-card{background:var(--sc-panel);border:1px solid var(--sc-border);border-radius:8px;padding:14px}.demo-stage{min-height:160px;display:grid;place-items:center;background:var(--sc-panel-2);border-radius:6px}@media(max-width:760px){.gallery-grid{grid-template-columns:1fr}}"))),
  tags$h1("Complete browser UI surface"),
  tags$p("Host-neutral browser presentation; Shiny remains reactive and authoritative."),
  browser_breadcrumbs("crumbs", list(list(id = "home", label = "Workspace"), list(id = "report", label = "Report Studio"), list(id = "current", label = "Evidence"))),
  browser_tabs("main_tabs", list(
    list(id = "surfaces", label = "Surfaces", content = tagList(
      div(class = "gallery-grid",
        div(class = "gallery-card", h2("Overlays"),
          browser_tooltip("help_tip", "Hover or focus for help", "A concise, accessible explanation."), br(), br(),
          browser_popover("details_pop", "Open contextual details", div(p("Anchored supplied content."), browser_status_badge("Ready", "success")), title = "Artifact details"), br(), br(),
          browser_context_menu("artifact_menu", div(class = "demo-stage", "Right click or Shift+F10"), list(
            list(id = "inspect", label = "Inspect"), list(id = "duplicate", label = "Duplicate"), list(id = "remove", label = "Remove", destructive = TRUE)))),
        div(class = "gallery-card", h2("Dialog family"),
          browser_action_button("open_dialog", "Open dialog", variant = "primary"),
          browser_action_button("open_drawer", "Open drawer", variant = "secondary"),
          browser_dialog("analysis_dialog", "Run analysis?", "The host remains responsible for execution.",
            p("Review the supplied configuration before emitting the run intent."),
            actions = list(list(id = "cancel", label = "Cancel"), list(id = "run", label = "Run", kind = "primary"))),
          browser_dialog("detail_drawer", "Artifact inspector", "Persistent contextual details.",
            div(style = "height:320px", object_inspector(list(status = "ready", evidence = list("e-1", "e-2")), element_id = "drawer_inspector")),
            variant = "drawer", actions = list(list(id = "close", label = "Close")))),
        div(class = "gallery-card", h2("Navigation"),
          browser_tabs("local_tabs", list(
            list(id = "overview", label = "Overview", content = p("Executive findings.")),
            list(id = "diagnostics", label = "Diagnostics", content = p("Quality gates and caveats.")),
            list(id = "appendix", label = "Appendix", content = p("Detailed evidence.")))),
          browser_accordion("disclosures", list(
            list(id = "assumptions", title = "Assumptions", content = p("Host-supplied assumptions."), open = TRUE),
            list(id = "limitations", title = "Limitations", content = p("Known analytical limitations.")))),
          browser_pagination("pages", page = 2, pages = 8)),
        div(class = "gallery-card", h2("Files and artifacts"),
          browser_file_upload("files", "Add data", "CSV, Parquet, or bundle", multiple = TRUE,
            accept = c(".csv", ".parquet", ".zip"), max_size = 25 * 1024^2),
          hr(), browser_download_action("download", "Download report", "analysis.html", "HTML", "2.4 MB"))),
      h2("Analytical output shells"),
      div(class = "gallery-grid",
        output_shell("ready_output", title = "Model evidence", subtitle = "Resize-aware component host", metadata = "Updated now", status = "Ready",
          actions = list(list(id = "refresh", label = "Refresh", kind = "secondary")),
          div(class = "demo-stage", style = "height:240px", object_inspector(list(metric = 0.932, diagnostics = list(status = "passed")), element_id = "shell_object"))),
        output_shell("empty_output", title = "Segment analysis", state = "empty", message = "No segment has been selected."),
        output_shell("error_output", title = "Failed output", state = "error", message = "The host supplied a bounded rendering error."),
        output_shell("loading_output", title = "Building evidence", state = "loading"))
    )),
    list(id = "report", label = "Report composition", content = split_pane_direct(
      panes = list(
        outline = report_outline("outline_nav", list(
          list(id = "executive", label = "Executive findings", status = "Ready"),
          list(id = "quality", label = "Quality gates", status = "Warning"),
          list(id = "effects", label = "Global effects", level = 2, status = "Ready"),
          list(id = "appendix", label = "Appendix", status = "Draft"))),
        canvas = output_shell("report_block", title = "Global effects", subtitle = "Generic report block shell",
          div(class = "demo-stage", "AutoPlots, a semantic table, or another qualified component"))
      ), direction = "horizontal", element_id = "report_split")),
    list(id = "system", label = "System composition", content = tagList(
      p("Existing specialized components retain independent state and share the package runtime."),
      parameter_workbench_ui("parameters", title = "Analysis parameters", subtitle = "Schema-driven configuration"),
      div(style = "height:280px", persistent_ui(
        lapply(1:8, function(i) list(id = paste0("row", i), type = "badge", label = paste("Job", i), value = if (i %% 3) "Ready" else "Attention")),
        element_id = "projection"))))
  )),
  notification_center("notifications", sample_notifications(2)),
  browser_action_button("notify_burst", "Send notification burst", variant = "secondary"),
  verbatimTextOutput("last_event")
)

server <- function(input, output, session) {
  parameter_workbench_server("parameters", schema = list(
    list(key = "method", label = "Method", type = "choice", choices = c("Regression", "Binary"), default = "Regression"),
    list(key = "threshold", label = "Threshold", type = "numeric", default = 0.5)))
  observeEvent(input$open_dialog, update_browser_surface(session, "analysis_dialog", "open"))
  observeEvent(input$open_drawer, update_browser_surface(session, "detail_drawer", "open"))
  observeEvent(input$notify_burst, update_notification_center(session, "notifications", sample_notifications(12), "append"))
  event_sources <- reactiveValues(last = "No bounded intent received yet.")
  observe({
    candidates <- c(input$analysis_dialog_event, input$detail_drawer_event, input$artifact_menu_event,
      input$main_tabs_event, input$local_tabs_event, input$outline_nav_event, input$ready_output_event,
      input$notifications_event, input$files_surface_event)
    values <- Filter(Negate(is.null), candidates)
    if (length(values)) event_sources$last <- values[[length(values)]]
  })
  output$last_event <- renderPrint(event_sources$last)
  output$download <- downloadHandler(filename = function() "analysis.html", content = function(file) writeLines("<h1>Qualified download seam</h1>", file))
}

shinyApp(ui, server)
