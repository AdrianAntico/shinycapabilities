# Monaco Editor 1.0

## Boundary

`code_editor()` is a host-neutral browser editor. It edits and compares text;
it does not execute code, authorize execution, manage files, or create another
Code Runner. The host owns persistence, validation, completions, execution,
history, and policy.

The component uses Direct Component Transport rather than htmlwidgets. Monaco
0.56.0 and its workers are pre-bundled, so installing or running the R package
does not require Node.js.

## Public API

- `code_editor()` creates an editor or read-only diff projection.
- `code_editor_output()` declares a Shiny output.
- `render_code_editor()` renders the component.
- `update_code_editor()` updates value, original value, language, read-only
  state, diagnostics, or a bounded completion response.
- `run_code_editor_demo()` opens the standalone qualification app.

Supported languages are R, Julia, Python, SQL, JSON, YAML, and Markdown.
Language support means Monaco tokenization and editing behavior; it does not
imply execution, semantic compilation, or a language server.

| Language | Bundled support | Qualification boundary |
|---|---|---|
| R | Monaco built-in definition | Highlighting, comments, brackets, indentation; host supplies semantic diagnostics/completions |
| Julia | Monaco built-in definition | Highlighting, comments, brackets, indentation; host supplies semantic diagnostics/completions |
| Python | Monaco built-in definition | Highlighting and editor configuration, not a Python language server |
| SQL | Monaco built-in definition | Generic SQL tokenization; dialect semantics remain host-owned |
| JSON | Monaco JSON feature and worker | Syntax/colorization plus Monaco JSON language services |
| YAML | Monaco built-in definition | Tokenization only; schema validation remains host-owned |
| Markdown | Monaco built-in definition | Markdown tokenization and editing, not rendered preview |

No external language-definition package is required for R or Julia, and no
additional editor engine is bundled.

## State and events

Document edits remain browser-local until **Apply** is pressed. The explicit
`<id>_apply` event carries the full document plus language, document id, and
host revision. Routine state events are bounded and contain only selection,
length, line count, dirty/conflict state, and a nonce. No document is streamed
on each keystroke.

A newer host value received while the editor is dirty creates a visible
conflict. The user chooses **Use host** or **Keep draft**; the component never
silently destroys a draft. Applied history remains a host responsibility.

Diagnostics are host-supplied Monaco markers. Completion requests contain a
bounded line prefix and location; completion responses are correlated by
request id and time out after 1.5 seconds. Neither path exposes private
reasoning.

## Runtime and scale

The component bundle is loaded only when a code editor output exists. Vite
emits an ES-module entry, split language chunks, and dedicated editor/JSON
workers. The direct transport queues an initial render until the deferred
component module registers. ResizeObserver-driven layout avoids remounting.

The qualification target is interactive editing and host updates at 10,000
lines; a 50,000-line stress option is included to characterize the practical
boundary. Extremely large generated files should remain files or artifacts rather
than becoming long-lived reactive values. Explicit Apply can transfer a larger
document by design; ordinary transport events retain the 16 KB bound.

The production build currently emits a 16.8 KB entry (5.6 KB gzip), language
chunks of roughly 3.8-9.8 KB, a 67.8 KB JSON feature chunk, 300 KB editor and
430 KB JSON workers, 352 KB CSS (including Monaco), and shared Monaco editor
chunks of 1.41 MB and 3.22 MB (325 KB and 747 KB gzip). Pages without a
`code_editor_output()` attach none of these assets.

Chromium browser qualification on the lab demo measured approximately 12 ms
of component-side work for a 10,000-line (199 KB) host update and 32 ms for a
50,000-line (1.04 MB) update. Both remained virtualized and responsive for
find, focus, and resizing. These are local qualification measurements, not a
cross-device SLA; 10,000 lines is the recommended ordinary ceiling and 50,000
lines is a stress-tested review boundary.

## Accessibility

Monaco supplies keyboard editing, screen-reader mode, high-contrast behavior,
diagnostic navigation, and diff navigation. The wrapper adds a named region,
visible status, non-color conflict text, focus indication, native buttons, and
forced-colors/reduced-motion treatment. Hosts must provide an accurate
`aria_label` and should not rely on color-only diagnostics.

## Promotion readiness

The component owns editing UI, browser draft state, markers, diff rendering,
and bounded interaction events. A host must supply document identity/revision,
diagnostics, completion results, persistence, permissions, and any execution
intent handling. Workstation can map its existing Code Runner editor seam to
`<id>_apply` without changing its execution model.

Before promotion, qualify the installed package in Workstation's supported
browser/Electron matrix, validate CSP handling of module workers, set document
size policy, connect governed completion providers, and verify that project
save/load remains authoritative. Execution must continue through the existing
Code Runner only.
