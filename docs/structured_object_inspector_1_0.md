# Structured Object Inspector 1.0

## Decision

The inspector is a focused package-owned React projection using the existing
Shared Browser Runtime and TanStack Virtual. It does not bundle
`vanilla-jsoneditor`. That editor is strong for mutable JSON documents, but its
editing surface, additional state model, and dependency cost do not improve
this read-only analytical inspection contract. Monaco remains responsible for
text/code diff; AG Grid remains responsible for tabular records.

The incremental browser bundle is 7.6 KB (3.2 KB gzip) plus 3.6 KB CSS (1.2 KB
gzip). React 19.2.8 and TanStack Virtual 3.13.12 are reused. Both are MIT. No
new runtime dependency or R wrapper package was added, and Node.js is not
required to install or run the package.

## Contract

`object_inspector()` accepts nested lists, atomic vectors, data frames, dates,
datetimes, nulls, missing values, raw/opaque values, and JSON-like structures.
R converts these into explicit `object`, `array`, and typed `scalar` envelopes
before serialization. Stable identity is a JSON Pointer path with RFC 6901
escaping, providing a future structural-comparison seam without adding a diff
engine.

Public functions:

- `object_inspector()`
- `object_inspector_output()`
- `render_object_inspector()`
- `update_object_inspector()`
- `run_object_inspector_demo()`

The host owns source data, authorization, revision ordering, retention, and any
mutation. The component owns projection, expansion, search, selection,
breadcrumbs, copy-safe scalar actions, focus, and viewport rendering. Events
contain paths and type metadata, never inspected values.

## Redaction

Credential, secret, token, private reasoning, and raw prompt/response keys are
recursively replaced in R before JSON serialization. Hosts can add explicit
`redact_paths`. Redacted nodes remain structurally visible as `[redacted]`, but
their original values cannot enter browser DOM, search, attributes, tooltips,
copy events, or Shiny events. Promotion adapters must redact at the authority
boundary as well; this package safeguard is defense in depth.

## Search, navigation, and updates

Search indexes the normalized in-memory tree, not mounted DOM rows, and matches
allowed keys, paths, and scalar values while retaining ancestor context. The
tree supports arrows, Home/End, left/right collapse and parent/child movement,
Enter/Space expansion, selected state, breadcrumbs, and programmatic focus.
TanStack Virtual mounts only viewport rows.

Full replacements and keyed `set`/`remove` patches update the mounted component.
Direct Transport rejects stale revisions. Expansion, search, selection, focus,
and scroll remain browser-owned when paths survive. Patch values pass through
the same typed/redaction normalizer before transport.

## Scale and comparison

Qualification targets are 1,000 and 10,000 nodes for ordinary use and 50,000
nodes as a stress boundary. `max_nodes` and `max_depth` cap serialization; a
visible opaque marker represents truncated content. Virtualization bounds DOM
rows independently of object size.

The included demo compares persistent in-place replacement/patching with the
architecture of nested `renderUI()`: the inspector serializes a typed payload
once, updates one mounted tree, and retains local interaction state. Nested
`renderUI()` regenerates HTML server-side, replaces a subtree, and loses native
expansion/focus unless state is recreated. Browser QA records concrete payload,
update latency, and DOM-row results for this checkpoint.

The bounded `tools/benchmark_object_inspector.R` comparison measured the typed
transport at 0.14 seconds for 100 records and 0.91 seconds for 1,000 records,
versus 0.19 and 1.94 seconds for recursive server-rendered HTML on the
qualification machine. Payload sizes were comparable. Browser QA loaded 10,001
nodes while mounting about 25 tree rows. The 50,001-node stress case also kept
the mounted rows bounded, but R normalization and serialization took roughly 30
seconds; 50,000 nodes is therefore a stress boundary, and host paging should be
preferred for larger or latency-sensitive projections.

## Accessibility

The viewport exposes tree/treeitem semantics, levels, expanded and selected
states, a named search field, live result counts, keyboard navigation, visible
focus, textual type labels, non-color redaction, breadcrumbs, and a native copy
button. Virtualized trees remain harder for some screen-reader browsing modes
than fully materialized trees; keyboard operation and search provide the
bounded structured path, and promotion requires testing with the host's actual
screen-reader/browser matrix.

## Promotion readiness

Candidate Workstation seams include artifact metadata, model diagnostics,
provenance/evidence details, configuration snapshots, execution/session state,
and structured errors currently rendered through repeated detail UI. Grok must
map authorized, bounded records into this generic contract; it must not send
private reasoning or secrets.

Before promotion, qualify real payload adapters, maximum payload policy,
redaction fixtures, stable path identity across host versions, CSP/assets,
Electron behavior, screen readers, project restoration, stale-update handling,
and whether host paging is required above 50,000 nodes. The inspector does not
edit, execute, approve, retry, or become a provenance authority.
