# Agent Activity Monitor: Discovery and Design Contract

Status: design only. This document defines a read-only, host-neutral monitor. It does not add execution behavior to `shinycapabilities`.

## Evidence Boundary

The discovery used the current Analytics Workstation source checkout read-only. The checkout is on `main` at `304c358615a97baae2ef09106ecbdfac108b63cb` and contains substantial uncommitted work, so this contract distinguishes committed concepts from currently present source contracts. Canonical evidence came from:

- `R/collaboration_foundation.R`: role registry, participants, teams, tasks, dispatch, lifecycle, runtime telemetry.
- `R/workstation_ai_objective.R`: roles selected for delegated analytical objectives.
- `R/workstation_ai_execution.R`: governed execution and step states, dependencies, failures, result bindings, leases, and progress.
- `R/workstation_ai_job.R`: durable user-facing jobs, attention state, milestones, outputs, retry safety, and timestamps.
- `R/agent_operation.R`: bounded agent-session, action, approval, evidence, service-run, and replay contracts.
- `R/agent_commentary.R`: safe bounded commentary and explicit private-reasoning exclusions.
- `docs/ui_opportunity_scan.md` in this repository: prior findings on long-running work, job monitoring, lineage, and event timelines.

UI labels, route names, collaboration styles, report audiences, and arbitrary reviewer names were not treated as canonical agent identities.

## Principal Archaeology Finding

Analytics Workstation does **not** currently implement one unified agent/execution model. It has several governed, partially overlapping seams:

1. `collaboration_foundation.R` defines canonical roles, AI participants, teams, coordination tasks, and bounded provider dispatch.
2. `governed_agent_delegation.R` defines human-origin Delegation Mandates, child-task authority, scope, consequence classes, and authority decisions. A Mandate carries authority but performs no execution.
3. `workstation_ai_objective.R`, `workstation_ai_execution.R`, and `workstation_ai_job.R` compile user intent into dependency steps, execute through canonical owners, and project durable user-facing jobs.
4. `agent_operation.R` defines an AgentSession campaign with actions, approvals, evidence references, service runs, replay, and report output. It is a campaign runner, not the universal scheduler.
5. `execution_lease_contract.R` and `execution_lease_runtime.R` define governed physical execution attempts, cancellation, heartbeat, timeout, orphan recovery, retry lineage, and append-only events.
6. Review, Devil's Advocate challenge, and adjudication are governed analytical/review records. They do not grant execution or publication authority.

The monitor therefore needs a source-aware projection. It may correlate these seams by existing IDs, but must not manufacture a master agent object, global state machine, or authority hierarchy that Workstation does not own.

## Current Role Inventory

`collaboration_roles()` is the canonical role registry. Any registered role can be used by an AI participant and passed to `collaboration_dispatch()`, but only some are currently selected by objective orchestration or included in default team templates.

### Active executable roles

| ID | Canonical title | Purpose | Current activation | Delegate | Review/challenge | Concurrency |
|---|---|---|---|---|---|---|
| `investigator` | Investigator | Conduct bounded analytical investigation and produce analytical summaries. | Delegated objectives; investigation, decision-support, research, and review teams. | No recursive dispatch. | Examines evidence, but is not the governed reviewer. | May coexist across jobs; default team plan permits one active member. |
| `researcher` | Researcher | Gather and synthesize research evidence. | Research-only delegated objectives and research teams. | No | Evidence-oriented, not approval authority. | Same constraint. |
| `synthesizer` | Synthesizer | Consolidate team outputs into a case summary. | Analytical/research delegated objectives and several teams. | No | Synthesis, not independent approval. | Same constraint. |
| `planner` | Planner | Propose and sequence bounded work. | Investigation, model-build, forecast, decision-support, research, and full-review teams. | No; creates proposals within the host plan. | No | Same constraint. |
| `data_steward` | Data Steward | Review data suitability, preparation, and stewardship concerns. | Model-build, forecast, and full-review teams. | No | Data review only. | Same constraint. |
| `methodologist` | Methodologist | Review methods and compare analytical strategies. | Methodology/method-competition objectives and several teams. | No | Yes, methodological challenge; not approval authority. | Same constraint. |
| `reviewer` | Reviewer | Produce scoped review findings. | Model-build, decision-support, and full-review teams. | No | Yes | Same constraint. |
| `decision_analyst` | Decision Analyst | Analyze alternatives and decision implications. | Decision-support teams. | No | Evaluative, not adjudication authority. | Same constraint. |

### Registered executable specialists

These are canonical, dispatchable roles, but the current objective role selector does not assign them directly and default team templates do not instantiate most of them. A monitor may show them only when host-supplied participant or task records prove they are active.

| ID | Canonical title | Purpose |
|---|---|---|
| `analytical_lead` | Analytical Lead | Analytical leadership and coordination. |
| `data_acquisition` | Data Acquisition / Connection | Data acquisition and connections. |
| `data_preparation` | Data Processing / Preparation | Data processing and preparation. |
| `data_quality` | Data Quality | Data-quality analysis. |
| `exploratory_analysis` | Exploratory Analysis | Exploratory analytical work. |
| `visualization` | Visualization | Analytical visualization. |
| `feature_engineering` | Feature Engineering | Feature-engineering work. |
| `statistical_testing` | Statistical / Hypothesis Testing | Statistical and hypothesis testing. |
| `modeling` | Modeling | Model development and analysis. |
| `unsupervised_learning` | Unsupervised Learning | Unsupervised analytical work. |
| `forecasting` | Forecasting / Time / Change | Forecasting, temporal, and change analysis. |
| `causal_modeling` | Causal Modeling | Governed causal modeling. |
| `evidence_research` | Evidence / Research | Evidence research. |
| `reporting` | Reporting / Communication | Reporting and communication. |
| `marketing` | Marketing | Marketing-domain analysis. |
| `finance` | Finance | Finance-domain analysis. |
| `operations` | Operations | Operations-domain analysis. |
| `supply_chain` | Supply Chain | Supply-chain analysis. |

### Reviewer and adjudicator roles

| ID | Canonical title | Classification | Executes work | Delegate | Review/challenge | Activation |
|---|---|---|---|---|---|---|
| `devils_advocate` | Devil's Advocate | Independent challenger | Yes, bounded challenge work | No | Yes | Explicit/high-impact challenge conditions. |
| `adjudicator` | Adjudicator | Governed adjudicator | Yes, bounded adjudication | No | Yes; resolves material disagreement but does not replace human authority. | Human-requested decision challenge or governed adjudication conditions. |

### Contextual and non-executable identities

- `human`, `project_owner`, `case_owner`, `analyst`, `approver`, and `observer` are host actors or contextual roles, not AI specialists.
- `service` is a participant type/runtime identity, not an agent persona.
- Collaboration styles such as Senior Analyst, Skeptical, Exploratory, and Executive modify communication behavior; they are not agents.
- Route classes labelled `specialist`, report audience labels, product-review fixture names, and free-text reviewer names are metadata, not canonical registry entries.
- No role is explicitly deprecated. The specialist roles not used by current orchestration are latent/registered, not proven active.

## Identity, Authority, and Execution Relationships

The actual relationship chain is:

```text
human request
  -> interpreted objective
  -> Delegation Mandate (human-origin authority; stable ID, revisioned fingerprint)
  -> delegated child task (role-specific, scope/action ceiling; cannot expand parent)
  -> objective dependency plan (canonical owner and operation per step)
  -> governed execution record
  -> Execution Lease where physical work needs an ownership envelope
  -> result binding / Dataset Revision / visual document / artifact
  -> evidence and bounded commentary
  -> review / challenge / adjudication
  -> human decision where authority is required
```

AgentSession is an adjacent campaign container. It can reference a project/dataset, run canonical services through actions, collect evidence and approvals, produce a report, and replay its presentation. `workstation_ai_context()` can carry an AgentSession reference alongside project, workflow, artifact, report, and Mandate identities. A user-facing Work job may link `objective_id`, `execution_id`, `mandate_id`, and `agent_session_id`, making it the best current join projection, not a new source of authority.

### Durability classification

| Identity | Durability | Meaning |
|---|---|---|
| Role ID | Schema-stable | Canonical role vocabulary; not an individual process. |
| Participant ID | Team/case durable | An instantiated human/AI/service participant; multiple instances of the same role may exist across cases or teams. |
| Mandate ID | Durable and revisioned | Human-origin authority identity remains stable; revisions receive new fingerprints and supersede prior authority snapshots. |
| Delegated task ID | Mandate-revision scoped | Execution-specific authority reduction for one role/task. It cannot expand its parent Mandate. |
| Objective ID | Request/plan scoped | Compiled intent and dependency plan. |
| Execution ID | Execution scoped | One governed execution record for an objective. |
| Job ID | User-facing durable projection | Snapshot/reconciliation record over objective and execution. Current storage uses RDS snapshots under a runtime temp directory, so cross-install durability is not guaranteed. |
| Lease ID | Physical-attempt scoped, optionally durable | One provider/runtime attempt; retries create a new lease linked by `retry_of_lease_id`. Durable history requires the metadata adapter. |
| AgentSession ID | Campaign scoped, serializable/replayable | One bounded campaign record, not an agent identity or Mandate. |
| Action/service-run ID | Session scoped | One bounded action or analytical service invocation. |
| Artifact/evidence/revision ID | Governed product identity | Durable output/lineage reference owned by the existing artifact, evidence, or revision system. |

There is no canonical singleton named “the Investigator.” The title is a role; the participant, delegated task, session, execution, and lease identify concrete activity.

### Delegation and authority rules relevant to display

- Mandate modes are `advise`, `explore`, and `evolve`; statuses are `active`, `paused`, `completed`, `terminated`, and `superseded`.
- Advise permits inspection, context retrieval, reasoning, consultation, and recommendation. Explore/evolve may additionally permit revisioned analytical actions.
- External/material and destructive actions remain human-gated. Hosted provider use is an `external_material` consequence.
- Child tasks intersect requested actions with the Mandate and role ceiling. They set `may_expand_parent = FALSE`.
- Consultation authority transfers only bounded read/reason/recommend actions and explicitly does not transfer parent authority.
- Recursive collaborator dispatch is prohibited. Default team plans set `maximum_active = 1L`.
- Adjudication can recommend `do_not_publish`, `publish_with_limitations`, or acceptance, but publication/override still requires named human authority.

## Actual Lifecycle and Activity States

The host currently exposes several state vocabularies. The monitor must preserve `raw_status` and derive a normalized display state rather than rewriting host records.

| Host contract | Actual states | Normalized monitor state |
|---|---|---|
| Collaborator participant | `sleeping`, `queued`, `active`, `awaiting_input`, `awaiting_approval`, `completed`, `blocked`, `cancelled`, `stopped`, `failed` | idle, queued, running, waiting, completed, blocked, cancelled, failed |
| Coordination task | `waiting` initially; plan is `planned` | waiting / queued |
| Governed execution/step | `PLANNED`, `READY`, `RUNNING`, `WAITING_FOR_INPUT`, `WAITING_FOR_APPROVAL`, `SUCCEEDED`, `PARTIAL`, `FAILED`, `INTERRUPTED`, `UNKNOWN_REMOTE_STATE`, `CANCELLED`, `BLOCKED` | queued, ready, running, waiting, completed, warning, failed, interrupted, cancelled, blocked |
| User-facing job | `READY`, `WORKING`, `NEEDS_YOU`, `PAUSED`, `COMPLETE`, `PARTIAL`, `FAILED`, `INTERRUPTED`, `CANCELLED` | ready, running, awaiting_human, paused, completed, warning, failed, interrupted, cancelled |
| Agent session | `created`, `planning`, `awaiting_approval`, `running`, `paused`, `completed`, `failed`, `cancelled`, `replaying` | ready, planning, awaiting_human, running, paused, completed, failed, cancelled, replaying |
| Agent action | `pending`, `running`, `completed`, `failed`, `skipped`, `cancelled`, `awaiting_approval` | queued, running, completed, failed, skipped, cancelled, awaiting_human |
| Delegation Mandate | `active`, `paused`, `completed`, `terminated`, `superseded` | active, paused, completed, cancelled/superseded |
| Execution Lease | `created`, `queued`, `running`, `cancelling`, `succeeded`, `failed`, `cancelled`, `timed_out`, `orphaned` | ready, queued, running, cancelling, completed, failed, cancelled, interrupted/recovery_required |

`retrying` is not a current status. Job retry updates the governed execution/job record; Execution Lease retry creates a new attempt linked by `retry_of_lease_id`. `waiting` exists on coordination tasks but is absent from `collaboration_lifecycle_states()`; the adapter must map it explicitly and surface a schema diagnostic until the host reconciles that mismatch.

Attention is already first-class on Work jobs: `none`, `needs_input`, `needs_approval`, `needs_human`, and `failure`. Additional attention signals are execution `WAITING_FOR_INPUT`, `WAITING_FOR_APPROVAL`, `UNKNOWN_REMOTE_STATE`, `INTERRUPTED`, and `BLOCKED`; Mandate expansion requests use `pending_human_decision`; AgentSession uses `awaiting_approval`; and adjudication can require human judgment or remediation. These should remain distinct in detail even if summarized under `awaiting_human`.

## Existing Telemetry and Data Seams

The component must consume projections supplied by the host. It must not read Workstation globals or stores directly.

| Read-only seam | Useful current fields |
|---|---|
| Role registry and team participants | participant ID, role ID/title, participant type, status, scope, current assignment, queue, last activity, permissions, budget/usage, lineage. |
| Coordination plans/tasks | plan ID, task ID, participant/role, sequence, dependency ID, instruction, output type, status, created time, maximum active count. |
| Work objectives | objective ID, organization mode, selected roles, dependency plan, step owner, required inputs, expected output, dependencies, permission state. |
| Governed executions | execution ID, objective ID, status, steps, result bindings, failures, safe resume step, remote-state knowledge, lease IDs, created/updated time. |
| Durable jobs | job ID, label, objective/execution/mandate/session IDs, status, attention, textual step progress, outputs, question, retry safety, timestamps, predecessor job, roles, milestones. |
| Agent sessions/actions | session ID, status, plan, actions, observations, decisions, approvals, service runs, evidence references, timestamps, current UI target, replay state, action errors and outputs. |
| Collaborator dispatch result | participant ID, task, provider/model, start/end, duration, reported input/output tokens, optional cost, response-contract validity, lineage. |
| Safe commentary | role, agent ID, kind, bounded statement, object identity, timestamp; forbidden private-reasoning keys are rejected. |
| Delegation authority | Mandate ID/revision/fingerprint, origin actor, scope, autonomy, allowed actions, boundaries, provider/cost/external policy, child-task role and authority, expansion requests. |
| Execution Lease service | lease/parent/retry IDs, owner, actor, work identity, scope, Mandate snapshot, provider/runtime, status, timestamps, heartbeat, cancellation evidence, result references, late-result disposition, cleanup/recovery state, redacted event history. |
| Review/adjudication | review and objection IDs, dispositions, evidence references, remaining uncertainty, readiness recommendation, human-judgment requirement, approval artifact requirement, lineage. |

Currently available: IDs, roles, dependencies, status, attention reason, created/updated/completed timestamps, action start/end, bounded progress labels, errors/failures, retry safety, output/artifact-like identities, approvals, review records, duration, and sometimes tokens/cost.

Not consistently available: numeric percent complete, queue ETA, resource utilization, universal capability/tool ID, aggregate retry count, throughput windows, aggregate token/cost totals, or latency for every execution path. Lease retry lineage exists, and collaborator dispatch may report tokens/cost/duration, but neither is universal. These values are future-only unless supplied by the host.

No private reasoning is a data seam. `agent_commentary` explicitly rejects chain-of-thought/scratchpad/hidden-trace fields and marks commentary as not evidence and not review.

## Normalized Monitor Contract

The proposed component is `agent_activity_monitor()`. Although jobs and services are included, the name reflects the primary user question: who or what is working, on which governed task, and what needs attention.

The component accepts one snapshot with four tables/lists. Required fields are deliberately small; optional fields are rendered only when present.

### `actors`

| Field | Required | Contract |
|---|---|---|
| `actor_id` | yes | Stable host identity. |
| `title` | yes | Canonical display title. |
| `role_id` | yes | Canonical role ID or host actor type. |
| `actor_type` | yes | `agent`, `reviewer`, `adjudicator`, `human`, or `service`. |
| `status` | yes | Normalized state. |
| `raw_status` | no | Exact host status. |
| `current_work_id` | no | Current work-item reference. |
| `last_activity_at` | no | ISO-8601 timestamp. |

### `work_items`

| Field | Required | Contract |
|---|---|---|
| `work_id` | yes | Stable task/job/execution/action identity. |
| `label` | yes | Human-readable bounded work label. |
| `kind` | yes | `job`, `execution`, `step`, `task`, `session`, `action`, or `review`. |
| `status` | yes | Normalized state. |
| `raw_status` | no | Exact host status. |
| `actor_id` | no | Assigned actor. |
| `parent_id` | no | Parent work item. |
| `dependency_ids` | no | Character vector of real prerequisites. |
| `attention` | no | `none`, `needs_input`, `needs_approval`, `needs_human`, or `failure`. |
| `progress_label` | no | Bounded host-supplied progress text. |
| `progress_value` | no | Numeric 0-1 only when genuinely supplied. |
| `capability_id` | no | Host-supplied operation/service/capability ID. |
| `started_at`, `updated_at`, `ended_at` | no | ISO-8601 timestamps. |
| `error_summary` | no | Sanitized error text. |
| `retry_safe` | no | Host-declared boolean; not a retry command. |
| `output_ids` | no | Artifact/result identities. |
| `source_contract` | yes | Host seam such as `workstation_job`, `governed_execution`, `execution_lease`, `agent_session`, or `collaboration_task`. |
| `authority_ref` | no | Existing Mandate/approval/review reference; display only. |

### `events`

| Field | Required | Contract |
|---|---|---|
| `event_id` | yes | Stable event identity. |
| `occurred_at` | yes | ISO-8601 timestamp. |
| `event_type` | yes | Bounded vocabulary such as `work_started`, `status_changed`, `capability_completed`, `dependency_resolved`, `review_requested`, `retry_recorded`, `artifact_produced`, `failure_recorded`. |
| `summary` | yes | Human-readable, bounded, non-private text. |
| `work_id`, `actor_id` | no | Related normalized identities. |
| `severity` | no | `info`, `success`, `warning`, or `error`. |
| `evidence_ids`, `output_ids` | no | Traceable host references. |

### `summary`

Optional host-computed values: `active`, `queued`, `blocked`, `failed`, `awaiting_review`, `completed`, `throughput`, `median_latency`, `token_total`, and `cost_total`. Missing values remain absent; the widget must never estimate them.

Adapters should also return `diagnostics` containing unknown raw states, unresolved references, duplicate IDs, invalid dependency edges, stale timestamps, and omitted sensitive fields. Diagnostics are not execution failures and must not mutate host records.

## UI Regions

1. **System summary**: compact counts for active, queued, blocked/failed, and awaiting human attention. Optional throughput/latency/cost appear only when supplied.
2. **Overview**: searchable, status-filterable work list grouped by attention first, then active work. Each row shows actor, canonical role, work label, status, dependency/attention state, bounded progress, and elapsed time where timestamps exist.
3. **Activity feed**: virtualized, bounded events with actor/work links and severity. It exposes outcomes, transitions, approvals, retries, and produced artifacts, never prompts or hidden reasoning.
4. **Inspector**: selected actor/work detail, real dependencies, failures, outputs, lineage IDs, and review requirement. Host navigation is emitted as an intent event.
5. **Attention and review queue**: a filtered projection over Work job attention, approval-gated execution/session state, Mandate expansion requests, and adjudication requiring human judgment. It is not a second approval model.

The prior opportunity scan supports a virtualized job monitor and linked event timeline because they improve triage and bound DOM growth. Human interruption must be visually dominant: `NEEDS_YOU`, approval, blocked, interrupted, unknown remote state, and failure cannot be collapsed into generic activity.

## External Interaction Patterns Retained

No Devpost-specific research artifact is present in the lab checkout, so no Devpost persona or product claim is treated as evidence. The existing UI opportunity scan and Workstation's ndexr reconnaissance support these generic patterns:

- make long-running work visibly owned and recoverable rather than fire-and-forget;
- use durable execution identity plus lease/heartbeat evidence instead of trusting a process ID;
- show explicit interruption, cancellation, approval, degraded, and orphan-recovery states;
- keep human approval between proposal and consequential effect;
- present bounded, virtualized event history instead of unbounded logs;
- preserve typed failures, provenance, output commit boundaries, and last-known-good context;
- avoid hidden observers/pollers when a monitor view is not active.

These are interaction and governance patterns only. ndexr is not a dependency, authority, vocabulary source, or agent taxonomy for this component.

## Topology Decision

A topology view is justified only for snapshots containing actual `parent_id` or `dependency_ids`. Workstation has real objective-step dependencies, coordination-task dependencies, predecessor jobs, and result lineage, so a read-only topology can add value. It is secondary to the accessible list/inspector, off by default for flat work, and must not invent agent-to-agent connections. React Flow is already bundled in `shinycapabilities`, but every graph relationship requires an equivalent keyboard-navigable textual representation.

## Current Versus Future-Only Views

| View/capability | Classification | Existing driver |
|---|---|---|
| Agent/session cards | Current | Participants, roles, current assignment, AgentSession, Work job links. |
| Queue/pipeline | Current with adapter | Coordination sequence/dependencies, objective steps, execution/lease states. |
| Bounded activity feed | Current | Job milestones, lease events, actions, inquiry events, safe commentary, outputs. |
| Attention-required surface | Current | Job attention plus approval/input/interruption/failure states. |
| Human-review queue | Current with multiple source adapters | Approval records, review/adjudication requirements, Mandate expansion requests. |
| Dependency topology | Current when edges exist | `depends_on`, parent/retry/predecessor IDs, result lineage. |
| Throughput/latency summary | Partial | Timestamps and some durations exist; host must aggregate. |
| Token/cost dashboard | Partial | Collaborator dispatch may report values; coverage is not universal. |
| Percent-complete bars and ETA | Future-only | No canonical numeric progress or ETA. |
| Resource/worker utilization | Future-only | No universal resource telemetry. |
| Decorative agent social graph | Not justified | No canonical social/communication topology. |
| Direct monitor controls for cancel/retry/approve | Future host integration only | Existing commands/services own mutation; 1.0 remains read-only. |

## Deliberate Non-Responsibilities

The monitor must not:

- schedule, dispatch, execute, cancel, pause, resume, approve, retry, or mutate work;
- become a second execution, event, approval, or artifact store;
- infer roles, progress, ETA, cost, or dependencies;
- expose prompts, chain-of-thought, scratchpads, hidden traces, tool payloads, or raw provider responses;
- turn safe commentary into evidence or review;
- imply concurrency when a team policy permits only one active participant;
- imply causal responsibility from temporal ordering;
- poll Workstation internals directly.

Human actions, if later desired, must be host-owned commands emitted outside this component's read-only 1.0 contract.

## Recommended Public Shiny API

```r
agent_activity_monitor(
  id,
  actors,
  work_items,
  events = NULL,
  summary = NULL,
  selected_work_id = NULL,
  views = c("overview", "activity", "topology"),
  max_events = 500L,
  height = "640px"
)
```

Inputs may be data frames/data tables or row-like lists normalized by R before serialization. The component emits only:

- `input[[paste0(id, "_selection")]]`: selected actor/work/event identity;
- `input[[paste0(id, "_navigation")]]`: host-neutral request to inspect a referenced output/evidence/work item;
- `input[[paste0(id, "_view_state")]]`: filters, active view, and expanded rows.

No output event authorizes or performs a job action.

## Promotion Readiness and Eventual Grok Integration

Grok is not a current canonical Workstation provider, role, agent, or execution state. No `grok` identity appears in the active Workstation source. The current hosted-provider surfaces recognize provider-neutral hosted adapters and selected providers such as OpenAI-compatible configurations; Workstation policy forbids silent local-to-hosted fallback. Development evidence also records a hosted AgentGateway path that is implemented but not operationally qualified because live invocation did not complete successfully.

Accordingly, promotion of this component and any later Grok adapter require:

1. **Provider neutrality**: the monitor displays host-supplied provider/model labels as execution metadata, never as agent identities or hard-coded states.
2. **No authority inflation**: enabling Grok must pass existing User Profile, credential, consent, sensitive-data, Delegation Mandate, consequence, cost, and approval gates. The monitor cannot grant or imply authorization.
3. **Contract parity**: hosted contributions must project the same normalized actor/work/event schema as local or deterministic runs while retaining `source_contract`, provider provenance, raw status, and typed failures.
4. **Redaction and bounded events**: no prompts, model reasoning, raw provider response, credentials, or sensitive payloads enter monitor events. Only safe commentary, status, evidence/output references, and sanitized errors are eligible.
5. **Operational qualification**: a real funded hosted invocation, write-back, replay, independence, timeout/quota/auth failure, cancellation/unknown-remote-state, and cost/token telemetry tests must pass before a Grok-backed run is labelled production-ready.
6. **No automatic fallback**: local failure must not silently promote work to Grok. Provider changes and material cost remain explicit human-visible events.
7. **Retry identity**: hosted retries create new attempt identities and preserve parent/retry lineage; the original failure remains visible.
8. **Promotion seam**: `shinycapabilities` needs only the generic display contract. Grok-specific adapters, policies, credentials, and execution belong to Workstation/AgentGateway, not this package.

The component itself is promotion-ready when deterministic fixtures cover every source contract, normalization diagnostics are lossless, accessibility and bounded-update QA pass, no mutation channel exists, and Workstation can replace the fixture adapter with a read-only projection without changing the widget API.

## Next Checkpoint Recommendation

Build a semantic, read-only 1.0 component against deterministic fixtures covering: one active delegated investigation, one dependency-blocked step, one approval gate, one failed execution, one completed artifact-producing action, and one safe commentary event. Implement overview, activity feed, inspector, state normalization diagnostics, keyboard navigation, and empty/loading/error states first. Add topology only after the list/feed contract passes QA with real Workstation-shaped fixtures.

Required QA should prove raw status preservation, deterministic normalization, attention precedence, dependency integrity, bounded event rendering, absence of private-reasoning fields, no mutation events, accessible list equivalents for graph data, and stable behavior when optional telemetry is absent.
