monitor_fixture <- function(event_count=3L) {
  actors <- list(list(actor_id="a1",title="Investigator",role_id="investigator",actor_type="agent",status="running",raw_status="active"))
  work <- list(list(work_id="w1",label="Inspect evidence",kind="task",status="running",raw_status="RUNNING",actor_id="a1",dependency_ids=character(),attention="none",source_contract="collaboration_task",metadata=list(project="p1")),
    list(work_id="w2",label="Review evidence",kind="review",status="awaiting_human",actor_id="",dependency_ids="w1",attention="needs_approval",source_contract="agent_session"))
  events <- lapply(seq_len(event_count),function(i)list(event_id=paste0("e",i),occurred_at=format(as.POSIXct("2026-01-01",tz="UTC")+i,"%Y-%m-%dT%H:%M:%SZ",tz="UTC"),event_type="status_changed",summary=paste("Event",i),work_id="w1",actor_id="a1",severity="info"))
  list(actors=actors,work=work,events=events)
}

testthat::test_that("monitor normalizes identity, status, source, and event order", {
  f<-monitor_fixture(); widget<-agent_activity_monitor(f$actors,f$work,rev(f$events),max_events=2L)
  testthat::expect_s3_class(widget,"agent_activity_monitor")
  testthat::expect_identical(widget$x$actors[[1]]$actor_id,"a1")
  testthat::expect_identical(widget$x$workItems[[1]]$source_contract,"collaboration_task")
  testthat::expect_identical(vapply(widget$x$events,`[[`,character(1),"event_id"),c("e2","e3"))
  testthat::expect_identical(widget$x$workItems[[2]]$attention,"needs_approval")
})

testthat::test_that("validation rejects malformed identities and statuses", {
  f<-monitor_fixture()
  testthat::expect_error(agent_activity_monitor(c(f$actors,f$actors),f$work),"unique")
  bad<-f$actors;bad[[1]]$status<-"invented"
  testthat::expect_error(agent_activity_monitor(bad,f$work),"Unsupported actor status")
  badwork<-f$work;badwork[[1]]$progress_value<-2
  testthat::expect_error(agent_activity_monitor(f$actors,badwork),"between 0 and 1")
})

testthat::test_that("malformed relationships are diagnostic and removed", {
  f<-monitor_fixture();f$work[[1]]$parent_id<-"missing";f$work[[2]]$dependency_ids<-c("w1","missing","w2")
  widget<-agent_activity_monitor(f$actors,f$work)
  testthat::expect_length(widget$x$diagnostics,2L)
  testthat::expect_identical(widget$x$workItems[[1]]$parent_id,"")
  testthat::expect_identical(widget$x$workItems[[2]]$dependency_ids,"w1")
})

testthat::test_that("private reasoning keys are removed recursively", {
  f<-monitor_fixture();f$work[[1]]$metadata<-list(project="p1",chain_of_thought="private",nested=list(raw_prompt="private",safe="yes"))
  widget<-agent_activity_monitor(f$actors,f$work)
  metadata<-widget$x$workItems[[1]]$metadata
  testthat::expect_false("chain_of_thought"%in%names(metadata))
  testthat::expect_false("raw_prompt"%in%names(metadata$nested))
  testthat::expect_identical(metadata$nested$safe,"yes")
})

testthat::test_that("missing telemetry remains absent", {
  f<-monitor_fixture();widget<-agent_activity_monitor(f$actors,f$work,summary=list(active=1L))
  testthat::expect_null(widget$x$workItems[[1]]$progress_value)
  testthat::expect_null(widget$x$summary$cost_total)
  testthat::expect_null(widget$x$summary$token_total)
})

testthat::test_that("updates namespace and bound events deterministically", {
  f<-monitor_fixture(8L);captured<-new.env(parent=emptyenv());session<-list(ns=function(id)paste0("mod-",id),sendCustomMessage=function(type,message){captured$type<-type;captured$message<-message})
  update_agent_activity_monitor(session,"monitor",actors=f$actors,work_items=f$work,events=f$events,max_events=3L,selected_work_id="w2")
  testthat::expect_identical(captured$type,"shinycapabilities.direct.update")
  testthat::expect_identical(captured$message$id,"mod-monitor")
  testthat::expect_identical(captured$message$component,"agent_activity_monitor")
  testthat::expect_identical(length(captured$message$payload$events),3L)
  testthat::expect_identical(captured$message$payload$selectedWorkId,"w2")
})

testthat::test_that("widget source carries virtualization, accessibility, and read-only events", {
  source<-paste(readLines(system.file("www","direct-transport","src","agent-activity-monitor.jsx",package="shinycapabilities"),warn=FALSE),collapse="\n")
  css<-paste(readLines(system.file("www","direct-transport","src","agent-activity-monitor.css",package="shinycapabilities"),warn=FALSE),collapse="\n")
  testthat::expect_match(source,"useVirtualizer",fixed=TRUE)
  testthat::expect_match(source,'publish(element, "selection"',fixed=TRUE)
  testthat::expect_match(source,'publish(element, "navigation"',fixed=TRUE)
  testthat::expect_match(source,'publish(element, "view_state"',fixed=TRUE)
  testthat::expect_false(grepl('publish(element, "cancel"',source,fixed=TRUE))
  testthat::expect_match(source,'kind === "event" ? "feed" : "listbox"',fixed=TRUE)
  testthat::expect_match(source,'aria-live="polite"',fixed=TRUE)
  testthat::expect_match(css,":focus-visible",fixed=TRUE)
  testthat::expect_match(css,"forced-colors",fixed=TRUE)
})

testthat::test_that("assets and composed demo are installable", {
  testthat::expect_true(file.exists(system.file("www","direct-transport","agent-activity-monitor.js",package="shinycapabilities")))
  demo<-system.file("examples","agent-activity-monitor","app.R",package="shinycapabilities")
  testthat::expect_true(file.exists(demo));text<-paste(readLines(demo,warn=FALSE),collapse="\n")
  testthat::expect_match(text,"split_pane",fixed=TRUE);testthat::expect_match(text,"virtual_tree_browser",fixed=TRUE);testthat::expect_match(text,"data_grid",fixed=TRUE)
})

testthat::test_that("stress payload is bounded and keeps stable identities", {
  f<-monitor_fixture(10000L);start<-proc.time()[[3]];widget<-agent_activity_monitor(f$actors,f$work,f$events,max_events=500L);elapsed<-proc.time()[[3]]-start
  testthat::expect_length(widget$x$events,500L)
  testthat::expect_identical(widget$x$events[[500]]$event_id,"e10000")
  testthat::expect_lt(elapsed,5)
})
