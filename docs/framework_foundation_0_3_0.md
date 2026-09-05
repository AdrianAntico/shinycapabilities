# Framework foundation 0.3.0

The foundation scopes presentation around ordinary Shiny components. It does not
replace reactive state, session ownership, routing, persistence, or execution.

## A small application

```r
library(shiny)
library(shinycapabilities)
commands <- list(command_record("review", "Request review", payload = list(scope = "selected")))
ui <- fluidPage(application_frame("app",
  work = browser_date_field("due", "Due date", "2026-10-01"),
  actions = command_button(commands[[1]]), commands = commands))
server <- function(input, output, session) {
  observeEvent(input$app_command, print(input$app_command))
}
shinyApp(ui, server)
```

For a composed maintenance workflow, run the installed public example:

```r
shiny::runApp(system.file("examples", "foundation-review", package = "shinycapabilities"))
```

It reuses the public equipment-review data and components. If bslib is installed,
the example uses its Bootstrap 5 page; otherwise it uses ordinary `fluidPage()`.

## Tokens and density

The frame defines CSS custom properties for surface/text hierarchy, borders,
primary/accent, selection, focus, disabled, success/warning/error/info, spacing,
radius, elevation, typography, motion, and control dimensions. Existing component
tokens are mapped within the frame; standalone components retain their existing
styles. `auto` derives defaults from Bootstrap body/foreground/primary variables.
Explicit light/dark scopes and named `tokens` overrides remain available. No Sass
or token-build pipeline and no mandatory bslib dependency are introduced.

`comfortable`, `compact` (default), and `dense` change presentation only. Native
fields, Workbench spacing, grid rows, and inspector rows respond to the frame.
Grid-specific explicit row heights remain expert overrides. Virtualized controls
retain their item sets and canonical selection values. CSS density is not a field
filter, validation policy, or alternate application state.

## Regions and commands

The optional header, navigation, context, inspector, parameters, output, actions,
and status regions surround `work`. Regions stack by default. Compose existing
split panes and navigation inside them; the frame does not invent a router or
sidebar state machine.

`command_record()` preserves stable ID, label, description, source, enabled state,
disabled reason, group, priority, shortcut metadata, and structured payload.
Records can supply palette items and frame command buttons. Shortcuts in records
are metadata, not an implicit global keybinding service. Existing header/menu APIs
remain available; the frame does not replace their event contracts.

`ShinyCapabilitiesFoundation.commands(frameId)` exposes all records, including
disabled alternatives. `invoke(frameId, commandId)` follows the same invocation
path as frame command buttons. The event is an **INVOCATION**, explicitly not an
authorization, execution, or effect. Hosts validate and authorize every request.
Palette events retain their existing channel as well as a matching frame invocation;
hosts should choose one channel rather than execute both.

## Fields and overlays

Text, numeric, secret, multiline, date, and datetime fields preserve distinct help,
error, warning, disabled, readonly, required, and busy states. Busy does not silently
disable a field. `update_browser_control()` preserves value identity and updates
these states through the existing input binding; `getState()` reports native
validity separately from warnings. Workbench draft/applied semantics are unchanged.

Dates return ISO date strings. Datetimes are **local wall-clock strings**, not UTC
instants: timezone and daylight-saving interpretation remain explicit host work.
Selection labels come from options or explicit label overrides, never replace values,
and grouping, multi-selection, ordering, search, and applied state remain available.

The frame overlay root preserves token inheritance. Dialogs, popovers, context
menus, and selection popups register a small focus/Escape stack. Native dialogs
still own modal focus trapping. Inline command palettes remain inline; their global
shortcut cannot pull focus outside an active modal. Notifications do not take focus.
No extra positioning library, command runtime, or agent runtime is introduced.

## Boundaries

Host applications still implement data loading, workflows, navigation policy,
authorization, execution, persistence, and full command updates via normal Shiny
rendering. Arbitrary third-party widgets do not automatically inherit every token.
No server-windowed grid, native grid replacement, or new drawer widget is added.
