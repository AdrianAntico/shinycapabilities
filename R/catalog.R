catalog_spec <- list(
  list("dataset.source", "Dataset source", "Sources", list(), list(dataset = "dataset")),
  list("data.prepare", "Data preparation", "Prepare", list(dataset = "dataset"), list(dataset = "dataset")),
  list("eda.profile", "EDA", "Explore", list(dataset = "dataset"), list(profile = "data_profile", findings = "evidence_collection")),
  list("target.analyze", "Target analysis", "Explore", list(dataset = "dataset"), list(findings = "evidence_collection")),
  list("statistics.analyze", "Statistical analysis", "Analyze", list(dataset = "dataset"), list(findings = "evidence_collection")),
  list("model.train", "Model training", "Model", list(dataset = "dataset"), list(model = "model", metrics = "metric_collection")),
  list("model.score", "Model scoring", "Model", list(dataset = "dataset", model = "model"), list(predictions = "prediction_set")),
  list("model.diagnostics", "Model diagnostics", "Model", list(model = "model", predictions = "prediction_set"), list(findings = "evidence_collection")),
  list("model.explain", "Explainability", "Model", list(model = "model", dataset = "dataset"), list(explanations = "evidence_collection")),
  list("forecast.fit", "Forecasting", "Analyze", list(dataset = "dataset"), list(forecast = "forecast")),
  list("causal.estimate", "Causal analysis", "Analyze", list(dataset = "dataset"), list(findings = "evidence_collection")),
  list("optimize.solve", "Optimization", "Decide", list(dataset = "dataset"), list(solution = "optimization_result")),
  list("visualize.compose", "Visualization", "Synthesize", list(dataset = "dataset"), list(plot = "plot_artifact")),
  list("research.collect", "Research", "Sources", list(), list(evidence = "evidence_collection")),
  list("ai.analyze", "AI analysis", "Synthesize", list(evidence = "evidence_collection"), list(findings = "evidence_collection")),
  list("evidence.synthesize", "Evidence synthesis", "Synthesize", list(evidence = "evidence_collection"), list(report = "evidence_synthesis")),
  list("report.generate", "Report generation", "Deliver", list(evidence = "evidence_synthesis"), list(report = "report_artifact"))
)

catalog_executor <- function(capability_id, output_types) {
  force(capability_id)
  force(output_types)
  function(context, config, inputs) {
    setNames(lapply(names(output_types), function(name) {
      list(
        kind = output_types[[name]]$type,
        capability = capability_id,
        config = config,
        inputs = names(inputs)
      )
    }), names(output_types))
  }
}

#' Create the exploratory default capability catalog
#' @export
default_capability_catalog <- function() {
  registry <- capability_registry()
  for (item in catalog_spec) {
    inputs <- lapply(item[[4]], port_type)
    outputs <- lapply(item[[5]], port_type)
    capability <- register_capability(
      id = item[[1]],
      version = "0.1.0",
      display_name = item[[2]],
      category = item[[3]],
      description = paste(item[[2]], "capability registered for host-owned R execution."),
      inputs = inputs,
      outputs = outputs,
      config = list(
        label = config_field("text", "Node label", default = item[[2]]),
        notes = config_field("text", "Analyst notes", default = "")
      ),
      execute = catalog_executor(item[[1]], outputs),
      summarize = function(outputs) paste(length(outputs), "output(s) ready"),
      icon = switch(item[[3]],
        Sources = "S", Prepare = "P", Explore = "E", Analyze = "A",
        Model = "M", Decide = "D", Synthesize = "Y", Deliver = "R", "C")
    )
    capability_registry_add(registry, capability)
  }
  registry
}
