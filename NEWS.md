# shinycapabilities 0.3.12

- Selection portals respect available viewport height and width. The option list shrinks and scrolls while search/close/status remain reachable; asynchronous positioning tolerates a closed portal. Restored-input semantics are unchanged.

# shinycapabilities 0.3.11

- Server-side selection and browser-control value updates now notify the subscribed Shiny input. Saved editors no longer display a different value from the one used by server actions. Metadata-only and unchanged-value updates remain quiet; selection user-gesture events are not fabricated.

# shinycapabilities 0.3.10

* Notify the existing Shiny visibility/resize observer after native tab selection,
  allowing initially hidden outputs to render when opened. Ignore unavailable tab
  targets and exclude disabled/hidden tabs from keyboard navigation.

* Preserve Shiny output registration and direct-transport lifecycle classes when
  a deferred data grid becomes visible. Grid density changes replace only grid-
  owned density classes. Removal and rerender keep their existing binding identity.

# shinycapabilities 0.3.9

* Bind configuration actions to selection identity, preventing host state changes
  from replaying Apply. Unchanged set_graph snapshots retain their revision and
  do not cancel a running workflow.
* Require browser graph edits to carry mutationId and baseGraphRevision. Return
  explicit accepted/refused receipts, reject stale or malformed edits, and retain
  a bounded session receipt cache for duplicate delivery. Incomplete authoring
  graphs remain allowed; required inputs are still enforced before execution.
* Resolve exact pending requests on receipt, restore the authoritative graph on
  refusal, and report unconfirmed requests after 15 seconds without inventing an
  outcome. Advance the canvas asset identity.

# shinycapabilities 0.3.6

* Preserve explicit capability refusal records in failed inline and background
  receipts. Validation details and typed owner conditions remain inspectable;
  neither creates a successful output. Ordinary exception behavior is unchanged.

# shinycapabilities 0.3.5

* Normalize DOM and jQuery scopes in the native browser-control/action input
  bindings. Dynamically inserted Shiny modals no longer interrupt input binding
  with `scope.querySelectorAll is not a function`. Scope membership and initial
  action values are unchanged. Advance the browser asset identity.

# shinycapabilities 0.3.4

* Preserve Shiny's existing output-binding marker when a direct component
  renderer replaces its CSS classes during delayed mount or update. Static
  components do not acquire a fabricated Shiny binding. Advance the transport
  asset identity so existing browsers receive the correction.

# shinycapabilities 0.3.3

* Advance the command-palette browser dependency identity with its changed
  executable bundle so an existing browser does not retain the pre-0.3.2
  dialog behavior under the same asset URL. Other component versions are unchanged.

# shinycapabilities 0.3.2

* Command palettes inside browser dialogs start a fresh search on each open.
  Escape instructions reflect the enclosing dialog contract; inline palettes
  retain their clear-search behavior. Enter chooses a command and does not
  imply authorization to execute analytical work. Public R signatures are unchanged.

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
