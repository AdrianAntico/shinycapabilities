test_that("registry stores closed capability definitions", {
  registry <- capability_registry()
  capability_registry_add(registry, register_capability(
    id = "source.value", version = "1.0.0", display_name = "Source",
    outputs = list(value = port_type("value")),
    execute = function(context, config, inputs) list(value = 1)
  ))
  expect_equal(capability_registry_get(registry, "source.value")$version, "1.0.0")
  expect_identical(
    vapply(capability_registry_list(registry), `[[`, character(1), "id"),
    "source.value"
  )
  expect_length(capability_registry_list(registry), 1)
})

test_that("default catalog is host neutral and empty", {
  registry <- default_capability_catalog()
  expect_length(capability_registry_list(registry), 0)
})
