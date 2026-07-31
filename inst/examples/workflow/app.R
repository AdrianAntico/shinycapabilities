library(shiny)
library(shinycapabilities)

`%or%` <- function(value, fallback) if (is.null(value)) fallback else value

# This order domain is an optional example fixture. Package core has no
# knowledge of these identifiers or behaviors.
registry <- capability_registry()
add_step <- function(id, label, description, order, optional_input = FALSE) {
  capability_registry_add(registry, register_capability(
    id = id, version = "1.0.0", display_name = label,
    description = description, category = "Order flow",
    inputs = list(item = port_type("work_item", required = !optional_input)),
    outputs = list(item = port_type("work_item")),
    config = list(note = config_field("text", "Operator note", label)),
    validate = function(context, config, inputs) list(valid = nzchar(config$note)),
    execute = function(context, config, inputs) {
      item <- inputs$item %or% context$work_item
      item$history <- c(item$history %or% character(), config$note)
      list(item = item)
    },
    implementation_fingerprint = paste0("optional-order-example-", id, "-1"),
    presentation = list(
      group_id = "order-flow", group_label = "Order flow", group_order = 10,
      display_order = order, icon_id = c("□", "✓", "→", "◇")[[order / 10]],
      short_summary = description, compact_summary = label,
      input_port_labels = list(item = "Work item"),
      output_port_labels = list(item = "Work item"),
      accessibility_label = paste(label, "order-flow step")
    )
  ))
}
add_step("example.receive_order", "Receive order", "Create a deterministic order work item.", 10, TRUE)
add_step("example.check_inventory", "Check inventory", "Confirm that requested items are available.", 20)
add_step("example.approve_packing", "Approve packing", "Record the bounded packing approval.", 30)
add_step("example.dispatch_shipment", "Dispatch shipment", "Produce the dispatched work item.", 40)

node <- function(id, capability_id, x, note) list(
  id = id, capability_id = capability_id, position = list(x = x, y = 110),
  size = list(width = 270, height = 180), state = "ready", config = list(note = note)
)
edge <- function(source, target) list(
  id = paste(source, target, sep = "__"), source = source, source_port = "item",
  target = target, target_port = "item"
)
connected_graph <- list(
  nodes = list(
    node("receive", "example.receive_order", 40, "Order received"),
    node("inventory", "example.check_inventory", 360, "Inventory checked"),
    node("packing", "example.approve_packing", 680, "Packing approved"),
    node("dispatch", "example.dispatch_shipment", 1000, "Shipment dispatched")
  ),
  edges = list(edge("receive", "inventory"), edge("inventory", "packing"),
    edge("packing", "dispatch"))
)

example_css <- "
html,body{width:100%;height:100%;margin:0;overflow:hidden;background:#f4f7fb;color:#172033;font-family:Inter,system-ui,sans-serif}
.container-fluid{height:100%;padding:0}.example-shell{height:100dvh;display:grid;grid-template-rows:52px minmax(0,1fr) 37px;overflow:hidden}
.example-header{display:flex;align-items:center;gap:14px;padding:0 14px;background:#fff;border-bottom:1px solid #d7deea}
.example-header h1{font-size:16px;margin:0}.example-header p{margin:0;color:#5d6a7e;font-size:12px}.example-actions{display:flex;gap:6px;margin-left:auto;flex-wrap:wrap}
.example-actions .btn{padding:5px 9px;font-size:12px}.example-body{min-height:0;overflow:hidden}.example-body>.shiny-bound-output{height:100%}
.example-drawer{--example-drawer-height:240px;position:relative;z-index:30;min-height:37px;background:#fff;border-top:1px solid #d7deea;overflow:hidden}
.example-drawer.is-open{height:var(--example-drawer-height);margin-top:calc(-1 * var(--example-drawer-height) + 37px);box-shadow:0 -12px 28px #21324c22}
.drawer-tabs{height:37px;display:flex;align-items:center;gap:4px;padding:0 10px}.drawer-tabs button{border:0;background:transparent;padding:7px 10px;color:#4c5b70}
.drawer-resizer{width:24px;cursor:ns-resize;font-size:16px}.drawer-resizer:focus-visible{outline:2px solid #1769aa;outline-offset:-2px}
.drawer-content{height:calc(100% - 37px);overflow:auto;padding:12px 16px;background:#fff}.drawer-content pre{white-space:pre-wrap}
.example-shell{--shinycap-color-background:#f7f9fc;--shinycap-color-panel:#fff;--shinycap-color-panel-raised:#eef3f9;--shinycap-color-border:#cdd6e4;--shinycap-color-text:#172033;--shinycap-color-muted:#5d6a7e;--shinycap-color-selection:#1769aa;--shinycap-color-consequential:#ad5b10;--shinycap-color-error:#b42335;--shinycap-color-success:#147a55;--sc-bg:#f7f9fc;--sc-panel:#fff;--sc-panel-2:#eef3f9;--sc-border:#cdd6e4;--sc-text:#172033;--sc-muted:#5d6a7e;--sc-cyan:#1769aa;--sc-amber:#ad5b10;--sc-red:#b42335;--sc-green:#147a55;--shinycap-workbench-background:#edf2f8;--shinycap-palette-width:220px;--shinycap-inspector-width:300px}
.example-shell .sc-flow .react-flow__background{background:#f4f7fb}.example-shell .sc-node{box-shadow:0 8px 22px #3047651c}.example-shell .react-flow__controls,.example-shell .react-flow__minimap{background:#fff}
.example-shell .sc-palette-category-body{grid-template-columns:1fr!important}.example-shell .sc-palette-item{min-height:50px}.example-shell .sc-palette-item strong{white-space:normal}
@media(max-width:1050px){.example-header p{display:none}.example-actions button:nth-of-type(n+7){display:none}.example-shell{--shinycap-palette-width:280px;--shinycap-inspector-width:300px}}
"

ui <- fluidPage(
  tags$head(
    tags$title("shinycapabilities order workflow example"),
    tags$link(rel = "icon", href = "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 64 64'%3E%3Crect width='64' height='64' rx='14' fill='%231769aa'/%3E%3Cpath d='M16 20h32v26H16zM22 14h20v12H22z' fill='none' stroke='white' stroke-width='5'/%3E%3C/svg%3E"),
    tags$style(HTML(example_css))
  ),
  tags$div(class = "example-shell",
    tags$header(class = "example-header",
      tags$div(tags$h1("Order workflow studio"), tags$p("Connect output handles to compatible inputs. R validates every connection.")),
      tags$div(class = "example-actions",
        actionButton("load_example", "Load connected example"),
        actionButton("start_blank", "Start blank"),
        actionButton("save_workflow", "Save"), actionButton("restore_workflow", "Restore"),
        actionButton("run_selected", "Run selected"), actionButton("run_dependencies", "Run + dependencies"),
        actionButton("run_workflow", "Run workflow", class = "btn-primary"),
        actionButton("inspect_plan", "Plan"),
        tags$button(type = "button", class = "sc-widget-command btn btn-default", `data-command` = "fitView",
          `data-target` = "workflow-canvas", "Fit view")
      )
    ),
    tags$main(class = "example-body",
      capability_canvas_ui("workflow", registry, height = "100%", toolbar = FALSE,
        palette_density_controls = FALSE)
    ),
    tags$section(id = "example_drawer", class = "example-drawer", `aria-label` = "Workflow details",
      tags$div(class = "drawer-tabs", role = "tablist",
        tags$button(type = "button", class = "drawer-resizer", `aria-label` = "Resize workflow details drawer",
          title = "Drag or use Up and Down arrow keys to resize", "↕"),
        tags$button(type = "button", `data-drawer-tab` = "outputs", "Outputs"),
        tags$button(type = "button", `data-drawer-tab` = "plan", "Execution plan"),
        tags$button(type = "button", `data-drawer-tab` = "problems", "Problems"),
        tags$button(type = "button", `data-drawer-tab` = "logs", "Logs"),
        tags$button(type = "button", id = "drawer_toggle", style = "margin-left:auto", `aria-expanded` = "false", "Open")
      ),
      tags$div(class = "drawer-content", uiOutput("drawer_content"))
    )
  ),
  tags$script(HTML("(()=>{const drawer=()=>document.getElementById('example_drawer');const resize=h=>{const value=Math.max(140,Math.min(innerHeight*.55,h));drawer().style.setProperty('--example-drawer-height',value+'px');window.dispatchEvent(new Event('resize'));};document.addEventListener('click',e=>{const tab=e.target.closest('[data-drawer-tab]');const toggle=e.target.closest('#drawer_toggle');if(!tab&&!toggle)return;const panel=drawer();if(tab)Shiny.setInputValue('drawer_tab',tab.dataset.drawerTab,{priority:'event'});panel.classList.toggle('is-open',tab?true:!panel.classList.contains('is-open'));const open=panel.classList.contains('is-open');document.getElementById('drawer_toggle').textContent=open?'Close':'Open';document.getElementById('drawer_toggle').setAttribute('aria-expanded',String(open));window.dispatchEvent(new Event('resize'));});document.addEventListener('pointerdown',e=>{const handle=e.target.closest('.drawer-resizer');if(!handle)return;e.preventDefault();drawer().classList.add('is-open');const start=e.clientY,height=drawer().getBoundingClientRect().height;const move=event=>resize(height+start-event.clientY);const end=()=>{removeEventListener('pointermove',move);removeEventListener('pointerup',end)};addEventListener('pointermove',move);addEventListener('pointerup',end)});document.addEventListener('keydown',e=>{if(!e.target.matches('.drawer-resizer'))return;if(e.key==='ArrowUp'||e.key==='ArrowDown'){e.preventDefault();drawer().classList.add('is-open');resize(drawer().getBoundingClientRect().height+(e.key==='ArrowUp'?20:-20))}else if(e.key==='Home'){e.preventDefault();resize(240)}else if(e.key==='Escape'){drawer().classList.remove('is-open')}});document.addEventListener('dblclick',e=>{if(e.target.closest('.drawer-resizer'))resize(240)});})();"))
)

server <- function(input, output, session) {
  studio <- capability_canvas_server("workflow", registry, connected_graph,
    context = list(work_item = list(id = "ORDER-1001", history = character())),
    bind_internal_controls = FALSE)
  saved <- reactiveVal(NULL)
  active_tab <- reactiveVal("outputs")
  observeEvent(input$load_example, studio$set_graph(connected_graph))
  observeEvent(input$start_blank, studio$set_graph(list(nodes = list(), edges = list())))
  observeEvent(input$save_workflow, saved(studio$graph()))
  observeEvent(input$restore_workflow, if (!is.null(saved())) studio$set_graph(saved()))
  observeEvent(input$run_selected, studio$controls$run_selected())
  observeEvent(input$run_dependencies, studio$controls$run_with_dependencies())
  observeEvent(input$run_workflow, studio$controls$run_workflow())
  observeEvent(input$inspect_plan, studio$controls$inspect_plan())
  observeEvent(input$drawer_tab, active_tab(input$drawer_tab))
  output$drawer_content <- renderUI({
    tab <- active_tab()
    if (identical(tab, "outputs")) return(tagList(tags$h3("Outputs"),
      if (!length(studio$cache())) tags$p("Run a step or workflow to inspect output provenance and summaries.") else tags$pre(jsonlite::toJSON(studio$cache(), auto_unbox = TRUE, pretty = TRUE))))
    if (identical(tab, "plan")) return(tagList(tags$h3("Execution plan"),
      if (is.null(studio$plan())) tags$p("Choose Plan to inspect deterministic dependency order and cache actions.") else tags$pre(jsonlite::toJSON(studio$plan(), auto_unbox = TRUE, pretty = TRUE))))
    if (identical(tab, "problems")) return(tagList(tags$h3("Problems"), tags$p("Connection and graph validation findings appear on the canvas and here when present.")))
    tagList(tags$h3("Logs"), tags$p("Runtime lifecycle messages remain bounded to this session."),
      tags$pre(if (is.null(studio$runtime())) "No workflow run yet." else jsonlite::toJSON(studio$runtime()$lifecycle, auto_unbox = TRUE, pretty = TRUE)))
  })
}

shinyApp(ui, server)
