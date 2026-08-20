# shinycapabilities

`shinycapabilities` is an experimental R package that provides a capability-based workflow canvas and execution runtime for Shiny applications. Host applications register their own capabilities and retain ownership of domain behavior.

## Installation

R 4.1 or later is required. Install a source archive with:

```r
install.packages("shinycapabilities_0.1.0.tar.gz", repos = NULL, type = "source")
```

Node.js is not required to install or use the package; required browser assets are bundled.

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

The [Workstation UI opportunity scan](docs/ui_opportunity_scan.md) documents
the evidence, JavaScript library review, prioritization, event contracts, and
future migration boundaries. No Workstation migration is included.

## Analytical data grid lab

`data_grid()` is a parallel AG Grid Community-backed component for dense,
virtualized analytical inventories. It uses stable row identity and bounded
Shiny events while leaving host behavior outside the widget.

```r
shinycapabilities::run_data_grid_demo()
```

The [AG Grid Data Grid 1.0 report](docs/data_grid_1_0.md) documents the API,
Community/Enterprise boundary, accessibility and scale tradeoffs, direct
reactable comparison, and future migration seams. The recommendation is to
selectively replace reactable for demanding interactive inventories, not report
tables.

## Agent activity monitor lab

`agent_activity_monitor()` renders a read-only, host-neutral projection of
governed actors, work items, events, attention states, and real dependency
relationships. The host remains responsible for execution and all mutations.

```r
shinycapabilities::run_agent_activity_monitor_demo()
```

The [Agent Activity Monitor 1.0 report](docs/agent_activity_monitor_1_0.md)
defines the normalized contract, bounded live-update behavior, accessibility
semantics, and promotion boundary.

## Relationship graph lab

`relationship_graph()` renders typed analytical relationships with directed
layout, navigation, filtering, neighborhood focus, and an accessible structured
representation. It does not edit or execute the supplied graph.

```r
shinycapabilities::run_relationship_graph_demo()
```

See the [Relationship Graph 1.0 report](docs/relationship_graph_1_0.md) for the
contract, scale boundary, dependency decision, and promotion guidance.

The installed runtime imports `callr`, `digest`, `htmltools`, `htmlwidgets`, `jsonlite`, and `shiny`.

## License and attribution

The package is available under the [MIT license](LICENSE). Bundled third-party software is listed in [DEPENDENCY-LICENSES.md](inst/docs/DEPENDENCY-LICENSES.md).
