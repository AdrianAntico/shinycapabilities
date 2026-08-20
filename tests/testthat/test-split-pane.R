testthat::test_that("split panes normalize identities directions and constraints", {
  horizontal <- split_pane("layout",left=htmltools::div("Left"),right=htmltools::div("Right"),sizes=c(35,65),min_sizes=15,max_sizes=c(70,90),collapsible=c(TRUE,FALSE))
  html <- htmltools::renderTags(horizontal)$html
  testthat::expect_match(html,'id="layout"',fixed=TRUE)
  model_text <- sub('.*<script type="application/json" data-for="layout">(.*)</script>.*','\\1',html)
  model <- jsonlite::fromJSON(model_text,simplifyVector=FALSE)
  testthat::expect_identical(model$direction,"horizontal")
  testthat::expect_identical(unlist(model$ids,use.names=FALSE),c("left","right"))
  testthat::expect_identical(model$sizes$left,"35%")
  testthat::expect_match(model$html$left,"Left",fixed=TRUE)
  vertical <- split_pane("vertical",top=htmltools::div(),bottom=htmltools::div(),direction="vertical")
  testthat::expect_match(htmltools::renderTags(vertical)$html,'"direction":"vertical"',fixed=TRUE)
})

testthat::test_that("split panes reject invalid configurations", {
  testthat::expect_error(split_pane("one",only=htmltools::div()),"at least two")
  testthat::expect_error(split_pane("bad",`not valid`=htmltools::div(),right=htmltools::div()),"CSS-safe")
  testthat::expect_error(split_pane("bad",left=htmltools::div(),right=htmltools::div(),sizes=c(20,30,50)),"pane count")
  testthat::expect_error(split_pane("bad",left=htmltools::div(),right=htmltools::div(),collapsed="missing"),"unknown")
})

testthat::test_that("nested panes retain independent deterministic identities", {
  nested <- split_pane("outer",main=split_pane("inner",top=htmltools::div("A"),bottom=htmltools::div("B"),direction="vertical"),detail=htmltools::div("C"))
  html <- htmltools::renderTags(nested)$html
  testthat::expect_match(html,'id="outer"',fixed=TRUE)
  model_text <- sub('.*<script type="application/json" data-for="outer">(.*)</script>.*','\\1',html)
  model <- jsonlite::fromJSON(model_text,simplifyVector=FALSE)
  testthat::expect_match(model$html$main,'id="inner"',fixed=TRUE)
  dependencies <- htmltools::findDependencies(nested)
  testthat::expect_true(any(vapply(dependencies,`[[`,character(1),"name")=="shinycapabilities-split-pane"))
})

testthat::test_that("programmatic update sends bounded operations", {
  messages <- list()
  session <- list(sendInputMessage=function(id,message) messages[[length(messages)+1L]] <<- list(id=id,message=message))
  update_split_pane(session,"layout",sizes=c(left=40,right=60),collapse="right")
  testthat::expect_identical(messages[[1]]$id,"layout")
  testthat::expect_identical(messages[[1]]$message$collapse,"right")
  testthat::expect_identical(messages[[1]]$message$sizes,c(left=40,right=60))
})

testthat::test_that("bundled split pane and composition demo ship", {
  testthat::expect_true(file.exists(system.file("htmlwidgets","lib","split-pane.js",package="shinycapabilities")))
  testthat::expect_true(file.exists(system.file("htmlwidgets","lib","split-pane.css",package="shinycapabilities")))
  testthat::expect_true(file.exists(system.file("examples","split-pane","app.R",package="shinycapabilities")))
})
