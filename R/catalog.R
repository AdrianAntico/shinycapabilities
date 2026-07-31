#' Create a neutral document-workflow example catalog
#'
#' The default catalog demonstrates generic typed workflow composition. Hosts
#' must register all domain vocabulary and behavior themselves.
#' @export
default_capability_catalog <- function() {
  example_document_catalog()
}

#' Create a neutral document-workflow example catalog
#' @export
example_document_catalog <- function() {
  registry <- capability_registry()
  add <- function(id, name, inputs = list(), outputs = list(), execute,
                  group, order) {
    capability_registry_add(registry, register_capability(
      id, "1.0.0", name,
      description = paste(name, "in the neutral document workflow example."),
      category = group, inputs = inputs, outputs = outputs,
      config = list(label = config_field("text", "Label", name)),
      validate = function(context, config, inputs) list(valid = nzchar(config$label)),
      execute = execute, implementation_fingerprint = paste0(id, "-example-1"),
      presentation = list(
        group_id = tolower(group), group_label = group, group_order = order,
        display_order = order, icon_id = "generic",
        short_summary = paste(name, "document content."),
        compact_summary = name,
        accessibility_label = paste(name, "workflow capability")
      )
    ))
  }
  add("document.intake", "Document intake", outputs = list(document = port_type("document")),
    execute = function(context, config, inputs) list(document = list(text = context$text %||% "")),
    group = "Intake", order = 10)
  add("document.cleanup", "Text cleanup", inputs = list(document = port_type("document")),
    outputs = list(document = port_type("document")),
    execute = function(context, config, inputs) list(
      document = list(text = trimws(inputs$document$text))
    ), group = "Edit", order = 20)
  add("document.approval", "Human approval", inputs = list(document = port_type("document")),
    outputs = list(approved = port_type("approved_document")),
    execute = function(context, config, inputs) list(approved = inputs$document),
    group = "Review", order = 30)
  add("document.publish", "Publication", inputs = list(approved = port_type("approved_document")),
    outputs = list(artifact = port_type("publication_artifact")),
    execute = function(context, config, inputs) list(
      artifact = list(id = "publication:example", document = inputs$approved)
    ), group = "Publish", order = 40)
  registry
}
