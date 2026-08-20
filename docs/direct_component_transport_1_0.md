# Direct Component Transport 1.0

## Decision

**Qualified for incremental migration planning; not qualified for removal.**
Command Palette and the non-React Persistent Dynamic UI now independently use
the same package-owned lifecycle, revision, event, resize, and teardown runtime.
This proves the transport is reusable and framework-neutral. It does not yet
justify removing `htmlwidgets`: existing widgets require static HTML and
installed-package, reconnect, CSP, and long-duration memory behavior still need
qualification. See the [second qualification](persistent_dynamic_ui_1_0.md).

## What htmlwidgets currently owns

| Concern | Current ownership | Direct equivalent | Still needed? |
|---|---|---|---|
| Output binding | Generic htmlwidgets Shiny output binding | One package output binding and registry | Yes |
| Serialization | R list normalization plus htmlwidgets JSON serialization | Shiny output serialization; `jsonlite` for static tags | Yes |
| Initialization | Widget factory and `renderValue()` | `mount()` contract | Yes |
| Sizing | Widget sizing policy and container styles | Explicit output dimensions plus `ResizeObserver` | Yes |
| Resize | htmlwidgets resize callback | output-binding resize plus `ResizeObserver` | Yes |
| Dependencies | YAML discovery and html dependency resolution | conditional `htmltools::htmlDependency()` | Yes |
| Updates | output re-render; component-specific custom handlers elsewhere | output render plus one revisioned custom message | Yes |
| Teardown | No React teardown in current palette factory | mutation observation plus required `destroy()` | Yes, improved |
| Multiple instances | Factory per element | instance map keyed by unique output id | Yes |
| Shiny events | `HTMLWidgets.shinyMode` plus `Shiny.setInputValue()` | bounded transport `emit()` | Yes |
| Static HTML | `createWidget()` and static bootstrap | embedded JSON tag plus static scan | Used by existing examples/reports |
| Reconnect/rebind | htmlwidgets/Shiny binding machinery | idempotent binding registration and render delivery | Yes |

The useful htmlwidgets contract is modest, but mature. The direct transport
should replace it only after matching the parts actually used, not by copying
the entire framework.

## Architecture

```text
command_palette_direct()
  -> direct_component_output()
  -> Shiny.OutputBinding / one custom-message handler
  -> component registry
  -> shared browser runtime v1
  -> command-palette-direct.js
```

The transport owns `mount`, `update`, `resize`, and `destroy` lifecycle calls.
It keeps one instance record per element, rejects stale revisions, limits
browser-to-Shiny event payloads to 16 KiB, exposes diagnostics, and displays
render failures as accessible alerts. A `MutationObserver` unmounts removed
React roots; a `ResizeObserver` notifies the active component. Dependencies are
attached only where a direct output/tag is present.

The R object remains host-neutral. Module namespacing is applied at the update
boundary with `session$ns()`. Output ids are the authoritative component ids.
Static objects use an explicit `element_id`, or a stable payload hash when none
is supplied; duplicate identical static objects should therefore provide
explicit unique ids.

## Shared runtime

The direct test separates:

* `browser-runtime-v1.js`: versioned React 19.2.8, React DOM, and TanStack Virtual 3.13.12;
* `direct-transport.js`: framework-neutral lifecycle and Shiny transport;
* `command-palette-direct.js`: component behavior only.

Built sizes are:

| Asset | Raw | Gzip |
|---|---:|---:|
| Shared browser runtime v1 | 203.26 KB | 63.30 KB |
| Direct palette | 4.72 KB | 2.03 KB |
| Direct palette CSS | 2.49 KB | 0.90 KB |
| Existing combined interaction bundle | 211.47 KB | approximately 66 KB |

One direct palette is not materially smaller than one existing bundle. The
payoff begins with the second React-backed component: it adds a component-sized
bundle rather than another embedded React runtime. AG Grid, XYFlow, and other
large libraries remain separate and lazy.

## Test component

`command_palette_direct()` mirrors the normalized payload of
`command_palette()` while coexisting with it. It exercises virtualized rows,
keyboard navigation, focus shortcuts, query and command events, custom-message
updates, multiple instances, static mount, and React teardown. Existing public
component behavior was not changed.

## Benchmarks

`tools/benchmark_direct_transport.R` compares R construction and serialized
payload bytes at 100, 1,000, and 10,000 commands. Browser QA records mount and
update duration on each element and transport lifecycle counters. Results are
captured during qualification rather than inferred from dependency count.

Measured results (25 repetitions) were:

| Commands | htmlwidgets median | direct median | htmlwidgets bytes | direct bytes |
|---:|---:|---:|---:|---:|
| 100 | <10 ms | <10 ms | 16,817 | 16,879 |
| 1,000 | 40 ms | 30 ms | 170,721 | 170,783 |
| 10,000 | 370 ms | 370 ms | 1,745,725 | 1,745,787 |

The 62-byte direct envelope is negligible and R construction is effectively
equivalent. Browser qualification mounted three simultaneous virtualized
palettes with 1,350 total records; initial direct delivery was 0.1-0.8 ms in
the transport timer. Both versions rendered 14 visible virtual rows at 420 px.
A 100-update burst reached revision 100 without duplicate instances; final
transport delivery was below timer resolution. Each 100-record update was
about 16.9 KB, so that deliberately aggressive burst transferred about 1.7 MB
and completed within the 6.5-second qualification window. The browser surface did not
expose reliable heap telemetry, so memory claims are deliberately withheld.

## Lifecycle qualification contract

The demo and browser checks cover:

* initial mount and structured payload;
* custom-message update and stale-revision rejection;
* multiple simultaneous instances;
* keyboard command activation and bounded Shiny events;
* hidden-to-visible and container resize;
* dynamic removal, React unmount, and remount;
* 100-update burst behavior;
* namespaced ids;
* singleton output binding and message handler;
* no duplicate React roots and no retained instance after removal.

All listed checks passed in Chromium. Removal reduced the target output count
to zero and remount created one fresh palette with reset local query state.
Hidden-to-visible restored the component without remount. Command and query
events arrived under the expected output-id suffixes. A disconnected-network
reconnect and long-duration heap profile remain unqualified.

Reconnect is covered structurally through idempotent registration and
`renderValue()` delivery, but a network disconnect/reconnect remains a future
installed-app qualification item.

## Static behavior

Static behavior is genuinely used: existing interaction components have R
Markdown/static examples and `createWidget()` returns portable tags. The
experiment supplies a minimal equivalent by embedding an application/json
payload and mounting it on DOM readiness. It intentionally does not recreate
htmlwidgets sizing policies, knitr hooks, or broad viewer integration. Those
must be qualified before elimination. A saved standalone HTML page was served
without Shiny and mounted the direct palette with no browser errors.

## Dependency impact

If every relevant htmlwidget is migrated and static/package qualification
passes, `htmlwidgets` could leave `Imports`; `shiny`, `htmltools`, and `jsonlite`
remain. Installation still requires no Node.js because built assets ship in
`inst/www`. Maintainers continue using Node/Vite. Browser payload should fall as
React-backed components share one runtime, but specialized libraries stay
page-specific. Package installation simplification is real but secondary to
lifecycle and payload evidence.

## Safest migration path

1. Use Persistent Dynamic UI as the second, framework-neutral qualification.
2. Add installed-package static HTML and reconnect tests.
3. Compare real browser memory after repeated mount/update/remove cycles.
4. Migrate simple Shiny-only components one at a time behind parallel APIs.
5. Migrate static-report components only after static parity is proven.
6. Remove `htmlwidgets` only when no package code, tests, docs, or Workstation
   seam depends on it.

## Promotion Readiness

Before canonical promotion, prove Windows installed-package behavior, source
package build/check, static R Markdown output, multiple Shiny modules,
disconnect/reconnect, browser memory stability, CSP compatibility, and all
supported browsers. Workstation must then qualify its installed package and
every migrated page independently. No Workstation integration is authorized by
this checkpoint.
