# Shiny Dependency Elimination Audit

Date: 2026-08-20
Scope: `shinycapabilities-lab` plus read-only inspection of Analytics Workstation
and canonical `shinycapabilities`

## Executive decision

The useful target is not elimination of Shiny. Shiny remains the host runtime,
reactive boundary, session owner, and application integration contract. The
high-value opportunity is to remove intermediate UI packages and repeated
server-rendered fragments where `shinycapabilities` can provide a stricter R
contract over pre-bundled browser code.

The best near-term actions are:

1. qualify removal of `shinyWidgets` from Workstation now that selectors use
   `shinycapabilities::selection_input()`;
2. migrate demanding interactive tables from `reactable` to `data_grid()` and
   small/report tables to semantic HTML, then remove `reactable` and `reactR`
   when coverage is complete;
3. use Typed Parameter Workbench and Selection System to replace repeated
   `renderUI()`/`selectInput()` construction in dense analytical configuration;
4. build a browser-owned notification center and bounded object inspector;
5. add CodeMirror only when a real code/value editing seam is selected; and
6. consolidate the duplicated React runtime currently embedded in several
   component bundles before adding many more React-backed primitives.

This yields fewer R packages, fewer wrapper layers, lower Shiny message churn,
more consistent event contracts, and better keyboard/accessibility behavior.
It does not trade stable core Shiny controls for custom JavaScript where the
gain is negligible.

## Evidence boundary

The Workstation repositories were inspected read-only. Their working trees are
active and dirty, so this report records observed usage without treating
uncommitted files as a migration baseline. No Workstation or protected-package
file was changed.

Observed Workstation source counts are directional rather than API guarantees:

| Pattern | Observed calls |
|---|---:|
| `selectInput()` | 243 |
| `shinycapabilities::selection_input()` | 5 |
| `uiOutput()` | 384 |
| `renderUI()` | 385 |
| `showNotification()` | 37 |
| `modalDialog()` | 4 |
| `sliderInput()` | 2 |
| `dateInput()` / `dateRangeInput()` | 0 |
| `render_table()` | 211 |
| direct `reactable::reactable()` | 1 |

The densest dynamic UI concentrations are Analysis Modules, Workflow Studio,
Causal Intelligence, Product Experience, Project, Evidence Review, Semantic
Intelligence, and Plot Builder. These are future migration candidates, not
authorization to edit those pages.

## 1. Current interactive UI dependency inventory

### shinycapabilities-lab R runtime

| Package | Interactive role | JS underneath | Recommendation |
|---|---|---|---|
| `shiny` | Session, inputs/outputs, modules, reactive state, host events | Yes, core Shiny runtime | **Keep.** It is the product integration boundary. |
| `htmltools` | Tags and dependency attachment | No separate interaction runtime | **Keep.** Lowest-level safe HTML dependency API. |
| `htmlwidgets` | Widget serialization/output bindings | Yes | **Keep for now.** Several lab components and static HTML use it. Revisit only through a separate transport audit. |
| `jsonlite` | Strict R-to-browser payload encoding | No UI | **Keep.** Shared serialization authority. |
| `callr` | Background workflow execution | No UI | Out of scope; not a UI dependency. |
| `digest` | Fingerprints and deterministic identity | No UI | Out of scope; not a UI dependency. |

The lab does not import `DT`, `reactable`, `shinyWidgets`, a tree package, a
popover package, a split-pane package, a graph package, or an editor package.
Its interaction dependencies are bundled JavaScript assets.

### Workstation UI-related R packages

| Package | Exact role observed | Wrapper shape | Material simplification potential |
|---|---|---|---|
| `shinyWidgets` 0.9.0 | Declared in `Imports`; stale third-party notice says Virtual Select backs Analytics Input System | Shiny wrapper -> `shinyWidgets` -> Virtual Select JS | **High.** No current `shinyWidgets::` or `virtualSelectInput()` call was found; modern selectors use `selection_input()`. Removal appears close, subject to installed-build and journey QA. |
| `reactable` 0.4.5 | Shared interactive table rendering, themes, filtering and pagination | Shiny/app helper -> `reactable` -> `reactR` -> React table JS | **High but staged.** Interactive inventories can move to AG Grid; compact/report tables should use semantic HTML rather than loading AG Grid. |
| `reactR` 0.6.1 | Transitive runtime used by `reactable` | Intermediate React bridge | Removable with complete `reactable` removal. |
| `echarts4r` | Analytical chart widget/output integration | Workstation/AutoPlots -> `echarts4r` -> ECharts | **Keep.** This is analytical rendering owned by AutoPlots, not a generic UI primitive. A replacement here would violate repository boundaries and duplicate major plotting capability. |
| `htmlwidgets`, `htmltools`, `jsonlite` | Widget transport, tags, payloads | Shared infrastructure | **Keep.** Already reused by AutoPlots and `shinycapabilities`. |
| `shiny` | Application host plus base controls, modals and notifications | Core runtime | **Keep.** Browser primitives can reduce server churn without removing Shiny. |

Installed dependency inspection shows why package counts alone are incomplete:
`shinyWidgets` imports `bslib`, `sass`, `rlang`, `htmltools`, `jsonlite`, and
`shiny`, but several are already present through Shiny. Removing it still
removes one package and its bundled selector layer, not the whole transitive
set. Removing `reactable` also removes the otherwise UI-specific `reactR`
bridge; its other imports are already common.

### Core Shiny surfaces with no extra R dependency

| Surface | Current pattern | Decision |
|---|---|---|
| Ordinary text/numeric/checkbox inputs | Base Shiny | **Keep** for small forms. Use Parameter Workbench for dense typed schemas. |
| Selectors | Many base `selectInput()` calls plus qualified Selection System | Migrate only high-cardinality, grouped, ordered, stale-aware, or server-search selectors. |
| Sliders | Two base controls observed | **Keep.** No dependency payoff from replacement. Parameter Workbench already covers schema-driven sliders/ranges. |
| Date/time | No base date controls observed | Do not add a date library pre-emptively. Parameter Workbench's native date/datetime fields are sufficient until timezone/range/calendar requirements emerge. |
| Modals | Four base modal declarations | **Keep now.** A drawer/dialog primitive may improve complex review workflows, but removing no R package is not enough justification. |
| Notifications | 37 base notifications, concentrated in Workflow Studio | Build a consistent bounded notification center for UX/event-churn reasons, not package removal. |
| Tabs/accordions | Sparse core usage | **Keep.** Native/Shiny semantics are smaller and adequate. |
| File input | Three core inputs | **Keep.** Browser security requires user-mediated file selection; Virtual Tree may browse host-supplied objects after selection. |

## 2. Lab components and dependency-removal value

| Lab component | Dependency/layer it can reduce | Payoff | Boundary |
|---|---|---|---|
| **AG Grid Data Grid** | `reactable` + `reactR` for dense interactive inventories | High performance and UX payoff: row/column virtualization, typed filters, stable selection IDs, column state, and bounded updates | Do not use for small report tables. AG Grid Community is MIT; Enterprise-only features remain excluded. |
| **Selection System** | `shinyWidgets::virtualSelectInput()`, many high-cardinality `selectInput()` controls | High. It already supports virtualization, grouped options, stale values, ordered selection, server search, and bounded input messages | Ordinary short selects can remain base Shiny. |
| **Virtual Tree Browser** | Future R tree widgets or repeated nested `renderUI()` lists | High when hierarchy is large; reuses TanStack Virtual | It renders host-supplied hierarchy and emits selection/expansion only. It is not a filesystem authority. |
| **Command Palette** | Ad hoc searchable action lists and dense selector menus | Medium/high UX; avoids repeated server-generated command menus | Commands remain host-owned. It does not replace ordinary form selects. |
| **Typed Parameter Workbench** | Repeated `renderUI()` plus base control construction for analytical schemas | High runtime/consistency payoff even though Shiny remains installed | Browser owns drafts and local validation; host owns schema, applied values, and execution. |
| **Split Pane** | Future split-layout packages and custom drag handlers | Medium. No current Workstation R dependency is removed, but a reusable accessible contract prevents one | Layout only; no domain state. |
| **Agent Activity Monitor** | Repeated status cards, progress fragments and event-feed `renderUI()` | High projection/runtime payoff; no package directly removed | Read-only host-supplied governed activity. |
| **Relationship Graph** | Future `visNetwork`/`DiagrammeR` UI layers and ad hoc provenance diagrams | High if promoted; uses bundled XYFlow/Dagre with a non-canvas accessible fallback | Analytical plotting remains AutoPlots-owned. |
| **Execution Replay** | Repeated log tables, state cards and historical inspector fragments | High information-density/runtime payoff; no package directly removed | Historical projection only; no execution authority. |

## 3. Duplicated abstraction layers worth collapsing

### Interactive tables

Current:

```text
Workstation render_table()
  -> reactable R API/theme/column definitions
    -> reactR
      -> React table runtime
```

Target:

```text
Workstation table adapter
  -> shinycapabilities::data_grid() for dense interactive inventories
  -> semantic HTML table for compact/report output
```

This removes `reactable`/`reactR`, unifies stable row identity and update events,
and avoids loading an 842 KB raw / 233 KB gzip AG Grid bundle for small tables.
The migration must preserve numeric/date formatting, exclusion filtering,
themes, export of full underlying data, and report/static rendering.

### High-cardinality selection

Stale documented path:

```text
Workstation helper
  -> shinyWidgets::virtualSelectInput()
    -> Virtual Select JS
```

Qualified target:

```text
Workstation schema/adapter
  -> shinycapabilities::selection_input()
    -> bundled Selection System
```

Current Workstation source already points predominantly at the target. The
remaining work is dependency and notice cleanup plus installed-build QA, not a
new component.

### Dense analytical forms

Current repeated pattern:

```text
renderUI()
  -> many base Shiny controls
    -> browser DOM replacement
      -> many individual input bindings/messages
```

Target for schema-driven pages:

```text
typed host schema
  -> parameter_workbench_ui()/server()
    -> one browser-owned draft model
      -> bounded apply/reset state
```

This does not remove Shiny, but it materially lowers server-side UI creation,
DOM churn, and overlapping validation logic. The 384 `uiOutput()` and 385
`renderUI()` occurrences make this the largest runtime simplification seam.

### Status and history projections

Agent Activity Monitor and Execution Replay can replace page-specific loops of
cards, progress fragments, and event rows. The host must project authoritative
records into their normalized schemas. They must not become a second job or
provenance model.

## 4. Strongest missing JavaScript opportunities

### A. Notification Center / Toast Queue — build next

**Why:** Workstation has 37 `showNotification()` calls concentrated in two
pages. A browser-owned bounded queue can deduplicate messages, preserve focus,
provide accessible `status`/`alert` semantics, group repeated events, and avoid
re-rendering notification markup from multiple page-specific paths.

**Implementation direction:** use a small host-neutral component and native
ARIA live regions. React Aria offers an accessible Toast primitive, but adopting
the broad package solely for toast would be disproportionate. Start lightweight;
reuse React only after shared-runtime bundling is solved.

**Payoff:** medium dependency payoff (Shiny remains), high consistency and
moderate event/runtime payoff. Small expected bundle.

### B. Structured Object Inspector — build next

**Why:** Workstation has hundreds of dynamic detail outputs. A virtualized,
searchable, copy-safe JSON/list/data inspector can replace repeated nested
`renderUI()` definitions and make metadata, provenance, diagnostics, parameters,
and artifact payloads consistent.

**Implementation direction:** reuse Virtual Tree Browser and TanStack Virtual;
add typed scalar formatting, path navigation, redaction markers, diff hooks, and
bounded expansion. Do not add a generic JSON-view R package.

**Payoff:** no immediate package removal, but high server-render and
serialization simplification with little incremental JS if existing kernels are
shared.

### C. Code / Value Editor — build when a migration seam is selected

**Why:** governed code, SQL, JSON, YAML, and expression editing need better
keyboard behavior, syntax awareness, diagnostics, and change events than a
textarea. A bundled editor prevents future adoption of `shinyAce` or another R
widget layer.

**Candidate:** modular CodeMirror 6 packages, MIT licensed. The former GitHub
development repository was archived after moving to the maintainer's forge, so
release/source tracking must follow the new canonical location rather than
mistaking the archive for project abandonment. Only required language modules
should be bundled.

**Payoff:** medium future dependency avoidance and high UX. Moderate bundle and
accessibility risk; qualify screen readers, IME, large documents, undo history,
and value-update conflicts before promotion.

### D. Overlay primitives — strong candidate, not a framework

Tooltips, popovers, menus, and contextual inspectors can reuse the already
bundled `@floating-ui/dom` 1.8.0 (MIT; about 0.17 MB installed, with tree-shakeable
sub-kilobyte middleware plus a small DOM platform). Use native `<dialog>` and
the Popover API where their behavior is sufficient, with Floating UI for
collision-aware positioning.

Do not import a complete design system. A small shared focus-dismissal and
positioning layer is enough. This is a consistency/accessibility investment,
not an R-package elimination by itself.

### E. International date/time/range input — later

React Aria is Apache-2.0 and provides unstyled, WAI-ARIA-oriented date, time,
range, popover, keyboard, localization, and international-calendar behavior.
Its date contract is much stronger than a hand-built calendar. However,
Workstation currently has no `dateInput()` or `dateRangeInput()` use, and the
Parameter Workbench already supports native date/datetime fields.

Add this only when timezone-aware ranges, unavailable dates, locale-sensitive
segments, or non-Gregorian calendars are real requirements. Do not pay the
bundle/API cost pre-emptively.

### F. Drag/drop and sortable lists — later

Existing XYFlow and AG Grid own their internal drag interactions. Selection
System owns ordered selection. There is no current R drag/drop dependency to
remove. If a host-neutral sortable/cross-list contract emerges, Atlassian's
Pragmatic Drag and Drop is an active, framework-neutral candidate with explicit
accessibility guidance. Do not add it for decorative dragging or duplicate
existing component behavior.

## 5. Dependencies that should remain

| Dependency/control | Why it remains the better choice |
|---|---|
| `shiny` | Required host/session/reactive runtime; custom JS should narrow messages, not recreate Shiny. |
| `htmltools` | Canonical dependency/tag packaging with low conceptual cost. |
| `htmlwidgets` | Shared static/Shiny widget transport today. A future transport audit may reduce it, but changing transport while changing components compounds risk. |
| `jsonlite` | Stable serialization authority shared throughout the ecosystem. |
| `echarts4r` through AutoPlots | Plotting is an AutoPlots concern. Replacing it here would cross ownership boundaries. |
| Base text/numeric/checkbox/slider/file controls | Small, stable and accessible enough for ordinary forms; no extra R package is removed. |
| Base tabs/accordions/modals for simple uses | Small count and low runtime pressure; custom replacements need a concrete UX requirement. |
| Semantic HTML tables | Best small/static/report-table path; AG Grid is intentionally too heavy for this role. |

## 6. Ranked dependency-elimination roadmap

| Rank | Priority | Current layer | Replacement/action | R reduction | UX/runtime gain | Complexity | Bundle/risk |
|---:|---|---|---|---|---|---|---|
| 1 | **High** | `shinyWidgets` + Virtual Select | Finish Selection System migration; remove `Imports` and stale notice after installed-app QA | 1 direct package | Better large-option UX; bounded search/update contract | Low/medium | No new bundle; Selection System already ships |
| 2 | **High** | `reactable` + `reactR` for interactive inventories | AG Grid Data Grid | 2 packages after full migration | Major scale, keyboard and column-state gains | High | AG Grid is 842 KB raw / 233 KB gzip; load only where needed |
| 3 | **High** | `reactable` for compact/report tables | Existing semantic HTML renderer with shared formatting/filter/export contracts | Enables rank 2 removal | Faster/lighter static output | Medium | Minimal bundle; preserve report semantics |
| 4 | **High** | Repeated `renderUI()` analytical forms | Typed Parameter Workbench + Selection System | No direct package | Large server/DOM/message simplification | High, incremental by page | Existing bundles; avoid full-page remounts |
| 5 | **Medium** | 37 Shiny notifications | Notification Center / Toast Queue | No direct package | Consistent accessible feedback and deduplication | Medium | Small if lightweight |
| 6 | **Medium** | Nested detail `renderUI()` | Structured Object Inspector | Avoids future viewer packages | Better density, search and bounded updates | Medium | Reuse TanStack/Tree; small incremental cost after runtime sharing |
| 7 | **Medium** | Textareas for code/value editing; risk of future editor widget | CodeMirror-based Code/Value Editor | Future dependency avoidance | Large editor UX improvement | Medium/high | Modular but non-trivial; qualify accessibility |
| 8 | **Medium** | Ad hoc popovers/tooltips/context menus | Shared overlay primitives using existing Floating UI/native platform | Avoids future UI packages | Better collision, focus and consistency | Medium | Very small incremental JS |
| 9 | **Low** | Base sliders | Parameter Workbench only where schema-driven | None | Consistency only | Low | Do not replace standalone sliders |
| 10 | **Keep** | Base date/time today | Native fields | None | Current need is satisfied | None | Reassess only with advanced date requirements |
| 11 | **Keep** | Simple tabs/accordions/modals | Core/native | None | Adequate | None | Avoid framework adoption |

## 7. JavaScript dependency and bundle view

### Already present

| JS package | Version | License | Role |
|---|---:|---|---|
| React / React DOM | 19.2.8 | MIT | Component rendering |
| AG Grid Community | 36.1.0 | MIT | Data Grid |
| TanStack React Virtual | 3.13.12 | MIT | Trees, feeds and replay virtualization |
| XYFlow React | 12.11.2 | MIT | Workflow and relationship graphs |
| Dagre | 3.1.1 | MIT | Graph layout |
| Floating UI DOM | 1.8.0 | MIT | Positioned overlays |
| React Resizable Panels | 4.12.2 | MIT | Split Pane |

All assets are pre-built under `inst/htmlwidgets/lib`; package installation does
not require Node.js. Node/npm remain optional maintainer tools for rebuilding.

### Current bundle reality

The lab's component JS totals roughly 2.9 MB raw before CSS. Individual bundles
include approximately:

| Bundle | Raw | Gzip |
|---|---:|---:|
| Data Grid | 842 KB | 233 KB |
| Relationship Graph | 416 KB | 131 KB |
| Workflow canvas | 379 KB | 119 KB |
| Selection System | 225 KB | 71 KB |
| Split Pane | 221 KB | 69 KB |
| Execution Replay | 213 KB | 66 KB |
| Agent Activity Monitor | 209 KB | 65 KB |
| Interaction Components | 207 KB | 64 KB |
| Parameter Workbench | 194 KB | 60 KB |

Several independent Vite entries embed React/runtime code. Before adding many
more React-backed components, create and qualify a shared browser-runtime
dependency or deliberate component-family bundles. The target is:

```text
one versioned React/vendor runtime
  + lazily attached component-specific bundles
  + no duplicate React copies on a page
```

This is a deployment optimization, not permission to expose Node.js to package
users. Asset integrity, htmlDependency ordering, cache versioning, standalone
HTML behavior, and coexistence with other React widgets require QA.

### Conceptual before/after

```text
BEFORE (Workstation)
Shiny
  + shinyWidgets -> Virtual Select
  + reactable -> reactR -> React table
  + htmlwidgets/htmltools/jsonlite
  + echarts4r/AutoPlots
  + many renderUI fragments and base inputs

AFTER (target)
Shiny
  + shinycapabilities
      - Selection System
      - AG Grid for interactive inventories
      - semantic HTML for small/report tables
      - Parameter Workbench and browser-owned projections
      - shared React/vendor runtime + bounded component bundles
  + htmlwidgets/htmltools/jsonlite
  + echarts4r/AutoPlots

R packages removed: shinyWidgets, reactable, reactR
R packages retained: shiny, htmltools, htmlwidgets, jsonlite, plotting stack
JS added: none for first selector/table migration; later optional CodeMirror
JS reused: AG Grid, TanStack Virtual, Floating UI, React, XYFlow, Dagre
```

Net installation improves by removing R packages and their version/installation
failure points. Net browser payload improves only if component assets are loaded
on demand and shared runtimes stop duplication. Replacing every small table with
AG Grid would make the browser side worse and is explicitly rejected.

## 8. Workstation migration seams for Grok

Grok should eventually perform migration work against explicit seams, not make
page-by-page substitutions from visual similarity.

| Old seam | New seam | Compatible inputs | Changed outputs | Qualification gate |
|---|---|---|---|---|
| Analytics Input / `shinyWidgets` declaration | `selection_input()` | choices/groups, selected values, multiple mode | Stable value plus optional search/dirty/stale events | Installed Workstation journeys; server search; module namespaces; remove stale third-party notice |
| `render_table(..., engine="reactable")` interactive mode | `data_grid()` adapter | data, column schema, row ID, formatting | Stable row IDs, action and grid-state events | All table themes/filters/exports; 1k/10k/100k performance; accessibility mode |
| `reactable` compact/report mode | semantic HTML table | data and formatting | No interactive grid state | Static HTML/export/report snapshots and numeric/date formatting |
| Repeated schema `renderUI()` | Parameter Workbench | typed fields, values, conditions | One draft/apply/reset contract | Dirty-state conflict, validation, keyboard, sampling/deferred choices |
| `showNotification()` calls | Notification Center | severity, title/message, identity, expiry/action metadata | bounded dismiss/action intents | Deduplication, live-region semantics, focus, burst updates |
| Nested inspector `renderUI()` | Structured Object Inspector | typed/redacted object projection | path/selection/copy intents | Redaction, virtualization, cyclic/large payload diagnostics |

All migrations preserve host authority. `shinycapabilities` renders supplied
state and emits bounded intents; Workstation continues to own data access,
execution, permission checks, persistence, export, navigation and business
semantics.

## 9. Next three components for dependency reduction

1. **Notification Center / Toast Queue 1.0**

   Consolidates 37 current notification calls into a namespaced, deduplicated,
   accessible browser queue. It should support replace/append, bounded history,
   severity semantics, optional host-defined action intents, and burst QA.

2. **Structured Object Inspector 1.0**

   Reuses Virtual Tree/TanStack kernels for large nested metadata, artifact,
   diagnostic and provenance objects. It should support redaction-safe values,
   path search, keyboard expansion, scalar copy intent, diff-ready identity and
   bounded serialization.

3. **Code / Value Editor 1.0**

   Uses a minimal CodeMirror 6 bundle for governed R/SQL/JSON/YAML/expression
   editing. It must separate browser draft from host-applied value, expose
   deterministic change/apply events, and qualify accessibility, large text,
   update conflicts and package-without-Node installation.

Before component 3, qualify shared React/vendor asset packaging. Date/time,
generic drag/drop, tabs and modal replacement are not top-three dependency work.

## 10. Promotion Readiness

Before any lab component is promoted into canonical `shinycapabilities` or
mapped by Grok into Workstation:

1. define the exact old/new event and value contract;
2. prove module namespacing and installed-package asset lookup;
3. test keyboard, screen reader semantics, forced colors and reduced motion;
4. test update/replace cycles for browser memory growth and event floods;
5. prove no host authority moved into the browser component;
6. preserve fallback behavior for missing optional capabilities;
7. measure both R dependency reduction and page-specific JS payload;
8. verify shared-runtime versioning and no duplicate React root/runtime conflict;
9. run Workstation journeys against the installed promoted package, not the lab
   checkout; and
10. update `DESCRIPTION`, lock/source configuration, third-party notices and
    deployment smoke tests in one governed migration.

Grok may map Workstation records and schemas into promoted component contracts.
It must not infer permissions, execute actions, silently translate old event
semantics, or treat the lab checkout as a runtime dependency.

## Research references

- [AG Grid Community repository and MIT license](https://github.com/ag-grid/ag-grid)
- [AG Grid accessibility guidance](https://www.ag-grid.com/javascript-data-grid/accessibility/)
- [TanStack Virtual](https://github.com/TanStack/virtual)
- [Floating UI](https://floating-ui.com/) and [MIT license](https://github.com/floating-ui/floating-ui/blob/master/LICENSE)
- [React Aria DatePicker and internationalized date contract](https://react-aria.adobe.com/DatePicker)
- [React Spectrum/Aria repository, accessibility claims and Apache-2.0 license](https://github.com/adobe/react-spectrum)
- [Pragmatic Drag and Drop](https://github.com/atlassian/pragmatic-drag-and-drop)
- [CodeMirror canonical-project move notice](https://github.com/codemirror/dev)

## Final recommendation

Treat dependency elimination as a migration program with measured browser cost,
not a package-count contest. Remove `shinyWidgets` first. Close the dual
AG-Grid/semantic-HTML table contract and then retire `reactable`/`reactR`.
Use Parameter Workbench and Object Inspector to attack the much larger
`renderUI()` overhead. Keep stable core Shiny controls where they remain the
smallest correct solution.
