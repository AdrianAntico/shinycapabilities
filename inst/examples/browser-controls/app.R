library(shiny)
library(shinycapabilities)

ui <- fluidPage(
  tags$style(HTML("body{background:var(--sc-bg);color:var(--sc-text);margin:0}body.sc-gallery-dark{--sc-bg:#0b1120;--sc-surface:#111827;--sc-surface-2:#1f2937;--sc-text:#e5e7eb;--sc-muted:#9ca3af;--sc-border:#374151;--sc-input-bg:#111827;--sc-input-border:#4b5563;--sc-primary:#60a5fa;--sc-primary-hover:#3b82f6;--aq-bg:var(--sc-bg);--aq-surface:var(--sc-surface);--aq-surface-2:var(--sc-surface-2);--aq-surface-elevated:var(--sc-surface);--aq-surface-hover:var(--sc-surface-2);--aq-text:var(--sc-text);--aq-muted:var(--sc-muted);--aq-border:var(--sc-border);--aq-input-bg:var(--sc-input-bg);--aq-input-border:var(--sc-input-border);--aq-primary:var(--sc-primary);--aq-primary-hover:var(--sc-primary-hover)}.sc-gallery{margin:0 auto;max-width:1180px;padding:24px}.sc-gallery h1{font-size:1.65rem}.sc-gallery-grid{display:grid;gap:16px;grid-template-columns:repeat(2,minmax(0,1fr))}.sc-gallery-section{align-content:start;background:var(--sc-surface);border:1px solid var(--sc-border);border-radius:8px;display:grid;gap:14px;padding:16px}.sc-gallery-actions{align-items:center;display:flex;flex-wrap:wrap;gap:8px}.sc-gallery-displays{align-items:start;display:grid;gap:14px;grid-template-columns:repeat(3,minmax(0,1fr))}@media(max-width:760px){.sc-gallery-grid,.sc-gallery-displays{grid-template-columns:1fr}}")),
  tags$script(HTML("Shiny.addCustomMessageHandler('sc.gallery.theme', function(theme){document.body.classList.toggle('sc-gallery-dark', theme === 'dark');});")),
  div(class = "sc-gallery",
    h1("Browser-native control system"),
    p("Shiny owns reactive state; shinycapabilities owns the visible interaction language."),
    div(class = "sc-gallery-grid",
      tags$section(class = "sc-gallery-section", h2("Fields"),
        browser_text_field("name", "Analysis name", "Revenue review",
          help = "A concise, reusable label.", required = TRUE),
        browser_numeric_field("iterations", "Iterations", 100, min = 1, max = 1000),
        browser_secret_field("secret", "API secret", placeholder = "Stored by the host"),
        browser_textarea("notes", "Notes", "Inspect regional instability.", rows = 4),
        browser_text_field("invalid", "Validated field", "bad value",
          error = "Use a governed identifier."),
        browser_text_field("readonly", "Read-only value", "artifact://result-17", readonly = TRUE)),
      tags$section(class = "sc-gallery-section", h2("Choices"),
        selection_input("dataset", "Dataset", c("Transactions", "Customers", "Forecasts")),
        browser_checkbox("include_appendix", "Include diagnostic appendix", TRUE),
        browser_switch("live_updates", "Live browser updates", TRUE,
          help = "The host remains authoritative."),
        browser_radio_group("density", "Density", c(Comfortable = "comfortable", Compact = "compact")),
        browser_segmented_control("theme", "Theme", c(Light = "light", Dark = "dark", System = "system"), "system"),
        browser_slider("confidence", "Minimum confidence", 70, 0, 100, 5)),
      tags$section(class = "sc-gallery-section", h2("Actions"),
        div(class = "sc-gallery-actions",
          browser_action_button("run", "Run analysis", variant = "primary"),
          browser_action_button("save", "Save draft", variant = "secondary"),
          browser_action_button("approve", "Approve", variant = "success"),
          browser_action_button("remove", "Remove", variant = "danger"),
          browser_action_link("details", "View details")),
        div(class = "sc-gallery-actions",
          browser_action_button("loading", "Running", loading = TRUE),
          browser_action_button("disabled", "Unavailable", disabled = TRUE))),
      tags$section(class = "sc-gallery-section", h2("Displays and feedback"),
        div(class = "sc-gallery-displays",
          browser_value_display("1,284", "Artifacts", "Across 12 sections", "number"),
          browser_value_display("94.2%", "Coverage", "Validated evidence", "percent"),
          browser_status_badge("Ready", "success")),
        browser_progress(72, label = "Analysis progress", description = "18 of 25 bounded steps"),
        browser_progress(NULL, label = "Preparing projection"),
        browser_alert("Review required", "Two high-impact findings need human adjudication.", "warning"),
        browser_skeleton(4, "Loading evidence"))
    ),
    h2("Advanced composition"),
    split_pane("gallery_split",
      monitor = virtual_tree_browser_output("tree", height = "100%"),
      inspector = object_inspector_output("inspector", height = "100%"),
      sizes = c(40, 60), height = "430px")
  )
)

server <- function(input, output, session) {
  output$tree <- render_virtual_tree_browser(virtual_tree_browser(list(
    list(id = "controls", label = "Foundational controls", children = list(
      list(id = "fields", label = "Fields"), list(id = "actions", label = "Actions"),
      list(id = "displays", label = "Displays"))))))
  output$inspector <- render_object_inspector(object_inspector(list(
    architecture = "Shiny authority -> browser-native capability",
    input_contract = list(value = "bounded", events = "user-triggered"),
    accessibility = c("keyboard", "focus", "high contrast", "reduced motion"))))
  observeEvent(input$run, {
    update_browser_control(session, "name", value = paste("Analysis", input$run), error = NULL)
  })
  observeEvent(input$theme, {
    session$sendCustomMessage("sc.gallery.theme", input$theme)
  }, ignoreInit = FALSE)
}

shinyApp(ui, server)
