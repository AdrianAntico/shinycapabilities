testthat::test_that("deferred construction preserves the entire table contract", {
  data <- data.table::data.table(id=c("a","b"), value=c(1.25,NA_real_))
  eager <- data_grid(data,row_id="id")
  deferred <- data_grid(data,row_id="id",options=list(defer_until_visible=TRUE))
  testthat::expect_identical(deferred$x$rows,eager$x$rows)
  testthat::expect_identical(deferred$x$columns,eager$x$columns)
  testthat::expect_false(eager$x$options$defer_until_visible)
  testthat::expect_true(deferred$x$options$defer_until_visible)
  testthat::expect_identical(shinycapabilities:::direct_component_dependency("data_grid")$version,"1.2.0")
  for(bad in list(NA,1,"yes",c(TRUE,FALSE),logical()))
    testthat::expect_error(data_grid(data,options=list(defer_until_visible=bad)),
      "defer_until_visible must be TRUE or FALSE",fixed=TRUE)
})
