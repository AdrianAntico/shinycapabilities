capability_presentation <- function(capability) {
  supplied <- isTRUE(attr(capability$presentation, "host_supplied"))
  metadata <- capability$presentation %||% normalize_capability_presentation()
  group_label <- if (supplied) metadata$group_label else capability$category %||% "Other"
  icon <- normalize_shinycapabilities_icon(if (supplied) metadata$icon_id else capability$icon)
  list(
    icon = icon,
    icon_id = icon,
    label = capability$display_name,
    category = group_label,
    group_id = if (supplied) metadata$group_id else "other",
    group_order = metadata$group_order,
    display_order = metadata$display_order,
    accent = if (supplied) metadata$emphasis else "default",
    description = capability$description,
    short_summary = metadata$short_summary %||% capability$description,
    compact_summary = metadata$compact_summary %||% capability$display_name,
    accessibility_label = metadata$accessibility_label %||%
      paste(capability$display_name, "capability"),
    input_port_labels = metadata$input_port_labels,
    output_port_labels = metadata$output_port_labels,
    search = tolower(paste(
      capability$id, capability$display_name, capability$description, group_label
    ))
  )
}

#' Validate visible capability identities in a palette
#'
#' Capability ids remain the execution identity. This validator separately ensures
#' that users are not shown two indistinguishable labels in the same visible
#' category.
#' @param registry A capability registry.
#' @return A list with `valid` and deterministic `findings` entries.
#' @export
validate_capability_palette <- function(registry) {
  capabilities <- capability_registry_list(registry)
  presentations <- lapply(capabilities, capability_presentation)
  normalize_identity <- function(value) {
    tolower(gsub("[[:space:]]+", " ", trimws(enc2utf8(value))))
  }
  keys <- vapply(seq_along(capabilities), function(index) {
    paste(
      normalize_identity(presentations[[index]]$category),
      normalize_identity(presentations[[index]]$label),
      sep = "\r"
    )
  }, character(1))
  duplicated_keys <- sort(unique(keys[duplicated(keys)]))
  findings <- lapply(duplicated_keys, function(key) {
    indexes <- which(keys == key)
    list(
      code = "ambiguous_palette_identity",
      severity = "error",
      category = presentations[[indexes[[1]]]]$category,
      label = presentations[[indexes[[1]]]]$label,
      capability_ids = sort(vapply(capabilities[indexes], `[[`, character(1), "id")),
      message = paste0(
        "Palette category '", presentations[[indexes[[1]]]]$category,
        "' contains multiple capabilities labeled '",
        presentations[[indexes[[1]]]]$label, "'."
      )
    )
  })
  list(valid = !length(findings), findings = findings)
}

palette_ui <- function(namespace, registry) {
  validation <- validate_capability_palette(registry)
  if (!validation$valid) {
    stop(validation$findings[[1]]$message, call. = FALSE)
  }
  capabilities <- capability_registry_list(registry)
  capabilities <- capabilities[!duplicated(vapply(capabilities, `[[`, character(1), "id"))]
  presentations <- lapply(capabilities, capability_presentation)
  categories <- split(seq_along(capabilities),
    vapply(presentations, `[[`, character(1), "category"))
  categories <- lapply(categories, function(indexes) indexes[order(
    vapply(presentations[indexes], `[[`, numeric(1), "display_order"),
    vapply(presentations[indexes], `[[`, character(1), "label")
  )])
  lifecycle_order <- c("Inputs", "Data Preparation", "Exploration")
  category_names <- names(categories)
  category_names <- c(
    intersect(lifecycle_order, category_names),
    sort(setdiff(category_names, lifecycle_order))
  )
  shiny::tagList(lapply(category_names, function(category) {
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
            `data-shinycap-part` = "capability",
            `data-shinycap-group` = item$group_id,
            `data-shinycap-emphasis` = item$accent,
            title = item$description,
            `aria-label` = paste("Insert", item$accessibility_label),
            shinycapabilities_icon_tag(item$icon_id, "sc-palette-icon"),
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
    resource = shiny::selectInput(id, definition$label, definition$choices %||% character(),
      selected = value),
    property = shiny::selectInput(id, definition$label, definition$choices %||% character(),
      selected = value),
    expression = shiny::textAreaInput(id, definition$label, value = value %||% "", rows = 3),
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
#' @param palette_density_controls Display the public palette density controls.
#' @export
capability_canvas_ui <- function(id, registry, height = "680px", toolbar = TRUE,
                                 palette_density_controls = TRUE) {
  ns <- shiny::NS(id)
  htmltools::tagList(
    htmltools::tags$script(htmltools::HTML(
      "document.addEventListener('dragstart',function(e){if(!e.target||typeof e.target.closest!=='function')return;const p=e.target.closest('[data-shinycap-part=\"capability\"],.sc-palette-item');if(!p)return;e.dataTransfer.setData('application/vnd.shinycapabilities.capability+json;version=1',JSON.stringify({bridgeVersion:'1.0.0',capabilityId:p.dataset.capabilityId}));e.dataTransfer.setData('application/x-shinycapability',p.dataset.capabilityId);e.dataTransfer.effectAllowed='copy';});"
    )),
    htmltools::tags$div(
      class = "sc-workbench",
      `data-shinycap-part` = "workbench",
      `data-shinycap-density` = if (isTRUE(palette_density_controls)) "compact" else "comfortable",
      htmltools::tags$aside(class = "sc-palette", `data-shinycap-part` = "palette",
        `data-shinycap-panel` = "palette",
        htmltools::tags$div(class = "sc-pane-heading",
          htmltools::tags$span("Capabilities"),
          if (isTRUE(palette_density_controls)) htmltools::tags$div(class = "sc-palette-density", role = "group",
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
      htmltools::tags$main(class = "sc-canvas-column", `data-shinycap-part` = "canvas-column",
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
            `data-command` = "fitView", `data-target` = ns("canvas"),
            `data-shinycap-command` = "fit-view", "Fit view")
        ),
        if (isTRUE(toolbar)) shiny::uiOutput(ns("runtime_summary")),
        capability_canvas_output(ns("canvas"), height = height),
        if (isTRUE(toolbar)) shiny::uiOutput(ns("plan"))
      ),
      htmltools::tags$aside(class = "sc-inspector", `data-shinycap-part` = "inspector",
        `data-shinycap-panel` = "inspector",
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
      "(function(){const root=document.getElementById('%s')?.closest('[data-shinycap-part=\"workbench\"],.sc-workbench');if(!root)return;const search=root.querySelector('.sc-palette-search');const enabled=%s;const key='shinycapabilities.paletteDensity';const setDensity=function(value){root.dataset.paletteDensity=value;root.dataset.shinycapDensity=value;if(enabled)sessionStorage.setItem(key,value);root.querySelectorAll('[data-palette-density]').forEach(function(b){b.setAttribute('aria-pressed',String(b.dataset.paletteDensity===value));});};setDensity(enabled?(sessionStorage.getItem(key)||'compact'):'comfortable');const insert=function(item){const canvas=document.getElementById(item.dataset.canvasId);if(!canvas)return;const rect=canvas.getBoundingClientRect();canvas.dispatchEvent(new CustomEvent('shinycapabilities:v1:insert',{bubbles:true,detail:{bridgeVersion:'1.0.0',capabilityId:item.dataset.capabilityId,x:rect.width/2,y:rect.height/2}}));};search?.addEventListener('input',function(){const term=this.value.trim().toLowerCase();root.querySelectorAll('.sc-palette-item').forEach(function(item){item.hidden=term&&!item.dataset.search.includes(term);});root.querySelectorAll('.sc-palette-category').forEach(function(group){const match=!!group.querySelector('.sc-palette-item:not([hidden])');group.hidden=!match;if(term&&match)group.open=true;});});root.addEventListener('click',function(e){if(!e.target||typeof e.target.closest!=='function')return;const density=e.target.closest('[data-palette-density]');if(density)setDensity(density.dataset.paletteDensity);});root.addEventListener('keydown',function(e){if(!e.target||typeof e.target.closest!=='function')return;const item=e.target.closest('.sc-palette-item');if(item&&e.key==='Enter'){e.preventDefault();insert(item);}});})();",
      ns("palette_search"), if (isTRUE(palette_density_controls)) "true" else "false"
    )))
  )
}

#' Capability workflow module server
#' @param id Module identifier.
#' @param registry Capability registry.
#' @param initial_graph Initial workflow graph.
#' @param context Host execution context.
#' @param bind_internal_controls Bind the legacy module input IDs to runtime commands.
#' @param config_control_renderer Optional host renderer for a configuration field.
#' @export
capability_canvas_server <- function(id, registry, initial_graph = list(nodes = list(), edges = list()),
                                     context = list(), bind_internal_controls = TRUE,
                                     config_control_renderer = NULL) {
  shiny::moduleServer(id, function(input, output, session) {
    graph <- shiny::reactiveVal(normalize_workflow_graph(initial_graph))
    cache <- shiny::reactiveVal(list())
    selected_id <- shiny::reactiveVal(NULL)
    last_plan <- shiny::reactiveVal(NULL)
    active_runtime <- shiny::reactiveVal(NULL)
    runtime_snapshot <- shiny::reactiveVal(NULL)
    config_drafts <- shiny::reactiveVal(list())
    inspector_revision <- shiny::reactiveVal(0L)
    graph_revision <- shiny::reactiveVal(0L)

    publish_graph <- function(ack_mutation_id = NULL, reason = "server_publication") {
      graph_revision(shiny::isolate(graph_revision()) + 1L)
      payload <- list(
        bridgeVersion = "1.0.0", id = session$ns("canvas"), graph = shiny::isolate(graph()),
        graphRevision = shiny::isolate(graph_revision()), ackMutationId = ack_mutation_id,
        reason = reason
      )
      session$sendCustomMessage("shinycapabilities:set-graph", payload)
      session$sendCustomMessage("shinycapabilities:v1:set-graph", payload)
      invisible(payload)
    }

    output$canvas <- render_capability_canvas({
      capability_canvas(registry, graph(), graph_revision = graph_revision())
    })

    shiny::observeEvent(input$canvas_event, {
      event <- input$canvas_event
      if (event$type %in% c(
        "capability_dropped", "move_completed", "resize_completed",
        "connection_accepted", "connection_removed", "node_removed", "node_duplicated", "group_created"
      )) {
        graph(normalize_workflow_graph(event$graph))
        publish_graph(event$mutationId %||% NULL, paste0("client_", event$type))
      }
      if (identical(event$type, "node_selected")) {
        selected_id(event$nodeId)
        session$onFlushed(function() session$sendCustomMessage(
          "shinycapabilities:v1:selection-ack",
          list(bridgeVersion = "1.0.0", id = session$ns("canvas"), nodeId = event$nodeId,
            capabilityId = selected_node()$capability_id %||% NULL,
            graphRevision = shiny::isolate(graph_revision()), mutationId = event$mutationId %||% NULL)
        ), once = TRUE)
      }
      if (identical(event$type, "connection_proposed")) {
        result <- validate_connection(registry, graph(), event$edge)
        session$sendCustomMessage("shinycapabilities:v1:connection-result", list(
          bridgeVersion = "1.0.0", id = session$ns("canvas"),
          edge = event$edge, result = result
        ))
      }
    }, ignoreInit = TRUE)

    selected_node <- shiny::reactive({
      id <- selected_id()
      if (is.null(id)) return(NULL)
      matches <- Filter(function(node) identical(node$id, id), graph()$nodes)
      if (length(matches) == 0L) return(NULL)
      matches[[1L]]
    })

    shiny::observe({
      node <- selected_node()
      if (is.null(node)) return()
      capability <- capability_registry_get(registry, node$capability_id)
      values <- setNames(lapply(names(capability$config), function(name) {
        input[[paste0("config__", name)]]
      }), names(capability$config))
      present <- !vapply(values, is.null, logical(1))
      if (!any(present)) return()
      shiny::isolate({
        drafts <- config_drafts()
        node_draft <- drafts[[node$id]] %||% list()
        node_draft[names(values)[present]] <- values[present]
        drafts[[node$id]] <- node_draft
        config_drafts(drafts)
      })
    })

    output$inspector <- shiny::renderUI({
      inspector_revision()
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
      draft <- shiny::isolate(config_drafts())[[node$id]] %||% list()
      custom <- if (is.function(capability$custom_ui)) capability$custom_ui(session$ns, node) else NULL
      execution_error <- cache()[[node$id]]$error %||% NULL
      execution_error_message <- if (is.list(execution_error)) {
        execution_error$message %||% paste(unlist(execution_error), collapse = " ")
      } else {
        paste(execution_error %||% "Unknown failure", collapse = " ")
      }
      htmltools::tags$div(`data-shinycap-node-id` = node$id,
        `data-shinycap-capability-id` = node$capability_id,
        `data-shinycap-graph-revision` = graph_revision(),
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
          definition <- capability$config[[name]]
          value <- draft[[name]] %||% node$config[[name]]
          control <- if (is.function(config_control_renderer)) {
            config_control_renderer(session$ns, name, definition, value, node, capability)
          } else NULL
          if (is.null(control)) control <- config_control(session$ns, name, definition, value)
          htmltools::tags$div(`data-shinycap-config-name` = name, control)
        }),
        custom,
        htmltools::tags$div(class = "sc-config-actions",
          shiny::actionButton(session$ns("save_config"), "Apply configuration", class = "btn-primary"),
          shiny::actionButton(session$ns("discard_config"), "Discard changes")),
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
      draft <- config_drafts()[[node$id]] %||% list()
      config <- setNames(lapply(names(capability$config), function(name) {
        draft[[name]] %||% input[[paste0("config__", name)]] %||% node$config[[name]]
      }), names(capability$config))
      next_graph <- graph()
      next_graph$nodes <- lapply(next_graph$nodes, function(candidate) {
        if (!identical(candidate$id, node$id)) return(candidate)
        candidate$config <- config
        candidate$state <- "ready"
        candidate
      })
      graph(normalize_workflow_graph(next_graph))
      drafts <- config_drafts()
      drafts[[node$id]] <- NULL
      config_drafts(drafts)
      inspector_revision(inspector_revision() + 1L)
      publish_graph(reason = "configuration_applied")
    })

    shiny::observeEvent(input$discard_config, {
      node <- selected_node()
      if (is.null(node)) return()
      drafts <- config_drafts()
      drafts[[node$id]] <- NULL
      config_drafts(drafts)
      inspector_revision(inspector_revision() + 1L)
    }, ignoreInit = TRUE)

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
      publish_graph(reason = "runtime_publication")
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

    command_run_selected <- function() {
      if (!is.null(selected_id())) run_plan(create_plan(selected_id()))
    }
    command_run_dependencies <- command_run_selected
    command_run_all <- function() run_plan(create_plan())
    command_force_run <- function() run_plan(create_plan(selected_id(), force = TRUE))
    command_clear_cache <- function() {
      if (is.null(active_runtime())) cache(list())
    }
    command_reset_failed <- function() {
      next_graph <- graph()
      next_graph$nodes <- lapply(next_graph$nodes, function(node) {
        if (node$state %in% c("failed", "blocked", "cancelled")) node$state <- "ready"
        node
      })
      graph(normalize_workflow_graph(next_graph))
      publish_graph(reason = "failed_state_reset")
    }
    command_cancel_node <- function() {
      runtime <- active_runtime()
      if (!is.null(runtime) && !is.null(selected_id())) {
        cancel_workflow_node(runtime, selected_id())
        publish_runtime(workflow_runtime_snapshot(runtime))
      }
    }
    command_cancel_branch <- function() {
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
    }
    command_cancel_workflow <- function() {
      runtime <- active_runtime()
      if (!is.null(runtime)) {
        cancel_workflow_runtime(runtime)
        publish_runtime(workflow_runtime_snapshot(runtime))
      }
    }
    command_inspect_plan <- function() last_plan(create_plan(selected_id()))
    command_fit_view <- function() {
      payload <- list(
        bridgeVersion = "1.0.0", id = session$ns("canvas"),
        command = "fit-view"
      )
      session$sendCustomMessage("shinycapabilities:v1:command", payload)
    }
    if (isTRUE(bind_internal_controls)) {
      shiny::observeEvent(input$run_selected, command_run_selected())
      shiny::observeEvent(input$run_dependencies, command_run_dependencies())
      shiny::observeEvent(input$run_all, command_run_all())
      shiny::observeEvent(input$force_run, command_force_run())
      shiny::observeEvent(input$clear_cache, command_clear_cache())
      shiny::observeEvent(input$reset_failed, command_reset_failed())
      shiny::observeEvent(input$cancel_node, command_cancel_node())
      shiny::observeEvent(input$cancel_branch, command_cancel_branch())
      shiny::observeEvent(input$cancel_workflow, command_cancel_workflow())
      shiny::observeEvent(input$inspect_plan, command_inspect_plan())
    }
    session$onSessionEnded(function() {
      runtime <- shiny::isolate(active_runtime())
      if (!is.null(runtime)) cleanup_workflow_runtime(runtime)
    })

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
      normalized <- normalize_workflow_graph(value)
      selected <- selected_id()
      node_ids <- vapply(normalized$nodes, `[[`, character(1), "id")
      if (!is.null(selected) && !selected %in% node_ids) selected_id(NULL)
      graph(normalized)
      publish_graph(reason = "graph_replaced")
      invisible(graph())
    }
    set_config_drafts <- function(value) {
      config_drafts(value %||% list())
      inspector_revision(inspector_revision() + 1L)
      invisible(config_drafts())
    }
    controls <- list(
      contract_version = "1.0.0",
      run_selected = command_run_selected,
      run_with_dependencies = command_run_dependencies,
      run_workflow = command_run_all,
      cancel_node = command_cancel_node,
      cancel_branch = command_cancel_branch,
      cancel_workflow = command_cancel_workflow,
      force_run = command_force_run,
      clear_cache = command_clear_cache,
      reset_failed = command_reset_failed,
      inspect_plan = command_inspect_plan,
      fit_view = command_fit_view,
      replace_graph = set_graph,
      replace_cache = function(value) cache(value),
      selection = shiny::reactive(selected_id()),
      runtime = shiny::reactive(runtime_snapshot())
    )
    list(graph = shiny::reactive(graph()), cache = shiny::reactive(cache()),
         selection = shiny::reactive(selected_id()), plan = shiny::reactive(last_plan()),
         runtime = shiny::reactive(runtime_snapshot()),
         is_running = shiny::reactive(!is.null(active_runtime())),
         run_plan = run_plan,
         cancel_workflow = function() {
           runtime <- active_runtime()
           if (!is.null(runtime)) cancel_workflow_runtime(runtime)
         },
         set_graph = set_graph, set_cache = function(value) cache(value),
         config_drafts = shiny::reactive(config_drafts()),
         set_config_drafts = set_config_drafts,
         graph_revision = shiny::reactive(graph_revision()),
         controls = controls, contract_version = "1.0.0")
  })
}
