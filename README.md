# shinycapabilities

`shinycapabilities` is an experimental R package that provides a capability-based workflow canvas and execution runtime for Shiny applications. Host applications register their own capabilities and retain ownership of domain behavior.

## Installation

R 4.1 or later is required. Install a source archive with:

```r
install.packages("shinycapabilities_0.1.0.tar.gz", repos = NULL, type = "source")
```

Node.js is not required to install or use the package; required browser assets are bundled.

The package includes browser-native controls, overlays, dialogs, notifications,
navigation, file upload/download controls, and output shells. Host applications
retain ownership of their domain behavior and execution policy.

## Smoke example

```r
shinycapabilities::run_capability_demo()
```

## Interaction capability lab

The package also includes host-neutral, virtualized interaction components for
large analytical catalogs and hierarchies:

```r
shinycapabilities::run_interaction_components_demo()
```

- `virtual_tree_browser()` provides searchable hierarchy navigation with
  keyboard and screen-reader semantics.
- `command_palette()` provides keyboard-first discovery and activation of
  host-defined commands without owning command execution.

`command_palette()` now preserves the public contract as a thin alias over the
qualified direct implementation. See the
[htmlwidgets Elimination and Component Modernization 1.0 report](docs/htmlwidgets_elimination_1_0.md)
and [Direct Component Transport 1.0 report](docs/direct_component_transport_1_0.md).

## Analytical data grid lab

`data_grid()` is a parallel AG Grid Community-backed component for dense,
virtualized analytical inventories. It uses stable row identity and bounded
Shiny events while leaving host behavior outside the widget.

```r
shinycapabilities::run_data_grid_demo()
```

## Agent activity monitor lab

`agent_activity_monitor()` renders a read-only, host-neutral projection of
governed actors, work items, events, attention states, and real dependency
relationships. The host remains responsible for execution and all mutations.

```r
shinycapabilities::run_agent_activity_monitor_demo()
```

## Relationship graph lab

`relationship_graph()` renders typed analytical relationships with directed
layout, navigation, filtering, neighborhood focus, and an accessible structured
representation. It does not edit or execute the supplied graph.

```r
shinycapabilities::run_relationship_graph_demo()
```

See the [Relationship Graph 1.0 report](docs/relationship_graph_1_0.md) for the
contract, scale boundary, dependency decision, and promotion guidance.

## Execution replay lab

`execution_replay()` provides a virtualized, read-only historical projection
over host-supplied events, state snapshots, artifacts, evidence, failures,
retries, interventions, and reviews. State-at-time never projects later state
backward, and appended events do not dislodge a user inspecting history.

```r
shinycapabilities::run_execution_replay_demo()
```

## Monaco editor lab

`code_editor()` provides pre-bundled Monaco editing and diff views for R,
Julia, Python, SQL, JSON, YAML, and Markdown. Drafts remain in the browser until
explicitly applied; execution remains the host's responsibility.

```r
shinycapabilities::run_code_editor_demo()
```

See the [Monaco Editor 1.0 report](docs/monaco_editor_1_0.md) for the state,
event, accessibility, worker, and promotion contracts.

## Structured object inspector lab

`object_inspector()` provides a persistent, searchable, virtualized, and
redaction-safe projection over nested analytical objects.

```r
shinycapabilities::run_object_inspector_demo()
```

See the [Structured Object Inspector 1.0 report](docs/structured_object_inspector_1_0.md)
for the typed schema, update, redaction, accessibility, scale, and promotion
contracts.

The installed runtime imports `callr`, `digest`, `htmltools`, `jsonlite`, and `shiny`.

## License and attribution

The package is available under the [MIT license](LICENSE). Bundled third-party software is listed in [DEPENDENCY-LICENSES.md](inst/docs/DEPENDENCY-LICENSES.md).
# Building a composed application

For linked tree/palette/grid selection, inspectable records, explicitly applied
parameters, a plot, and a resizable workspace, see
[`inst/examples/equipment-review/app.R`](inst/examples/equipment-review/app.R).
It uses ordinary Shiny reactivity and existing public components, not a second
application-state framework.

The current framework audit, replacement boundaries, and qualification limits are
in [UI_FRAMEWORK_AUDIT_IMPLEMENTATION_1_0.md](UI_FRAMEWORK_AUDIT_IMPLEMENTATION_1_0.md).
The [public surface inventory](UI_FRAMEWORK_PUBLIC_SURFACE.csv) includes all exports,
including compatibility paths. This is not a declaration that every component is
mobile, screen-reader, or production-scale qualified.
