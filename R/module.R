capability_presentation <- function(capability) {
    category <- capability$category %||% "Other"
    semantic <- tolower(paste(capability$id, capability$display_name, category))
    group <- if (grepl("dataset|data quality|prepar|profile", semantic)) "Data"
    else if (grepl("eda|association|target|explor", semantic)) "Explore"
    else if (grepl("model|regression|classification|forecast", semantic)) "Model"
    else if (grepl("explain|importance|dependence|shap", semantic)) "Explain"
    else if (grepl("causal", semantic)) "Causal"
    else if (grepl("decision|alternative|scenario|optim|recommend", semantic)) "Decision"
    else if (grepl("research|evidence", semantic)) "Research"
    else if (grepl("report|brief|visual", semantic)) "Delivery"
    else category
    icon <- if (grepl("dataset", semantic)) "\u25a6"
    else if (grepl("prepar", semantic)) "\u2699"
    else if (grepl("quality", semantic)) "\u2713"
    else if (grepl("explor|eda|profile", semantic)) "\u2301"
    else if (grepl("association|statistic", semantic)) "\u2211"
    else if (grepl("regression", semantic)) "\u2197"
    else if (grepl("classification", semantic)) "\u25eb"
    else if (grepl("forecast|time", semantic)) "\u25f7"
    else if (grepl("visual|plot", semantic)) "\u25a5"
    else if (grepl("research", semantic)) "\u2315"
    else if (grepl("evidence|synthesis", semantic)) "\u25ce"
    else if (grepl("causal", semantic)) "\u21c4"
    else if (grepl("optim", semantic)) "\u2316"
    else if (grepl("decision|alternative|scenario|recommend", semantic)) "\u25c6"
    else if (grepl("report|brief|delivery", semantic)) "\u25a4"
    else if (grepl("model", semantic)) "\u25c7"
    else "\u25c7"
    list(
      icon = if (is.null(capability$icon) || capability$icon %in% c("", "\u25c7")) icon else capability$icon,
      label = capability$display_name,
      category = group,
      accent = tolower(group),
      description = capability$description,
      search = tolower(paste(capability$id, capability$display_name,
        capability$description, category, group))
    )
}

palette_ui <- function(namespace, registry) {
  capabilities <- capability_registry_list(registry)
  capabilities <- capabilities[!duplicated(vapply(capabilities, `[[`, character(1), "id"))]
  presentations <- lapply(capabilities, capability_presentation)
  categories <- split(seq_along(capabilities),
    vapply(presentations, `[[`, character(1), "category"))
  shiny::tagList(lapply(sort(names(categories)), function(category) {
    htmltools::tags$details(
      class = "sc-palette-category",
      open = "open",
      htmltools::tags$summary(category),
      htmltools::tags$div(
        class = "sc-palette-category-body",
        lapply(categories[[category]], function(index) {
          capability <- capabilities[[index]]
          item <- presentations[[index]]
          htmltools::tags$button(
            type = "button",
            class = paste("sc-palette-item", paste0("sc-accent-", item$accent)),
            draggable = "true",
            `data-capability-id` = capability$id,
            `data-canvas-id` = namespace("canvas"),
            `data-search` = item$search,
            title = item$description,
            `aria-label` = paste("Insert", item$label, "capability"),
            htmltools::tags$span(class = "sc-palette-icon", `aria-hidden` = "true", item$icon),
            htmltools::tags$strong(item$label)
          )
        })
      )
    )
  }))
}

config_control <- function(namespace, name, definition, value = NULL) {
  id <- namespace(paste0("config__", name))
  value <- value %||% definition$default
  switch(definition$type,
    select = shiny::selectInput(id, definition$label, definition$choices, selected = value),
    multi_select = shiny::selectInput(id, definition$label, definition$choices,
      selected = value, multiple = TRUE),
    text = shiny::textInput(id, definition$label, value = value %||% ""),
    numeric = shiny::numericInput(id, definition$label, value = value %||% 0,
      min = definition$minimum %||% NA, max = definition$maximum %||% NA,
      step = definition$step %||% NA),
    checkbox = shiny::checkboxInput(id, definition$label, value = isTRUE(value)),
    slider = shiny::sliderInput(id, definition$label,
      min = definition$minimum %||% 0, max = definition$maximum %||% 100,
      value = value %||% definition$minimum %||% 0, step = definition$step),
    dataset = shiny::selectInput(id, definition$label, definition$choices %||% character(),
      selected = value),
    column = shiny::selectInput(id, definition$label, definition$choices %||% character(),
      selected = value),
    formula = shiny::textAreaInput(id, definition$label, value = value %||% "", rows = 3),
    custom = htmltools::tags$div(class = "sc-custom-field",
      htmltools::tags$strong(definition$label),
      htmltools::tags$p(definition$help %||% "Host-provided custom UI.")),
    shiny::textInput(id, definition$label, value = value %||% "")
  )
}

#' Capability workflow module UI
#' @param id Module identifier.
#' @param registry Capability registry.
#' @param height Canvas height.
#' @param toolbar Display the package execution toolbar. Hosts may provide their own.
#' @export
capability_canvas_ui <- function(id, registry, height = "680px", toolbar = TRUE) {
  ns <- shiny::NS(id)
  htmltools::tagList(
    htmltools::tags$script(htmltools::HTML(
      "document.addEventListener('dragstart',function(e){const p=e.target.closest('.sc-palette-item');if(!p)return;e.dataTransfer.setData('application/x-shinycapability',p.dataset.capabilityId);e.dataTransfer.effectAllowed='copy';});"
    )),
    htmltools::tags$div(
      class = "sc-workbench",
      htmltools::tags$aside(class = "sc-palette",
        htmltools::tags$div(class = "sc-pane-heading",
          htmltools::tags$span("Capabilities"),
          htmltools::tags$div(class = "sc-palette-density", role = "group",
            `aria-label` = "Palette density",
            htmltools::tags$button(type = "button", `data-palette-density` = "comfortable",
              title = "Comfortable palette", `aria-label` = "Comfortable palette", "\u2630"),
            htmltools::tags$button(type = "button", `data-palette-density` = "compact",
              title = "Compact palette", `aria-label` = "Compact palette", "\u25a6"),
            htmltools::tags$button(type = "button", `data-palette-density` = "icon",
              title = "Icon-only palette", `aria-label` = "Icon-only palette", "\u25c6")
          ),
          htmltools::tags$small("Drag or focus and press Enter")
        ),
        htmltools::tags$label(class = "sc-palette-search-label",
          `for` = ns("palette_search"), "Search capabilities"),
        htmltools::tags$input(id = ns("palette_search"), class = "sc-palette-search",
          type = "search", placeholder = "Search", autocomplete = "off"),
        palette_ui(ns, registry)
      ),
      htmltools::tags$main(class = "sc-canvas-column",
        if (isTRUE(toolbar)) htmltools::tags$div(class = "sc-toolbar",
          shiny::actionButton(ns("run_selected"), "Run selected"),
          shiny::actionButton(ns("run_dependencies"), "Run + dependencies"),
          shiny::actionButton(ns("run_all"), "Run workflow", class = "btn-primary"),
          shiny::actionButton(ns("cancel_node"), "Cancel node"),
          shiny::actionButton(ns("cancel_branch"), "Cancel branch"),
          shiny::actionButton(ns("cancel_workflow"), "Cancel workflow"),
          shiny::actionButton(ns("force_run"), "Force rerun"),
          shiny::actionButton(ns("clear_cache"), "Clear cache"),
          shiny::actionButton(ns("reset_failed"), "Reset failed"),
          shiny::actionButton(ns("inspect_plan"), "Inspect plan"),
          htmltools::tags$button(type = "button", class = "sc-widget-command",
            `data-command` = "fitView", `data-target` = ns("canvas"), "Fit view")
        ),
        if (isTRUE(toolbar)) shiny::uiOutput(ns("runtime_summary")),
        capability_canvas_output(ns("canvas"), height = height),
        if (isTRUE(toolbar)) shiny::uiOutput(ns("plan"))
      ),
      htmltools::tags$aside(class = "sc-inspector",
        htmltools::tags$button(
          type = "button",
          class = "sc-inspector-resizer",
          `data-resize` = "inspector",
          title = "Resize configuration inspector; double-click to reset",
          `aria-label` = "Resize configuration inspector",
          `aria-orientation` = "vertical"
        ),
        htmltools::tags$div(class = "sc-pane-heading",
          htmltools::tags$span("Configuration"),
          htmltools::tags$small("Shiny-owned inspector")
        ),
        shiny::uiOutput(ns("inspector"))
      )
    ),
    htmltools::tags$script(htmltools::HTML(sprintf(
      "(function(){const root=document.getElementById('%s')?.closest('.sc-workbench');if(!root)return;const search=root.querySelector('.sc-palette-search');const key='shinycapabilities.paletteDensity';const setDensity=function(value){root.dataset.paletteDensity=value;sessionStorage.setItem(key,value);root.querySelectorAll('[data-palette-density]').forEach(function(b){b.setAttribute('aria-pressed',String(b.dataset.paletteDensity===value));});};setDensity(sessionStorage.getItem(key)||'compact');const insert=function(item){const canvas=document.getElementById(item.dataset.canvasId);if(!canvas)return;const rect=canvas.getBoundingClientRect();canvas.dispatchEvent(new CustomEvent('shinycapabilities:insert',{bubbles:true,detail:{capabilityId:item.dataset.capabilityId,x:rect.width/2,y:rect.height/2}}));};search?.addEventListener('input',function(){const term=this.value.trim().toLowerCase();root.querySelectorAll('.sc-palette-item').forEach(function(item){item.hidden=term&&!item.dataset.search.includes(term);});root.querySelectorAll('.sc-palette-category').forEach(function(group){const match=!!group.querySelector('.sc-palette-item:not([hidden])');group.hidden=!match;if(term&&match)group.open=true;});});root.addEventListener('click',function(e){const density=e.target.closest('[data-palette-density]');if(density)setDensity(density.dataset.paletteDensity);});root.addEventListener('keydown',function(e){const item=e.target.closest('.sc-palette-item');if(item&&e.key==='Enter'){e.preventDefault();insert(item);}});})();",
      ns("palette_search")
    )))
  )
}

#' Capability workflow module server
#' @param id Module identifier.
#' @param registry Capability registry.
#' @param initial_graph Initial workflow graph.
#' @param context Host execution context.
#' @export
capability_canvas_server <- function(id, registry, initial_graph = list(nodes = list(), edges = list()),
                                     context = list()) {
  shiny::moduleServer(id, function(input, output, session) {
    graph <- shiny::reactiveVal(normalize_workflow_graph(initial_graph))
    cache <- shiny::reactiveVal(list())
    selected_id <- shiny::reactiveVal(NULL)
    last_plan <- shiny::reactiveVal(NULL)
    active_runtime <- shiny::reactiveVal(NULL)
    runtime_snapshot <- shiny::reactiveVal(NULL)

    output$canvas <- render_capability_canvas({
      capability_canvas(registry, graph(), element_id = session$ns("canvas"))
    })

    shiny::observeEvent(input$canvas_event, {
      event <- input$canvas_event
      if (event$type %in% c(
        "capability_dropped", "move_completed", "resize_completed",
        "connection_accepted", "node_removed", "node_duplicated", "group_created"
      )) graph(normalize_workflow_graph(event$graph))
      if (identical(event$type, "node_selected")) selected_id(event$nodeId)
      if (identical(event$type, "connection_proposed")) {
        result <- validate_connection(registry, graph(), event$edge)
        session$sendCustomMessage("shinycapabilities:connection-result", list(
          id = session$ns("canvas"), edge = event$edge, result = result
        ))
      }
    }, ignoreInit = TRUE)

    selected_node <- shiny::reactive({
      id <- selected_id()
      if (is.null(id)) return(NULL)
      Filter(function(node) identical(node$id, id), graph()$nodes)[[1]] %||% NULL
    })

    output$inspector <- shiny::renderUI({
      node <- selected_node()
      if (is.null(node)) return(htmltools::tags$div(class = "sc-empty",
        htmltools::tags$strong("Select a capability"),
        htmltools::tags$p("Configuration, validation, dependencies, status, history, and outputs appear here.")
      ))
      if (isTRUE(node$metadata$composite)) {
        return(htmltools::tagList(
          htmltools::tags$h2(node$metadata$display_name %||% "Workflow composite"),
          htmltools::tags$p("Collapsed presentation of an executable internal workflow."),
          htmltools::tags$dl(class = "sc-node-facts",
            htmltools::tags$dt("State"), htmltools::tags$dd(node$state),
            htmltools::tags$dt("Internal nodes"),
            htmltools::tags$dd(length(node$metadata$internal_graph$nodes %||% list()))
          )
        ))
      }
      capability <- capability_registry_get(registry, node$capability_id)
      custom <- if (is.function(capability$custom_ui)) capability$custom_ui(session$ns, node) else NULL
      execution_error <- cache()[[node$id]]$error %||% NULL
      execution_error_message <- if (is.list(execution_error)) {
        execution_error$message %||% paste(unlist(execution_error), collapse = " ")
      } else {
        paste(execution_error %||% "Unknown failure", collapse = " ")
      }
      htmltools::tagList(
        htmltools::tags$h2(capability$display_name),
        htmltools::tags$p(capability$description),
        htmltools::tags$dl(class = "sc-node-facts",
          htmltools::tags$dt("State"), htmltools::tags$dd(node$state),
          htmltools::tags$dt("Profile"), htmltools::tags$dd(capability$execution_profile),
          htmltools::tags$dt("Progress"), htmltools::tags$dd(
            runtime_snapshot()$lifecycle[[node$id]]$progress_message %||% "Not running"
          ),
          htmltools::tags$dt("Elapsed"), htmltools::tags$dd(sprintf(
            "%.1fs", runtime_snapshot()$lifecycle[[node$id]]$elapsed_seconds %||% 0
          )),
          htmltools::tags$dt("Started"), htmltools::tags$dd(
            runtime_snapshot()$lifecycle[[node$id]]$started_at %||% "Not started"
          ),
          htmltools::tags$dt("Upstream"), htmltools::tags$dd(paste(
            runtime_snapshot()$lifecycle[[node$id]]$upstream %||% character(),
            collapse = ", "
          ) %||% "None"),
          htmltools::tags$dt("Reuse"), htmltools::tags$dd(
            runtime_snapshot()$lifecycle[[node$id]]$cache_status %||% "not_current"
          ),
          htmltools::tags$dt("Version"), htmltools::tags$dd(capability$version),
          htmltools::tags$dt("Cache"), htmltools::tags$dd(capability$cache_policy),
          htmltools::tags$dt("Cancellation"), htmltools::tags$dd(if (capability$cancellation) "Supported" else "Not supported")
        ),
        lapply(names(capability$config), function(name) {
          config_control(session$ns, name, capability$config[[name]], node$config[[name]])
        }),
        custom,
        shiny::actionButton(session$ns("save_config"), "Apply configuration", class = "btn-primary"),
        htmltools::tags$hr(),
        if (identical(cache()[[node$id]]$status %||% NULL, "failed")) {
          htmltools::tags$div(
            class = "sc-node-error",
            htmltools::tags$strong("Execution failed"),
            htmltools::tags$p(execution_error_message)
          )
        },
        htmltools::tags$h3("Produced outputs"),
        htmltools::tags$pre(stable_json(cache()[[node$id]]$summary %||% list()))
      )
    })

    shiny::observeEvent(input$save_config, {
      node <- selected_node()
      if (is.null(node)) return()
      capability <- capability_registry_get(registry, node$capability_id)
      config <- setNames(lapply(names(capability$config), function(name) {
        input[[paste0("config__", name)]]
      }), names(capability$config))
      next_graph <- graph()
      next_graph$nodes <- lapply(next_graph$nodes, function(candidate) {
        if (!identical(candidate$id, node$id)) return(candidate)
        candidate$config <- config
        candidate$state <- "ready"
        candidate
      })
      graph(normalize_workflow_graph(next_graph))
      session$sendCustomMessage("shinycapabilities:set-graph",
        list(id = session$ns("canvas"), graph = graph()))
    })

    create_plan <- function(target = NULL, force = FALSE) {
      plan_workflow(registry, graph(), target = target, cache = cache(), force = force)
    }
    publish_runtime <- function(snapshot) {
      runtime_snapshot(snapshot)
      cache(snapshot$results)
      states <- setNames(lapply(snapshot$lifecycle, `[[`, "state"), names(snapshot$lifecycle))
      next_graph <- graph()
      next_graph$nodes <- lapply(next_graph$nodes, function(node) {
        if (isTRUE(node$metadata$composite)) {
          internal <- node$metadata$internal_graph$nodes %||% list()
          internal_states <- vapply(internal, function(candidate) {
            states[[candidate$id]] %||% candidate$state
          }, character(1))
          node$state <- if (any(internal_states %in% c("running", "queued", "cancelling"))) {
            "running"
          } else if (any(internal_states %in% c("failed", "cancelled", "blocked"))) {
            "blocked"
          } else if (length(internal_states) && all(internal_states %in% c("succeeded", "reused"))) {
            "succeeded"
          } else {
            node$state
          }
          return(node)
        }
        node$state <- states[[node$id]] %||% node$state
        node
      })
      graph(normalize_workflow_graph(next_graph))
      session$sendCustomMessage("shinycapabilities:set-graph",
        list(id = session$ns("canvas"), graph = graph()))
    }
    poll_runtime <- function() {
      runtime <- active_runtime()
      if (is.null(runtime)) return()
      tick_workflow_runtime(runtime)
      snapshot <- workflow_runtime_snapshot(runtime)
      publish_runtime(snapshot)
      if (isTRUE(snapshot$complete)) {
        cleanup_workflow_runtime(runtime)
        active_runtime(NULL)
        shiny::showNotification(
          if (isTRUE(snapshot$cancelled)) "Workflow cancelled." else "Workflow execution completed.",
          type = if (any(vapply(snapshot$lifecycle, function(item) {
            item$state %in% c("failed", "blocked")
          }, logical(1)))) "warning" else "message"
        )
      } else {
        shiny::invalidateLater(150, session)
      }
    }
    shiny::observe(poll_runtime())
    run_plan <- function(plan) {
      last_plan(plan)
      if (!isTRUE(plan$valid)) return()
      if (!is.null(active_runtime())) return()
      execution_context <- if (is.function(context)) context() else context
      runtime <- workflow_runtime(
        registry, graph(), plan, context = execution_context, cache = cache()
      )
      active_runtime(runtime)
      tick_workflow_runtime(runtime)
      publish_runtime(workflow_runtime_snapshot(runtime))
    }

    shiny::observeEvent(input$run_selected, {
      if (!is.null(selected_id())) run_plan(create_plan(selected_id()))
    })
    shiny::observeEvent(input$run_dependencies, {
      if (!is.null(selected_id())) run_plan(create_plan(selected_id()))
    })
    shiny::observeEvent(input$run_all, run_plan(create_plan()))
    shiny::observeEvent(input$force_run, run_plan(create_plan(selected_id(), force = TRUE)))
    shiny::observeEvent(input$clear_cache, {
      if (is.null(active_runtime())) cache(list())
    })
    shiny::observeEvent(input$reset_failed, {
      next_graph <- graph()
      next_graph$nodes <- lapply(next_graph$nodes, function(node) {
        if (node$state %in% c("failed", "blocked", "cancelled")) node$state <- "ready"
        node
      })
      graph(normalize_workflow_graph(next_graph))
      session$sendCustomMessage("shinycapabilities:set-graph",
        list(id = session$ns("canvas"), graph = graph()))
    })
    shiny::observeEvent(input$cancel_node, {
      runtime <- active_runtime()
      if (!is.null(runtime) && !is.null(selected_id())) {
        cancel_workflow_node(runtime, selected_id())
        publish_runtime(workflow_runtime_snapshot(runtime))
      }
    })
    shiny::observeEvent(input$cancel_branch, {
      runtime <- active_runtime()
      if (!is.null(runtime) && !is.null(selected_id())) {
        node <- selected_node()
        if (isTRUE(node$metadata$composite)) {
          internal_ids <- vapply(
            node$metadata$internal_graph$nodes %||% list(), `[[`, character(1), "id"
          )
          for (internal_id in internal_ids) {
            cancel_workflow_branch(runtime, internal_id)
          }
        } else {
          cancel_workflow_branch(runtime, selected_id())
        }
        publish_runtime(workflow_runtime_snapshot(runtime))
      }
    })
    shiny::observeEvent(input$cancel_workflow, {
      runtime <- active_runtime()
      if (!is.null(runtime)) {
        cancel_workflow_runtime(runtime)
        publish_runtime(workflow_runtime_snapshot(runtime))
      }
    })
    session$onSessionEnded(function() {
      runtime <- active_runtime()
      if (!is.null(runtime)) cleanup_workflow_runtime(runtime)
    })
    shiny::observeEvent(input$inspect_plan, last_plan(create_plan(selected_id())))

    custom_servers_started <- new.env(parent = emptyenv())
    shiny::observeEvent(selected_id(), {
      node <- selected_node()
      if (is.null(node) || exists(node$id, envir = custom_servers_started, inherits = FALSE)) return()
      capability <- capability_registry_get(registry, node$capability_id)
      if (is.function(capability$custom_server)) {
        capability$custom_server(session$ns, node, context)
        assign(node$id, TRUE, envir = custom_servers_started)
      }
    }, ignoreInit = TRUE)

    output$plan <- shiny::renderUI({
      plan <- last_plan()
      if (is.null(plan)) return(NULL)
      htmltools::tags$details(class = "sc-plan", open = "open",
        htmltools::tags$summary("Execution plan"),
        htmltools::tags$ol(lapply(plan$steps, function(step) {
          htmltools::tags$li(
            htmltools::tags$strong(step$node_id),
            sprintf(" - %s (%s)", step$action, step$reason)
          )
        }))
      )
    })

    output$runtime_summary <- shiny::renderUI({
      snapshot <- runtime_snapshot()
      if (is.null(snapshot)) return(NULL)
      htmltools::tags$div(
        class = "sc-runtime-summary",
        role = "status",
        `aria-live` = "polite",
        htmltools::tags$strong(sprintf(
          "Workflow %d%%", round(100 * snapshot$progress)
        )),
        htmltools::tags$span(sprintf(
          "%d active job%s - %d of %d complete",
          snapshot$active_jobs,
          if (snapshot$active_jobs == 1L) "" else "s",
          snapshot$completed_nodes, snapshot$total_nodes
        ))
      )
    })

    set_graph <- function(value) {
      runtime <- active_runtime()
      if (!is.null(runtime)) {
        cancel_workflow_runtime(runtime)
        cleanup_workflow_runtime(runtime)
        active_runtime(NULL)
      }
      runtime_snapshot(NULL)
      graph(normalize_workflow_graph(value))
      session$sendCustomMessage("shinycapabilities:set-graph",
        list(id = session$ns("canvas"), graph = graph()))
      invisible(graph())
    }
    list(graph = shiny::reactive(graph()), cache = shiny::reactive(cache()),
         selection = shiny::reactive(selected_id()), plan = shiny::reactive(last_plan()),
         runtime = shiny::reactive(runtime_snapshot()),
         is_running = shiny::reactive(!is.null(active_runtime())),
         run_plan = run_plan,
         cancel_workflow = function() {
           runtime <- active_runtime()
           if (!is.null(runtime)) cancel_workflow_runtime(runtime)
         },
         set_graph = set_graph, set_cache = function(value) cache(value))
  })
}
