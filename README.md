# shinycapabilities

`shinycapabilities` is a private alpha R package for composing governed,
executable capability workflows in Shiny. It combines a React Flow graph editor
with R-owned typed contracts, dependency planning, scheduling, caching,
staleness, cancellation, proposals, composites, and artifact placement.

The package is deliberately generic. Host applications register their own
analytical, research, decision, or delivery capabilities; host logic and private
data do not belong in this repository.

## Why R owns execution

JavaScript owns smooth browser interaction: graph presentation, selection,
dragging, resizing, connection gestures, pan, zoom, minimap, and fit-to-view.
R/Shiny remains authoritative for registration, validation, typed connections,
dependency closure, execution, lifecycle, caching, cancellation, and artifacts.
The browser never needs full datasets, fitted models, credentials, arbitrary R
objects, or executable node payloads.

## Features

- Closed capability registration and configuration contracts.
- Typed input/output ports and R-validated connections.
- Deterministic graph normalization, fingerprints, and dependency-aware plans.
- Inline, planning-only, network, and supervised background-R profiles.
- Progress, failure, timeout, cancellation, cache, and staleness lifecycle.
- Human acceptance of bounded AI workflow proposals before execution.
- Collapsible composites with deterministic expansion for planning.
- Renderer-independent secondary artifact placement.
- Serializable workflow documents without process handles or runtime state.
- Responsive, searchable, accessible capability palette and Shiny inspector.

## Installation

The repository is private. Authenticate GitHub access before installing:

```r
pak::pak("AdrianAntico/shinycapabilities")
```

Alternatively, clone the repository and install the local source package:

```r
pak::pkg_install("path/to/shinycapabilities")
```

Installed users do not need Node.js. Production JavaScript and CSS are bundled
in the R package.

## Minimal Shiny application

```r
library(shiny)
library(shinycapabilities)

registry <- default_capability_catalog()

ui <- fluidPage(
  capability_canvas_ui("workflow", registry, height = "680px")
)

server <- function(input, output, session) {
  capability_canvas_server("workflow", registry)
}

shinyApp(ui, server)
```

Run the installed demonstration with:

```r
shinycapabilities::run_capability_demo()
```

## Register a host capability

```r
profile <- register_capability(
  id = "example.profile",
  version = "1.0.0",
  display_name = "Profile data",
  description = "Create a bounded profile artifact.",
  category = "Explore",
  inputs = list(dataset = port_type("dataset")),
  outputs = list(profile = port_type("data_profile")),
  config = list(
    include_missingness = config_field(
      "checkbox", "Include missingness", default = TRUE
    )
  ),
  validate = function(context, config, inputs) {
    list(valid = !is.null(inputs$dataset))
  },
  execute = function(context, config, inputs) {
    list(profile = summary(inputs$dataset))
  },
  implementation_fingerprint = "example-profile-v1"
)

registry <- capability_registry()
capability_registry_add(registry, profile)
```

Hosts may provide custom Shiny configuration UI/server hooks. Typed connection
acceptance remains R-owned.

## Execution and cancellation

`plan_workflow()` computes the transitive upstream closure and deterministic
topological order. Signatures include configuration, capability version,
implementation fingerprint, and dependency signatures. Current successful cache
entries may be reused.

`workflow_runtime()` and `tick_workflow_runtime()` provide non-blocking lifecycle
management. Supervised background R work uses owned `callr` processes. Failed,
cancelled, crashed, or timed-out work does not register partial artifacts.

## Proposals, composites, and artifacts

`workflow_proposal()` ingests a bounded proposed graph. Nothing becomes
executable until the host calls `accept_workflow_proposal()`.

`collapse_workflow()` and `expand_workflow_composite()` preserve internal graph
structure while presenting a composite node. Planning expands composites before
validation and execution.

`workflow_document()` stores the normalized graph separately from secondary
`output_placements`, so arranging artifacts does not mutate analytical workflow
semantics.

## Development

Rebuild browser assets reproducibly:

```powershell
npm --prefix tools/javascript ci
npm --prefix tools/javascript run build
```

Regenerate R documentation and validate:

```powershell
Rscript -e "roxygen2::roxygenise('.', roclets = c('rd', 'namespace'))"
Rscript -e "devtools::test()"
R CMD build .
R CMD check shinycapabilities_0.1.0.tar.gz
```

See [ARCHITECTURE.md](ARCHITECTURE.md), [CONTRIBUTING.md](CONTRIBUTING.md), and
`inst/docs/DEPENDENCY-LICENSES.md`.

## Alpha limitations

- Public contracts are alpha and may evolve only through compatibility review.
- Hosts own authentication, authorization, persistence, deployment hardening,
  domain validation, and durable artifact storage.
- Formula fields are text inputs; hosts must use bounded expression parsers.
- Persistent run history and distributed scheduling are host concerns.
- Provider execution for AI proposals remains host-owned.
- The package has not received production security certification.

## License and attribution

`shinycapabilities` is licensed under the MIT license. Bundled React Flow, React,
and related dependency attribution is documented in
`inst/docs/DEPENDENCY-LICENSES.md`.
