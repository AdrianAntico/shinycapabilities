# Framework foundation 0.3.0 qualification

## Scope and contracts

1. Foundation: six additive exports compose presentation, native dates, and command records.
2. Tokens: scoped CSS custom properties cover surfaces, text, borders, accent,
   selection, focus, status, spacing, radius, elevation, type, motion, and dimensions.
   Existing field, selection, tree, grid, inspector, and workbench token names are
   mapped within the frame; standalone styling remains compatible.
3. bslib: auto theme inherits Bootstrap variables with standalone fallbacks.
   No new mandatory dependency. Host token overrides remain available.
4. Density: comfortable/compact/dense change spacing and dimensions, not fields,
   validation, commands, values, or expert overrides. Grid rows measure 42/34/28px.
5. Frame owns named optional regions, presentation scope, and overlay placement.
6. It owns no routing, reactive state, sessions, authorization, or execution.
7. Fields retain separate help/error/warning/busy/required/readonly/disabled state;
   updates use the existing binding. Workbench draft/applied state is unchanged.
8. Native date and local datetime fields added; timezone interpretation stays with hosts.
9. Selection preserves labels separately from values. Existing search, grouping,
   multi-selection, ordering, virtualization, and server-search paths remain intact.
10. Overlay stack coordinates Escape, focus return, nested popups, and modal
    shortcut containment. Native dialogs retain modal focus responsibility.
11. Commands are records shared by buttons/palettes/programmatic invocation,
    not a service. Invocation explicitly carries `authorized = FALSE`.
12. Stable IDs, complete command records (including disabled alternatives),
    canonical values, and existing expert controls remain inspectable.
13. Public proof: `inst/examples/foundation-review/app.R`, using the public
    equipment-review data, tree, grid, inspector, workbench, split layout,
    selection, fields, modal, palette, and command buttons.
14. Hosts still supply data, navigation, persistence, authorization, and execution
    through ordinary Shiny. No private dependencies are needed.
15. Deferred: universal third-party-widget theming, new drawers, server-windowed
    data, routers, agent runtimes, global command services, and automatic timezone rules.

## Qualification

- Isolated staged-candidate source R suite: **803 pass, 0 fail/warn/skip**.
  Existing 779 assertions retained; 24 foundation assertions added.
- Full installed `R CMD check --no-multiarch`: **Status OK**, including examples,
  installed tests, and PDF manual. R 4.5.2, Windows x64, Rtools45.
- Node tests: **13/13**, comprising nine unchanged lifecycle tests and four
  foundation invocation/overlay/presentation tests.
- Real installed Shiny application browser matrix: **36 combinations**:
  1600/1366/900/640px, light/dark/Bootstrap auto, all three densities.
  No page overflow; field IDs, command records, and date values unchanged.
- Browser checks: canonical selection value, field error/warning/loading and
  recovery, palette shortcut, modal containment, nested selection Escape/focus
  return, disabled invocation rejection, and human/programmatic invocation.
- Existing composed workflow: selection, explicit Apply, inspector updates,
  grid hide/show and DOM movement, late component mount/unmount, responsive resize.
- Visual inspection corrected tree/grid-toolbar token gaps and ordinary text
  output colors in dark mode. Host-generated plot images remain host-owned.
- Qualification fixes: await inspector mounting and popup focus return before
  sampling state; assertions were retained. Reference palette uses its public
  render/output pair to avoid a permanently pending output presentation.
- Defensive fixes: embedded command labels cannot terminate JSON script tags
  and round-trip exactly; closing a parent overlay includes portalled descendants.
- `git diff --check`: clean. New public files contain no private repository references.
- AG Grid remains **36.1.0**. Dependency lock and existing shared transport/runtime
  are unchanged. No analytical or host application repository was modified.

The release excludes the pre-existing browser-surface emission guard and its
extra assertion, untracked local instructions, and unrelated line-ending changes.
Release identity is the commit containing this report on `main`; publication is
verified against `https://github.com/AdrianAntico/shinycapabilities.git`.
