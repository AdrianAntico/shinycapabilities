# Complete User-Facing Shiny UI Elimination Program

## Boundary

The target is strict: **Shiny remains the reactive, session, upload, download,
and server-authority runtime; `shinycapabilities` owns the visible browser UI.**
This checkpoint does not modify Analytics Workstation. Its active source was
inspected read-only at `AnalyticsWorkstation` commit `6e37222`; the checkout had
102 existing changes, so counts describe the current working tree rather than a
clean release tag.

## Observed Workstation Surface

Counts are direct calls in the active `R/` tree. Helpers can multiply the visible
runtime surface, so these are conservative implementation counts.

| Primitive | Count | Primitive | Count |
|---|---:|---|---:|
| `actionButton()` | 358 | `uiOutput()` | 384 |
| `renderUI()` | 385 | `selectInput()` | 243 |
| `textInput()` | 242 | `numericInput()` | 114 |
| `checkboxInput()` | 68 | `showNotification()` | 37 |
| `textAreaInput()` | 34 | `renderText()` | 31 |
| `tabPanel()` | 26 | `textOutput()` | 19 |
| `verbatimTextOutput()` | 12 | `checkboxGroupInput()` | 6 |
| `downloadButton()` / handler | 5 / 5 | `modalDialog()` / `showModal()` | 4 / 4 |
| `tableOutput()` / `renderTable()` | 4 / 4 | `fileInput()` | 3 |
| `tabsetPanel()` | 3 | `passwordInput()` | 2 |
| `radioButtons()` | 2 | `sliderInput()` | 2 |
| `actionLink()` | 1 | direct `plotOutput()` / `imageOutput()` | 0 / 0 |

Manual browser markup also forms part of the visible surface: 114
`tags$button()` calls, 27 `tags$input()` calls, one `tags$select()`, and three
`tags$textarea()` calls. These are not stock Shiny controls, but they must still
move behind the shared interaction contract unless they belong to an already
qualified purpose-built component. Existing server mutation includes 18
`updateTextInput()`, 3 `updateNumericInput()`, 55 `updateSelectInput()`, 6
`updateCheckboxInput()`, 2 `updateRadioButtons()`, and 6 `updateTabsetPanel()`
calls; migration must preserve these update intents.

The highest concentrations are `page_workflow_studio.R` (253 matched calls),
`page_causal_intelligence.R` (237), `page_analysis_modules.R` (185),
`page_product_experience.R` (150), `page_semantic_intelligence.R` (148), and
`page_project.R` (134). Existing app-owned helpers such as `ui_card()`,
`ui_action_row()`, `ui_status_badge()`, `ui_empty_state()`, and `render_table()`
are high-leverage migration seams.

## Existing Coverage

| Capability class | Qualified replacement |
|---|---|
| Large and grouped selection | Selection System |
| Hierarchy browsing | Virtual Tree Browser |
| Keyboard command discovery | Command Palette |
| Dense analytical tables | AG Grid Data Grid |
| Schema-driven forms | Typed Parameter Workbench |
| Resizable layout | Split Pane |
| Operational activity | Agent Activity Monitor |
| Provenance/dependencies | Relationship Graph |
| Historical execution | Execution Replay |
| Keyed dynamic UI | Persistent Dynamic UI |
| Code/value editing | Monaco Editor |
| Structured values | Structured Object Inspector |
| Browser lifecycle | Direct Component Transport and Shared Browser Runtime |

## Technology Decisions

| Class | Decision | Reason |
|---|---|---|
| Basic fields and actions | Native HTML/CSS plus one Shiny input binding | Native semantics, password managers, mobile keyboards, range behavior, and low bundle cost are already best-in-class. |
| Rich select/tree/listbox | Existing virtualized Selection/Tree components; React Aria is the preferred future interaction kernel where a rewrite earns its cost | Composite ARIA ownership is difficult; React Aria provides tested keyboard, screen-reader, touch, and internationalization behavior without prescribing visual style. |
| Popover/tooltip/context positioning | Floating UI | Collision, clipping, placement, and viewport behavior are nontrivial and Floating UI is already an appropriate focused dependency. |
| File upload/drop | Native file input plus drag/drop enhancement over Shiny's upload authority | Browser security requires user selection; drag/drop must retain a keyboard file-picker path. |
| Dense grids | AG Grid Community | Qualified virtualization and typed interaction; do not use Enterprise-only APIs. |
| Code editing | Monaco | The specialized engine materially exceeds textarea behavior. |
| Graphs | XYFlow/Dagre | Specialized interaction and layout justify isolation. |
| Analytical plots | AutoPlots | Plot computation/rendering remains outside this package; add only a presentation shell later. |

Primary references: [React Aria](https://react-spectrum.adobe.com/react-aria/getting-started.html),
[Floating UI](https://floating-ui.com/), and the browser-native
[file drag/drop contract](https://developer.mozilla.org/en-US/docs/Web/API/HTML_Drag_and_Drop_API/File_drag_and_drop).

## Foundational Browser Controls 1.0

This checkpoint implements one native, dependency-light layer:

- `browser_text_field()`
- `browser_numeric_field()`
- `browser_secret_field()`
- `browser_textarea()`
- `browser_checkbox()`
- `browser_switch()`
- `browser_radio_group()`
- `browser_segmented_control()`
- `browser_slider()`
- `browser_action_button()` and `browser_action_link()`
- `browser_value_display()`
- `browser_status_badge()`
- `browser_progress()`
- `browser_alert()`
- `browser_skeleton()`
- `update_browser_control()`
- `run_browser_controls_gallery()`

Fields emit their scalar/logical value under the supplied Shiny input ID.
Actions preserve Shiny's integer click-count convention. Updates use the normal
namespaced input-message channel and mutate in place. The implementation adds no
React, htmlwidget, or R wrapper dependency.

## Interaction Language

1. **Density:** controls use a stable 40px default with responsive segmented
   choices; dense specialized components may opt into their own bounded density.
2. **Labels:** persistent labels are required. Placeholders are examples, never
   substitutes. Help and errors have explicit accessible relationships.
3. **Focus:** every interactive element has a visible `:focus-visible` ring.
4. **Keyboard:** native controls retain browser semantics. Enter/Space activate
   buttons; arrow keys operate radio/range controls; Escape belongs to overlays.
5. **State:** disabled, read-only, required, invalid, loading, and indeterminate
   states are explicit and never conveyed by color alone.
6. **Actions:** primary, secondary, success, destructive, and ghost semantics are
   consistent; destructive confirmation belongs to the future overlay contract.
7. **Events:** only user-triggered bounded values/intents return to Shiny.
8. **Theme:** CSS consumes app variables with neutral fallbacks and supports
   dark themes, forced colors, reduced motion, narrow layouts, and touch targets.
9. **Dirty/applied:** simple fields expose current value; workflows needing draft
   versus applied state use Parameter Workbench or Selection System contracts.
10. **Copy/paste:** native fields preserve platform behavior; specialized viewers
    own bounded copy actions and redaction.

## Dynamic UI Classification

The 384 `uiOutput()` and 385 `renderUI()` calls are the largest migration risk.
They must be adjudicated individually:

- stable repeated records -> Persistent Dynamic UI;
- typed forms -> Parameter Workbench;
- inventories -> Data Grid, Tree, or Selection System;
- details -> Object Inspector;
- workflow/report composition -> keyed Direct Component projection;
- arbitrary trusted markup -> temporary compatibility output with a recorded
  owner and removal criterion.

No migration should replace a `renderUI()` loop with an equally opaque browser
loop. Stable identity, state ownership, patch semantics, focus, and teardown are
part of the replacement contract.

## Remaining Gaps

1. Overlay system: dialog, drawer, popover, tooltip, context menu.
2. Notification center and bounded inline feedback orchestration.
3. Navigation system: tabs, breadcrumbs, disclosure, pagination.
4. File transfer: upload/drop and download action over Shiny authority.
5. Scalar/preformatted output projection with in-place updates.
6. Media and AutoPlots presentation shell with resize/fullscreen/actions.
7. Arbitrary-markup compatibility policy and migration telemetry.
8. Workstation-wide theme/token promotion and installed Electron qualification.

## Dependency Consequences

The foundation adds no R dependency. Once Grok migrates all consumers:

- `shinyWidgets` can leave Workstation after Selection System and basic controls
  replace every selector/control.
- `reactable` and `reactR` can leave after Data Grid or semantic small tables
  replace `render_table()` consumers.
- `htmlwidgets` cannot leave Workstation while AutoPlots/echarts4r or other
  analytical widgets still require it; this is not a generic UI migration.
- `shiny`, `htmltools`, and `jsonlite` remain infrastructure.

## Promotion Readiness

Grok should consume [the migration matrix](workstation_ui_migration_matrix.csv),
migrate one helper seam/page family at a time, preserve input IDs, and qualify
browser, project-state, Electron, accessibility, and rollback behavior. The lab
component owns presentation and bounded events; Workstation continues to own
authorization, files, downloads, execution, persistence, and analytical state.

Zero-visible-stock-Shiny is not yet promotion-ready. Foundational fields/actions
are covered, but overlays, navigation, file transfer, notification orchestration,
output shells, and the large dynamic-UI inventory remain explicit blockers.
