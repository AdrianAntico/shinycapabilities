# Best-in-Class Browser UI Modernization Roadmap

Date: 2026-08-20

## Authority and outcome

This is the implementation-order authority for browser UI modernization in
`shinycapabilities`. The companion
[`best_in_class_ui_replacement_research.md`](best_in_class_ui_replacement_research.md)
contains the candidate evidence and alternatives behind these decisions.

The target stack is:

```text
Shiny session and governed host state
  -> shinycapabilities normalized contract
  -> Direct Component Transport
  -> Shared Browser Runtime
  -> selected best-in-class browser engine or focused custom projection
```

Shiny remains the reactive/session authority. Browser components may own local
interaction state, rendering, focus, and bounded history. They never become a
second permission, persistence, execution, review, or provenance system.

The goal is not minimum dependency count. The goal is better interaction,
faster updates, fewer redundant wrapper layers, and a coherent product.

## Standard browser platform

| Concern | Standard | Boundary |
|---|---|---|
| Live component transport | Direct Component Transport | Stable IDs, keyed patches, bounded intent events, host authority |
| Shared lifecycle/runtime | Shared Browser Runtime | One deduplicated runtime, mount/update/destroy discipline, shared diagnostics |
| Persistent projections | Persistent Dynamic UI | Update in place; preserve focus, scroll, expansion, draft, and selection where valid |
| Accessible fields/collections | React Aria Components | Behavioral semantics only; package owns visual language and event contract |
| Virtualization | TanStack Virtual | Package owns markup, ARIA, remote-loading policy, and stable identity |
| Dense analytical grid | AG Grid Community | Community features only; compact/static tables remain semantic HTML |
| Code, structured text, and diff | Monaco Editor | One serious editor platform; semantic services are separate adapters |
| Split layout | react-resizable-panels | Resizing only; no domain or dock-layout authority |
| Floating positioning | Floating UI | Positioning/collision kernel; React Aria or native semantics own interaction |
| Node-centric graphs | XYFlow | Workflow/provenance interaction with equivalent textual navigation |
| Sortable drag/drop | Pragmatic Drag and Drop | Every drag outcome also has a non-drag accessible control |

All browser assets are built during package development and shipped in `inst/`.
Node.js is never required to install or run the R package.

## Capability decision map

| Capability | Current approach | Best-in-class target | Decision | UX gain | Runtime gain | Dependency impact | Migration priority |
|---|---|---|---|---|---|---|---|
| Selectors / comboboxes | Base Shiny plus Selection System | Preserve Selection System API; test React Aria as internal behavior kernel; retain TanStack Virtual | **Enhance / shootout** | Better edge-case keyboard, IME, validation, and screen-reader behavior without losing ordered/stale/server search | Browser-local filtering and bounded updates | Remove `shinyWidgets`; avoid future selector wrappers | P0 |
| Large selectors | Selection System + TanStack Virtual | Existing virtualized component | **Keep** | Stable high-cardinality search and selection | Viewport-only DOM | Same removal path for `shinyWidgets` | P0 qualification |
| Dense data grid | Workstation `reactable`; lab AG Grid | AG Grid Community over Direct Transport | **Keep lab / replace host layer** | Typed filters, column controls, selection, editing, keyboard density | Row/column virtualization and in-place patches | Retire `reactable` + `reactR` after migration; no Enterprise features | P1 |
| Compact/report table | `reactable` often used broadly | Semantic HTML table with shared formatting/filter helpers where interactive behavior is modest | **Replace selectively** | Faster, simpler report reading | No large grid runtime | Helps complete `reactable` removal | P1 |
| Hierarchical browser | Selects, nested `renderUI()`, Virtual Tree | Existing Virtual Tree + TanStack Virtual | **Keep** | Searchable hierarchy and durable context | Viewport-only DOM, persistent expansion | Avoid R tree packages | P1 migration |
| Structured object inspector | Bespoke tables/text/details | Prototype Virtual Tree composition against `vanilla-jsoneditor` | **Shootout** | Search, paths, expand/collapse, copy, redaction, optional structural editing | Persistent virtualized inspection | Avoid JSON R widgets and repeated `renderUI()` | P1 |
| Command palette/navigation | Lab Command Palette | Existing component + visible navigation | **Keep** | Keyboard discovery without hiding product structure | Local search and virtual rows | Avoid command-menu wrappers | P1 migration |
| Typed parameter editor | Repeated Shiny controls and `renderUI()`; lab Workbench | Existing Typed Parameter Workbench with shared React Aria field semantics | **Enhance** | Consistent search, help, validation, dependencies, presets, dirty/applied state | One browser draft model and bounded apply | Reduces input-binding/message volume; no core Shiny removal | P0/P1 |
| Code editor | Textareas | Monaco Editor direct component | **Build** | IDE-grade editing, search, commands, undo, diagnostics seam | Incremental editor model and keyed updates | Avoid `shinyAce`, `shinyMonaco`, editor htmlwidgets | P0 |
| R editor | Textareas | Monaco R/Rmd tokenizer + future governed R language-service adapter | **Build on Monaco** | Consistent code workspace; completions only when real service exists | Shared Monaco runtime | No R-specific editor package | P0 |
| Julia editor | Textareas | Monaco Julia tokenizer + future Julia language-service adapter | **Build on Monaco** | Same editor conventions as R/Python/SQL | Shared Monaco runtime | No Julia-specific wrapper | P0 |
| Python editor | Textareas | Monaco Python + optional governed diagnostics adapter | **Build on Monaco** | Strong syntax/editing and future semantic support | Shared Monaco runtime | Avoid notebook/editor wrapper for ordinary code | P0 |
| SQL editor | Textareas | Monaco SQL + required dialect + host schema completion adapter | **Build on Monaco** | Dialect-aware completion path and consistent execution UX | Shared Monaco runtime | Avoid separate SQL editor package | P0 |
| JSON/YAML/Markdown editor | Textareas/typed fields | Monaco for full documents; ordinary textarea/Workbench for small scalar prose | **Standardize** | One command, selection, undo, validation, and conflict language for serious documents | Shared editor runtime; trivial fields stay cheap | Do not add CodeMirror or format-specific R wrappers | P0 |
| Code/value diff | Bespoke comparisons | Monaco Diff Editor for text/code; typed structural diff for tables/metadata | **Build / compose** | Navigable changes and consistent review | Renders only chosen comparison; reuse Monaco | Avoid diff widget packages | P1 |
| Split panes | Host scripts; lab Split Pane | Existing react-resizable-panels wrapper | **Keep** | Keyboard/touch resize, collapse/reset, stable layout | Browser-local geometry | Avoid split-pane R packages and custom handlers | P1 migration |
| Dockable layouts | Not canonical | FlexLayout only after a governed persisted-layout contract | **Defer / shootout later** | Potential workstation layout flexibility | Browser-local tab movement | Avoid hand-built docking; adds meaningful JS state | P3 |
| Tabs/accordions | Base Shiny/HTML | Keep base/native; React Aria behavior only inside direct components | **Keep current** | No material broad gain | Lowest cost | No dependency change | Keep |
| Dialogs/drawers/sheets | `modalDialog()` plus bespoke panels | Shared React Aria modal/dialog contract; native `<dialog>` for simple cases | **Prototype** | Predictable focus, dismissal, labels, nested overlays | Persistent contents avoid regeneration | Reduces modal glue, not core Shiny | P1 |
| Popovers/tooltips | Ad hoc implementations; Floating UI present | Floating UI positioning + React Aria/native interaction semantics | **Enhance infrastructure** | Collision-safe, keyboard/touch-consistent overlays | Shared positioning runtime | Avoid tooltip/popover R packages | P1 |
| Context menus | Bespoke buttons | React Aria Menu + Floating UI | **Prototype** | Typeahead, submenus, keyboard and dismissal consistency | Browser-local interaction | Avoid menu wrapper packages | P2 |
| Notifications/toasts | `showNotification()` | Lightweight custom Notification Center with accessible live regions and bounded queue/history | **Build** | Deduplication, severity, persistence, consistent attention behavior | Browser queue; fewer server-created DOM fragments | Avoid toast packages; reduces Shiny notification use | P0 |
| Drag/drop/sortable | Limited bespoke behavior | Pragmatic Drag and Drop with visible menu/button alternatives | **Prototype** | Pointer/touch direct manipulation plus accessible equivalent | Modular core and virtual-list compatibility | Avoid sortable/drag R wrappers | P2 |
| Workflow/provenance graph | XYFlow lab components | Existing XYFlow Relationship Graph/workflow canvas + textual equivalent | **Keep** | Rich topology navigation and bounded interaction | Selective rerendering/viewport behavior | Avoid `visNetwork`/`DiagrammeR` UI layers | P1 migration |
| Large analytical network | No distinct contract | Cytoscape.js or Sigma.js only if scale requirements exceed XYFlow | **Avoid until required** | Could handle large network analysis | Potential canvas/WebGL scale | Adds second graph engine | P3 |
| Timeline/execution replay | Tables/cards; lab Replay | Existing custom Execution Replay + TanStack Virtual | **Keep** | Deterministic temporal investigation | Bounded event viewport and incremental updates | Avoid generic timeline R widgets | P1 migration |
| Agent/job monitor | Cards/progress fragments; lab Monitor | Existing custom Agent Activity Monitor | **Keep** | Fast operational and attention triage | Persistent bounded projections | Replaces repeated status `renderUI()` | P1 migration |
| Progress/status | Base progress, cards, notifications | Lightweight semantic progress/meter/status/log primitives | **Build small** | Honest unavailable states; consistent urgency | Minimal persistent DOM | Avoid progress UI packages | P1 |
| Review/approval | Bespoke action rows/details | Custom Review Surface composed from dialog, evidence links, status, and immutable intent events | **Build after primitives** | Consistent evidence-first decisions and focus | Persistent inspector; bounded intents | Consolidates UI but does not own policy | P2 |
| File/object browser | Selects/tables/details | Virtual Tree + AG Grid/semantic list + Split Pane + Object Inspector | **Compose existing** | Familiar hierarchy/list/inspector workflow | Persistent panes and virtual views | Avoid file-browser R package | P2 |
| Searchable navigation | Buttons/tabs/selects | Visible navigation augmented by existing Command Palette | **Keep / migrate** | Discoverability plus keyboard speed | Local search | Avoid route-selector proliferation | P2 |
| Report/document navigation | Anchors/tabs | Native anchors + virtual outline + IntersectionObserver scrollspy | **Custom build** | Fast section/finding/warning navigation | Browser-local active-section projection | No R package | P2 |
| Fullscreen/spotlight | Ad hoc CSS | Native Fullscreen/`dialog`/Popover APIs behind a small focus-safe wrapper | **Custom build** | Consistent inspect-in-place behavior | Browser-native | No new dependency | P2 |
| Dynamic UI/projections | 384+ `uiOutput()`/`renderUI()` occurrences observed in prior audit | Persistent Dynamic UI + purpose-built keyed components | **Replace by class, not mechanically** | Preserves focus, scroll, expansion, draft and selection | Avoids repeated HTML generation, binding, and remount | Reduces reliance on `htmlwidgets` for new live components | P0-P2 |
| Date/time/range | Sparse base controls | Keep native/base for simple dates; React Aria Date/Range when locale/timezone/calendar requirements exist | **Requirement-gated** | Advanced semantics only where needed | Browser-local segments | Avoid future date wrapper packages | P3 |
| Slider/range | Sparse base/Workbench controls | Keep base for scalar; React Aria Slider for direct multi-thumb controls | **Keep / internal standard** | Keyboard and multi-thumb consistency | Minimal | Avoid slider package | Keep |
| Upload/drop zone | Base Shiny upload | Keep Shiny transport; add drag affordance only when required | **Keep current** | No meaningful broad replacement gain | Existing upload pipeline | Avoid FilePond/Uppy until resumable/cloud upload is real | Keep |

## Existing lab adjudication

| Lab capability | Classification | Required next work |
|---|---|---|
| Selection System | **Enhance / prototype against competitor** | Preserve API; React Aria behavior shootout and installed-package accessibility QA |
| Virtual Tree Browser | **Keep - preferred** | Remote paging only when a host contract exists; compose with inspector |
| Command Palette | **Keep - preferred** | Promotion and Workstation route/command adapter QA |
| AG Grid Data Grid | **Keep - preferred** | Community-boundary audit, direct transport promotion, table migration fixtures |
| Typed Parameter Workbench | **Enhance** | React Aria field semantics, conflict handling, large-schema profiling |
| Split Pane | **Keep - preferred** | Shared-runtime promotion and Workstation layout seam |
| Agent Activity Monitor | **Keep - preferred** | Promote normalized projection adapters only; retain read-only authority |
| Relationship Graph | **Keep - preferred** | Preserve accessible textual equivalent and malformed-edge diagnostics |
| Execution Replay | **Keep - preferred** | Promote shared event adapter and bounded update behavior |
| Persistent Dynamic UI | **Infrastructure** | Turn benchmark evidence into migration rules and reusable keyed host adapters |
| Direct Component Transport | **Infrastructure** | Qualify CSP, reconnect, teardown, static assets, namespacing, exactly-once intents |
| Shared Browser Runtime | **Infrastructure** | Deduplicate React/utility kernels and become the default new-component runtime |

## One coherent interaction language

Different engines must implement the following product-level rules.

### Keyboard and focus

- `Tab` enters/leaves a component; arrows navigate within composite controls.
- `Enter` activates or applies the focused primary action; `Space` selects or
  toggles when the ARIA pattern requires it.
- `Escape` closes the top overlay or exits a transient mode without silently
  discarding an applied value.
- `Home`/`End` move to collection bounds; Page Up/Down operate where meaningful.
- Opening an overlay moves focus intentionally; closing restores it to the
  trigger. Updates never steal focus without an urgent, documented reason.
- Drag, graph, and canvas outcomes always have a keyboard/list alternative.

### Search and selection

- Search is case-insensitive, whitespace-trimmed, debounced only when remote,
  and exposes result count/loading/empty state.
- Stable IDs, never labels or row positions, are authoritative.
- Single, multiple, ordered, stale, and disabled selection states have shared
  meanings. Selection is not execution.
- Virtualization never changes result order or keyboard semantics.

### Editing

- Monaco is the sole serious text/code editor platform. Ordinary short prose
  remains a native textarea; no second editor engine is introduced.
- Undo/redo is browser-local until apply. Host updates carry revision/version
  identity and cannot silently overwrite a dirty draft.
- Components expose `clean`, `dirty`, `valid`, `conflict`, `applying`, and
  `applied` consistently where editing exists.
- Completion, diagnostics, and execution are separate governed services.

### State and messaging

- Every component has explicit loading, empty, error, stale, disabled, and
  unavailable states.
- Browser events are bounded, versioned intents with stable component and item
  IDs. No executable payloads or full datasets return through input events.
- Status never relies on color alone. Toasts do not carry decisions that require
  durable review; those use a review surface or dialog.
- Copy/paste produces predictable plain text and optional structured formats;
  redacted values remain redacted.

### Styling

- Components consume common CSS tokens for surface, border, text, muted text,
  focus ring, status, density, radius, and motion.
- Engine default themes are adapted to those tokens rather than visually
  coexisting as separate products.
- Respect reduced motion, high contrast, zoom, narrow widths, and touch targets.

## `renderUI()` / `uiOutput()` migration rules

### Migrate to Persistent Dynamic UI

Use keyed direct updates when the same logical surface is repeatedly regenerated
and users expect local state to survive:

- parameter schemas and module configuration;
- artifact/evidence/project inspectors;
- activity, job, execution, and provenance projections;
- code editor plus output/history layouts;
- large searchable collections and relationship views;
- repeated review/detail drawers; and
- browser-owned report navigation.

### Replace with purpose-built components

- record inventory -> AG Grid or semantic table;
- hierarchy -> Virtual Tree;
- code/value document -> Monaco;
- typed analytical configuration -> Parameter Workbench;
- relationship topology -> Relationship Graph;
- event history -> Execution Replay;
- current operations -> Agent Activity Monitor;
- dense details -> Object Inspector; and
- multi-region inspection -> Split Pane composition.

### Keep ordinary Shiny

- small static conditional fragments;
- infrequent confirmation dialogs;
- simple scalar forms with few fields;
- upload transport;
- server-authoritative validation messages that do not regenerate a large
  subtree; and
- UI whose identity genuinely changes rather than being updated in place.

Migration is evidence-driven. A `renderUI()` occurrence is not a defect by
itself; repeated remounting that loses interaction state or creates measurable
server/browser churn is the target.

## Keep

- AG Grid Data Grid for dense analytical inventories.
- Virtual Tree Browser for read-only hierarchy.
- Command Palette for host-defined action/navigation discovery.
- Typed Parameter Workbench as the analytical form contract.
- Split Pane on react-resizable-panels.
- Agent Activity Monitor, Relationship Graph, and Execution Replay as focused
  host-neutral projections.
- TanStack Virtual, XYFlow, and Floating UI in their bounded roles.
- Core Shiny, `htmltools`, and `jsonlite`.

## Replace

- `shinyWidgets` selectors after Selection System journey qualification.
- `reactable` and `reactR` after dense grids and compact/report tables cover all
  actual journeys.
- serious code/value textareas with Monaco.
- repeated nested detail `renderUI()` with keyed persistent components.
- page-local resize, overlay, menu, and notification scripts with shared
  qualified primitives.
- new `htmlwidgets`/`reactR` wrappers for live components where Direct Transport
  is demonstrably simpler. Retain `htmlwidgets` where static/report rendering or
  existing qualified widgets still require it.

## Enhance

- Selection System internals and accessibility QA.
- Typed Workbench field semantics, conflict state, and schema scale.
- AG Grid direct update and table formatting/export migration coverage.
- Shared Runtime deduplication and lifecycle diagnostics.
- Persistent Dynamic UI adapters and migration instrumentation.
- Relationship Graph textual equivalence and large-graph boundary.

## Prototype shootouts

| Shootout | Required evidence | Decision produced |
|---|---|---|
| Selection System vs React Aria kernel | 100k options, multi/order/stale/server search, IME, keyboard, screen readers, message volume | Keep current kernel or adopt React Aria internally without API change |
| Monaco editor | All required languages, JSON schema, SQL dialect seam, diff, 1 MB document, workers, IME, accessibility, reconnect/conflict | Production editor API and bundle split |
| Object Inspector | Virtual Tree composition vs vanilla-jsoneditor, redaction, read-only/edit mode, 10-100 MB, keyboard, bundle | One inspector strategy by authority/size |
| Overlay system | React Aria + Floating UI vs native dialog/popover for simple cases | Shared overlay API and native escape hatch |
| Pragmatic Drag and Drop | Virtual lists, touch, menu alternative, announcements, deterministic reorder events | Sortable collection primitive or defer |
| Dock manager | Only after requirements: FlexLayout state, keyboard, persistence, mobile, focus | Adopt FlexLayout or remain Split Pane + tabs |

## Avoid

- CodeMirror as a second editor solely because it is lighter.
- `shinyAce`, `shinyMonaco`, and new R wrappers over engines we can bundle
  directly.
- AG Grid Enterprise features without an explicit commercial decision.
- AG Grid for small/static report tables.
- a full generic design system such as MUI solely to obtain primitives.
- `cmdk` when the virtualized Command Palette already has the better contract.
- React Arborist for read-only trees already served by Virtual Tree Browser.
- a second graph engine until a measured network-scale requirement exceeds
  XYFlow.
- custom pointer geometry, custom editor engines, or custom generic JSON
  editing before testing qualified engines.
- browser components that mutate governed host state directly.

## Dependency elimination sequence

| Dependency/layer | Target | Removal gate |
|---|---|---|
| `shinyWidgets` | Selection System | Source and installed-package searches clean; selector journeys pass; notices updated |
| `reactable` | AG Grid for dense use; semantic HTML for compact/report use | Formatting, filtering, pagination, theme, export, accessibility, and all table journeys pass |
| `reactR` | Shared Browser Runtime | Last `reactable` or legacy React bridge removed |
| New editor R packages | Monaco direct component | Monaco promotion QA passes before any wrapper is introduced |
| New tree/menu/drag/layout R packages | Direct browser primitives | Capability contract and browser QA pass |
| `htmlwidgets` for new live components | Direct Component Transport | Direct transport supports install, reconnect, CSP, teardown, namespacing, and static assets |

`htmlwidgets` is not globally deprecated. It remains appropriate for existing
qualified widgets and static/report output until those use cases have a better
transport. The migration target is unnecessary wrapper depth, not a package
name.

## Top 10 next modernization actions

| Order | Action | Codex can build independently in lab | Grok Workstation integration later |
|---:|---|---|---|
| 1 | Promote Shared Browser Runtime + Direct Transport with lifecycle, CSP, reconnect, namespace, static-asset, and exactly-once intent QA | Yes | Switch host pages only after canonical package promotion |
| 2 | Build Monaco Editor 1.0 and Diff 1.0 prototype for R, Julia, Python, SQL, JSON, YAML, and Markdown | Yes | Map Code Runner/editor state, permissions, execution, and saved drafts |
| 3 | Build Notification Center 1.0 with queue, dedupe, history, accessible announcements, and host actions | Yes | Replace selected `showNotification()` journeys and map severity/action policy |
| 4 | Run Selection System vs React Aria internal-kernel shootout | Yes | Remove `shinyWidgets` after installed Workstation journey QA |
| 5 | Build Object Inspector shootout and select read-only/edit strategies | Yes | Replace persisted-result, metadata, evidence, and diagnostics detail surfaces |
| 6 | Build shared Overlay Primitives 1.0 using React Aria/native semantics + Floating UI | Yes | Migrate drawers, popovers, context help, and selected dialogs |
| 7 | Qualify Persistent Dynamic UI migration kit with keyed Tree/Grid/Split/Inspector composition and metrics | Yes | Convert high-churn `renderUI()` pages incrementally |
| 8 | Complete AG Grid direct-transport/table migration fixtures and compact semantic table contract | Yes | Migrate tables, then remove `reactable` and `reactR` only after full journey QA |
| 9 | Prototype Pragmatic Drag and Drop Sortable Collection with accessible non-drag controls | Yes | Apply to report plans/layout ordering only through host intent handlers |
| 10 | Build Report Outline + Review Surface from the qualified primitives | Yes | Bind to Workstation findings/evidence/review authority and report navigation |

## Ownership split

### Codex can build independently in `shinycapabilities-lab`

- host-neutral schemas, R wrappers, direct browser components, assets, demos;
- semantic and browser tests, stress fixtures, accessibility qualification;
- bundle/license inventories and shared-runtime integration;
- migration adapters that accept normalized records but no Workstation domain
  packages; and
- promotion-readiness documents and compatibility tables.

### Grok must eventually perform Workstation integration/migration

- map canonical Workstation records to normalized component contracts;
- preserve permissions, persistence, review, execution, and provenance owners;
- decide page-level rollout and backward-compatible state migration;
- update Workstation dependencies, notices, packaging, and Electron fixtures;
- perform end-to-end user journey, installed-package, and production data QA;
- remove old dependencies only after no source/runtime path relies on them.

No lab component should inspect Workstation internals at runtime. Integration is
an explicit adapter in the host, never hidden coupling.

## Promotion gates

Every promoted component must prove:

1. deterministic normalized input validation and bounded event output;
2. namespacing, reconnect, update, teardown, and multiple-instance behavior;
3. keyboard-only and screen-reader journeys, focus restoration, zoom, contrast,
   reduced motion, and touch where applicable;
4. stable behavior under burst updates and realistic scale;
5. no Node.js requirement at R install/runtime;
6. dependency license and built-asset verification;
7. no silent host-state mutation or executable browser payload;
8. consistent loading, empty, error, stale, disabled, dirty, conflict, and
   unavailable states as applicable;
9. package tests, browser QA, build/check, and `git diff --check`; and
10. a documented Workstation migration seam and rollback path.

## Expected end state

The product uses different engines where their strengths matter, but users see
one interaction language. Expensive projections remain mounted and update by
stable identity. Dense data, code, topology, and hierarchy use specialized
engines. Small controls remain simple. Shiny owns the session and governed
state; `shinycapabilities` owns reusable browser interaction; Workstation owns
product meaning.
