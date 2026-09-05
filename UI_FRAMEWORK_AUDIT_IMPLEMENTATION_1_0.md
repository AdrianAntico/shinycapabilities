# UI/UX framework audit and next wave 1.0

## Current release qualification: 0.2.2 QUALIFIED (2026-09-05)

The approved assertion-preserving portability follow-up closes the installed-package
blocker below. Qualification is for the bounded composition/runtime repair release,
not a claim of complete device/accessibility/network-resumption coverage.

### Test portability and assertion preservation

All five failures assumed tests ran two directories below a package source root.
R CMD check runs them against an installed layout: `inst/` is flattened and raw
`R/*.R` files are replaced by the lazy-load database. Only resource lookup changed.

| Test | Property preserved | Portable evidence | Unchanged assertion expressions |
|---|---|---|---:|
| browser-controls | Native input binding, teardown, motion/forced-colors contracts, no React/htmlwidgets | Same JS/CSS under installed `www/` | 28 |
| browser-surfaces | Observers, bounded history, fullscreen/focus, scoped tabs, accessible CSS, no React/htmlwidgets | Same JS/CSS under installed `www/` | 41 |
| config-draft-extension | Explicit empty selection publication and R-side value handling | Same installed JSX plus exact retained raw `module.R` | 32 |
| htmlwidgets-elimination | No dependency, forbidden implementation patterns, or htmlwidgets directory; direct constructors | Installed DESCRIPTION/assets and complete raw R qualification snapshot | 6 |
| palette-exactly-once-and-fanout | Guarded insertion identity and deterministic fan-out | Same installed `widget.jsx`; behavioral assertions unchanged | 19 |

An independent parsed-expression comparison against HEAD verified all **126** existing
assertion expressions unchanged after normalizing only path lookup. None removed,
skipped, or weakened. No deparsed-function substitution was made for raw source checks.
The explicit test-only snapshot retains all 32 R files because the original negative
implementation scan covered all R source. Four new checks validate completeness and
SHA-256 text identity. Only newline conventions are normalized, as in the original
`readLines(..., collapse="\\n")` inspection. Source execution rejects stale snapshots;
installed execution checks the retained source evidence and real installed assets.
Refresh the snapshot with `Rscript tools/sync-qualification-source.R` after R changes.

`browser_action_link` now documents `disabled` in both roxygen and Rd. No runtime
behavior changed in this follow-up. Prior lifecycle, queued-update, watermark,
workbench atomicity, resize, and overlay repairs remain in the release candidate.

### Final verification

- Full source suite, isolated intended candidate: **779 PASS / 0 FAIL / 0 WARN**.
  Before portability: 775; the difference is exactly four snapshot checks.
  Dirty working tree: 780, including one unrelated pre-existing assertion excluded
  from this release together with its corresponding unrelated JS guard.
- Full installed **R CMD check: Status OK**, including PDF manual;
  **779 PASS / 0 FAIL / 0 WARN / 0 SKIP**. R 4.5.2 on Windows x64. Existing Rtools45
  was put on this process's PATH, with process-only LANG/LC_ALL=C. No toolchain was
  installed. Repository-index network lookup warnings did not become check findings.
- JavaScript lifecycle suite: **9/9 PASS**, zero skips.
- Five existing browser scripts passed against the installed candidate: composition,
  release/atomicity/overlays/responsive, lifecycle stress, grid scale, and keyboard.
  Lifecycle: 120 cycles, mounts 4 -> 124, destroys 0 -> 120, live instances 4 -> 4,
  errors 0. Seven distinct atomic Apply/Reset events. Focus returned correctly.
  1600/1366/900/640 layouts fit the document; touch action passed. Console had only
  a missing favicon (404). Guided keyboard tests are not a full Tab-only audit.
- AG Grid **36.1.0 unchanged**; package.json/package-lock unchanged. No dependencies
  or framework features added. `git diff --check` and staged diff check passed.
- Remote ancestry before release: local main = origin/main =
  `e28770d37c4ce10ec489def94894cf814486cb22`, ahead/behind 0/0. Release target:
  `https://github.com/AdrianAntico/shinycapabilities.git`, branch `main`, version 0.2.2.
  Exact release SHA is the commit containing this section (reported at publication).

Unrelated browser guard/test and untracked AGENTS.md remain outside the commit;
line-ending-only generated CSS working changes are also left untouched. Previously
disclosed full touch-drag, dark contrast, Tab-only, and real network reconnect limits
remain limits, not silently upgraded claims. AG Grid was not modified.

## Prior release checkpoint: NOT_QUALIFIED (resolved above)

This section supersedes the initial-wave qualification/disposition below. The bounded
implementation passed the source and browser checks described here, but **publication
is blocked by installed-package test failures in R CMD check**. Nothing was committed
or pushed. Published main remains `e28770d37c4ce10ec489def94894cf814486cb22` / 0.2.1.
The staged, uncommitted candidate is 0.2.2; origin is
`https://github.com/AdrianAntico/shinycapabilities.git`, branch `main`.

### New defects found and repaired

- Queued operation lists were shallow-merged, losing earlier operations. Accepted
  patches now replay separately in arrival order.
- An authoritative full Shiny render lowered the stale-patch guard. The patch
  watermark now stays nondecreasing within the live instance.
- Explicit teardown retained a queued patch for the same element. Teardown clears it.
- Escape focused closed overlays and stole dialog-return focus. Only an open overlay
  closes; one Escape closes the active overlay before the dialog. Nested popovers
  remain inside the native modal, and their cleanup callback is retained.

Full renders remain authoritative host replacements, including ordinary reactive
renders whose constructor revision defaults to 1. This is **not** a distributed
ordering protocol across renders, sessions, or producer clocks. Patch senders must
use coherent revisions. Equal revisions remain accepted for compatibility with
multiple updates in the same second. Replacing/remounting an element starts a new
instance; the host owns durable identity and restoration.

### Qualification evidence

Tests ran against an isolated export of the staged candidate, excluding the
pre-existing browser-surface guard and its extra test assertion. Those unrelated
changes remain untouched and unstaged. No new repository was created.

| Area | Actual result |
|---|---|
| Full source R suite | 775 expectations PASS; zero failures/errors/warnings. Earlier 776 included the unrelated dirty assertion. |
| Executable JS transport suite | 9/9 PASS; late insertion, moves, replacement, duplicate identity, queued/stale operations, teardown, current-handle resize and 100 cycles. |
| Real composed lifecycle | 120 inspector mount/reparent/remove cycles: 124 total mounts, 120 destroys, 4 live instances before and after, zero transport errors. |
| Equipment-review | Tree/palette/grid/inspector/plot/split/action composition PASS, including early selection patch and applied threshold propagation. |
| Workbench | Seven distinct first-event Apply/Reset snapshots: applied=draft=event.values, dirty/conflict false, valid true, no errors. Three rapid Apply/invalid-draft/Reset sequences passed. A dirty draft of 72 survived host applied-value 35 with conflict visible; Reset was atomic. |
| Keyboard | Palette Ctrl+K/typing/Enter, tree arrow/Enter, grid arrow navigation, action Enter, modal focus containment/return, and split separator arrows passed. These are guided component journeys, not a complete Tab-only or screen-reader audit. |
| Overlays | Nested popover plus modal Escape/focus-return and palette shortcut containment passed after repair; popover/context-menu open/Escape exercised with notifications present. Exhaustive stacking/click-outside combinations remain unqualified. |
| Responsive / media | 1600/1366/900/640px: document width equaled viewport width; plot widths approximately 638/541/475/332px. Light presentation plus reduced-motion/forced-colors emulation exercised; separator focus outline remained solid. Coherent dark-theme and numerical contrast certification are not claimed. |
| Touch | Chromium touchStart/touchEnd activated the inspection action and reached Shiny. Physical-device testing and touch drag/resize remain TOUCH_UNQUALIFIED. |
| Reconnect | Repeated bridge initialization did not duplicate mounts. Fresh reload/remount worked. Real network session resumption and durable draft restoration remain unqualified and host-owned. |
| Existing API signatures / dependencies | Preserved; no new widgets, no AG Grid change. Asset dependency versions were bumped for cache invalidation in the unreleased candidate. |
| R CMD check | BLOCKED: five source-relative test file lookups fail when installed; 750 assertions pass before failures. Also one pre-existing missing `disabled` argument description in browser_action_link.Rd. |

### Scale characterization

Local Windows / R 4.5.2 / Chromium, single observations, not production limits.
R construction/JSON timings and browser fixture timings are separate measurements
with different fixture encodings, **not** an end-to-end transport benchmark.

| Rows | R JSON bytes | R construction / JSON seconds | Browser JSON bytes | DOM rows after filter | Mount observation ms (includes 500ms wait) | Filter observation ms (includes 100ms wait) |
|---:|---:|---:|---:|---:|---:|---:|
| 10 | 1,012 | 0.000 / 0.000 | 1,258 | 2 | 501.5 | 108.4 |
| 1,000 | 39,956 | 0.050 / 0.000 | 89,365 | 19 | 509.2 | 108.3 |
| 10,000 | 413,599 | 0.000 / 0.010 | 900,149 | 19 | 507.9 | 123.4 |
| 100,000 | 4,330,001 | 0.000 / 0.120 | 9,097,978 | 19 | 527.4 | 170.3 |

Zero reported R durations mean below measurement resolution, not zero cost. Browser
quick filtering produced the expected visible status values at every size. RSS/heap
peaks, network latency, reconnect transport, and sustained interaction percentiles
were not measured. Client virtualization does not solve transport size. AG Grid was
already in 0.2.1; this wave neither adds nor upgrades it. A future replacement requires
parity; server-backed/windowed browsing is a separate architecture decision.

### Exact remaining release blocker

With process-local `LANG=C` and `LC_ALL=C`, the locale startup failure disappeared.
R CMD check then exposed source-tree assumptions in:

- test-browser-controls.R: installed JS/CSS lookup;
- test-browser-surfaces.R: installed JS/CSS lookup;
- test-config-draft-extension.R: JS and R source lookup;
- test-htmlwidgets-elimination.R: DESCRIPTION and source lookup;
- test-palette-exactly-once-and-fanout.R: JS source lookup.

The proposed portability repair was rejected by the approval system because replacing
source inspection with installed-package/namespace inspection could weaken tests.
**That rejected patch made no changes.** No skip, removed assertion, test weakening,
or workaround was applied. Approval is needed for an assertion-preserving portability
repair before rerunning R CMD check and considering publication. The missing Rd argument
description is also still outstanding.

Other explicitly unqualified areas: screen readers, complete keyboard traversal,
physical touch devices and touch-resize gestures, comprehensive theme/contrast matrix,
all overlay stacks, and real disconnected-session restoration. These limits alone
need not block a bounded release, but the current R CMD check failures do.

Release decision: **NOT_QUALIFIED; uncommitted and unpublished**. The implementation,
tests and existing report are preserved for continuation; no competing closure report
was created. Reproduction scripts live under `tools/javascript/` and
`tools/grid-serialization-qa.R`. R CMD check logs are in the temporary
`sc-release-check-022-c/shinycapabilities.Rcheck` directory.

## Verdict and authority

**An emerging framework with strong components, not a completed UI framework.** Its unusually useful combination is typed configuration, inspectable objects, graph interaction, revisioned updates, and explicit draft/application behavior. The next investment should make these reliable together before adding widgets.

Inspected local and published `main`: `e28770d37c4ce10ec489def94894cf814486cb22`, version **0.2.1**, origin **https://github.com/AdrianAntico/shinycapabilities**. Remote main matched this commit. The host-neutral branch is a different, narrower history, not a newer complete UI platform. No branch switch, merge, commit, push, or version change was performed. Implementation described below is **uncommitted on main**, not contained in that SHA.

Pre-existing changes to `inst/www/browser-surfaces/browser-surfaces.js`, `tests/testthat/test-browser-surfaces.R`, and untracked `AGENTS.md` were preserved. Other packages were not modified.

**Dependency discrepancy:** published main already depends on `ag-grid-community` 36.1.0. This wave did not introduce, upgrade, or replace that dependency. A non-AG-Grid migration is not already present on the inspected remote branches; removing the existing grid without parity would violate component preservation. This remains a boundary requiring an explicit subsequent migration, not something silently resolved here.

## Inventory and evidence limits

`UI_FRAMEWORK_PUBLIC_SURFACE.csv` accounts for **144 exports**, with exact source files, parameter names, families, and classifications. Aliases, render/output/update functions and demo launchers are included, not counted as independent widgets. Regenerate with `Rscript tools/audit-ui-surface.R`.

The table below groups shared implementation contracts. R-suite PASS is package-wide; browser observations in this wave are specifically listed under QA. Presence of ARIA or a passing source-marker test is **not** screen-reader certification. Mobile/touch, full theme coverage, deep-data limits and reconnect restoration are **UNPROVEN unless explicitly tested below**. No component was judged missing solely because a demo did not expose it.

| Surface / source family | Classification | Problem, API and state | Interaction/accessibility and composition | Main gap / documentation judgment |
|---|---|---|---|---|
| Text, numeric, secret, textarea (`browser_controls.R`) | FOUNDATIONAL | Explicit native fields; value/error/disabled state; common updater | Native inputs and associated labels; easy Shiny use | Server update validation and consistent theme documentation need hardening |
| Checkbox, switch, radio, segmented, slider | FOUNDATIONAL | Binary, option and range choices; explicit parameters | Native interaction foundations; shared control shell | Do not replace native semantics merely for styling; hostile update coverage is thin |
| Action button/link | FOUNDATIONAL | Commands, loading/disabled hierarchy | Intent input distinct from configuration | Exactly-once initialization tests exist; server must authorize actions |
| Upload/download (`browser_surfaces.R`) | HIGH_VALUE | File transfer presentation over Shiny | Keep Shiny transfer lifecycle | Large/cancelled transfer and assistive-technology QA not established here |
| Tooltip, popover, context menu | HIGH_VALUE | Supplemental/contextual content | Focus/keyboard handled in browser surface JS | Overlay stacking and focus restoration across mixed components need composed QA |
| Dialog, confirmation, drawer/side-sheet/bottom-sheet modes | HIGH_VALUE | Native dialog with explicit open/dismissible state | Covers overlays; a new drawer widget would duplicate existing scope | Not a complete responsive application shell; uncommitted surface changes not owned by this wave |
| Tabs, accordion, breadcrumbs, pagination | HIGH_VALUE | Local navigation/disclosure | Appropriate semantic primitives exist | URL/history navigation and route restoration remain host work |
| Value, badge, progress, alert, skeleton | FOUNDATIONAL | Scalar/status/loading/error feedback | Semantic status surfaces | Retry policy/cancellation are host behavior; no universal async component contract |
| Notification center | HIGH_VALUE | Bounded notifications and updates | Existing feedback surface | Multiple overlay/live-region interaction needs browser proof |
| Output shell, report outline, output placement | HIGH_VALUE | Structured content placement and navigation | Useful wrappers, not an application router | Reader task examples and clear placement/state distinction needed |
| Selection input / field-picker alias | NEEDS_REDESIGN | Grouped search, multi/ordered selection, draft/applied, server search | Virtualized popup; keyboard handlers and portal theme copying | Closed caption uses `model.labels` rather than deriving option labels; R character normalization also discards supplied names. Updates accept broad `...`; normalization needed without removing features |
| Tree (`interaction_components.R`) | HIGH_VALUE | Search, expand, select, activate hierarchical records | Tree roles and keyboard paths; linked inspector demonstrated | Deep/large tree and singleton-array behavior need dedicated hostiles; no turnkey lazy hierarchy provider |
| Command palette / direct aliases | HIGH_VALUE; aliases REDUNDANT | Search/activation/server-search intent | Keyboard activation demonstrated | Alias naming increases memorization; preserve compatibility, document one preferred constructor trio |
| Split pane / direct split variants | FOUNDATIONAL | Named panes, bounds, collapse, resize state | Keyboard separator; arbitrary Shiny content | Responsive orientation policy and delayed plot sizing remain application responsibilities |
| Grid | INCOMPLETE | Stable row IDs, sorting/filtering, column state, copy, selection, virtualization | Linked selection and browser rendering demonstrated | Full data sent to browser; not server-backed browsing. No transactional editing API. Existing AG Grid dependency conflicts with intended future boundary |
| Parameter workbench | HIGH_VALUE | Typed schema, conditions, sections, validation, draft/applied/conflict | Composes with inspector and plot after atomic Apply repair | Server currently receives browser validity, not an independent authorization gate. Presets/undo and async composition need explicit design; module API is legitimate, not needless inconsistency |
| Object inspector | HIGH_VALUE | Typed, redacted, bounded nested object projection; patch/update | Search/tree/copy/focus; composed record inspection | Not an arbitrary object serializer; communicate truncation/redaction limits and scaling |
| Code editor | HIGH_VALUE | Monaco edit/diff, diagnostics, completion requests, dirty conflict | Expert editing, explicit Apply | Heavy but justified for IDE use; not a replacement for every textarea. Cross-editor shortcut/focus QA remains |
| Persistent UI | HIGH_VALUE | Keyed bounded schema patches, revision and identity | Avoids whole-tree replacement for suitable content | Not a second reactivity system; documentation must explain when ordinary renderUI is simpler |
| Relationship graph | NICHE | Validated read-only nodes/edges; selection/navigation/filter intent | Host-neutral graph projection | Useful for graph tasks, not mandatory app navigation; dense graph touch/keyboard QA remains |
| Agent activity monitor | NICHE | Actors/work/dependencies/events, redacted projection | Read-only inspection, no execution authority | Name/domain breadth narrower than general app needs; retain rather than prioritize more monitor variants |
| Execution replay | NICHE | Ordered events/snapshots and state-at-time | Explicit historical selection, read-only | Valuable specialist surface; not durable application persistence by itself |
| Workstation header | HIGH_VALUE | Command groups, priorities, responsive header | Generic command data despite historical name | Legacy naming, not proof of host dependence; full shell/sidebar/routing not supplied |
| Direct transport/shared runtime | FOUNDATIONAL | Output/render/update with registered mount/update/destroy | Shared resize/lifecycle and bounded events | This wave repairs composition defects; mixed revision streams and truncation deserve tighter contracts |
| Canvas, registry, ports, config, graph validation | FOUNDATIONAL for workflow apps | Typed capabilities, graph edits, semantic connections | Browser intent vs host graph truth | Not needed by ordinary form apps; README over-centers this special case |
| Planner/runtime/cancellation/cache | FOUNDATIONAL for workflow apps | Bounded callr execution and runtime snapshots | Explicit ownership of child processes | Preserve optionality; do not make every UI action enter a graph scheduler |
| Documents/proposals/collapse/expand/compatibility/icons | FOUNDATIONAL support | Serializable workflow identity, proposals, graph composites, presentation vocabulary | Not individual UI components | `composition.R` means graph composition, not UI layout composition; document this distinction |
| Demo launchers | NICHE support | Discoverability, not analytical/UI capability | Existing examples mostly demonstrate one surface at a time | Equipment review now provides a linked task, not another gallery |

No API was marked LEGACY solely because its name is old. REDUNDANT denotes compatible access paths, not permission to delete them. Per-family classifications in the CSV are triage judgments, not deprecation declarations.

## Framework target and replacement boundary

It can reasonably absorb **most common field/control presentation**, much **inspection and navigation interaction**, and **some desktop layout plumbing**. A percentage would be invented: no representative application corpus or labor measurements exist. It cannot yet absorb most responsive shell, remote-data, transactional-editing, and cross-component accessibility work.

| Shiny concept | Boundary |
|---|---|
| Reactives, observers, reactive values, modules, sessions, invalidation | KEEP_SHINY |
| renderPlot/renderUI, async integration, downloads/uploads | WRAP_SHINY where presentation helps; retain runtime semantics |
| Ordinary fields, buttons, feedback, disclosure, tables | REPLACE_PRESENTATION where current components improve the task |
| Selection, keyboard tree/palette, panes, inspector navigation, draft editing | REPLACE_INTERACTION using existing input/output bindings |
| A new reactive engine, universal graph around every input, duplicate session/router authority | NOT_WORTH_REPLACING |

Missing application work is concentrated in shell regions/breakpoints, routing/back-forward, common theme propagation, consistent empty/error/repair presentation, server-backed data windows, and chart resize/selection coordination. Drawers, typed forms, menus and inspectors are **not absent**.

## Ten ranked gaps

Scores are qualitative engineering prioritization, not measured utility. Frequency / end-user / developer / composition / accessibility leverage are H/M/L; complexity is relative. Existing overlap is a reason to harden, not duplicate.

| Rank | Work | Freq / user / DX / composition / a11y | Complexity; overlap |
|---|---|---|---|
| 1 | Lifecycle and atomic event/state consistency | H/H/H/H/H | M; shared transport/workbench already exist; implemented bounded repair |
| 2 | Application theme/token and density propagation | H/H/H/H/H | M; separate component CSS systems already exist |
| 3 | Responsive region/shell composition recipes | H/H/H/H/M | M; header/splits/drawers exist, no need for a new shell engine |
| 4 | Programmatic update validation and documented revision/identity rules | H/H/H/H/M | M; existing update APIs should remain |
| 5 | Selection label/value consistency and focus/lifecycle hardening | H/H/H/H/H | M; use existing selector, no new dropdown family |
| 6 | Unified overlay focus, Escape, shortcut arbitration | H/H/M/H/H | M; dialogs/palette/menus already overlap |
| 7 | Server-backed windowed data and explicit editing transactions | M/H/H/H/H | H; current client grid is not this capability; non-AG boundary needs explicit migration |
| 8 | Form presets/reset/conflict and async task composition recipes | H/H/H/H/M | M; workbench/runtime primitives exist |
| 9 | Resize-aware chart host and linked-selection recipe | M/H/H/H/M | M; retain Shiny plotting and third-party charts |
| 10 | API task index, error troubleshooting, executable composition matrix | H/M/H/H/H | L/M; many demos/help files exist but weakly connected |

Defer novelty widgets, a new reactive/server layer, an obligatory app-state store, automatic business actions, wholesale API renaming, and grid replacement without feature/interaction parity. What makes this compelling is fewer timing, focus and state bugs in ordinary code, not maximum widget coverage.

## Common component philosophy

1. Host owns durable/application truth; browser owns focus, viewport and explicitly unapplied drafts.
2. Stable component ID identifies one live element. Reparent is not unmount; removal cleans owned observers/resources; replacement has distinct element identity.
3. Constructors provide complete initial state. Updates are patches, never mistaken for full initialization.
4. Apply/Reset events carry the state they claim to commit. Intent is not authorization; browser validation is not server authorization.
5. Named public constructor/output/render/update families remain; modules are appropriate for multi-reactive forms. Do not force all interfaces into one signature.
6. Revision policy must say whether it orders patches, full renders, or both. Do not call timestamp defaults globally monotonic across reconnects.
7. Labels and values remain distinct. Error/loading/empty/disabled/conflict are inspectable; bounded/truncated events must not look complete.
8. Standard focus, keyboard, reduced-motion, density and theme contracts need shared documented expectations plus real-browser tests.

## Implemented wave: composition reliability

No new public functions or dependencies. Public signatures preserved.

- Direct transport mounts late-inserted static payloads.
- DOM moves preserve mounted instances; detached replacements are retired by element identity, not ID alone.
- Connected duplicate IDs produce a visible error without taking over the original instance.
- ResizeObserver uses the current handle returned by update rather than a stale mount-time handle.
- Transport restores its lifecycle marker when a renderer replaces className (the existing grid does this).
- Early custom patches are queued until a complete initial render; stale queued patches cannot overwrite newer queued state.
- Workbench Apply/Reset publishes coherent applied/draft/dirty/conflict/validation state with the event, removing the observed previous-value race.
- Added `inst/examples/equipment-review/app.R`: tree/palette/grid selection, inspector, explicit parameter Apply, plot, split and inspection action. Deterministic 120-record equipment fixture; no domain-specific coupling.
- Added executable lifecycle tests and browser composition/scale scripts. Rebuilt shipped assets with existing Vite configs.

## QA and limits

Baseline full R test suite: PASS. Final full R regression: **776 passed expectations, zero failures/errors/warnings** (R startup emits separate local locale warnings). `git diff --check`: PASS. Six new Node lifecycle tests: PASS, including 100 mount/unmount cycles, connected duplicate identity, replacement, late insertion, stale early updates and replacement-handle resizing.

Real Chromium/Shiny composition: PASS for explicit inspection action, parameter Apply reaching the inspector, tree selection, keyboard palette activation, grid reparent preservation, hidden/show exercise, late static mount and removal. Desktop 1440px and 900px screenshots captured and inspected. Initial fixture typo (`number` instead of the public `numeric`) was corrected; early-patch and atomic-Apply defects were reproduced before correction. Cache clearing was required to test rebuilt assets under unchanged development dependency versions.

Existing-grid browser smoke measurement (local machine, four mixed columns):

| Rows | JSON bytes | DOM rows | Elapsed including deliberate 500ms wait |
|---:|---:|---:|---:|
| 10 | 1,258 | 10 | 507ms |
| 100,000 | 9,097,978 | 19 | 520.6ms |

These are **not fit-to-screen benchmarks, R-to-browser timings, memory optimization, production ceilings, or throughput claims**. No heap/RSS measurement was taken. Virtualization bounds visible DOM, not transported data. Narrow screenshot timing exposed the need to wait for Shiny's resized plot before judging clipping.

Still UNPROVEN in this wave: screen-reader operation; touch gestures; full light/dark/reduced-motion/contrast matrix; all overlays combined; deep trees; many-field forms; disconnected session restoration; cross-component shortcut arbitration; async cancellation/retry composition; end-to-end 100k-row serialization/network/heap behavior. The broader framework is **not fully qualified** by these targeted checks. The composed demo is a useful reference starting point, not a polished universal shell.

## Run and review

From the package root with this source installed:

```r
shiny::runApp(system.file("examples", "equipment-review", package = "shinycapabilities"))
```

Developer source run: `pkgload::load_all(); shiny::runApp("inst/examples/equipment-review")`.
Node regression: `node --test tools/javascript/direct-transport.test.cjs`.
Browser scripts: `tools/javascript/composition-browser-qa.js` and `grid-scale-browser-qa.js`, used through the existing Playwright CLI with the app at port 7897. Their temporary screenshot paths are local QA artifacts, not package runtime assumptions.

**Release disposition:** bounded repairs and evidence are available for review; no release/publication claimed. Complete accessibility/responsive/async qualification and choose the non-AG-grid boundary before calling the framework complete.
