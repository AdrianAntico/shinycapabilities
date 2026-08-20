# Accessible Split Pane 1.0

## Library decision

The component wraps [`react-resizable-panels` 4.12.2](https://www.npmjs.com/package/react-resizable-panels). It is actively maintained, [MIT licensed](https://github.com/bvaughn/react-resizable-panels/blob/main/LICENSE.md), has no runtime dependencies, supports nested horizontal/vertical groups, unit-aware constraints, imperative resize/collapse APIs, pointer and touch input, and WAI-ARIA separators with keyboard resizing. This is materially safer than package-owned pointer geometry. The bundled component is about 71 KB gzip including its isolated React runtime, roughly 8.6 KB more than the Typed Parameter Workbench bundle, and does not require Node.js at package runtime.

## Public API

```r
split_pane(
  "workspace",
  data = data_grid_output("data"),
  inspector = parameter_workbench_ui("parameters"),
  sizes = c(70, 30),
  min_sizes = c(35, 15),
  collapsible = c(FALSE, TRUE)
)
```

Named pane arguments define deterministic pane IDs. `direction` supports horizontal and vertical groups; two or more panes and nested `split_pane()` calls are supported. Sizes and constraints accept percentages or explicit CSS units. Pane contents remain ordinary Shiny UI and retain their own input/output ownership.

`update_split_pane()` supports `sizes`, `collapse`, `expand`, and `reset`. Host updates complete atomically through the library's imperative API. Pointer movement remains client-side. Shiny receives a bounded value only after a user resize completes or an explicit update/reset occurs:

```r
list(
  componentId = "workspace",
  direction = "horizontal",
  paneIds = c("data", "inspector"),
  sizes = list(data = 68.2, inspector = 31.8),
  collapsed = character(),
  event = list(type = "resize", source = "user", nonce = "...")
)
```

Separators expose native `separator` semantics, values, orientation, and keyboard interaction from the underlying library. Focus is visible, touch hit areas expand for coarse pointers, scroll ownership stays inside pane contents, and double-click resets initial sizes.

Run the standalone composition gallery with:

```r
shinycapabilities::run_split_pane_demo()
```
