test_that("changed palette executable has its own cache identity", {
  palette <- shinycapabilities:::direct_component_dependency("command_palette_direct")
  expect_identical(palette$version, "1.1.1")
  expect_identical(palette$script, "command-palette-direct.js")
  expect_identical(shinycapabilities:::direct_component_dependency("data_grid")$version, "1.1.0")
  expect_identical(shinycapabilities:::direct_component_dependency("object_inspector")$version, "1.1.0")
})
