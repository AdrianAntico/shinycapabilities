# shinycapabilities architecture

## Purpose

`shinycapabilities` is a generic capability-oriented workflow framework for
Shiny. It provides a typed graph editor, deterministic planning contracts,
governed execution lifecycle, and artifact references. Host applications own
domain-specific analytical capabilities and their data.

## Authority boundaries

- React Flow owns graph presentation and browser interaction: selection, drag,
  resize, connection gestures, pan, zoom, minimap, and fit-to-view.
- R/Shiny owns capability registration, typed-port validation, dependency
  planning, scheduling, execution, caching, staleness, cancellation, and
  artifacts.
- JavaScript never receives full datasets, fitted models, credentials,
  arbitrary R objects, executable payloads, or generic opaque passthrough.
- AI-proposed nodes remain non-executable until accepted by the host.
- Saved workflow documents contain no process handles or transient runtime
  state.
- Background execution exposes artifacts only after successful completion.
- Public graph, port, operation, proposal, and serialization contracts require
  compatibility review and migrations for breaking changes.
- Bundled browser assets must be reproducible from locked source dependencies
  and properly attributed.

## Repository map

- `R/`: public contracts, graph/document normalization, planning, runtime,
  proposals, composition, Shiny module, and widget binding.
- `tools/javascript/src/`: authored React Flow bridge and presentation source.
- `tools/javascript/package*.json`: reproducible JavaScript dependency graph.
- `inst/htmlwidgets/`: generated production JavaScript/CSS shipped to users.
- `inst/examples/`: installed demonstration application.
- `inst/docs/`: installed architecture and dependency-attribution notes.
- `man/`, `NAMESPACE`: generated from R documentation.
- `tests/testthat/`: contract, runtime, graph, and presentation tests.
- `.github/`: collaboration templates and continuous integration.

## Data and control flow

1. A host registers closed capability definitions and typed ports in R.
2. R sends presentation-safe capability metadata and a normalized graph to the
   widget.
3. React Flow handles local interaction and emits bounded boundary events.
4. R validates graph mutations and typed connections before accepting them.
5. R plans the transitive dependency closure and deterministic execution order.
6. The runtime schedules only accepted, valid capabilities and owns process
   lifecycle, cache signatures, cancellation, failure, and staleness.
7. Successful work returns typed artifact references. Partial or failed
   background output is not registered.
8. Serialization persists governed graph and output-placement state, never
   transient process state.

## Distribution

Installed users consume tracked assets in `inst/htmlwidgets/lib` and do not need
Node.js. Maintainers rebuild those assets with `npm ci && npm run build` from
`tools/javascript`. Bundle changes must have corresponding source or lockfile
changes and pass the drift check in CI.
