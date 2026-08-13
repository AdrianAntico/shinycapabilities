library(shiny)
library(shinycapabilities)

groups <- list(
  workstation_header_group("file", "File", priority = 10, preferred_row = 1),
  workstation_header_group("edit", "Edit", priority = 20, preferred_row = 1),
  workstation_header_group("run", "Run", priority = 10, preferred_row = 2),
  workstation_header_group("view", "View", priority = 30, preferred_row = 2),
  workstation_header_group("context", "Context", priority = 40, preferred_row = 2)
)
commands <- list(
  workstation_header_command("new", "New", "file", icon = "+", priority = 1, overflow = FALSE),
  workstation_header_command("open", "Open", "file", icon = "O", priority = 2, overflow = FALSE),
  workstation_header_command("save", "Save", "file", icon = "S", priority = 3, shortcut = "Ctrl+S"),
  workstation_header_command("undo", "Undo", "edit", icon = "U", priority = 1),
  workstation_header_command("redo", "Redo", "edit", icon = "R", priority = 2,
    enabled = FALSE, disabled_reason = "Nothing to redo"),
  workstation_header_command("run", "Run", "run", icon = ">", priority = 1, overflow = FALSE),
  workstation_header_command("stop", "Stop", "run", icon = "[]", priority = 2,
    enabled = FALSE, disabled_reason = "Nothing is running"),
  workstation_header_command("fit", "Fit", "view", icon = "F", priority = 1),
  workstation_header_command("focus", "Focus", "view", icon = "#", priority = 2, active = TRUE),
  workstation_header_command("inspect", "Inspect selection", "context", icon = "I", priority = 1),
  workstation_header_command("advanced", "Advanced tools", "context", icon = "...", priority = 99)
)

ui <- fluidPage(
  tags$style(HTML(paste(
    "body { margin: 0; padding: 12px; background: var(--aq-app-bg); color: var(--aq-text); }",
    ".example-narrow { width: min(720px, 100%); margin-top: 2rem; }",
    ".theme-light { --aq-app-bg:#f4f7fb; --aq-surface:#fff; --aq-text:#172033; --aq-muted:#64748b; --aq-border:#cbd5e1; --aq-primary:#2563eb; }",
    ".theme-dark { --aq-app-bg:#07111f; --aq-surface:#0d192c; --aq-text:#e8f0fc; --aq-muted:#9cb0c8; --aq-border:#2d405b; --aq-primary:#58a6ff; }",
    ".theme-cyberpunk { --aq-app-bg:#080716; --aq-surface:#141027; --aq-text:#f3f7ff; --aq-muted:#a7a1c9; --aq-border:#533d78; --aq-primary:#00e5ff; --aq-focus-ring:#ff3df2; }",
    sep = "\n"))),
  selectInput("theme", "Theme", c("Light" = "light", "Dark" = "dark", "Cyberpunk" = "cyberpunk")),
  workstation_header_ui("wide", "Example workspace", groups, commands,
    context = "Wide two-row qualification", rows = 2),
  div(class = "example-narrow",
    workstation_header_ui("narrow", "Compact workspace", groups[1:3], commands,
      context = "Narrow one-row qualification", rows = 1)),
  verbatimTextOutput("event"),
  tags$script(HTML("Shiny.addCustomMessageHandler('workstation-header-theme', function(theme) { document.body.className = 'theme-' + theme; });"))
)

server <- function(input, output, session) {
  output$event <- renderPrint(if (!is.null(input$wide_command)) input$wide_command else input$narrow_command)
  observeEvent(input$theme, session$sendCustomMessage("workstation-header-theme", input$theme), ignoreInit = FALSE)
}

shinyApp(ui, server)
