workbench_schema <- function() list(
  list(key="name",label="Name",type="text",default="fit",required=TRUE,section="General"),
  list(key="iterations",label="Iterations",type="integer",default=100L,min=1,max=1000,section="Fit"),
  list(key="enabled",label="Enabled",type="boolean",default=TRUE,section="General"),
  list(key="mode",label="Mode",type="choice",choices=c(Fast="fast",Full="full"),default="fast"),
  list(key="methods",label="Methods",type="multi_choice",choices=c(A="a",B="b"),default="a"),
  list(key="rate",label="Rate",type="slider",default=.5,min=0,max=1,step=.1),
  list(key="bounds",label="Bounds",type="range",default=c(1,5),min=0,max=10),
  list(key="date",label="Date",type="date",default="2026-08-20"),
  list(key="advanced",label="Advanced",type="numeric",default=2,condition=list(key="mode",equals="full"))
)

testthat::test_that("workbench schema normalizes all bounded field types", {
  schema <- shinycapabilities:::normalize_parameter_workbench_schema(workbench_schema())
  testthat::expect_identical(vapply(schema, `[[`, character(1), "type"), c("text","integer","boolean","choice","multi_choice","slider","range","date","numeric"))
  testthat::expect_identical(shinycapabilities:::parameter_workbench_defaults(schema)$iterations, 100L)
  testthat::expect_identical(schema[[9]]$condition$operator, "equals")
})

testthat::test_that("malformed schemas and dependency cycles fail deterministically", {
  testthat::expect_error(shinycapabilities:::normalize_parameter_workbench_schema(list(list(key="x"),list(key="x"))),"unique")
  testthat::expect_error(shinycapabilities:::normalize_parameter_workbench_schema(list(list(key="x",type="choice"))),"choices")
  testthat::expect_error(shinycapabilities:::normalize_parameter_workbench_schema(list(list(key="x",type="range",min=2,max=1))),"min cannot")
  testthat::expect_error(shinycapabilities:::normalize_parameter_workbench_schema(list(
    list(key="a",condition=list(key="b",equals=1)),list(key="b",condition=list(key="a",equals=1)))),"cycles")
})

testthat::test_that("UI is namespaced and ships semantic model metadata", {
  ui <- parameter_workbench_ui("fit",title="Fit model",height="500px")
  html <- htmltools::renderTags(ui)$html
  testthat::expect_match(html,'id="fit-workbench"',fixed=TRUE)
  testthat::expect_match(html,"sc-parameter-workbench",fixed=TRUE)
  dependency <- htmltools::findDependencies(ui)
  testthat::expect_true(any(vapply(dependency, `[[`, character(1), "name") == "shinycapabilities-parameter-workbench"))
})

testthat::test_that("server exposes draft applied validation and nonce-bearing events", {
  shiny::testServer(parameter_workbench_server,args=list(schema=workbench_schema(),value=list(name="fit")), {
    state <- session$returned
    session$setInputs(workbench=list(draft=list(name="changed"),applied=list(name="fit"),valid=TRUE,dirty=TRUE,errors=list(),conflict=FALSE,event=list(type="apply",nonce="n-1",values=list(name="changed"))))
    testthat::expect_true(state$dirty()); testthat::expect_true(state$valid())
    testthat::expect_identical(state$draft()$name,"changed")
    testthat::expect_identical(state$apply_event()$nonce,"n-1")
    session$setInputs(workbench=list(draft=list(),applied=list(name="fit"),valid=FALSE,dirty=TRUE,errors=list(list(key="name",code="required")),conflict=FALSE,event=NULL))
    testthat::expect_false(state$valid())
    testthat::expect_identical(state$apply_event()$nonce,"n-1")
    testthat::expect_identical(state$errors()[[1]]$code,"required")
  })
})

testthat::test_that("authored client contract covers apply reset conflicts and accessibility", {
  source <- paste(readLines(system.file("htmlwidgets","src","parameter-workbench.jsx",package="shinycapabilities"),warn=FALSE),collapse="\n")
  testthat::expect_match(source,'type: "apply"',fixed=TRUE)
  testthat::expect_match(source,'type: "reset"',fixed=TRUE)
  testthat::expect_match(source,"conflictPolicy",fixed=TRUE)
  testthat::expect_match(source,"aria-describedby",fixed=TRUE)
  testthat::expect_match(source,"aria-invalid",fixed=TRUE)
  testthat::expect_match(source,"if (!valid)",fixed=TRUE)
})

testthat::test_that("standalone workbench demo and bundled assets ship", {
  testthat::expect_true(file.exists(system.file("examples","parameter-workbench","app.R",package="shinycapabilities")))
  testthat::expect_true(file.exists(system.file("htmlwidgets","lib","parameter-workbench.js",package="shinycapabilities")))
  testthat::expect_true(file.exists(system.file("htmlwidgets","lib","parameter-workbench.css",package="shinycapabilities")))
})
