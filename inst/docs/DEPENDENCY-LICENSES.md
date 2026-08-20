# Dependency Licenses

Inventory generated from `tools/javascript/package-lock.json` for the build that
produced the bundled assets.

## Bundled runtime

| Package | Version | License |
|---|---:|---|
| @xyflow/react | 12.11.2 | MIT |
| @xyflow/system | 0.0.79 | MIT |
| @dagrejs/dagre | 3.1.1 | MIT |
| @dagrejs/graphlib | 3.0.4 | MIT |
| @tanstack/react-virtual | 3.13.12 | MIT |
| @tanstack/virtual-core | 3.13.12 | MIT |
| @floating-ui/dom | 1.8.0 | MIT |
| @floating-ui/core | 1.8.0 | MIT |
| @floating-ui/utils | 0.2.12 | MIT |
| React | 19.2.8 | MIT |
| React DOM | 19.2.8 | MIT |
| AG Grid Community | 36.1.0 | MIT |
| Zustand | 4.5.7 | MIT |
| classcat | 5.0.5 | MIT |
| scheduler | 0.27.0 | MIT |
| use-sync-external-store | 1.6.0 | MIT |
| @types/d3-color, @types/d3-drag, @types/d3-interpolate, @types/d3-selection, @types/d3-transition, @types/d3-zoom | 3.x | MIT |
| d3-color, d3-dispatch, d3-drag, d3-interpolate, d3-selection, d3-timer, d3-transition, d3-zoom | 3.x | ISC |
| d3-ease | 3.0.1 | BSD-3-Clause |

## R runtime

| Package | Role | License |
|---|---|---|
| callr | Supervised, owned background R processes on Windows and other supported platforms | MIT |

`callr` is used instead of a custom process protocol. Its `processx` dependency
provides the owned-process lifecycle primitives. No worker cluster, daemon, or
distributed queue is introduced.

## Development/build only

Vite 8.2.0 and `@vitejs/plugin-react` 6.0.5 are MIT licensed. The complete
locked build dependency names are:

- MIT: `@emnapi/core`, `@emnapi/runtime`, `@emnapi/wasi-threads`,
  `@napi-rs/wasm-runtime`, `@oxc-project/types`, all platform-specific
  `@rolldown/binding-*` packages, `@rolldown/pluginutils`, `@tybys/wasm-util`,
  `fdir`, `fsevents`, `nanoid`, `picomatch`, `postcss`, and `rolldown`;
- Apache-2.0: `detect-libc`;
- MPL-2.0: `lightningcss` and all platform-specific `lightningcss-*` packages;
- ISC: `picocolors`;
- BSD-3-Clause: `source-map-js`;
- 0BSD: `tslib`.

These packages are not required at installed-package runtime and
`tools/javascript/node_modules` is excluded from the R source package. The
authoritative versions and dependency graph are retained in
`tools/javascript/package-lock.json`; the grouped inventory above is checked
against that lockfile when dependencies change.

React Flow and Rete.js were reviewed from their current official documentation.
React Flow core is MIT. Rete core is MIT, but its `rete-structures` and
`rete-scopes-plugin` optional plugins are CC-BY-NC-SA-4.0 and were not selected
or bundled.

AG Grid Enterprise is not installed or bundled. The data-grid component uses
selectively registered modules from the MIT-licensed Community package only.
