# Typed Parameter Workbench 1.0

The Typed Parameter Workbench is a host-neutral Shiny module for editing analytical configurations from bounded metadata. Hosts own schemas, applied values, persistence, and consequences. The component owns draft interaction, deterministic validation, accessibility, and explicit Apply/Reset intent.

## Public contract

```r
parameter_workbench_ui("fit", title = "Model configuration")

state <- parameter_workbench_server(
  "fit",
  schema = reactive(parameter_schema()),
  value = reactive(applied_configuration()),
  conflict_policy = "preserve"
)
```

Supported types are `text`, `numeric`, `integer`, `boolean`, `choice`, `multi_choice`, `slider`, `range`, `date`, and `datetime`. Fields may include `key`, `label`, `type`, `default`, `required`, `description`, `choices`, `min`, `max`, `step`, `read_only`, `disabled`, `section`, and one explicit `condition`.

Conditions reference one other key and use exactly one of `equals` or `in`. Unknown dependencies, self-dependencies, and cycles are rejected. This is intentionally not an expression language.

The server returns reactives for `draft`, `applied`, `valid`, `dirty`, structured `errors`, `conflict`, `apply_event`, and `reset_event`. Apply/Reset events carry a nonce. Invalid drafts cannot emit Apply.

## Host updates

`update_parameter_workbench()` can replace schema, values, or overall enabled state. The default `preserve` policy retains a dirty browser draft and exposes a conflict when host-applied values change. `replace` explicitly discards the draft. No host update silently destroys edits.

## Scale and accessibility

Sections and local search support schemas with dozens of fields. The component does not target thousands of controls and intentionally avoids virtualization, which would complicate focus and form semantics at this scale. Labels, help, errors, disabled/read-only state, focus rings, native keyboard controls, and Apply/Reset status are associated semantically.

Run the standalone model/optimizer stress demo with:

```r
shinycapabilities::run_parameter_workbench_demo()
```
