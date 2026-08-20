graph_fixture <- function() list(
  nodes=list(list(id="a",label="Source",type="dataset",status="ready",metadata=list(owner="qa")),list(id="b",label="Model",type="model",status="running"),list(id="c",label="Artifact",type="artifact",status="ready")),
  edges=list(list(id="e1",source="a",target="b",type="TRAINS"),list(id="e2",source="b",target="c",type="PRODUCES")))

testthat::test_that("graph contract preserves typed nodes and relationships",{
  f<-graph_fixture();widget<-relationship_graph(f$nodes,f$edges)
  testthat::expect_s3_class(widget,"relationship_graph")
  testthat::expect_identical(widget$x$nodes[[2]]$type,"model")
  testthat::expect_identical(widget$x$edges[[2]]$type,"PRODUCES")
  testthat::expect_identical(widget$x$diagnostics$nodeCount,3L)
})

testthat::test_that("duplicate identities and missing endpoints fail deterministically",{
  f<-graph_fixture();testthat::expect_error(relationship_graph(c(f$nodes,f$nodes[1]),f$edges),"Node id values")
  testthat::expect_error(relationship_graph(f$nodes,c(f$edges,f$edges[1])),"Edge id values")
  f$edges[[1]]$source<-"missing";testthat::expect_error(relationship_graph(f$nodes,f$edges),"missing node endpoints: missing")
})

testthat::test_that("cycles and disconnected components are valid and diagnosed",{
  f<-graph_fixture();f$edges<-c(f$edges,list(list(id="e3",source="c",target="a",type="FEEDS")))
  testthat::expect_true(relationship_graph(f$nodes,f$edges)$x$diagnostics$hasCycle)
  f<-graph_fixture();f$nodes<-c(f$nodes,list(list(id="d",label="Detached",type="note")))
  diagnostics<-relationship_graph(f$nodes,f$edges)$x$diagnostics
  testthat::expect_true(diagnostics$disconnected);testthat::expect_identical(diagnostics$componentCount,2L)
})

testthat::test_that("metadata is bounded and redaction safe",{
  f<-graph_fixture();f$nodes[[1]]$metadata<-c(as.list(stats::setNames(1:30,paste0("field",1:30))),list(chain_of_thought="private",nested=list(raw_prompt="private",safe="yes")))
  metadata<-relationship_graph(f$nodes,f$edges,max_metadata_fields=10L)$x$nodes[[1]]$metadata
  testthat::expect_lte(length(metadata),10L);testthat::expect_false("chain_of_thought"%in%names(metadata))
})

testthat::test_that("filters direction and progressive limit are normalized",{
  f<-graph_fixture();widget<-relationship_graph(f$nodes,f$edges,filters=list(nodeType="model"),direction="TB",max_render_nodes=100L,state="loading",message="Preparing projection")
  testthat::expect_identical(widget$x$filters$nodeType,"model");testthat::expect_identical(widget$x$options$direction,"TB")
  testthat::expect_identical(widget$x$options$maxRenderNodes,100L)
  testthat::expect_identical(widget$x$options$state,"loading");testthat::expect_identical(widget$x$options$message,"Preparing projection")
})

testthat::test_that("updates namespace and validate complete relationship replacements",{
  f<-graph_fixture();captured<-new.env(parent=emptyenv());session<-list(ns=function(id)paste0("mod-",id),sendCustomMessage=function(type,message){captured$type<-type;captured$message<-message})
  update_relationship_graph(session,"graph",nodes=f$nodes,edges=f$edges,selected_id="b",focus_id="b",filters=list(status="ready"),direction="TB",fit_request="2",state="error",message="Host error")
  testthat::expect_identical(captured$type,"shinycapabilities:relationship-graph:update")
  testthat::expect_identical(captured$message$id,"mod-graph");testthat::expect_identical(captured$message$selectedId,"b")
  testthat::expect_true(captured$message$diagnostics$componentCount>=1L)
  testthat::expect_identical(captured$message$state,"error");testthat::expect_identical(captured$message$message,"Host error")
  testthat::expect_error(update_relationship_graph(session,"graph",edges=f$edges),"nodes must accompany edges")
})

testthat::test_that("self loops are allowed as cycles",{
  nodes<-list(list(id="a",label="Iterative result",type="artifact"));edges<-list(list(id="loop",source="a",target="a",type="REFINES"))
  widget<-relationship_graph(nodes,edges);testthat::expect_true(widget$x$diagnostics$hasCycle)
})

testthat::test_that("widget assets and installable demo exist",{
  testthat::expect_true(file.exists(system.file("htmlwidgets","relationship_graph.yaml",package="shinycapabilities")))
  testthat::expect_true(file.exists(system.file("htmlwidgets","lib","relationship-graph.js",package="shinycapabilities")))
  testthat::expect_true(file.exists(system.file("examples","relationship-graph","app.R",package="shinycapabilities")))
})

testthat::test_that("large host projections validate with stable counts",{
  n<-3000L;nodes<-lapply(seq_len(n),function(i)list(id=paste0("n",i),label=paste("Node",i),type="artifact"));edges<-lapply(2:n,function(i)list(id=paste0("e",i),source=paste0("n",i-1L),target=paste0("n",i),type="DERIVED_FROM"))
  widget<-relationship_graph(nodes,edges,max_render_nodes=300L)
  testthat::expect_identical(widget$x$diagnostics$nodeCount,n)
  testthat::expect_identical(widget$x$diagnostics$edgeCount,n-1L)
})
