# Analytics Workstation: shinycapabilities UI Handoff

## Status

The next-generation browser UI program is developed and qualified independently in:

- Repository: `C:/Users/Bizon/Documents/GitHub/shinycapabilities-lab`
- Branch: `codex/capability-lab`

The protected `shinycapabilities` checkout, installed Workstation package, and
Analytics Workstation have not been modified by this program.

## Architectural Direction

The target division of responsibility is:

> **Shiny owns session, reactivity, and server authority.**
>
> **shinycapabilities owns the user-facing browser UI platform.**

Choose the best browser implementation for each capability class. Replace
Shiny-style UI and wrapper packages where a browser-native alternative improves
performance, usability, accessibility, or deployment. Maintain one consistent
interaction language across the product.

Do not introduce new visible stock Shiny controls when an appropriate
`shinycapabilities` primitive exists.

## Ownership and Integration Boundary

- Grok owns Analytics Workstation integration and promotion decisions.
- Codex owns isolated invention and qualification in `shinycapabilities-lab`.
- Workstation remains the authority for business state, governance, execution,
  permissions, and workflow semantics.
- Browser components render host-supplied state and emit bounded user intents.
- Work in the lab is never permission to edit Workstation.

The standing delivery loop is:

1. Grok discovers a reusable UI gap.
2. The gap becomes a bounded component requirement.
3. Codex implements and qualifies it in `shinycapabilities-lab`.
4. Promotion Readiness documents its contracts and risks.
5. Grok selectively integrates or promotes it.

## Browser Infrastructure

### Direct Component Transport

Direct Component Transport replaces `htmlwidgets` and provides:

- Shiny output bindings
- revisioned updates and stale-revision rejection
- bounded browser-to-Shiny events
- namespacing
- mount, resize, unmount, teardown, and remount behavior
- multiple independent instances
- static HTML support

See [Direct Component Transport 1.0](direct_component_transport_1_0.md).

### Shared Browser Runtime

One versioned runtime supplies React 19.2.8, ReactDOM, and TanStack Virtual to
ordinary React components. Large specialized engines remain independently
lazy-loaded.

Representative ordinary React payloads were reduced from approximately 1.30 MB
to 313 KB raw and from 404 KB to 102 KB gzip.

See [Shared Browser Runtime 1.0](shared_browser_runtime_1_0.md).

### Persistent Dynamic UI

Persistent Dynamic UI is the bounded browser-owned alternative for appropriate
high-churn `uiOutput()` and `renderUI()` projections:

- `persistent_ui()`
- `persistent_ui_output()`
- `render_persistent_ui()`
- `update_persistent_ui()`

It preserves focus, drafts, scroll position, selection, and collapsed state.
Purpose-built components remain preferable when a specialized interaction model
exists.

See [Persistent Dynamic UI 1.0](persistent_dynamic_ui_1_0.md).

## Qualified User-Facing Capabilities

### Foundational Browser Controls

Browser-native controls cover text, numeric and secret fields, multiline text,
checkboxes, switches, radio groups, segmented controls, sliders, action buttons,
action links, values, statuses, progress, alerts, and loading skeletons.

Visible stock controls should migrate to the corresponding browser primitive.
See the [UI elimination program](zero_visible_stock_shiny_program.md).

### Selection System

The qualified selection system provides virtualization, grouping, search,
server search, ordered selection, stale-value handling, keyboard navigation, and
dirty/applied state. Use it instead of new `selectInput()` or `shinyWidgets`
surfaces.

### AG Grid Data Grid

AG Grid Community 36.1.0 is the dense analytical grid. It supports typed
filtering, virtualization, sorting, resizing, reordering, visibility, pinning,
selection, keyboard navigation, deterministic row identity, and bounded events.
It is qualified at 100,000 rows.

Use it for inventories, previews, artifact libraries, and histories. Use semantic
HTML for small static or report tables.

See [AG Grid Data Grid 1.0](data_grid_1_0.md).

### Monaco Editor

Monaco 0.56.0 is the single serious editor platform for R, Julia, Python, SQL,
JSON, YAML, Markdown, and diffs. It supports diagnostics, bounded completions,
dirty state, conflict-safe updates, search, multi-cursor editing, and undo/redo.
It is lazy-loaded. Workstation Code Runner remains execution authority.

See [Monaco Editor 1.0](monaco_editor_1_0.md).

### Typed Parameter Workbench

The schema-driven workbench owns dense analytical configuration with sections,
search, validation, conditional fields, dirty/applied state, Apply/Reset, and
conflict-safe updates. Prefer it over large generated collections of individual
Shiny inputs.

See [Typed Parameter Workbench 1.0](parameter_workbench_1_0.md).

### Virtual Tree and Structured Object Inspector

Use the virtual tree for hierarchical navigation and the object inspector for
persistent, read-only exploration of nested analytical objects. The inspector is
qualified at 10,000 and 50,000 nodes while mounting approximately 25 DOM rows.

See [Structured Object Inspector 1.0](structured_object_inspector_1_0.md).

### Accessible Split Pane

The split-pane system supports horizontal and vertical layouts, nested panes,
constraints, collapse, keyboard resizing, reset, and programmatic updates. Use it
for workspace composition rather than page-specific resize scripts.

See [Accessible Split Pane 1.0](split_pane_1_0.md).

### Command Palette

The virtualized command palette provides deterministic search, Ctrl/Cmd+K,
keyboard navigation, disabled commands, server search, and structured command
intents. Use it for dense action and capability discovery.

### Relationship Graph

The generic XYFlow-backed graph supports typed nodes and edges, Dagre layout,
cycles, disconnected graphs, filtering, neighborhood focus, pan/zoom, minimap,
inspection, and an accessible structured fallback. Reuse it across lineage,
provenance, evidence, workflow, model, artifact, agent, and report relationships.

See [Relationship Graph 1.0](relationship_graph_1_0.md).

### Agent Activity Monitor

The monitor is a read-only operational projection with overview, virtualized
activity feed, attention/review surface, inspection, dependency representation,
bounded history, live updates, and recursive redaction. It does not execute,
retry, approve, cancel, delegate, or expose private reasoning.

See [Agent Activity Monitor 1.0](agent_activity_monitor_1_0.md).

### Execution Replay

Execution Replay provides a virtualized historical timeline, state-at-time,
structured changes, artifacts, evidence, failures, retries, interventions,
filtering, and live append without losing historical position. It is qualified
with 5,000-event histories while mounting approximately 33 rows. It never
re-executes work.

See [Execution Replay 1.0](execution_replay_1_0.md).

## Dependency Direction

`htmlwidgets` has been eliminated from the lab package. Current R runtime
dependencies are:

- `shiny`
- `htmltools`
- `jsonlite`
- `callr`
- `digest`

Future Workstation migration should target removal of `shinyWidgets`, `reactable`,
and `reactR` after replacement coverage and installed-application qualification
are complete.

Do not add R wrapper packages around browser libraries when
`shinycapabilities` can own the direct browser integration cleanly.

## Remaining Capability Gaps

The following browser-native capability classes still require implementation or
qualification:

- overlays, popovers, tooltips, and context menus
- modal, dialog, drawer, and sheet surfaces
- notification center and toast queue
- navigation primitives where Workstation requires replacement
- enhanced file upload and drop presentation
- download and action presentation
- output shells, fullscreen, and spotlight presentation
- reusable Report Studio capabilities discovered during integration

These gaps do not block migration of already qualified surfaces.

## Workstation Migration Evidence

Read-only Workstation archaeology found approximately:

| Stock surface | Observed calls |
|---|---:|
| `selectInput()` | 243 |
| `actionButton()` | 358 |
| `textInput()` | 242 |
| `numericInput()` | 114 |
| `uiOutput()` | 384 |

The largest modernization concentrations include Workflow Studio, Causal
Intelligence, Analysis Modules, Product Experience, Semantic Intelligence, and
Project.

The machine-readable migration evidence is maintained in
[workstation_ui_migration_matrix.csv](workstation_ui_migration_matrix.csv).

## Migration Rules

1. Introduce no new visible stock Shiny UI.
2. Use the mapped `shinycapabilities` primitive when coverage exists.
3. Prefer best-in-class browser components over Shiny/R wrapper packages.
4. Use Persistent Dynamic UI only for appropriate bounded, high-churn projections.
5. Prefer purpose-built components over generic dynamic UI.
6. Preserve Workstation server authority and governance.
7. Emit bounded intents; do not move business execution into browser components.
8. Choose the correct interaction model rather than substituting controls blindly.
9. Perform explicit composition and visual-system QA after functional migration.
10. Remove obsolete dependencies only after replacement and installed-app QA pass.

## Product Target

The destination is not a heavily customized Shiny application. It is a
state-of-the-art analytical and AI application whose browser UI is owned by
`shinycapabilities`, with Shiny effectively invisible as the reactive server
runtime.
