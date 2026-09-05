# Agent Activity Monitor 1.0

`agent_activity_monitor()` is a read-only htmlwidget for host-supplied governed activity. It owns schema normalization, validation diagnostics, bounded/virtualized display, accessible selection, and navigation intents. It does not own agents, scheduling, execution, retries, cancellation, approval, provenance, evidence, or artifacts.

## Public API

- `agent_activity_monitor()`
- `agent_activity_monitor_output()`
- `render_agent_activity_monitor()`
- `update_agent_activity_monitor()`
- `run_agent_activity_monitor_demo()`

The normalized projection contains `actors`, `work_items`, `events`, and optional host-computed `summary`. Work items preserve `source_contract` and `raw_status`; invalid relationships become visible diagnostics rather than invented edges. Event history is sorted, bounded, and virtualized.

## Promotion Readiness

The host must supply canonical identities, normalized and raw states, relationships, attention reasons, telemetry, and sanitized event summaries.

Provider adapters belong to the host application. The monitor accepts only sanitized, provider-neutral metadata; it does not grant credentials, consent, or execution authority.

Percent completion, ETA, resource utilization, universal cost/token totals, and universal latency remain unsupported when the host does not supply them. Important risks before promotion are lossy state mapping, authority conflation, leaking private provider content, unbounded event updates, stale dependency references, and treating monitor intents as authorization.

Promotion requires deterministic adapter fixtures for every host seam, browser accessibility and burst-update qualification, redaction verification, dependency integrity, package checks, and proof that no monitor event directly mutates host work.
