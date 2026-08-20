library(shiny)
library(shinycapabilities)

now <- Sys.time()
actors <- data.frame(actor_id=c("ag-investigator","ag-methodologist","human-reviewer"),
  title=c("Investigator","Methodologist","Human Reviewer"),
  role_id=c("investigator","methodologist","reviewer"),
  actor_type=c("agent","reviewer","human"), status=c("running","waiting","awaiting_human"),
  raw_status=c("active","queued","awaiting_approval"),
  current_work_id=c("work-investigate","work-method","work-review"),
  last_activity_at=format(now-c(3,10,18),"%Y-%m-%dT%H:%M:%SZ",tz="UTC"))

make_work <- function(step=0L) list(
  list(work_id="work-investigate",label="Investigate revenue change",kind="job",status="running",raw_status="WORKING",actor_id="ag-investigator",parent_id="",dependency_ids=character(),attention="none",progress_label=paste("Evidence review step",step+1L),capability_id="analytics.investigate",started_at=format(now-120,"%Y-%m-%dT%H:%M:%SZ",tz="UTC"),updated_at=format(Sys.time(),"%Y-%m-%dT%H:%M:%SZ",tz="UTC"),output_ids=c("artifact:profile"),source_contract="workstation_job",authority_ref="mandate:demo@1",metadata=list(project="Demo")),
  list(work_id="work-method",label="Compare candidate methods",kind="step",status="waiting",raw_status="PLANNED",actor_id="ag-methodologist",parent_id="work-investigate",dependency_ids="work-investigate",attention="none",progress_label="Waiting for investigation",capability_id="analytical_method_election",source_contract="governed_execution"),
  list(work_id="work-review",label="Review high-impact recommendation",kind="review",status="awaiting_human",raw_status="WAITING_FOR_APPROVAL",actor_id="human-reviewer",parent_id="",dependency_ids="work-investigate",attention="needs_approval",progress_label="Decision required",source_contract="agent_session",authority_ref="approval:demo"),
  list(work_id="work-failed",label="Refresh remote evidence",kind="execution",status="failed",raw_status="UNKNOWN_REMOTE_STATE",actor_id="",parent_id="",dependency_ids=character(),attention="failure",error_summary="Remote state could not be reconciled.",retry_safe=FALSE,source_contract="execution_lease"))

make_events <- function(n=200L) lapply(seq_len(n), function(i) list(event_id=sprintf("event-%05d",i),
  occurred_at=format(now-n+i,"%Y-%m-%dT%H:%M:%SZ",tz="UTC"),
  event_type=c("work_started","capability_completed","artifact_produced","review_requested")[(i-1)%%4+1],
  summary=paste(c("Investigator started a bounded task","Capability completed","Artifact produced","Human review requested")[(i-1)%%4+1],i),
  work_id=c("work-investigate","work-method","work-investigate","work-review")[(i-1)%%4+1],
  actor_id=c("ag-investigator","ag-methodologist","ag-investigator","human-reviewer")[(i-1)%%4+1],
  severity=c("info","success","success","warning")[(i-1)%%4+1],output_ids=if(i%%4==3) paste0("artifact:",i) else character()))

tree_nodes <- data.frame(id=c("mandate","investigate","method","review"),
  parent_id=c("","mandate","investigate","mandate"),label=c("Mandate","Investigation","Method comparison","Human review"),
  description=c("Human-origin authority","Active work","Dependency blocked","Approval required"),status=c("ready","running","waiting","warning"))

ui <- fluidPage(tags$head(tags$style(HTML("body{background:#eef2f6}.demo{max-width:1450px;margin:auto;padding:16px}.card{height:100%;padding:10px;background:#fff}"))),
  div(class="demo",h2("Agent Activity Monitor 1.0"),p("A read-only projection. Updates do not execute or mutate work."),
    div(style="display:flex;gap:8px;margin-bottom:8px",actionButton("advance","Update activity"),actionButton("burst","Burst 1,000 events")),
    tabsetPanel(
      tabPanel("Standalone",agent_activity_monitor_output("monitor",height="680px")),
      tabPanel("Composed",split_pane("monitor_layout",
        monitor=div(class="card",agent_activity_monitor_output("monitor_composed",height="100%")),
        records=split_pane("record_layout",
          tree=div(class="card",h4("Governed relationships"),virtual_tree_browser_output("tree",height="100%")),
          ledger=div(class="card",h4("Bounded event ledger"),data_grid_output("ledger",height="100%")),
          direction="vertical",sizes=c(42,58),height="100%"),sizes=c(68,32),min_sizes=c(40,20),height="680px")),
      tabPanel("Events",verbatimTextOutput("intent")))))

server <- function(input,output,session){
  state <- reactiveValues(step=0L,events=make_events())
  model <- reactive(agent_activity_monitor(actors,make_work(state$step),state$events,
    summary=list(active=1L,queued=1L,awaiting_review=2L,failed=1L),max_events=500L,height="100%"))
  output$monitor <- render_agent_activity_monitor(model())
  output$monitor_composed <- render_agent_activity_monitor(model())
  output$tree <- render_virtual_tree_browser(virtual_tree_browser(tree_nodes,expanded=c("mandate","investigate"),height="100%"))
  output$ledger <- render_data_grid(data_grid(data.frame(event_id=vapply(tail(state$events,100),`[[`,character(1),"event_id"),
    type=vapply(tail(state$events,100),`[[`,character(1),"event_type"),summary=vapply(tail(state$events,100),`[[`,character(1),"summary")),row_id="event_id",height="100%"))
  observeEvent(input$advance,{state$step<-state$step+1L;state$events<-c(state$events,list(list(event_id=paste0("live-",state$step),occurred_at=format(Sys.time(),"%Y-%m-%dT%H:%M:%SZ",tz="UTC"),event_type="status_changed",summary=paste("Live update",state$step),work_id="work-investigate",actor_id="ag-investigator",severity="info"))); update_agent_activity_monitor(session,"monitor",actors=actors,work_items=make_work(state$step),events=state$events,max_events=500L);update_agent_activity_monitor(session,"monitor_composed",actors=actors,work_items=make_work(state$step),events=state$events,max_events=500L)})
  observeEvent(input$burst,{state$events<-make_events(1000L);update_agent_activity_monitor(session,"monitor",events=state$events,max_events=500L);update_agent_activity_monitor(session,"monitor_composed",events=state$events,max_events=500L)})
  output$intent<-renderPrint(list(selection=input$monitor_selection,navigation=input$monitor_navigation,view=input$monitor_view_state))
}
shinyApp(ui,server)
