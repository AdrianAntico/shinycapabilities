# Run from the package root. Inventory only: no package execution or mutation.
exports <- sub('^export\\((.*)\\)$', '\\1', grep('^export\\(', readLines('NAMESPACE'), value = TRUE))
definitions <- list()
for (file in list.files('R', pattern = '\\.R$', full.names = TRUE)) {
  for (expression in parse(file)) {
    if (is.call(expression) && identical(expression[[1]], as.name('<-')) &&
        is.call(expression[[3]]) && identical(expression[[3]][[1]], as.name('function'))) {
      definitions[[as.character(expression[[2]])]] <- list(file = file,
        parameters = paste(names(expression[[3]][[2]]), collapse = ';'))
    } else if (is.call(expression) && identical(expression[[1]], as.name('<-')) &&
               is.symbol(expression[[3]])) {
      definitions[[as.character(expression[[2]])]] <- list(file = file,
        parameters = paste('Alias of', as.character(expression[[3]])))
    }
  }
}
classification <- c(browser_controls = 'FOUNDATIONAL', browser_surfaces = 'HIGH_VALUE',
  selection_input = 'NEEDS_REDESIGN', direct_component_transport = 'FOUNDATIONAL',
  parameter_workbench = 'HIGH_VALUE', split_pane = 'FOUNDATIONAL', split_pane_direct = 'FOUNDATIONAL',
  interaction_components = 'HIGH_VALUE', command_palette_direct = 'HIGH_VALUE',
  data_grid = 'INCOMPLETE', object_inspector = 'HIGH_VALUE', code_editor = 'HIGH_VALUE',
  relationship_graph = 'NICHE', execution_replay = 'NICHE', agent_activity_monitor = 'NICHE',
  persistent_ui = 'HIGH_VALUE', workstation_header = 'HIGH_VALUE')
rows <- lapply(exports, function(name) {
  definition <- definitions[[name]]
  if (is.null(definition)) stop('Unresolved export: ', name)
  family <- sub('\\.R$', '', basename(definition$file))
  category <- unname(classification[family])
  if (is.na(category)) category <- 'FOUNDATIONAL'
  if (name %in% c('analytics_field_picker', 'command_palette', 'command_palette_output',
      'render_command_palette')) category <- 'REDUNDANT'
  if (grepl('^run_.*demo$|^run_.*gallery$', name)) category <- 'NICHE'
  data.frame(function_name = name, source = definition$file, parameters = definition$parameters,
    family = family, classification = category,
    evidence = 'API_SOURCE_AND_BASELINE_R_SUITE;BROWSER_COVERAGE_SEE_REPORT')
})
utils::write.csv(do.call(rbind, rows), 'UI_FRAMEWORK_PUBLIC_SURFACE.csv', row.names = FALSE)
cat(length(rows), 'exported functions inventoried\n')
