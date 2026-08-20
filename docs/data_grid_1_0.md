# AG Grid Data Grid 1.0

## Decision

**Selectively replace reactable.** Use `data_grid()` for dense, highly interactive
analytical inventories where virtualization, column manipulation, stable row
selection, and programmatic updates matter. Keep reactable for compact report
tables, static summaries, and places where its smaller dependency and familiar R
formatting API are the better fit.

This component is parallel capability work. It does not migrate Analytics
Workstation and does not change an existing `shinycapabilities` API.

## Public API

```r
data_grid(
  data,
  columns = NULL,
  row_id = NULL,
  options = list(),
  width = NULL,
  height = "560px",
  element_id = NULL
)

data_grid_output(output_id, width = "100%", height = "560px")
render_data_grid(expr)
update_data_grid(session, output_id, ...)
```

The original `data_grid(id, data, ...)` sketch was refined to standard
htmlwidgets/Shiny composition: the output owns the ID, while the widget owns
data and presentation. This works in modules, static R Markdown/HTML, and normal
Shiny output bindings without a second component model.

Columns are inferred or declared with a strict named-list schema. Arbitrary
JavaScript callbacks cannot pass through the public R API. Row identity uses a
user-selected unique column or deterministic `row_000000001` identifiers.

## Capability contract

### Included in 1.0

- client-side row and column virtualization;
- typed text, numeric, and date filters plus quick filtering;
- single or multiple row selection, including keyboard selection;
- sorting, resizing, moving, visibility, and pinning;
- native cell text selection and explicit copy-selected action;
- raw, numeric, compact, percent, currency, date, datetime, and logical display;
- compact and comfortable density;
- responsive toolbar, empty overlay, and loading overlay;
- replacement data, selection, quick-filter, loading, and column-state updates;
- bounded Shiny events for selection, cell activation, and debounced state.

Scrolling does not send Shiny events. Selection sends stable row IDs rather than
entire records. Cell activation sends one row ID, column ID, and scalar value.

### Intentionally excluded

AG Grid Community is MIT and free for production. Enterprise-only row grouping,
pivoting/aggregation, range selection, server-side row model, Excel export,
integrated charts, master/detail, tool panels, enhanced clipboard operations,
and custom context menus are not imported or emulated. The package supplies a
small Community-compatible column visibility menu instead of the Enterprise
Columns Tool Panel. See the official [Community versus Enterprise
matrix](https://www.ag-grid.com/javascript-data-grid/community-vs-enterprise/).

The selected Community modules are client-side row model, text/number/date
filters, quick filter, row selection, pagination, and the small API modules used
for column state, updates, cell styling, and widget resize.
AG Grid recommends selective registration to reduce bundle size; the
component does not register `AllCommunityModule`. See [AG Grid module
registration](https://www.ag-grid.com/javascript-data-grid/modules/).

## Event contract

| Input | Trigger | Payload |
|---|---|---|
| `<id>_selection` | row selection changes | `rowIds`, `count`, `timestamp` |
| `<id>_action` | cell double activation | `type`, `rowId`, `columnId`, `value`, `timestamp` |
| `<id>_state` | sort/filter/column state settles | `columns`, `filters`, `timestamp` |

State publication is debounced and can be disabled. Events communicate UI
intent only; host applications retain navigation, mutation, persistence, and
business logic.

## Dense analytical UX

The default compact density uses 32 px rows and 36 px headers. Numeric cells are
right aligned with tabular figures. Long tables retain a fixed, scannable header;
quick filtering and row count stay in one restrained toolbar. Columns can be
pinned and hidden without a dashboard sidebar. Empty/loading states occur inside
the data surface and do not resize the surrounding page.

## Accessibility

AG Grid supplies ARIA semantics and keyboard navigation. Virtualization creates
a real screen-reader tradeoff because off-screen cells do not exist in the DOM.
The `accessibility_mode = "paginated"` option enables pagination, ordered DOM,
and disables column virtualization for a more screen-reader-compatible mode.
This costs density and some performance. AG Grid documents the same tradeoff and
recommends pagination when full DOM availability is required: [AG Grid
accessibility](https://www.ag-grid.com/javascript-data-grid/accessibility/).

The package wrapper adds labelled controls, a polite status region, visible
keyboard focus, forced-color support, reduced-motion behavior, and native buttons
and inputs. Known AG Grid limitations remain, including incomplete announcements
for some in-place state changes and complex headers.

## Scale and performance

The standalone demo exposes 1,000, 10,000, and 100,000 row datasets. The client-
side row model stores all records in browser memory while virtualizing rendered
DOM rows. That makes 100,000-row analytical inspection a reasonable qualification
target, but not a promise for arbitrary width or value complexity.

Use `tools/benchmark-data-grid.R` to measure R construction and serialized payload
size at those scales. Browser qualification records first render, scroll, sort,
filter, selection latency, and event traffic. A larger practical dataset may be
tested manually only when memory remains bounded. Million-row workflows require
a future host-neutral server/infinite-row contract; the Enterprise server-side
row model is explicitly outside 1.0.

Qualified columnar-wrapper results were:

| Rows | R constructor | Serialized payload |
|---:|---:|---:|
| 1,000 | 0.01 s | 0.07 MB |
| 10,000 | 0.11 s | 0.70 MB |
| 100,000 | 0.64 s | 7.06 MB |

The initial row-wise prototype took 7.67 seconds and produced 12.11 MB at
100,000 rows. Keeping the R payload columnar until one browser conversion cut
construction by roughly 12x and payload size by 42%. This is an architectural
result: serialization shape matters as much as DOM virtualization.

Real-browser QA loaded and interacted with the 100,000-row demo without console
errors or warnings. Only the viewport-sized row window was present in the DOM.
Quick filtering, numeric sorting, pointer and keyboard-addressable selection,
programmatic selection, and structured event display all remained responsive.
No Shiny input was emitted by scrolling. Browser memory was not captured with a
repeatable cross-browser metric in 1.0, so payload size and replacement-cycle
stability are the current memory proxies.

Stability is part of performance. Qualification must fail a candidate that is
fast but freezes the main Shiny session, floods inputs while scrolling, or causes
browser memory growth after replacement-data cycles.

## Bundle analysis

`ag-grid-community` 36.1.0 is locked in the browser build and is MIT licensed.
The selective production bundle is approximately 862 KB minified and 241 KB
gzip on the qualification machine. This is larger than reactable's incremental
surface in Workstation, but package users do not need Node.js: built JS/CSS ships
under `inst/htmlwidgets/lib`.

The package already depends on `htmlwidgets`, so that runtime is reused. The AG
Grid wrapper is vanilla JavaScript and does not add another React root or require
`ag-grid-react`. Analytics Workstation currently receives `reactable` plus its
`reactR` dependency; a complete future migration could remove those only if no
other Workstation surface still consumes them. `htmlwidgets`, `htmltools`, and
`jsonlite` would remain ecosystem dependencies regardless.

`npm audit --omit=dev` reports zero runtime vulnerabilities. The full build-tree
audit reports one existing high-severity advisory in Vite's development-only
`postcss -> nanoid` chain; it is not included as an installed-package runtime
dependency or used by the grid in users' browsers.

## Direct comparison with reactable

| Need | AG Grid component | reactable |
|---|---|---|
| 100k-row interactive inventory | Preferred after qualification | Less suitable without custom virtualization work |
| Column reorder/pinning/visibility | Strong built-in behavior | More limited/custom |
| Typed filtering and dense keyboard work | Strong | Good for ordinary tables |
| Stable row event contract | Explicit IDs and bounded events | Requires app-specific wiring |
| Compact report/static summary | Heavier than necessary | Preferred |
| R-native cell rendering | Strict schema by design | More flexible/familiar |
| Bundle cost | Higher | Lower incremental cost in Workstation |
| Enterprise analytics features | Deliberately absent | Not applicable |

## Future migration seams

| Workstation surface | Existing control | Candidate | Expected gain | Risk |
|---|---|---|---|---|
| Artifact Library inventory | reactable | `data_grid()` | stable selection, column state, 100k-scale virtualization | medium: event/state mapping |
| Code History | reactable | `data_grid()` | dense keyboard navigation and pinned identity/status columns | low-medium |
| Data preview | reactable/basic preview | `data_grid()` | typed filters and large previews | medium: payload size |
| Report tables | reactable | Keep reactable | no meaningful benefit from heavier grid | migration not recommended |

No migration should occur until a Workstation-specific spike proves module
namespacing, theme adaptation, project-state restoration, and real dataset
performance without changing this host-neutral contract.

## QA contract

- source data must have unique, non-empty column names;
- row IDs must be stable, non-missing, non-empty, and unique;
- missing values serialize as JSON null;
- column/options schemas reject arbitrary browser code;
- scrolling publishes no Shiny inputs;
- programmatic updates do not overwrite the original widget contract;
- all assets are bundled and package runtime requires no Node.js;
- keyboard focus and accessible labels remain present;
- 1k, 10k, and 100k scale results are reported separately rather than averaged.
