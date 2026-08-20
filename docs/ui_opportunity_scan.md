# Workstation UI Opportunity Scan

## Scope and Boundary

This scan inspected Analytics Workstation read-only at commit
`304c358615a97baae2ef09106ecbdfac108b63cb`. It does not propose moving domain
state or analytical behavior into `shinycapabilities`. The package should own
reusable interaction contracts; hosts continue to own data, permissions,
business semantics, persistence, and action consequences.

The scan found 236 `selectInput()` calls, 241 `textInput()` calls, 114
`numericInput()` calls, and 211 calls to the shared `render_table()` helper in
production R sources. Counts describe opportunity density, not automatic
replacement targets.

## Ranked Opportunities

| Rank | Priority | Current Workstation pattern | Friction or limitation | Proposed capability | UX benefit | Runtime benefit | Integration complexity | Reuse outside Workstation |
|---:|---|---|---|---|---|---|---|---|
| 1 | **Build now** | Project, evidence, artifact, and persisted-result browsers combine select controls, cards, and regenerated `renderUI()` detail panels. | Deep collections are difficult to scan; every level competes for page space; large collections create many DOM nodes or long selects. | **Virtualized hierarchical browser** with search, expansion, status/badges, keyboard navigation, and bounded metadata events. | One coherent object-navigation model with stable context and fast traversal. | Only visible rows render; expansion does not require thousands of DOM nodes. Client virtualization does not reduce the initial payload, so truly remote collections still need host-side paging later. | Medium | Very high: schemas, files, artifacts, model objects, evidence, jobs, and report trees. |
| 2 | **Build now** | Workflow Studio has a capability palette and many navigation/action controls; the catalog already exceeds one hundred insertable capabilities. | Users must remember where an action lives and visually traverse panels; ordinary selects do not unify navigation and action discovery. | **Virtualized command palette** with fuzzy-ish ranked search, groups, shortcuts, disabled states, and one activation event. | Keyboard-first discovery and activation without removing the visible UI. | Small virtual DOM for large action catalogs; local filtering avoids a Shiny round trip. | Medium | High: admin tools, analytical apps, project actions, and report builders. |
| 3 | **Strong candidate** | `page_analysis_modules.R` contains 58 select controls and large module-specific `renderUI()` blocks. Workflow inspectors also contain host-authored conditional JavaScript. | Parameter density, conditional visibility, validation, and help are difficult to keep consistent. | Schema-driven typed parameter workbench built on the existing `config_field()` contract and Selection System. | Searchable groups, dependency-aware visibility, inline validation, presets, and compact review. | Fewer repeated server-rendered UI fragments and input-binding churn. | High | Very high across modeling, forecasting, simulation, and optimization apps. |
| 4 | **Strong candidate** | Workflow panels use substantial page-local JavaScript for resizing, drawers, persistence, and responsive limits. | Pointer/keyboard behavior and layout persistence are expensive to reproduce and qualify. | Accessible split-pane primitive using `react-resizable-panels`. | Predictable resizing, collapse/reset, keyboard separator control, and responsive constraints. | Less host script and fewer mutation observers; runtime gains are secondary to reliability. | Medium | High for inspectors, code/results, table/details, and compare views. |
| 5 | **Strong candidate** | Code Runner uses ordinary text areas and separate output/history views. | Editing code, finding errors, and comparing reruns are constrained. | Code/value editor using CodeMirror 6, plus an optional read-only diff mode. | Syntax-aware editing, search, diagnostics, accessible keyboard commands, and structured selection. | Incremental document model performs better for long code than textarea replacement loops. | Medium-high | High for SQL, JSON, rules, formulas, and configuration. |
| 6 | **Strong candidate** | Project operations and Workflow Studio expose job status through cards, tables, and regenerated details. | Long-running and concurrent work is difficult to scan; logs and state transitions lack a single compact visual model. | Virtualized job monitor with state timeline, progress, cancellation affordance, and expandable logs. | Fast triage of running, blocked, warning, and failed work. | Bounded rendered log rows and throttled updates. | Medium-high | High for any asynchronous Shiny application. |
| 7 | **Strong candidate** | Provenance, evidence relationships, revisions, and task lineage are spread across tables and detail panels. | Relationship structure and change history require mental reconstruction. | Read-only lineage explorer using the already bundled React Flow for topology and a virtual tree/list for accessible fallback. | Direct navigation between evidence, computations, revisions, and findings. | Viewport rendering for large graphs; server remains the canonical graph authority. | High | High for pipelines, reports, governance, and reproducibility. |
| 8 | **Later** | Artifact comparisons and review details are rendered as bespoke HTML/tables. | Differences across revisions are difficult to localize. | Structured comparison viewer for text, JSON, tables, and artifact metadata. | Side-by-side or unified differences with changed-field navigation. | Can avoid rendering unchanged sections. | High | High for configuration, model, report, and governance review. |
| 9 | **Later** | Advanced report/layout ordering uses ordinary controls and host-authored interactions. | Reordering and placement become cumbersome for large plans. | Accessible sortable collection based on dnd-kit with complete keyboard parity and live announcements. | Direct manipulation without excluding keyboard or screen-reader users. | Limited; primarily capability gain. | High | Medium-high. |
| 10 | **Later** | Large JSON-like metadata is converted to tables or text blocks. | Nested values are hard to inspect and copy; full render is expensive. | Read-only JSON/object inspector, potentially using `vanilla-jsoneditor` after bundle and security review. | Expand/collapse, search, path copy, and value inspection. | Virtualized tree modes can handle large documents, but payload limits remain necessary. | Medium-high | High. |
| 11 | **Later** | Timelines are represented by tables and activity cards. | Sequence, overlap, duration, and causality cues are weak. | Virtualized event timeline with filters and linked detail. | Better temporal comprehension of jobs, evidence, and decisions. | Bounded viewport rendering. | High | Medium-high. |
| 12 | **Not worth replacing** | Shared `reactable` renderer supports ordinary analytical tables. | It lacks spreadsheet-grade editing and extreme-scale browser virtualization. | Keep `reactable` as the default. Evaluate AG Grid Community only for a separately contracted editable/very-large grid. | Avoids replacing a qualified, themed system for marginal gains. | Preserves the smaller existing runtime. | N/A | N/A. |
| 13 | **Not worth replacing** | Small scalar text, numeric, checkbox, and short select controls. | Minor visual differences only. | Keep native/base Shiny controls. | Familiar accessibility and predictable behavior. | Lowest overhead. | N/A | N/A. |
| 14 | **Not appropriate** | Graph editing already uses the package's qualified React Flow canvas. | A second graph engine would split event and state ownership. | Do not introduce Rete, Cytoscape, or a 3D graph editor for the same workflow contract. | Preserves one obvious interaction model. | Avoids duplicate bundles and state synchronization. | N/A | N/A. |

## JavaScript Ecosystem Assessment

The recommendation is deliberately selective. A library is valuable only when
its behavior is difficult to reproduce correctly and it fits Shiny's
server-authoritative event model.

| Category | Candidate | Maintenance/license | Performance and accessibility | Shiny/package fit | Recommendation |
|---|---|---|---|---|---|
| Virtualization | [TanStack Virtual](https://github.com/TanStack/virtual) | Active, MIT; already locked at 3.13.12. | Headless vertical/horizontal/grid virtualization; markup and ARIA remain package-owned. Approximately 10–15 KB according to its project documentation. | Excellent. Already bundled with the Selection System, so the new components add no dependency. | **Use now.** |
| Tree browser | [React Arborist](https://github.com/jameskerr/react-arborist) | MIT, feature-rich. Its dependency set includes React DnD, Redux, and react-window. | Virtualization, filtering, keyboard navigation, ARIA, rename, and drag/drop. | Useful when editing/reordering becomes necessary, but heavier and more opinionated than the read-only browser contract needed now. | **Do not bundle now.** Re-evaluate for an editable hierarchy. |
| Accessible combobox | [React Aria ComboBox](https://react-spectrum.adobe.com/react-aria/ComboBox.html) | Adobe-maintained, Apache-2.0 ecosystem. | Strong interaction and screen-reader behavior; supports descriptions and validation. | Good for a future typed editor, but broad React Aria adoption would add a second primitives layer beside existing package controls. | **Strong candidate**, not this checkpoint. |
| Command menu | [cmdk](https://github.com/dip/cmdk) | MIT and maintained. | Accessible semantics, but its own documentation notes no built-in virtualization and a practical range around 2,000–3,000 items. | Good API inspiration. Existing TanStack Virtual plus a bounded package contract is a better fit for catalogs beyond that range. | **Do not bundle now.** |
| Popovers/tooltips | [Floating UI](https://github.com/floating-ui/floating-ui) | Active, MIT; DOM package already bundled. | Collision-aware positioning, modular and tree-shakeable. | Excellent and already available for future contextual details. | **Use existing dependency when needed.** |
| Split panes | [react-resizable-panels](https://github.com/bvaughn/react-resizable-panels) | Active, MIT. | WAI-ARIA separators and keyboard resizing; touch hit-target guidance. | Clean React wrapper and bundle candidate; materially better than repeated host-local resize scripts. | **Strong candidate next.** |
| Drag/drop | [dnd-kit](https://docs.dndkit.com/guides/accessibility) | MIT ecosystem. | Keyboard sensors, customizable screen-reader instructions, and live-region announcements. Accessibility still requires domain-specific wording and QA. | Appropriate for a future sortable-plan contract, not generic graph state. | **Later.** |
| Data grid | [AG Grid Community](https://www.ag-grid.com/javascript-data-grid/community-vs-enterprise/) | Active, Community core is MIT; advanced features cross into a paid edition. | Excellent virtualization and keyboard support, with documented screen-reader tradeoffs when virtualization remains enabled. | Large bundle and API surface. It should not replace the shared report-table framework. | **Specialized later option only.** |
| Headless data table | [TanStack Table](https://tanstack.com/table/latest/docs/framework/react/guide/virtualization) | Active, MIT. | Flexible row models; pairs with TanStack Virtual. Accessibility markup is implementer-owned. | Attractive for a narrowly scoped virtual data browser, but would duplicate existing table behavior if adopted broadly. | **Later, only with a distinct contract.** |
| Code/value editing | [CodeMirror 6](https://codemirror.com/) | Active, MIT. | Modular editor with documented accessibility support and incremental state. | Strong fit for Code Runner, SQL, and JSON text modes; package must bundle only required language modules. | **Strong candidate.** |
| JSON inspection | [vanilla-jsoneditor](https://github.com/josdejong/svelte-jsoneditor) | Active, ISC. | Tree/text/table modes, search, schema validation, and large-document support. Standalone bundle includes substantial dependencies; optional query languages can execute JavaScript and must remain excluded. | Useful as a read-only bounded inspector after bundle/security evaluation. | **Later.** |
| Graph/network | [React Flow](https://reactflow.dev/) | Active, MIT; already bundled. | Viewport rendering and established package interaction contract. | Canonical choice for workflow and future lineage topology. | **Reuse; do not add another graph engine.** |

## Implemented Components

### `virtual_tree_browser()`

Purpose: inspect large host-owned hierarchies without transferring domain logic
or creating a second canonical state authority.

Minimal record contract:

```r
list(
  id = "artifact-1",
  parent_id = "report-1",
  label = "Feature Importance",
  description = "Plot · Model Insights",
  badge = "plot",
  status = "Ready",
  disabled = FALSE,
  metadata = list(artifact_id = "artifact-1")
)
```

Shiny events:

| Input | Trigger | Payload |
|---|---|---|
| `<outputId>_selection` | Click or Space | `id`, `label`, `path`, bounded `metadata`, `nonce` |
| `<outputId>_activate` | Double click or Enter | Same as selection |
| `<outputId>_toggle` | Expand/collapse | `id`, `label`, `expanded`, bounded `metadata`, `nonce` |

Keyboard contract: Up/Down changes the active row; Right expands or enters the
first child; Left collapses or returns to the parent; Home/End move to bounds;
Space selects; Enter activates. The DOM uses `tree`/`treeitem`, roving focus,
`aria-level`, `aria-selected`, `aria-expanded`, and `aria-disabled`.

### `command_palette()`

Purpose: discover and trigger host-defined commands from a large catalog. The
component reports intent only; it never executes host behavior.

Minimal item contract:

```r
list(
  id = "run-eda",
  label = "Run Exploratory Data Analysis",
  group = "Analyze",
  description = "Generate EDA artifacts",
  keywords = c("profile", "autoquant"),
  shortcut = "Ctrl R",
  disabled = FALSE,
  metadata = list(capability_id = "autoquant_eda")
)
```

Shiny events:

| Input | Trigger | Payload |
|---|---|---|
| `<outputId>_command` | Click or Enter | `id`, `label`, `group`, query, bounded `metadata`, `nonce` |
| `<outputId>_query` | Query change when `server_search = TRUE` | query and nonce |

Keyboard contract: Ctrl/Cmd+K focuses the palette while mounted; Up/Down,
Home/End navigate; Enter activates; Escape clears and leaves the field. The
field uses combobox/listbox semantics and `aria-activedescendant`.

## Future Migration Seams

No migration is part of this checkpoint.

| Workstation surface | Existing component | Candidate component | Compatible input | Changed output | Expected gain | Migration risk |
|---|---|---|---|---|---|---|
| Project persisted-result and operation browsers | Select + `renderUI()` cards/tables | `virtual_tree_browser()` | Existing IDs, labels, statuses, and summaries map directly to node records. | One structured selection/activation event replaces select value plus card-action observers. | Persistent hierarchy, search, virtualization, keyboard traversal. | Medium: preserve durable selection and route semantics. |
| Artifact Library collection/run navigation | Filter selects + gallery + inspector | Tree browser as optional collection navigator; gallery remains primary visual inventory. | Artifact index already has IDs, collection, run, type, status, and metadata. | Tree selection drives the existing selected-artifact reactive. | Faster traversal of large projects without removing visual cards. | Low-medium: avoid competing selection authorities. |
| Dataset/schema selection | Base selects and generated controls | Tree browser for dataset → table → field exploration; existing Selection System remains the actual field picker. | Dataset/table/column IDs and type summaries. | Tree activation chooses context; selected fields still use the existing input contract. | Better hierarchy and column context at scale. | Low if kept read-only. |
| Workflow capability discovery | Existing visible palette | Command palette as an augmenting search/action surface. | Capability IDs, labels, categories, descriptions, disabled/permission state. | Command event routes through the existing host insertion/command authority. | Keyboard discovery across a large catalog. | Medium: exactly-once command routing and permission checks must remain host-owned. |
| Global navigation and project actions | Buttons, menus, and route-specific controls | Command palette with host-defined routes/actions. | Stable command IDs and labels. | Structured intent event rather than direct execution. | One discoverable keyboard surface. | Medium-high: command availability, focus scope, and confirmation policy. |

## Qualification and Limitations

- Both components render only visible rows through the existing TanStack
  Virtual runtime.
- Both are host-neutral and publish bounded intent payloads. They do not accept
  executable JavaScript, arbitrary R code, fitted models, or full datasets.
- Package installation remains Node-free because built JS/CSS is included under
  `inst/htmlwidgets/lib`; Node/npm are development-only rebuild tools.
- Virtualization limits DOM cost, not browser payload size. Remote paging and
  incremental loading require a separate future server contract.
- Fuzzy ranking is intentionally conservative and deterministic. It is not an
  opaque relevance model.
- The command palette is an augmenting control, not an authorization boundary.
  Hosts must validate every received command.
- The tree is read-only. Editing, reparenting, and drag/drop are intentionally
  outside this first contract.

Run the standalone demo after installing or loading the package:

```r
shinycapabilities::run_interaction_components_demo()
```
