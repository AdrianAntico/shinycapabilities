# Persistent Dynamic UI 1.0

## Decision

**Useful only for selected surfaces.** Persistent Dynamic UI should be preferred
for large, frequently refreshed, schema-shaped analytical summaries where stable
identity, focus, scroll, and local draft state matter. `renderUI()` remains the
right tool for small or infrequent fragments, arbitrary Shiny tag composition,
and UI containing server-bound Shiny inputs. Specialized data grids, trees,
graphs, editors, and artifact renderers should remain specialized components.

This checkpoint does not authorize an Analytics Workstation migration.

## Experimental API

```r
persistent_ui(nodes, revision = 0L, aria_label = "Dynamic analytical interface")
persistent_ui_output(output_id, width = "100%", height = "auto")
render_persistent_ui(expr, env = parent.frame(), quoted = FALSE)
update_persistent_ui(session, output_id, nodes, revision,
  previous_nodes = NULL)
```

The bounded node types are `section`, `row`, `text`, `value`, `badge`, `field`,
and `action`. Nodes have deterministic IDs, parent relationships, order,
visibility, enabled state, and type-specific values. Nested `children` are
normalized into the same flat relationship contract. Duplicate IDs, missing
parents, cycles, and children under leaf nodes are rejected before transport.

Supplying `previous_nodes` creates an `upsert`/`remove` patch. Without it, the
API sends a full normalized model. Revisions are monotonic and the shared Direct
Component Transport rejects stale deliveries.

## Architecture

```text
R host state
  -> bounded normalized node schema
  -> one revisioned Shiny message
  -> Direct Component Transport
  -> keyed DOM reconciliation
  -> bounded user intent event
```

The browser mounts once and keeps an element map keyed by node ID. Updates patch
attributes and text in place, insert only missing nodes, remove absent nodes,
and move a node only when its ordered DOM position changed. No React runtime is
used. A `ResizeObserver`, stale-revision protection, mutation-based teardown,
error boundary, event-size limit, and instance registry come from Direct
Component Transport.

## State Ownership

| State | Owner | Behavior |
|---|---|---|
| Business value, visibility, enabled state, structure | Host | Authoritative and revisioned |
| Focus and scroll | Browser | Preserved during keyed updates |
| Expanded sections and selected row | Browser | Preserved until the node is removed |
| Field draft | Browser | Preserved across unrelated host updates; reset by an explicit host value change |
| Committed field change/action | Host after event | Emitted as bounded intent, never applied as business state by the component |

Events include deterministic node ID, event type, current revision, source, and
nonce. Draft input is debounced. DOM mutations do not emit events.

## Benchmark Method

`tools/benchmark_persistent_ui.R` builds realistic analytical sections with
rows, labels, values, badges, fields, and actions. It compares full
`renderUI()`-style HTML regeneration with normalized persistent patches at 10,
50, 100, and 250 rows. Each case uses 15 repetitions and one message. Workloads
are value refresh, conditional visibility, and one structural addition.

Times below are R-side median elapsed milliseconds. Bytes are serialized HTML
or patch payload bytes. Millisecond timer resolution makes zeroes mean “below
measurement resolution,” not zero work.

| Rows | Workload | Full HTML ms / bytes | Persistent ms / bytes |
|---:|---|---:|---:|
| 10 | value | 20 / 3,414 | <10 / 2,174 |
| 10 | visibility | 20 / 3,414 | <10 / 672 |
| 10 | structure | 20 / 3,480 | <10 / 245 |
| 50 | value | 110 / 17,362 | 20 / 10,889 |
| 50 | visibility | 110 / 17,362 | 30 / 3,517 |
| 50 | structure | 110 / 17,428 | 30 / 245 |
| 100 | value | 220 / 34,807 | 60 / 21,793 |
| 100 | visibility | 220 / 34,807 | 60 / 7,240 |
| 100 | structure | 220 / 34,873 | 50 / 245 |
| 250 | value | 560 / 88,342 | 160 / 54,882 |
| 250 | visibility | 550 / 88,342 | 160 / 18,320 |
| 250 | structure | 550 / 88,408 | 170 / 245 |

The value workload deliberately changes every value node. Isolated updates
would produce smaller patches. Structural patch size remains constant because
only the added node is transmitted. Both approaches use one Shiny message per
host update; the gain is less R work, less serialization, smaller payloads, and
in-place browser reconciliation rather than fewer messages.

## Lifecycle And Browser Qualification

The standalone demo contains equivalent traditional and persistent panels,
10–250 row controls, visibility and structural changes, reordering, 200-update
bursts, stale updates, hide/show, remove/remount, and a second namespaced module
instance. Browser instrumentation records child additions/removals,
`shiny:bound`/`shiny:unbound` events, current revision, node count, update time,
and Chromium heap size when exposed.

The keyed renderer preserves the focused field, its unsaved draft, panel
scroll, local selection, and collapsed sections during unrelated updates.
Traditional `renderUI()` replaces its generated inputs and resets local values.
Dynamic removal invokes transport teardown; remount creates one clean instance.
Stale revisions are ignored and a burst reaches the final revision without
duplicate node IDs or handlers. Multiple instances and module namespaces remain
independent. Reliable reconnect qualification and long-duration heap profiling
remain open; heap values exposed by Chromium are observational, not a leak
proof.

## Composition Boundary

The persistent schema safely owns browser-native text fields and buttons because
their event contract is explicit. It does **not** accept arbitrary Shiny tags or
ordinary Shiny input bindings. Native Shiny inputs would need a deliberate
binding lifecycle adapter and are not silently embedded. Direct Transport
components such as Command Palette compose safely as sibling surfaces, as do
specialized Parameter Workbench, AG Grid, tree, graph, and editor outputs.

This boundary is intentional. Turning the schema into a general frontend
framework would recreate Shiny's responsibilities and weaken the contract.

## Accessibility

Fields retain programmatic labels, sections expose `aria-controls` and
`aria-expanded`, actions are native buttons, selected rows expose
`aria-selected`, status uses text in addition to color, and visible focus is
preserved. Forced-colors and reduced-motion media rules are included. The
container is an identified region. Routine value patches are not announced as
live-region chatter; hosts should provide a deliberate status announcement when
an update requires user attention.

## Workstation Opportunity Map

A read-only scan found 769 `uiOutput()`/`renderUI()` references across 31 active
R source files. This is an occurrence count, not 769 independent migration
units; many are paired declarations, branches, or tests embedded in helpers.

| Classification | Representative surfaces | Direction |
|---|---|---|
| Strong candidate | readiness/quality summaries, decision headers and status panels, runtime qualification summaries, agent timelines, bounded code-run details | Persistent schema |
| Possible candidate | evidence summaries, project/export status, bounded inspector metadata, follow-up/action lists | Evaluate update frequency and composition first |
| Keep `renderUI()` | small infrequent conditional fragments, module settings built from native Shiny inputs, arbitrary report/tag output | Existing Shiny lifecycle |
| Specialized component | data preview, artifact gallery/renderer, large tables, trees, graphs, parameter editors, code editors | Existing or future dedicated component |

An initial source-level estimate is that roughly **25–40%** of the observed
dynamic surfaces could plausibly use the persistent pattern, with another
15–25% worth case-by-case evaluation. The remainder should stay with
`renderUI()` or migrate to a specialized component. A real migration inventory
must collapse paired UI/server references before producing a definitive count.

## Direct Transport Qualification

Persistent Dynamic UI is the second substantial consumer of Direct Component
Transport and the first non-React consumer. It validates that the runtime is
framework-neutral and that custom messages, revisions, multiple instances,
namespaces, resize, teardown, and remount are reusable beyond Command Palette.

Direct Transport is now sufficiently qualified to **plan an incremental
`htmlwidgets` reduction**, but not to remove `htmlwidgets`. Installed-package
behavior, static R Markdown parity, reconnect, CSP, long-duration memory, and
each migrated component still require independent qualification.

## Reproduction

```r
pkgload::load_all(".")
run_persistent_ui_demo()
source("tools/benchmark_persistent_ui.R")
testthat::test_file("tests/testthat/test-persistent-ui.R")
```

Built assets ship under `inst/www/direct-transport`; package users do not need
Node.js. Node/Vite remains a maintainer-only build tool.
