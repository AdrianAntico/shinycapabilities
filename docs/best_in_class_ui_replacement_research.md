# Best-in-Class UI Replacement Research

Date: 2026-08-20
Scope: `shinycapabilities-lab` and read-only Analytics Workstation inspection

## Executive decision

The best future stack is not one widget library. It is a deliberately small
set of browser engines behind `shinycapabilities` contracts:

1. **React Aria Components** for semantic input and overlay behavior;
2. **TanStack Virtual** for package-owned high-scale lists and feeds;
3. **AG Grid Community** for dense analytical grids;
4. **Monaco Editor** for serious code editing and diff;
5. **XYFlow** for editable/node-centric topology and **Cytoscape.js** only for
   large analytical networks;
6. **react-resizable-panels** for simple splits and **FlexLayout** only when a
   real dockable-workspace requirement exists;
7. **Floating UI** for positioning package-owned overlays; and
8. focused custom components for Workstation-specific projections such as
   activity, replay, review, and report navigation.

All assets can be compiled during package development and shipped under
`inst/`; package installation and use do not require Node.js. R remains the
authority for data, permissions, persistence, and action consequences. Browser
components own interaction state and emit bounded intents through Direct
Component Transport and Shared Browser Runtime.

## Decision rules

- Prefer a mature engine when virtualization, editing, graph geometry, focus,
  or accessibility behavior is costly to reproduce correctly.
- Prefer a custom component when the difficult part is the product's data
  projection rather than a generic interaction kernel.
- Do not add a broad design system. Share behavior primitives and CSS tokens,
  while keeping host-neutral markup in `shinycapabilities`.
- Preserve base Shiny controls for small, ordinary forms. Replacement must
  improve scale, interaction quality, or dependency/runtime cost materially.
- No component executes work directly. It emits selections or user intents;
  the host validates and performs them.

## Component-class comparison matrix

| Component class | Current/baseline | Best candidate | Serious alternatives | Decision | Why | Dependency impact |
|---|---|---|---|---|---|---|
| Single select / combobox | Base `selectInput()`; Selection System for advanced use | **React Aria ComboBox/Select behavior**, styled and transported by the package | Ariakit; current custom Selection System | **Prototype** | React Aria supplies mature keyboard, focus, validation, collection, and screen-reader semantics. Preserve the current event contract during a shootout. | Can remove `shinyWidgets`; avoids adding another R selector package. |
| Multi-select | Selection System | **Keep current contract**, replace internal semantics with React Aria only if QA proves a gain | React Aria ListBox/ComboBox; Ariakit | **Keep current / Prototype kernel** | Ordered values, stale selections, server search, and bounded Shiny events are already product-fit. Mature primitives may improve edge-case accessibility without changing the API. | Continues the path away from `shinyWidgets`. |
| Large virtualized selector | Selection System + TanStack Virtual | **Selection System + TanStack Virtual** | React Aria Virtualizer; custom remote-paging listbox | **Keep current** | The lab already owns the required high-cardinality contract and TanStack Virtual renders only the viewport while leaving markup under package control. | Removes `shinyWidgets`; no new R layer. |
| Analytical data grid | AG Grid Data Grid; Workstation mostly `reactable` | **AG Grid Community** | TanStack Table + Virtual; Glide Data Grid for canvas-scale read-mostly data | **Use** | Best overall qualified combination of row/column virtualization, typed filtering, selection, editing, keyboard navigation, theming, and framework support. Community is MIT, but grouping, Excel export, and other Enterprise features must remain out of the contract. | Can replace `reactable` + `reactR` for demanding grids; use semantic HTML for small report tables. |
| Hierarchical tree/object browser | Virtual Tree Browser + TanStack Virtual | **Keep current** for read-only hierarchy | React Arborist for editable trees; React Aria Tree | **Keep current** | Current component is lighter, host-authoritative, virtualized, and has explicit keyboard/tree semantics. React Arborist becomes worthwhile only for rename/reparent/drag editing. | Avoids an R tree package and React Arborist's extra state/drag stack. |
| Structured object / JSON inspector | Tree/browser and bespoke detail surfaces | **vanilla-jsoneditor** for editable/large JSON; custom Virtual Tree composition for bounded read-only metadata | Monaco JSON mode; react-json-view-lite | **Prototype** | It offers tree, text, and table modes, search, repair, schema validation, theming, and large-document handling from a framework-neutral bundle. Its substantial standalone dependencies and edit authority require a security/bundle shootout. | Avoids an R JSON-widget package and many nested `renderUI()` inspectors. |
| Command palette | Custom virtualized Command Palette | **Keep current** | `cmdk`; React Aria ComboBox | **Keep current** | Host command IDs, disabled/permission state, server search, virtualization, and bounded activation are already first-class. `cmdk` lacks built-in virtualization and would not improve the contract materially. | Avoids command-menu R packages and repeated server-rendered action lists. |
| Parameter/form editor | Typed Parameter Workbench | **Keep current contract**, adopt React Aria field kernels incrementally | JSON Forms; react-jsonschema-form | **Keep current** | The differentiator is typed analytical schemas, drafts, validation, conditional fields, and apply/reset authority. Generic JSON-schema form engines add abstraction and styling weight without matching those semantics. | Replaces dense `renderUI()` trees and many individual Shiny input messages; does not remove core Shiny. |
| General code/value editor | Textareas | **Monaco Editor** | CodeMirror 6; Ace | **Prototype** | Monaco provides models, URI identity, editor/diff surfaces, command palette, completion/diagnostic extension points, and the strongest workstation-class experience. Bundle and worker setup are the cost. | Avoids `shinyAce`, `shinyMonaco`, and their htmlwidget wrappers. |
| SQL editor | Textareas | **Monaco + SQL language service adapter** | CodeMirror 6 SQL; `@sqlrooms/sql-editor` if its larger stack is accepted | **Prototype** | Monaco tokenizes SQL and provides completion/diagnostic hooks. Dialect-aware intelligence must come from host metadata or a separately bundled language service. | Same direct editor transport; no R editor package. |
| R editor | Textareas | **Monaco + R tokenizer**, with optional future language-server bridge | CodeMirror 6 plus a maintained R grammar; Tree-sitter grammar | **Prototype** | Monaco includes R/Rmd basic language support. Completion and diagnostics are not implied by highlighting and should be supplied only by a governed R language-service seam. | Avoids an R-specific editor widget; one editor contract across Code Runner languages. |
| Julia editor | Textareas | **Monaco + Julia tokenizer**, optional future language-server bridge | CodeMirror 6 + Julia legacy/StreamLanguage grammar; Tree-sitter Julia | **Prototype** | Monaco's basic-language set includes Julia. It is the least-fragmented route to consistent R/Julia/Python/SQL UX; semantic intelligence remains a separate service. | Avoids a Julia-specific wrapper and a second editor engine. |
| Python editor | Textareas | **Monaco**, optionally connected to Pyright-compatible diagnostics later | CodeMirror 6 Python; embedded Jupyter editor stack | **Use after prototype** | Strong built-in Python tokenization and mature completion/diagnostic interfaces. Do not bundle a notebook system for a code field. | One direct editor replaces future R wrappers. |
| JSON/YAML editor | Textareas / typed fields | **Monaco** for full documents; Typed Workbench or CodeMirror 6 for compact embedded values | vanilla-jsoneditor for structural JSON | **Needs requirement before choosing** | Full documents benefit from schema diagnostics and diff; small values do not justify Monaco's runtime. YAML schema validation needs a language-service adapter. | Avoids separate JSON/YAML R widgets; reuses editor runtime when loaded. |
| Markdown editor | Textareas | **CodeMirror 6** for embedded authoring; Monaco when already mounted in a code workspace | Milkdown for rich Markdown | **Needs requirement before choosing** | Markdown authoring values lightweight editing and extension modularity more than IDE behavior. Rich WYSIWYG is a separate requirement, not a default. | Avoids a rich-text dependency until genuinely required. |
| Split panes | Split Pane 1.0 | **react-resizable-panels** | Split.js; native CSS resize for one simple edge | **Keep current** | Active, MIT, no runtime dependencies, nested groups, imperative sizing, pointer/touch, and separator semantics. Current lab wrapper already provides the right host-neutral contract. | Avoids split-pane R packages and host-local pointer code. |
| Dockable layouts | Not implemented | **FlexLayout (`flexlayout-react`)** | Lumino DockPanel; Golden Layout | **Needs requirement before choosing** | FlexLayout provides draggable/resizable tabsets, serialization, overflow, and React-only runtime. It is too stateful to add before Workstation has a governed persisted-layout contract. | Could avoid future R dashboard/layout packages, but adds a meaningful JS/state surface. |
| Tabs / accordions | Base Shiny/HTML | **Native HTML + React Aria behavior where dynamic** | Radix Primitives; base Shiny | **Keep current** | Ordinary tabs/disclosures are solved; replacement gives little dependency or runtime benefit. Use shared primitives only inside direct components. | None; do not replace stable Shiny for ideology. |
| Dialogs / drawers / sheets | `modalDialog()` and custom detail surfaces | **React Aria Dialog/Modal behavior** with package-owned styling | native `<dialog>`; Radix Dialog | **Prototype** | Focus containment, dismissal, labeling, and nested overlays are hard. Native dialog is attractive for simple modals, but drawers and composed overlays need a shared contract. | Reduces repeated `renderUI()`/modal glue; core Shiny remains. |
| Popovers / tooltips | Ad hoc; Floating UI already bundled | **Floating UI positioning + React Aria interaction semantics** | native Popover API; Radix Popover/Tooltip | **Use** | Floating UI is modular, framework-neutral, collision aware, and already in the asset graph. React Aria supplies semantics; native popovers can be used for simple non-modal cases. | Avoids tooltip/popover R packages and redundant JS engines. |
| Context menus | Bespoke buttons/menus | **React Aria Menu behavior + Floating UI** | Radix Context Menu; custom native menu pattern | **Prototype** | Keyboard navigation, typeahead, submenu focus, dismissal, and positioning are not good custom-code targets. | Avoids future menu packages and repeated observers. |
| Notification/toast center | `showNotification()` | **Lightweight custom Notification Center using React Aria Toast semantics/live regions** | Sonner; React Hot Toast | **Custom build** | Queueing, dedupe, severity, history, bounded memory, and host acknowledgment are product contracts. A small implementation is preferable to adopting a styled toast library; urgent actions still require dialogs, not disappearing toast. | Replaces many server-created notifications and avoids a toast R dependency. |
| Drag/drop and sortable lists | Limited bespoke behavior | **Atlassian Pragmatic Drag and Drop** | dnd-kit; native DnD | **Prototype** | Framework-agnostic, small core, virtualization support, touch support, and optional assistive controls. Accessibility still requires visible non-drag alternatives and live announcements. | Avoids sortable/drag R wrappers; adds only selected JS modules. |
| Graph/network visualization | Relationship Graph / workflow canvas on XYFlow | **XYFlow for interactive node workflows and medium topology** | Cytoscape.js for large network analysis; Sigma.js for very large WebGL networks | **Keep current, add second engine only by contract** | XYFlow is active, MIT, keyboard-aware, customizable, and optimized for node UI. It is not the universal answer for tens of thousands of analytical graph elements. | Avoids `visNetwork`/`DiagrammeR` for interactive workflow/provenance UI. |
| Provenance/lineage graph | Relationship Graph | **XYFlow + accessible list/table projection** | Cytoscape.js + ELK; custom tree for acyclic lineage | **Keep current** | Provenance is generally a bounded, interactive node/edge inspection problem. The accessible textual equivalent is mandatory and remains the navigation authority for screen-reader users. | Same graph runtime; no new R graph widget. |
| Timelines / execution replay | Execution Replay 1.0 | **Keep custom Execution Replay**, backed by TanStack Virtual | vis-timeline for calendar-scale scheduling; Plotly/AutoPlots for analytical durations | **Keep current** | Replay's hard problem is deterministic event projection, temporal controls, bounded history, and provenance, not generic chart rendering. | Replaces log tables and detail `renderUI()` without adding a timeline R package. |
| Agent/job activity monitor | Agent Activity Monitor 1.0 | **Keep custom monitor** | AG Grid + inspector composition; generic observability dashboard | **Keep current** | Its value is normalized governed activity, attention precedence, redaction, and bounded host events. A generic library cannot own those semantics. | Replaces repeated cards/progress feeds; no extra R package. |
| Progress/status surfaces | Base progress/notifications and monitor | **Custom semantic primitives** (`progress`, status badge, bounded log) | React Aria ProgressBar/Meter | **Custom build** | Small, easy to render accessibly, and tightly tied to supplied telemetry. Never fabricate ETA or percent. | Reduces repeated UI fragments; no new dependency. |
| Diff/comparison viewer | Bespoke detail/table comparisons | **Monaco Diff Editor** for text/code; custom typed structural diff for metadata/tables | `diff2html`; vanilla-jsoneditor patch view | **Prototype** | No one representation fits code, JSON, tabular, and artifact differences. Reuse Monaco for text and create a typed summary contract for non-text changes. | Avoids an R diff widget and repeated server-rendered comparisons. |
| Review/approval controls | Bespoke actions | **Custom Review Surface built from semantic buttons, dialog, evidence links, and immutable intent events** | React Aria primitives; AG Grid for queue inventory | **Custom build** | Review is governance, not a generic widget. The component should display evidence and emit approve/reject/request-change intent; the host owns policy and mutation. | Consolidates repeated controls, but removes no core dependency. |
| File/object explorer | Selects, tables, Virtual Tree | **Composition: Virtual Tree + AG Grid + Split Pane** | React Arborist; FilePond only for uploads | **Custom composition** | A filesystem-like browser is three capabilities: hierarchy, item list, and inspector. Existing lab primitives cover them without granting browser code filesystem authority. | Avoids a file-browser R package and nested detail UI. |
| Date/time/range input | Sparse base controls | **React Aria DatePicker/DateRangePicker** only when timezone/calendar semantics are required | native date/time inputs; flatpickr | **Needs requirement before choosing** | React Aria handles locale, segments, calendar systems, keyboard, and validation through `@internationalized/date`. Native fields remain smaller for simple dates. | Avoids `shinyWidgets`/date-range packages if advanced dates arrive. |
| Sliders/ranges | Base `sliderInput()` / Typed Workbench | **React Aria Slider** inside direct components; base Shiny for ordinary use | native range input; noUiSlider | **Keep current / Use internally** | Multi-thumb and keyboard semantics are difficult; ordinary scalar sliders are not. | Avoids adding a slider package; no broad migration. |
| Searchable navigation | Buttons/tabs plus Command Palette | **Current Command Palette + visible navigation** | React Aria search field/listbox; cmdk | **Keep current** | The palette augments rather than hides navigation, keeps host command authority, and already handles large catalogs. | Avoids duplicated route selectors and action menus. |
| Report/document navigation | Basic anchors/tabs | **Custom virtual outline + IntersectionObserver scrollspy** | Virtual Tree Browser; native `<nav>` + anchors | **Custom build** | Report hierarchy, active section, findings, and warnings need a lightweight projection, not a general tree editor. Native anchors preserve static-report compatibility. | No R dependency; can reduce server-synchronized navigation. |
| Fullscreen / spotlight containers | Ad hoc CSS | **Native Fullscreen API + `<dialog>`/Popover API with a small package wrapper** | React Aria Modal | **Custom build** | Browser-native behavior is sufficient; the wrapper should handle focus restoration, escape, unsupported browsers, and bounded open/close intents. | No R dependency or large JS library. |
| Search/query builder | Typed controls | **Custom typed expression builder using Parameter Workbench kernels** | React Query Builder; jQuery QueryBuilder | **Needs requirement before choosing** | A generic query grammar can become a second execution language. Choose only after a canonical host expression contract exists. | Potentially avoids a query-builder R widget. |
| Upload/drop zone | Base `fileInput()` | **Keep base Shiny upload; add Pragmatic DnD affordance only if needed** | FilePond; Uppy | **Keep current** | Shiny already owns upload transport and limits. A heavy resumable-upload engine is unjustified without large/resumable/cloud requirements. | None. |

## Editor strategy: R + Julia + SQL + Python

### Recommendation

Use **Monaco as the primary code workspace**, not as a universal text field.
Its model/URI abstraction, editor and diff surfaces, completion/diagnostic APIs,
command discovery, and accessibility mode fit Code Runner and future multi-file
work. Monaco's shipped basic-language history includes R/Rmd and Julia, and its
language set also covers SQL, Python, JSON, Markdown, and common web languages.
The [Monaco repository](https://github.com/microsoft/monaco-editor) documents
the public ESM API and model contract; its [accessibility guide](https://github.com/microsoft/monaco-editor/wiki/Monaco-Editor-Accessibility-Guide)
documents keyboard-only command discovery. The project is MIT licensed.

Language support must be described honestly:

| Language | Syntax highlighting | Completion/diagnostics path | Decision |
|---|---|---|---|
| R / Rmd | Monaco basic language/tokenizer | Future governed R language-server bridge or host-provided completions | Monaco prototype must prove comments, strings, pipes, formulas, and Rmd fences. |
| Julia | Monaco basic language/tokenizer | Future Julia language-server bridge | Monaco is the best common-editor choice; semantic support is future work. |
| SQL | Monaco basic SQL tokenizer | Host schema completion + selected dialect parser/service | Require a `dialect` field; generic SQL diagnostics are misleading. |
| Python | Strong basic language support | Optional Pyright-compatible service or host diagnostics | Best-qualified language in this set. |
| JSON | Built-in JSON language service | JSON Schema supplied by host | Use Monaco for full documents; structural editor remains separate. |
| YAML | Basic tokenizer; schema intelligence needs an adapter | YAML language service/schema supplied by host | Prototype worker/bundle cost before promotion. |
| Markdown | Basic language support | Optional lint/preview supplied separately | Use CodeMirror for small embedded prose; Monaco in code workspaces. |

Use **CodeMirror 6** only for lightweight embedded Markdown/configuration fields
where loading Monaco is disproportionate. Do not force one engine into every
text input. Both engines must be pre-bundled; neither introduces Node.js at R
install/runtime. Large-document, IME, screen-reader, worker lifecycle, update
conflict, and copy/paste QA are promotion gates.

## Platform findings and evidence

- [React Aria Components](https://react-aria.adobe.com/) provides unstyled,
  accessible collection, input, date, overlay, menu, and toast primitives. It
  is the preferred semantics layer, not a visual design system.
- [TanStack Virtual](https://tanstack.com/virtual/v3/docs/introduction) is a
  headless vertical, horizontal, and grid virtualizer. The package already uses
  it, so list-scale components should share that runtime.
- [AG Grid's license](https://github.com/ag-grid/ag-grid/blob/latest/LICENSE.txt)
  distinguishes MIT Community packages from commercial Enterprise packages.
  Its documented row/column virtualization and grid feature depth justify the
  bundle for analytical inventories, not small report tables.
- [XYFlow](https://reactflow.dev/) remains active and MIT licensed, with
  selection, pan/zoom, node/edge interaction, keyboard behavior, and selective
  rerendering. Keep it for node-centric UI; do not pretend it replaces a
  large-network engine.
- [react-resizable-panels](https://www.npmjs.com/package/react-resizable-panels)
  remains active and MIT licensed. The qualified lab Split Pane should remain.
- [Floating UI](https://floating-ui.com/docs/getting-started) is MIT,
  framework-neutral, modular, and tree-shakeable. Reuse its existing runtime
  for collision-aware overlays.
- [Pragmatic Drag and Drop](https://github.com/atlassian/pragmatic-drag-and-drop)
  has an Apache-2.0, framework-neutral, small modular core and virtualization
  support. Its [accessibility guidance](https://atlassian.design/components/pragmatic-drag-and-drop/accessibility-guidelines)
  correctly requires non-drag alternatives and live feedback.
- [vanilla-jsoneditor](https://github.com/josdejong/svelte-jsoneditor) offers a
  framework-neutral bundle with tree/text/table modes, schema validation,
  search, and large-document support. Its bundle and editable authority make a
  prototype mandatory rather than immediate adoption.
- [FlexLayout](https://github.com/caplin/FlexLayout) is MIT, React-only, and
  supplies serializable draggable/resizable tabsets. Adopt it only when a
  canonical dock-layout model is approved.

## Direct answers

1. **Is AG Grid Community still the best dense analytical table choice?** Yes,
   for interactive analytical inventories. It is not the default for small or
   static report tables. Keep Community/Enterprise boundaries explicit.
2. **Is the Selection System preferable to mature alternatives?** Its public
   contract is. Run a React Aria kernel shootout for accessibility edge cases,
   but retain ordered/stale/server-search semantics and TanStack virtualization.
3. **Best editor strategy for R + Julia + SQL + Python?** Monaco for the code
   workspace and diff; CodeMirror 6 only for lightweight embedded prose/config.
   Highlighting is available, while semantic completion and diagnostics are
   explicit per-language integrations, not assumed.
4. **What replaces nested `renderUI()` details?** Persistent Dynamic UI plus
   Virtual Tree/Object Inspector, Split Pane, and keyed direct updates. AG Grid
   handles dense record inventories; the host sends normalized state once and
   patches it.
5. **What owns toast UX?** A small `shinycapabilities` Notification Center built
   on accessible live-region/toast semantics. The host owns message truth and
   actions; the browser owns queue, dedupe, display timing, and local history.
6. **Is React Flow/XYFlow still the best graph foundation?** Yes for workflow,
   provenance, and node-centric relationship interaction. Use Cytoscape.js or
   Sigma.js only after a distinct large-network contract demonstrates need.
7. **Is react-resizable-panels still best for split panes?** Yes. Keep the
   qualified wrapper. It is not a dock manager.
8. **Which capabilities stay lightweight custom?** Notification center,
   progress/status, activity monitor, execution replay, review controls,
   report outline, fullscreen/spotlight wrapper, and compositions of existing
   tree/grid/split primitives.
9. **Biggest R dependency reductions?** Selection System can remove
   `shinyWidgets`; AG Grid plus semantic HTML can eventually remove `reactable`
   and `reactR`; direct Monaco avoids adding `shinyAce`/editor wrappers; direct
   tree/overlay/drag primitives avoid future R widget packages.
10. **Where are we custom-building something materially better solved outside?**
    Generic combobox accessibility should be compared with React Aria;
    editable JSON should not be rebuilt before testing vanilla-jsoneditor;
    code/diff editing should use Monaco; sortable drag behavior should use
    Pragmatic Drag and Drop; dock management should not be hand-built.

## Existing components that are already effectively best-in-class

- **AG Grid Data Grid:** correct specialized engine and bounded host contract.
- **Virtual Tree Browser:** right read-only, virtualized scope.
- **Command Palette:** stronger product fit than importing `cmdk`.
- **Typed Parameter Workbench:** analytical schema semantics justify custom
  orchestration; only low-level field behavior should be shared.
- **Split Pane:** already wraps the preferred engine.
- **Agent Activity Monitor, Relationship Graph, and Execution Replay:** their
  projection contracts are the value. Generic libraries cannot replace them.
- **Direct Component Transport, Persistent Dynamic UI, and Shared Browser
  Runtime:** these are the correct cross-component foundation and should become
  the default for new interactive components after promotion qualification.

## Components to rebuild or prototype

| Area | Action | Acceptance gate |
|---|---|---|
| Selection internals | React Aria versus current kernel shootout | Same contract; better screen-reader, IME, async loading, stale-value, and 100k-option results without larger Shiny traffic. |
| Code/value editor | Monaco prototype | R/Julia/SQL/Python syntax; JSON schema; diff; workers; accessibility; 1 MB document; no Node at runtime. |
| Object inspector | vanilla-jsoneditor versus Virtual Tree composition | Bundle, read-only security, redaction, 10–100 MB behavior, keyboard and screen-reader QA. |
| Notification center | Lightweight custom implementation | Dedupe, bounded queue/history, focus-neutral status, urgent alert behavior, deterministic events. |
| Overlay primitives | React Aria + existing Floating UI | Nested focus/dismissal, portals, clipping, touch, keyboard, reduced motion. |
| Sortable collections | Pragmatic DnD prototype | Pointer/touch plus visible menu/button alternative, live announcements, virtualization, deterministic reorder intent. |
| Dockable workspace | FlexLayout proof only after requirements | Persisted schema, stable panel IDs, keyboard path, focus restoration, mobile fallback, host-authoritative layout changes. |

## Dependency-elimination implications

Conceptual target:

```text
Current
Shiny helper -> R widget package -> htmlwidget/reactR -> JavaScript library

Target
Shiny capability contract -> Direct Component Transport
  -> Shared Browser Runtime -> pre-bundled JavaScript engine
```

| R-side layer | Target disposition | Browser replacement |
|---|---|---|
| `shinyWidgets` | Remove after installed-build and journey QA | Selection System, potentially React Aria-backed |
| `reactable` | Remove only after dense and compact table migrations | AG Grid Community + semantic HTML |
| `reactR` | Removed with last `reactable`/legacy React bridge | Shared Browser Runtime |
| `htmlwidgets` | Retain for static/report widgets and legacy components; stop making it mandatory for new live components | Direct Component Transport |
| Future `shinyAce`/editor package | Avoid | Monaco/CodeMirror direct bundle |
| Future tree/menu/drag/layout R packages | Avoid | Existing tree, React Aria/Floating UI, Pragmatic DnD, qualified layout engines |

Core `shiny`, `htmltools`, and `jsonlite` remain. This is an architectural
simplification, not a contest to minimize `DESCRIPTION` at the expense of a
larger, less maintainable browser bundle.

## Top 10 modernization actions

1. **Promote Shared Browser Runtime and Direct Component Transport** after
   cross-component lifecycle, CSP, static-asset, and installed-package QA.
2. **Build the Notification Center** as the next lightweight direct component.
3. **Prototype Monaco Editor** against real R, Julia, SQL, Python, JSON, YAML,
   Markdown, diff, accessibility, and worker fixtures.
4. **Run the Selection System/React Aria shootout** without changing the public
   Selection API.
5. **Build a bounded Object Inspector prototype** comparing existing Virtual
   Tree composition with vanilla-jsoneditor.
6. **Create shared overlay primitives** using React Aria semantics and the
   already bundled Floating UI positioning engine.
7. **Plan the Workstation table migration seam:** AG Grid for dense inventories,
   semantic HTML for compact/report tables, then remove `reactable`/`reactR`.
8. **Qualify Pragmatic Drag and Drop** for report-plan and ordered-list use with
   non-drag accessible controls.
9. **Standardize direct persistent detail surfaces** using keyed patches,
   Split Pane, Tree/Grid, and inspectors instead of nested `renderUI()`.
10. **Defer dockable layouts and a second graph engine** until measured product
    requirements justify their state and bundle cost.

## Research limitations

- This is a source/documentation review, not a browser shootout. Accessibility
  claims are qualification targets, not inherited guarantees.
- Bundle size depends on selected modules and shared-runtime deduplication; it
  must be measured from production builds before promotion.
- Commercial restrictions were evaluated at the package-family level. Any AG
  Grid capability must be checked against the Community feature boundary.
- Language highlighting does not equal parsing, completion, diagnostics, or
  execution. Those remain separate, governed contracts.
- Workstation was inspected read-only; no migration or dependency removal was
  performed.
