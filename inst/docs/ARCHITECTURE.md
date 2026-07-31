# Architecture

## Product model

The canvas represents executable analytical capabilities, not output objects.
Artifacts such as plots, tables, findings, and reports are typed outputs that may
later be arranged in a secondary composition surface.

The normalized graph contains stable node IDs, capability IDs, positions, sizes,
configuration, state, parent identity, typed edges, and schema version. It never
contains R functions or renderer objects.

## R authority

The registry stores capability version, ports, configuration schema, validation
and execution functions, custom Shiny configuration hooks, summarization,
implementation fingerprint, cache policy, cancellation declaration, resource
hints, and presentation metadata.

`plan_workflow()` computes the transitive upstream closure and deterministic
topological order. Its node signature includes configuration, capability version,
implementation fingerprint, and dependency signatures. Current successful cache
entries are skipped unless forced. Cycles and invalid typed inputs fail before
execution.

`execute_workflow_plan()` executes only R functions. A failed required upstream
node blocks its dependents while independent successful branches remain intact.

## Non-blocking execution runtime

Capabilities declare one closed execution profile: `inline`, `background_r`,
`network`, or `planning_only`. The host retains deterministic planning and cache
signatures. `workflow_runtime()` adds lifecycle state and schedules only ready
nodes. It defaults to two isolated analytical jobs and one network job.

Windows-safe isolated work uses supervised `callr` processes. The runtime records
only its own process handles and kills only those handles for cancellation or
timeout. Completed output is registered after the worker returns successfully;
failed, cancelled, crashed, and timed-out work contributes no partial output.
Inline and planning-only work remains host-owned and should be short.

The serializable runtime snapshot contains lifecycle, typed failures, progress,
elapsed time, and successful results but never live process handles. Workflow
documents remain graph and output-placement documents. Restoring a document
normalizes previously pending, queued, running, or cancelling nodes to `stale`.

The synchronous `execute_workflow_plan()` remains available for tests and
compatibility. Shiny hosts should poll `tick_workflow_runtime()` through a
throttled reactive invalidation loop.

## JavaScript authority

React Flow 12.11.2 provides the spatial interaction layer. Local React state keeps
drag, resize, pan, zoom, selection, and connection gestures smooth. Shiny receives
only boundary events. A proposed connection is not committed until R returns a
typed acceptance.

The package chose React Flow over Rete.js because the product needs a controlled
graph editor while R remains the execution engine. Rete's visual-programming
plugin architecture did not solve an identified blocker and would introduce a
second execution-oriented abstraction. Some optional Rete plugins also use a
noncommercial license, while the selected React Flow package is MIT licensed.

## Host adapter boundary

Host applications register domain capabilities through the public registry.
Adapters translate host-owned functions into closed typed inputs, outputs,
configuration, validation, execution, and summarization contracts. Domain
implementation details, private datasets, credentials, and application-specific
navigation remain outside this package.

## AI proposal boundary

An AI may produce the same normalized graph schema with rationale and provenance.
`workflow_proposal()` loads it as an inspectable proposal and
`accept_workflow_proposal()` accepts all or a selected subset. Rejection, editing,
ordering, composition, and execution remain explicit human/governance actions.

Executable alpha composites replace selected nodes with one presentation node
while preserving the complete internal graph and boundary mappings. Planning
expands composites deterministically before validation and execution.

Secondary output placements live in `workflow_document()$output_placements`,
separate from the normalized graph. Save/restore therefore preserves composite
internals and output layout without treating an output move as an analytical edit.
