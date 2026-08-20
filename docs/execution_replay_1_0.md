# Execution Replay 1.0

## Boundary

`execution_replay()` is a read-only historical projection. It owns normalization, bounded recursive redaction, deterministic ordering, state-at-time projection, visual playback, filtering, virtualized navigation, structured inspection, and bounded intent events. It does not own execution, retries, cancellation, approval, provenance truth, context, resumption, or host state.

Playback moves a visualization cursor only. It never re-executes work.

## Normalized contract

- `execution`: `execution_id`, `label`, `type`, `status`; optional start/end timestamps, `source_mode`, and bounded metadata.
- `events`: `event_id`, non-negative deterministic `sequence`, `event_type`, and `summary`; optional timestamp, actor, source, status, entity/artifact/evidence references, and bounded metadata.
- `snapshots`: `snapshot_id`, sequence, `entity_id`, and `state`; optional timestamp, version, fingerprint, and bounded metadata.
- `related_records`: `record_id`, `record_type`, label, and sequence; optional timestamp, entity, status, fingerprint, typed relationships, and bounded metadata.

Duplicate identities and malformed sequences fail. Unknown references remain visible diagnostics because the host may intentionally supply a partial projection. Event history is bounded by `max_events`; truncation is disclosed.

## State at time

For selected sequence `N`, the component chooses the latest supplied snapshot for each entity where `snapshot.sequence <= N`. It displays only related records where `record.sequence <= N`. Current or later state is never projected backward. The change view compares the snapshot introduced at `N` with the prior supplied snapshot for that entity; it does not invent missing deltas.

## Public API and events

- `execution_replay()`
- `execution_replay_output()`
- `render_execution_replay()`
- `update_execution_replay(mode = "replace" | "append")`
- `run_execution_replay_demo()`

The widget emits `<id>_position`, `<id>_event_selection`, `<id>_entity_selection`, and `<id>_return_to_latest`. Payloads carry deterministic identities, sequence where relevant, a monotonic browser nonce, and emission time. They are navigation intents only.

Append updates preserve a historical selection. If the user was already at latest, the cursor follows appended events; otherwise the UI states that it is a historical view and exposes an explicit Return to latest action.

## Scale and accessibility

The timeline uses TanStack Virtual and does not mount every event row. The browser payload remains bounded, so virtualization is not presented as a substitute for host paging. The visual slider is paired with a structured listbox history. Arrow keys, Home/End, direct selection, previous/next controls, and visible focus support keyboard navigation. Event type is conveyed with text and symbols rather than color alone. State and change information remain textual and structured.

## Composition

The demo composes Replay with Split Pane and AG Grid while using one host event collection. Agent Activity Monitor can project current state from the same records; Replay projects historical state. Relationship Graph can navigate the same entity/artifact/evidence identities. None of these components becomes the canonical event ledger.

## Promotion readiness

Analytics Workstation candidates include governed execution events, collaboration task history, AgentSession events, execution leases, capability runs, artifact/evidence creation, review records, workflow transitions, and project audit records. A host adapter must provide stable IDs, deterministic ordering, truthful source modes, historical snapshots or reconstructible deltas, authorization-safe metadata, and reference integrity.

Before promotion, qualify event retention, timestamp/sequence policy, late-arriving event behavior, redaction, source-mode labels, snapshot semantics, identity stability, maximum payload, update rate, and whether partial history is disclosed. Grok must emit provider-neutral bounded operational records through existing Workstation authority and provenance seams. Private reasoning, raw prompts/responses, and provider secrets must never enter the replay contract.

Unsupported semantics include re-execution, retry/cancel, approvals, resume receipts, context capsules, source-code diffing, server-side history queries, causal inference, and reconstruction of state the host did not supply.
