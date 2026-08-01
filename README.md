# shinycapabilities

`shinycapabilities` is an experimental, host-neutral R package that supplies a typed workflow canvas and execution contracts for Shiny applications.

## Installation

Install from a source checkout or source archive:

```r
pak::pkg_install("path/to/shinycapabilities")
```

Installed users do not need Node.js; the browser assets are bundled with the package.

## Minimal smoke example

Run the installed neutral example with:

```r
shinycapabilities::run_capability_demo()
```

The example registers a small host-owned workflow and does not provide an application-specific analytical catalog.

## Basic host use

```r
library(shiny)
library(shinycapabilities)

registry <- capability_registry()
capability_registry_add(
  registry,
  register_capability(
    id = "example.step",
    version = "1.0.0",
    display_name = "Example step",
    outputs = list(item = port_type("work_item")),
    execute = function(context, config, inputs) list(item = context$item)
  )
)

ui <- fluidPage(capability_canvas_ui("workflow", registry))
server <- function(input, output, session) {
  capability_canvas_server("workflow", registry)
}
shinyApp(ui, server)
```

Hosts own domain vocabulary, capability catalogs, authentication, persistence policy, and deployment configuration. The public R API is documented in the generated help pages.

## Development

When browser source changes, rebuild the deterministic assets with:

```powershell
npm --prefix tools/javascript ci
npm --prefix tools/javascript run build
```

Validate with the package tests, a source-archive installation, and `R CMD check`.

## License

See [LICENSE](LICENSE). Bundled dependency attribution is recorded in `inst/docs/DEPENDENCY-LICENSES.md`.
