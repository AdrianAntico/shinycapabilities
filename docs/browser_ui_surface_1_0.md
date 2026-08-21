# Complete Browser UI Surface 1.0

## Scope

This release closes the known generic browser-presentation gaps required for a
zero-visible-stock-Shiny Analytics Workstation migration. Shiny remains session,
reactivity, upload, download, and server authority. Browser surfaces render
supplied state and emit bounded intents.

## Technology Decisions

- Native semantic HTML is used for controls, tabs, disclosures, breadcrumbs,
  pagination, file selection, downloads, and dialogs.
- Native `<dialog>` owns modal behavior, focus containment, Escape handling, and
  browser accessibility semantics.
- The package-owned overlay layer provides deterministic anchoring, viewport
  collision handling, portal layering, keyboard dismissal, and focus restoration.
- Shiny's existing upload and download transports remain hidden authority seams;
  no second file protocol or artifact generator was introduced.
- `ResizeObserver`, Fullscreen API, and application-level spotlight state support
  analytical output composition without changing AutoPlots or child engines.
- No new R or JavaScript dependency was added. The native layer does not need
  React, Floating UI, React Aria, or Node.js at install/runtime.

## Public API

### Overlays

- `browser_tooltip()`
- `browser_popover()`
- `browser_context_menu()`

### Dialog family

- `browser_dialog()` with dialog, drawer, side-sheet, and bottom-sheet variants
- `browser_confirmation_dialog()`
- `update_browser_surface(..., action = "open" | "close")`

Dialog actions are intents. The host performs confirmation, deletion, retry, or
other business operations.

### Notifications

- `notification_center()`
- `update_notification_center()`

Records have deterministic IDs, severity, title, message, persistence, timeout,
and bounded host-defined actions. Duplicate IDs update and increment a repetition
count. Browser history and visible queues are bounded.

### Navigation

- `browser_tabs()`
- `browser_accordion()`
- `browser_breadcrumbs()`
- `browser_pagination()`
- `report_outline()`

Tabs use roving focus and arrow/Home/End navigation. Disclosures use native
`<details>` semantics. Breadcrumb and outline actions emit navigation intents;
the host owns routes and history.

### File and artifact actions

- `browser_file_upload()`
- `browser_download_action()`

The file surface adds drag/drop, keyboard browsing, selection metadata,
client-side size feedback, and clearing while preserving Shiny's upload binding.
The download surface preserves Shiny's download handler URL and renders supplied
filename, type, size, and preparation state.

### Analytical output presentation

- `output_shell()`

The shell supports headings, metadata, status, bounded toolbar actions, loading,
empty and error states, fullscreen, spotlight, responsive sizing, and resize
notification to child outputs. It wraps rather than replaces AutoPlots, AG Grid,
Monaco, Relationship Graph, Object Inspector, semantic tables, images, and other
qualified content.

### Shared update contract

- `update_browser_surface()`

Updates are namespaced through the Shiny session. User events are emitted as
`<surface_id>_event` with a type, surface ID, timestamp, and bounded event data.

## Interaction Contract

- Escape closes dismissible overlays/dialogs and exits spotlight.
- Focus is restored to the invoking element after dismissal.
- Outside clicks dismiss transient overlays, not persistent panels.
- Actions use primary, secondary, destructive, and ghost hierarchy.
- Attention and error states do not rely on color alone.
- Reduced-motion and forced-color preferences are respected.
- Multiple instances are independent and IDs remain host-namespaced.
- Removed surfaces release observers and event listeners.

## Report Studio Findings

Read-only archaeology identified these generic needs:

| Need | Qualified primitive |
|---|---|
| Hierarchical section navigation | `report_outline()` or Virtual Tree |
| Responsive editor/outline composition | Split Pane |
| Report block chrome and state | `output_shell()` |
| Section details and progressive disclosure | `browser_accordion()` |
| Block focus/fullscreen | Output Shell spotlight/fullscreen |
| Synchronized child resizing | Output Shell `ResizeObserver` contract |
| Dense block inventory | AG Grid |
| Nested block metadata | Object Inspector |

Document persistence, report semantics, authoring workflows, block mutation,
selection authority, and export remain Workstation responsibilities.

## Replacement Coverage

The migration matrix now assigns every observed visible class to a qualified
component or explicit semantic HTML strategy. `uiOutput()` and `renderUI()` are
not mechanical substitutions: Persistent Dynamic UI handles bounded high-churn
projections, while purpose-built components own specialized interactions.

## Dependencies

No dependency was added. The package still imports only `shiny`, `htmltools`,
`jsonlite`, `callr`, and `digest`. `htmlwidgets` remains absent. Workstation may
eventually remove `shinyWidgets`, `reactable`, and `reactR` after migration and
installed-application QA.

## Promotion Readiness

Before Workstation promotion, Grok should qualify each migrated surface against
its host state contract, module namespace, installed Electron build, light/dark
theme, and authoritative server action. File upload and download require explicit
installed-app transport QA. Fullscreen requires Electron/browser policy QA.

## Qualification Results

- 69 focused browser-control and browser-surface assertions passed.
- 768 full-package assertions passed.
- Four unrelated pre-existing failures remain unchanged: one canvas event-target
  guard expectation and three legacy professional-presentation palette markers.
- Live Chromium QA passed for host-driven dialog/drawer opening, Escape dismissal,
  focus restoration, overlay portal behavior, nested tab isolation, notification
  burst bounding, output spotlight, responsive layout, and independent state.
- Browser console: zero component errors or warnings after qualification.
- JavaScript syntax validation passed.
- Production npm audit: zero vulnerabilities.
- Source build, isolated installation, installed-package load, exports, assets,
  and gallery lookup passed.
- `git diff --check` passed before commit.
