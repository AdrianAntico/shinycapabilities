library(shiny)
library(shinycapabilities)

scenario_data <- function(name) {
  scenarios <- list(
    lineage = list(
      nodes = list(
        list(id="raw",label="Raw transactions",type="dataset",status="ready",metadata=list(owner="Data platform")),
        list(id="clean",label="Qualified transactions",type="dataset",status="ready"),
        list(id="features",label="Model features",type="feature_set",status="ready"),
        list(id="report",label="Revenue report",type="report",status="published")),
      edges = list(
        list(id="l1",source="raw",target="clean",type="QUALIFIES"),
        list(id="l2",source="clean",target="features",type="DERIVED_FROM"),
        list(id="l3",source="features",target="report",type="PRODUCED_BY"))),
    evidence = list(
      nodes = list(
        list(id="claim",label="Retention improved",type="claim",status="review"),
        list(id="metric",label="Cohort metric",type="evidence",status="qualified"),
        list(id="survey",label="Customer survey",type="evidence",status="qualified"),
        list(id="risk",label="Seasonality risk",type="caveat",status="open")),
      edges = list(
        list(id="e1",source="metric",target="claim",type="SUPPORTS"),
        list(id="e2",source="survey",target="claim",type="SUPPORTS"),
        list(id="e3",source="risk",target="claim",type="CHALLENGES"))),
    agents = list(
      nodes = list(
        list(id="investigate",label="Investigate change",type="job",status="running"),
        list(id="compare",label="Compare methods",type="task",status="waiting"),
        list(id="review",label="Human review",type="review",status="queued")),
      edges = list(
        list(id="a1",source="investigate",target="compare",type="DEPENDS_ON"),
        list(id="a2",source="compare",target="review",type="REQUIRES_REVIEW"))),
    model = list(
      nodes = list(
        list(id="train",label="Training data",type="dataset",status="ready"),
        list(id="model",label="CatBoost model",type="model",status="qualified"),
        list(id="scores",label="Scored population",type="dataset",status="ready"),
        list(id="assessment",label="Assessment artifacts",type="artifact_set",status="ready"),
        list(id="shap",label="Contribution artifacts",type="artifact_set",status="ready")),
      edges = list(
        list(id="m1",source="train",target="model",type="TRAINED"),
        list(id="m2",source="model",target="scores",type="PRODUCED_BY"),
        list(id="m3",source="scores",target="assessment",type="ASSESSED_BY"),
        list(id="m4",source="scores",target="shap",type="EXPLAINED_BY")))
  )
  scenarios[[name]]
}

ui <- fluidPage(tags$head(tags$style(HTML("body{background:#eef2f6}.demo{max-width:1500px;margin:auto;padding:16px}.event{white-space:pre-wrap;font:12px ui-monospace,monospace;background:white;border:1px solid #ccd5e1;padding:8px}"))),
  div(class="demo",h2("Relationship Graph 1.0"),p("Host-neutral analytical relationships. Selection emits navigation intents only."),
    fluidRow(column(4,selectInput("scenario","Scenario",c("Dataset lineage"="lineage","Evidence relationships"="evidence","Agent/job dependencies"="agents","Model provenance"="model"))),
      column(8,actionButton("cycle","Add a valid cycle"),actionButton("fit","Fit view"),actionButton("stress","Load 1,000-node stress graph"))),
    split_pane("layout",graph=relationship_graph_output("graph",height="100%"),
      records=div(style="height:100%;display:grid;grid-template-rows:1fr auto",data_grid_output("records",height="100%"),div(class="event",verbatimTextOutput("event"))),
      sizes=c(70,30),min_sizes=c(40,20),height="720px")))

server <- function(input, output, session) {
  current <- reactiveVal(scenario_data("lineage")); latest <- reactiveVal("Select a graph node, edge, or grid row.")
  observeEvent(input$scenario,current(scenario_data(input$scenario)),ignoreInit=TRUE)
  observeEvent(input$cycle,{x<-current();x$edges<-c(x$edges,list(list(id="cycle",source=x$nodes[[length(x$nodes)]]$id,target=x$nodes[[1]]$id,type="RELATES_TO")));current(x)})
  observeEvent(input$stress,{
    nodes<-lapply(seq_len(1000L),function(i)list(id=sprintf("n%04d",i),label=paste("Analytical object",i),type=c("dataset","artifact","evidence")[(i%%3L)+1L],status="ready"))
    edges<-lapply(2:1000,function(i)list(id=sprintf("x%04d",i),source=sprintf("n%04d",max(1L,i%/%2L)),target=sprintf("n%04d",i),type="DERIVED_FROM"))
    current(list(nodes=nodes,edges=edges))
  })
  output$graph <- render_relationship_graph({x<-current();relationship_graph(x$nodes,x$edges,max_render_nodes=350L,height="100%")})
  output$records <- render_data_grid({
    x<-current();rows<-data.frame(id=vapply(x$nodes,`[[`,character(1),"id"),label=vapply(x$nodes,`[[`,character(1),"label"),type=vapply(x$nodes,`[[`,character(1),"type"),status=vapply(x$nodes,function(z)if(is.null(z$status))"" else z$status,character(1)),stringsAsFactors=FALSE)
    data_grid(rows,row_id="id",options=list(selection="single",density="compact"),height="100%")
  })
  observeEvent(input$fit,update_relationship_graph(session,"graph",fit_request=input$fit))
  observeEvent(input$graph_node_selection,{latest(jsonlite::toJSON(input$graph_node_selection,auto_unbox=TRUE,pretty=TRUE));update_data_grid(session,"records",selected_rows=input$graph_node_selection$id)})
  observeEvent(input$graph_edge_selection,latest(jsonlite::toJSON(input$graph_edge_selection,auto_unbox=TRUE,pretty=TRUE)))
  observeEvent(input$graph_neighborhood_request,latest(jsonlite::toJSON(input$graph_neighborhood_request,auto_unbox=TRUE,pretty=TRUE)))
  observeEvent(input$records_selection,{ids<-input$records_selection$selectedIds;id<-if(length(ids))ids[[1]] else NULL;if(!is.null(id))update_relationship_graph(session,"graph",selected_id=id);latest(jsonlite::toJSON(input$records_selection,auto_unbox=TRUE,pretty=TRUE))})
  output$event <- renderText(latest())
}

shinyApp(ui,server)
