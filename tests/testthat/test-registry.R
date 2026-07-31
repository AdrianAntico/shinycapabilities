test_that("registry stores closed capability definitions", {
  registry <- capability_registry()
  capability_registry_add(registry, register_capability(
    id = "source.data", version = "1.0.0", display_name = "Source",
    outputs = list(dataset = port_type("dataset")),
    execute = function(context, config, inputs) list(dataset = data.frame(x = 1))
  ))
  expect_equal(capability_registry_get(registry, "source.data")$version, "1.0.0")
  expect_length(capability_registry_list(registry), 1)
})

test_that("default catalog covers the product capability boundary", {
  registry <- default_capability_catalog()
  expect_length(capability_registry_list(registry), 17)
  expect_true(all(c("eda.profile", "model.train", "ai.analyze", "report.generate") %in%
    vapply(capability_registry_list(registry), `[[`, character(1), "id")))
})

