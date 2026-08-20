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

The installed runtime imports `callr`, `digest`, `htmltools`, `htmlwidgets`, `jsonlite`, and `shiny`.

## License and attribution

The package is available under the [MIT license](LICENSE). Bundled third-party software is listed in [DEPENDENCY-LICENSES.md](inst/docs/DEPENDENCY-LICENSES.md).
