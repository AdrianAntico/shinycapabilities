# Shared Browser Runtime 1.0

## Decision

**Adopt the shared runtime for new Direct Transport components and incrementally
migrate existing components.** Do not mass-migrate existing htmlwidgets and do
not move specialized libraries into the runtime.

This checkpoint does not authorize Analytics Workstation integration or
`htmlwidgets` removal.

## Duplication Inventory

The lab currently ships these React-backed htmlwidget bundles:

| Bundle | Raw JS | Gzip JS | Material dependency |
|---|---:|---:|---|
| Interaction components | 211,472 | 65,805 | React, TanStack Virtual |
| Parameter Workbench | 198,143 | 61,856 | React |
| Split Pane | 225,880 | 70,412 | React, react-resizable-panels |
| Agent Activity Monitor | 214,230 | 66,595 | React, TanStack Virtual |
| Execution Replay | 217,733 | 67,571 | React, TanStack Virtual |
| Selection System | 230,006 | 72,811 | React, ReactDOM portal, TanStack Virtual |

These six files total 1,297,464 raw bytes and 405,050 gzip bytes. Each is an
independent IIFE containing React/ReactDOM. TanStack Virtual is duplicated in
four bundles. Parameter Workbench needs neither virtualization nor a specialized
kernel. Split Pane needs its panel kernel but not a private React runtime.

Specialized bundles intentionally remain isolated:

| Bundle | Raw JS | Gzip JS | Reason |
|---|---:|---:|---|
| AG Grid | 861,988 | 238,671 | Large, grid-only engine |
| Relationship Graph | 426,204 | 134,237 | XYFlow and Dagre |
| Capability Canvas | 388,374 | 121,910 | XYFlow and canvas behavior |

Moving those libraries into a common runtime would make unrelated pages pay for
them and would weaken lazy loading.

Across current htmlwidget and Direct Transport JS assets, the source package
contains 3,234,043 raw bytes and 981,803 gzip bytes. This total deliberately
includes parallel qualification implementations; it is not the payload of one
page.

## Runtime Contract

`browser-runtime-v1.js` publishes one frozen global:

```text
window.ShinyCapabilitiesBrowserRuntimeV1
  identity.name
  identity.major
  identity.version
  identity.react
  identity.tanstackVirtual
  React
  ReactDOM
  createRoot
  useVirtualizer
  assertCompatible(requiredMajor)
```

Runtime identity is `shinycapabilities-browser-runtime` major 1, version 1.0.0.
Loading a conflicting major fails visibly. A component declares `runtimeMajor`
when registering with Direct Component Transport; registration fails if the
runtime is absent or incompatible.

R attaches three independent `htmlDependency()` layers in deterministic order:

1. `shinycapabilities-browser-runtime` when the component needs React;
2. `shinycapabilities-direct-transport` once per page;
3. one component-specific JS/CSS dependency.

`htmltools::resolveDependencies()` deduplicates the first two by stable name and
version. Package upgrades change the dependency version or package resource URL,
preventing stale runtime/component mixtures. Component/runtime major mismatch
checks are a second guard. Built assets ship in `inst`; Node.js is not required
at package installation or runtime.

## Qualification Components

### Command Palette

Command Palette exercises React, TanStack Virtual, keyboard navigation,
virtualized records, bounded events, updates, multiple instances, and static
mounting. Its component bundle is 4,717 raw bytes / 2,026 gzip bytes.

### Split Pane

The experimental `split_pane_direct()` uses shared React while retaining
`react-resizable-panels` in its 35,554 raw byte / 11,752 gzip byte component
bundle. It exercises a materially different lifecycle: embedded bounded HTML,
Shiny binding/unbinding inside panes, resize events, imperative collapse/expand,
teardown, and remount.

Existing `command_palette()` and `split_pane()` implementations and public
contracts remain supported and unchanged. Direct variants are parallel
qualification surfaces.

## Before And After

For the qualified Command Palette plus Split Pane surface:

| Architecture | Raw JS | Gzip JS |
|---|---:|---:|
| Existing palette bundle + split bundle + old direct vendor | 433,295 | about 136,200 |
| Shared runtime + direct palette + direct split | 243,530 | 77,052 |
| Reduction | 189,765 (44%) | about 59,100 (43%) |

The comparison includes the runtime once in both paths. Browser load and mount
cost still depend on parsing, cache state, DOM complexity, and specialized
component work; byte savings alone are not a latency claim.

If all six generic React bundles eventually migrate, eliminating five duplicate
runtime copies offers roughly 1 MB raw and 300 KB gzip theoretical savings.
That estimate must be replaced by component-by-component built evidence because
tree shaking and component code differ.

## Lazy Loading

| Page surface | Loaded Direct JS |
|---|---:|
| Persistent UI only | 16,483 raw; no React runtime |
| Command Palette only | 214,879 raw |
| Command Palette + Split Pane | 250,433 raw |
| Palette + Split Pane + Persistent UI | 260,013 raw |
| AG Grid page | AG Grid bundle only; shared runtime not attached |
| Relationship Graph page | graph bundle only; shared runtime not attached |

Installing the package loads nothing into the browser. Dependencies are attached
only by rendered tags. A full composition demo intentionally loads the runtime,
three Direct components, AG Grid, Relationship Graph, Agent Activity Monitor,
and Execution Replay to detect conflicts; that page is a stress fixture, not a
recommended production payload.

## Composition And Lifecycle

`run_shared_browser_runtime_demo()` qualifies simultaneous Direct and htmlwidget
components. The expected page contract is:

* one browser runtime and one Direct Transport script;
* independent React roots per component output;
* no event or namespace cross-talk;
* stable updates and revisions;
* resize propagation;
* direct-surface remove/remount with clean teardown;
* specialized htmlwidget assets remaining independent;
* no duplicate runtime globals or incompatible-major acceptance.

Direct Transport remains responsible for output binding, revision handling,
bounded events, resize observation, accessible errors, static payload mounting,
and mutation-based teardown. The runtime owns libraries and compatibility only;
it does not own component instances or business state.

Chromium composition QA loaded exactly one runtime script and one transport
script alongside all four specialized htmlwidget bundles. Three Direct
components mounted with zero errors. A coordinated update preserved the
Persistent UI draft, updated Command Palette content, and advanced Split Pane to
revision 2. Removing the containing UI destroyed all three instances and reduced
the live count to zero; remount produced three fresh instances while the runtime
script count remained one. The incompatible-major check rejected major 2 with a
clear error. Warm-cache navigation reached DOM content loaded in about 95 ms;
Direct delivery timers were 0.1 ms for Palette, 0.9 ms for Persistent UI, and
0.5 ms for Split Pane. These are local warm-cache observations, not network
benchmarks. Chromium exposed roughly 11.9 MB used heap after composition, but a
single snapshot is not evidence of a memory reduction or leak.

## Static And Cache Behavior

Static `as.tags()` output retains ordered dependencies and embedded JSON. The
runtime loads before Direct Transport and component registration. Static mount
continues through Direct Transport's DOM scan. Browser and package caches key
the runtime through its dependency name/version and resource path.

Patch releases within runtime major 1 must remain backward compatible. A
breaking library or global contract requires `browser-runtime-v2.js`, a new
dependency name/major, and explicit component migration. Two runtime majors must
not silently share a component root.

Disconnected-network reconnect and mixed installed package versions remain
promotion qualifications rather than inferred guarantees.

## Performance Interpretation

Consolidation primarily reduces transfer, parsing, and retained duplicate
library code when several compatible components share a page. It does not make
component algorithms faster. Persistent UI remains faster because of keyed
patching, not because of this runtime. AG Grid and graph performance are
unchanged. Browser heap readings are useful for regression detection but are not
precise enough here to claim a quantified memory reduction.

## htmlwidgets Implications

The shared runtime removes a major obstacle to Direct Transport adoption: new
React-backed components no longer need private React bundles. It strengthens the
case for incremental `htmlwidgets` reduction, but does not justify removal.
Static R Markdown, reconnect, installed-package upgrades, CSP, browser support,
and each component's lifecycle must still be independently qualified.

## Promotion Readiness

The package owns runtime versions and built assets. Components own only their
specific code and declared runtime major. Specialized engines remain local.
Hosts supply state and handle emitted intents.

Before Grok promotes this architecture to canonical `shinycapabilities`, it
must qualify:

* installed source and binary package resource URLs;
* package-upgrade cache behavior;
* Workstation CSP and Electron/WebView behavior;
* reconnect and long-duration memory;
* all migrated component parity and accessibility;
* static/R Markdown consumers;
* old and new implementation coexistence during migration.

No Workstation migration is authorized by this checkpoint.

## Reproduction

```r
pkgload::load_all(".")
source("tools/audit_shared_browser_runtime.R")
run_shared_browser_runtime_demo()
testthat::test_file("tests/testthat/test-shared-browser-runtime.R")
```
