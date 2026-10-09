# shinycapabilities 0.3.1

* Named configuration fields no longer change `node_signature()` or
  `graph_fingerprint()`. Sequences remain ordered. Explicit null is not a
  missing field. Duplicate names and unsupported types are refused.
* A surface event calls `Shiny.setInputValue` only when that binding is a
  function. A command invocation is not authorization.

# shinycapabilities 0.3.0

* Presentation and interaction foundation on the public main line, including
  browser surfaces and the foundation review example.

# shinycapabilities 0.2.0

* Promote Direct Component Transport, Shared Browser Runtime, Persistent Dynamic UI,
  foundational browser controls, surfaces (overlay/dialog/notification/navigation/file/download/output shell),
  AG Grid, Monaco, Typed Parameter Workbench, virtual tree, object inspector, split pane,
  command palette, relationship graph, agent activity monitor, and execution replay
  from the isolated `codex/capability-lab` qualification branch into canonical `main`.
* Remove the `htmlwidgets` dependency. Public browser components use Direct Component Transport.

# shinycapabilities 0.1.0

* Added an isolated AG Grid Community analytical data-grid component with
  virtualization, typed filtering, stable row events, programmatic updates,
  standalone demo, and explicit Enterprise exclusions.

- Initial experimental release
- Added host-neutral virtualized hierarchy and command-palette components with
  bundled runtime assets, keyboard/accessibility contracts, and a standalone
  interaction lab.
