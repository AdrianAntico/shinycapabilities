# htmlwidgets Elimination and Component Modernization 1.0

## Decision

`shinycapabilities` no longer depends on or implements components through
`htmlwidgets`. Public browser components use Direct Component Transport, with
Shared Browser Runtime reused where it reduces duplication. Specialized browser
engines remain isolated behind the same transport contract.

The resulting architecture is:

```text
Shiny / htmltools
  -> normalized R component contract
  -> Direct Component Transport
  -> Shared Browser Runtime, when applicable
  -> specialized browser component or engine
```

This change removes an intermediate R-to-JavaScript abstraction. It does not
remove Shiny, `htmltools`, `jsonlite`, or the mature browser engines that provide
material interaction value.

## Migration Inventory

| Component | Previous transport | 1.0 transport | Browser engine decision |
|---|---|---|---|
| Capability Canvas | htmlwidget | Direct Component Transport | Retain isolated XYFlow engine |
| Virtual Tree Browser | htmlwidget | Direct Component Transport + Shared Browser Runtime | Reuse React/TanStack runtime |
| Command Palette | htmlwidget | Thin compatibility alias to `command_palette_direct()` | Reuse shared runtime; retire duplicate bundle |
| AG Grid Data Grid | htmlwidget | Direct Component Transport | Retain isolated AG Grid Community engine |
| Agent Activity Monitor | htmlwidget | Direct Component Transport + Shared Browser Runtime | Reuse React/TanStack runtime |
| Relationship Graph | htmlwidget | Direct Component Transport | Retain isolated XYFlow/Dagre engine |
| Execution Replay | htmlwidget | Direct Component Transport + Shared Browser Runtime | Reuse React/TanStack runtime |
| Selection Input | custom Shiny input stored under `inst/htmlwidgets` | Direct asset layout + Shared Browser Runtime | Preserve input contract |
| Typed Parameter Workbench | custom Shiny input stored under `inst/htmlwidgets` | Direct asset layout + Shared Browser Runtime | Preserve input contract |
| Split Pane | custom Shiny input stored under `inst/htmlwidgets` | Direct asset layout + Shared Browser Runtime | Reuse panel engine |

Every previous use is classified. There is no compatibility htmlwidget shim.

## Contract

R constructors return `shinycapabilities_direct_component` objects containing a
component name, normalized payload, dimensions, and revision. Output bindings
mount registered components, deliver revisioned updates, reject stale revisions,
observe resize, and destroy instances after removal. Component update helpers use
the same `shinycapabilities.direct.update` message contract.

Static tags embed bounded JSON and the same browser dependencies. Reports and
other static consumers can therefore mount components without the htmlwidgets
runtime. Shiny input components still require Shiny when their purpose is to send
host input events.

## State and Lifecycle

- Host state remains authoritative.
- Browser-only interaction state is preserved across in-place updates where the
  component contract permits it.
- Updates are namespaced and monotonic; stale revisions are ignored.
- Mutation and resize observers are shared rather than recreated per component.
- Destroy handlers release React roots, engine instances, observers, and event
  subscriptions.
- Components emit bounded user events, not mirrored internal state.

## Dependency Boundary

Required R runtime dependencies are `shiny`, `htmltools`, `jsonlite`, `digest`,
and `callr`. Node.js is only required to rebuild checked-in browser assets.

Specialized dependencies are justified by capability:

- XYFlow/Dagre for graph interaction and directed layout.
- AG Grid Community for dense analytical grids.
- Monaco for code editing.
- React/TanStack and panel primitives once in Shared Browser Runtime.

Removing those engines would reduce capability rather than simplify the system.

## Bundle Evidence

Ordinary React components no longer embed separate React/TanStack copies. The
shared runtime grows once to include reusable panel support, while selection,
tree, parameter, split-pane, activity, and replay bundles become small component
definitions. Large specialized bundles remain independently lazy-loadable.

| Asset | Before raw / gzip | After raw / gzip |
|---|---:|---:|
| Selection | 230.0 / 72.7 KB | 27.8 / 10.6 KB |
| Tree and legacy palette | 211.5 / 65.7 KB | 5.9 / 2.6 KB |
| Parameter Workbench | 198.1 / 61.7 KB | 9.1 / 3.4 KB |
| Split Pane | 225.9 / 70.3 KB | 4.5 / 2.0 KB |
| Agent Activity Monitor | 214.2 / 66.4 KB | 12.4 / 4.3 KB |
| Execution Replay | 217.7 / 67.4 KB | 15.9 / 5.3 KB |
| Shared Browser Runtime | duplicated above | 238.0 / 73.9 KB once |

For these ordinary React capabilities, raw JavaScript falls from about 1.30 MB
of repeated runtimes to about 313 KB including the shared runtime. Gzip falls
from about 404 KB to about 102 KB. Capability Canvas (~389 KB raw), Data Grid
(~862 KB), and Relationship Graph (~426 KB) remain approximately unchanged
because their specialized engines are independently lazy-loaded.

This optimizes page-level payload: shared libraries are paid once and specialized
engines are loaded only when used. Measurements use production files and gzip
level 9; they are checkpoint evidence rather than API guarantees.

## Qualification Contract

Promotion requires all of the following:

1. `htmlwidgets` is absent from `DESCRIPTION`, R sources, direct assets, and the
   installed package implementation.
2. The package installs and loads in a library where `htmlwidgets` is unavailable.
3. Public constructors, outputs, renderers, and update helpers retain their
   documented behavior.
4. Static tags contain valid payload/dependency markup.
5. Multiple instances, namespacing, resize, removal/reinsertion, and stale-update
   behavior are qualified.
6. The composition demo mounts representative shared and specialized components.
7. Browser console, keyboard, focus, and bounded-event checks pass.
8. Built assets are present in source archives and installed packages.

The four pre-existing baseline failures remain tracked separately and are not a
license for new regressions.

## Rollback

Rollback is a Git revert of this modernization commit. There is no dual-runtime
feature flag because maintaining two component transports would recreate the
complexity this checkpoint removes. Host applications should promote a qualified
package build, not bind directly to the lab source tree.

## Promotion Readiness

The lab package owns browser rendering, component lifecycle, normalization at its
public boundary, and bounded interaction events. A host owns business semantics,
authorization, execution, persistence, and governed state.

Before Workstation promotion, Grok should map one component at a time, verify its
existing input/output seam, run installed-package and Electron qualification, and
retain a package-version rollback. No host migration is included in this change.
