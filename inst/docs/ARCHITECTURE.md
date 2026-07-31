# Installed architecture boundary

`shinycapabilities` is a host-neutral capability graph, execution, lifecycle,
artifact-reference, and persistence engine.

The package owns:

- closed capability and port contracts;
- deterministic graph validation and planning;
- execution, progress, cancellation, caching, and staleness;
- workflow serialization and restoration;
- bounded browser messages and presentation hooks.

Hosts own:

- every domain capability and executor;
- labels, groups, ordering, icons, summaries, and friendly port labels;
- domain configuration interpretation;
- private resources and artifact contents.

Core never infers semantics from IDs, labels, categories, ports, or
descriptions. The installed demonstration uses only the neutral document
workflow.
