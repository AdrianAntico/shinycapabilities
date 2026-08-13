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

test_that("capabilities own normalized execution plans and deliverables", {
  capability <- register_capability(
    "test.ledger", "1.0.0", "Ledger test",
    outputs = list(result = port_type("report")),
    execution_contract = list(
      actions = list(list(id = "validate", label = "Validate inputs")),
      deliverables = list(list(
        id = "report", label = "Governed report", type = "report",
        destination = "reports", optional = FALSE
      ))
    )
  )
  expect_identical(capability$execution_contract$actions[[1]]$id, "validate")
  expect_identical(capability$execution_contract$deliverables[[1]]$destination, "reports")
  expect_error(register_capability(
    "test.invalid-ledger", "1.0.0", "Invalid ledger",
    execution_contract = list(actions = list(list(id = "missing-label")))
  ), "require stable ids and labels")
})
