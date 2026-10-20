# Deferred table construction

`data_grid(data, options = list(defer_until_visible = TRUE))` retains the complete
data payload but constructs its interactive grid only when exposed in the
viewport, focused with the keyboard, explicitly opened, or prepared for printing.
The default remains eager construction. This option changes browser presentation,
not data acquisition, analysis, row selection, missingness or identity.

Updates received before construction are retained. Offscreen tables expose a
keyboard-accessible Show table control with the current row count. Unsupported
browsers use eager construction. Destroying a component disconnects its observer
and handlers. Once constructed, it remains mounted so sorting, filtering and
selection are preserved while scrolling away and back.

The browser control `tests/browser/data-grid-deferred.cjs` exercises the shipped
bundle. This is a bounded presentation qualification, not analytical or general
accessibility certification.
