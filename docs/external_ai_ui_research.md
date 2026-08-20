# External AI/UI Research: Gaps Worth Closing

## Executive conclusion

The ecosystem does not need another agent dashboard, topology viewer, tree, grid, command palette, parameter editor, or split pane. The qualified lab already covers those projection primitives well. The important external lesson is that **observability is only the first half of governed agent work**. The unresolved product surface sits between evidence and authority:

1. replay a bounded execution from the evidence it actually saw;
2. review a proposal together with its risks, evidence, and exact mutation;
3. invalidate approval when the reviewed subject changes;
4. compare competing judgments without collapsing disagreement into one confidence score; and
5. preserve decisions, assumptions, and later outcomes as durable learning artifacts.

These are durable needs even if models become faster, cheaper, and much more capable. Role-heavy swarms, token-driven context rituals, and dashboards centered on model internals are not durable architecture.

## Strongest findings

| Classification | Source | Actual mechanism | Why it matters | Durability | Implication |
|---|---|---|---|---|---|
| **Adopt** | [Incident Commander AI](https://devpost.com/software/incident-commander-ai) | Typed proposals are separated from authority. Evidence citations, approval bindings, verification artifacts, and risk are validated by deterministic state transitions. Two approvals bind to different artifacts. | “Approve” is meaningless unless the reviewed bytes, evidence, authority, and resulting action are bound together. | Durable | Add an artifact-bound review contract and stale-approval detection to Workstation. |
| **Adopt** | [Decision Receipt](https://devpost.com/software/decision-receipt) | Capture, lock, review, and learn: expectations, assumptions, falsification signal, confidence, and review date are immutable before the outcome is known. | Workstation can learn from analytical decisions rather than merely retain generated outputs. | Durable | Introduce decision/outcome receipts as project artifacts, not chat history. |
| **Adapt** | [AgentLoop](https://devpost.com/software/agentloop) | Durable files carry plan, state, and rubric; fresh workers receive concrete critic fixes; events and transcripts survive process boundaries. | Explicit resumable state is more reliable than treating conversation history as canonical memory. | Mixed | Keep durable context capsules and recovery checkpoints; do not institutionalize fresh-process cycling as a permanent requirement. |
| **Adopt** | [SignalReview](https://devpost.com/software/signalreview-autonomous-multi-agent-ai) | Strict analysis specifications, declared outputs, isolated validation, content-addressed candidate bundles, and a visible candidate/tests/validation/provenance evidence pack. | A generated result should be inspectable as one sealed review subject with reproducible evidence. | Durable | Define review bundles and content identity for generated analytical/code artifacts. |
| **Adapt** | [Shepherd](https://devpost.com/software/the-shepherd) | A bounded pre-failure replay joins observed state, grounding/action events, verifier verdicts, and intervention. | Failures are easier to diagnose from a synchronized timeline than from logs and a final error alone. | Durable if private reasoning is excluded | Build an execution replay primitive over safe events, snapshots, artifacts, and policy decisions. |
| **Adapt** | [CrisisOps](https://devpost.com/software/crisisops-weyvut) | The UI shows the active path and branches not taken; specialists submit structured findings; a deterministic gate decides whether action is allowed. | Hidden alternatives make automated decisions hard to audit. | Durable | Add branch/rationale projections and structured disagreement comparison; reject self-reported confidence as sufficient authority. |
| **Adopt** | [LeanCOO Pre-contract Workspace](https://devpost.com/software/leancoo-pre-contract-workspace) | Original sources remain separate; generated claims cite source markers; every edit and approval is versioned; only approved material crosses the business boundary. | Evidence-linked editing and deterministic handoff are reusable beyond documents. | Durable | Add claim-to-evidence inspection and version-aware handoff receipts. |
| **Adapt** | [ReachAI](https://devpost.com/software/reachai-enterpriseagentframework) | Versioned workflow configuration, explicit allowlists, revision checks, dry-run validation, structured streaming, and separate policies for reads, page actions, writes, and failures. | Authority should be action-specific, not a single “agent enabled” switch. | Durable | Make capability authority and revision identity visible at review time. |
| **Adapt** | [Meridian](https://devpost.com/software/meridian-uw62z5) | Flat PASS/FAIL/REVIEW contracts pause a case, provide focused review context, and resume without losing or double-counting state. | Human-in-the-loop quality depends on the return path, not the presence of a button. | Durable | Treat interruption and resumption as one governed contract with idempotency. |
| **Future** | [Agent Readiness Protocol](https://devpost.com/software/agent-onboarding-protocol) | A reviewable readiness contract pairs requirements with observable readiness across integration, authentication, data, infrastructure, stakeholders, and approval. | Preflight visibility prevents hidden prerequisites from surfacing halfway through a run. | Durable | Consider a generic readiness/dependency matrix after Workstation contracts stabilize. |

## ndexr findings

The local ndexr source contains several mechanisms more valuable than its surface UI:

- **Scoped pane context, not a parallel application.** `exec.ndexr.io` receives the target surface through its URL; pane mode does not merely hide host chrome, it avoids constructing unrelated servers and pollers. A future Workstation assistant should receive a bounded context projection from the active surface rather than scrape or duplicate the app.
- **Reviewable policy is the governance unit.** The deployment documentation explicitly scopes agent credentials and keeps policy JSON beside the governed system so authority can be diffed and reviewed. Workstation permissions should resolve to versioned policy evidence, not UI state.
- **Durable detached execution.** Fleet actions run asynchronously, persist host logs, and survive worker restart. Render paths never perform operational work. This supports Workstation's existing separation between monitor projections and execution authority.
- **Checkpoints have expected evidence.** Setup stages end in a command plus expected output. The skills catalog couples reusable procedures to hard-stop validators. Capability discovery without qualification evidence is incomplete.
- **Paths are part of context quality.** The mount-alignment plan removes host/container path translation so logs, people, and agents refer to the same object identity. Workstation should prefer canonical resource URIs that survive process and environment boundaries.
- **Bound expensive live surfaces.** The agents wall pages live iframes and unloads off-page sessions. It distinguishes the selected set from the live fleet and states fallbacks honestly. This is a strong precedent for bounded monitor projections and explicit source labels.
- **Close-session memory is curated, not transcript archival.** Decisions, rationale, open work, and references are persisted separately from narration. This is the right direction for context capsules, although the contract should become typed and host-neutral.
- **Validation is fail-soft only where authority permits it.** Read-only preference/data surfaces can fall back; deployment and package qualification use hard gates. Workstation should encode whether a failed check blocks, warns, or merely degrades a projection.

Relevant local sources include `src/domains/agents.ndexr.io/CONTEXT.md`, `src/domains/exec.ndexr.io/`, `src/domains/skills.ndexr.io/catalog.r`, `src/domains/traces.ndexr.io/`, `src/domains/ndexr.ndexr.io/crate/src/app/permissions.rs`, `docs/mount-alignment-plan.md`, and `src/domains/ymnnpc.ndexr.io/`.

## Strong Devpost projects inspected

The projects above were selected for implemented mechanisms, not polish or popularity. The most substantive were Incident Commander AI (evidence and authorization model), SignalReview (sealed candidate evidence packs), AgentLoop (resumable file-backed loops), Decision Receipt (immutable expectation/outcome learning), LeanCOO (evidence-linked review and version history), ReachAI (revision-aware workflow authority), Shepherd (failure replay), CrisisOps (visible branches and deterministic gates), and Meridian (pause/review/resume contract).

Projects centered mainly on generic chat, personas, stat-card dashboards, or unverified “shared intelligence” were rejected. [Watchdog](https://devpost.com/software/watchdog-erlu0z), for example, usefully questions all-to-all agent communication but its semantic consensus mechanism risks converting correlated agreement into truth. Workstation's evidence and epistemic-judgment direction is stronger.

## Durable architecture lessons

1. **Intelligence proposes; deterministic authority disposes.** Model output may be a typed proposal, never an approval or mutation authority.
2. **Approval binds to a versioned subject.** Bind reviewer identity, policy version, evidence set, artifact/content hash, proposed effect, and expiration. Any relevant change makes approval stale.
3. **Events are replay inputs, not just monitor decoration.** Store bounded typed events with causation, subject identity, source, timestamp, and evidence/artifact references.
4. **State must resume idempotently.** Pausing for a human and continuing later must not repeat completed effects or lose the original decision context.
5. **Generated work needs an evidence pack.** Candidate, inputs, declared contract, tests/checks, provenance, limitations, and validation receipt should be inspectable together.
6. **Preserve alternatives and counter-evidence.** Branches not taken, dissenting judgments, failed checks, and uncertainty should remain visible.
7. **Truth labels are first-class.** Live, fixture, replay, deterministic local analysis, and model-generated output must never be visually conflated.
8. **Canonical context is curated state.** Durable goals, constraints, decisions, resource identities, and unresolved questions matter more than retaining every conversational token.

## Current-model scaffolding to avoid

- Permanent role-per-prompt agent societies when a typed computation/review stage would suffice.
- Fresh-process cycles as a universal architecture. They are a useful response to current context rot, not the durable abstraction; resumable state and qualification are durable.
- Model-tier routing encoded into product concepts. Keep provider/model routing behind capability requirements.
- Token counts, chain-of-thought, and verbose internal reasoning as primary observability. Show evidence, actions, bounded rationale, decisions, and outcomes.
- Self-reported confidence as an authorization signal. Confidence must be calibrated against diagnostics, evidence quality, and observed reliability.
- Phone/voice approval as the governance mechanism. It may be a delivery channel, but identity, reviewed subject, and signed decision remain canonical.
- Opaque “consensus” as truth. Agreement among agents sharing data, prompts, or failure modes is correlated evidence, not independent validation.

## Things already covered or better

| External pattern | Existing lab position | Classification |
|---|---|---|
| Mission-control status cards and event feeds | Agent Activity Monitor already provides bounded, virtualized, host-neutral activity, attention, inspector, and topology projection. | **Already Better** |
| Dependency/trust/provenance graphs | Relationship Graph already supports typed nodes/edges, cycles, diagnostics, accessible fallback, and progressive disclosure. | **Already Better** |
| Large tabular inspection | AG Grid Data Grid already owns the specialized virtualized grid seam. | **Already Covered** |
| Hierarchy/capability discovery | Virtual Tree Browser and Command Palette cover these without duplicating host authority. | **Already Covered** |
| Dense configuration forms | Typed Parameter Workbench is the correct reusable primitive. | **Already Covered** |
| Resizable inspector layouts | Accessible Split Pane is already qualified. | **Already Covered** |
| Decorative multi-agent maps | Real typed relationships are required; decorative connections are rejected. | **Reject** |

## Newly discovered UI/UX gaps

### 1. Execution Replay and Investigation Timeline — **Build next**

A synchronized, read-only replay over host-supplied events, state snapshots, artifacts, policy decisions, validations, and interventions. It should support temporal scrubbing, event-to-evidence navigation, before/after state, failure-window focus, source labels, and redacted payload inspection. It must not expose private reasoning or recreate execution.

This is not another activity feed: the monitor answers “what is happening?” Replay answers “what exactly changed, what evidence was available then, and why did the governed system advance or stop?”

### 2. Artifact-Bound Review Workbench — **Build next**

A focused approval/review surface that displays the exact proposal, affected resources, evidence, checks, policy/version identity, risks, alternatives, and downstream effects. It emits approve/reject/request-change intents against a supplied subject fingerprint. The host owns authorization and must reject stale fingerprints.

### 3. Judgment / Disagreement Comparator — **Strong candidate**

A structured comparison surface for claims or proposals with evidence, counter-evidence, assumptions, confidence basis, diagnostic status, and falsification tests. It should preserve minority positions and distinguish independent evidence from duplicated sources. Relationship Graph may provide navigation, but not the comparative reading surface.

### 4. Decision Receipt and Outcome Review — **Strong candidate**

A compact capture/lock/review primitive for decision, expected outcome, assumptions, disconfirming signals, confidence, evidence, deadline, actual outcome, and lessons. The reusable capability is immutable version comparison and outcome calibration, not AI advice.

### 5. Context Capsule Inspector — **Adapt later**

A host-neutral inspector for the curated state passed into a run: objective, constraints, decisions, unresolved questions, resources, policy, capability set, provenance, compaction lineage, and freshness. It should compare capsules across resume/compaction boundaries and flag dropped or stale commitments.

### 6. Readiness and Authority Matrix — **Later**

A matrix crossing required capabilities/resources with readiness, authorization, validator evidence, owner, expiration, and blocker. This becomes valuable when the underlying Workstation readiness and permission contracts are stable.

## Newly discovered agent-system gaps

1. No canonical **review subject fingerprint** tying approval to exact artifacts, evidence, policy, and intended effect.
2. No general **stale approval** rule for changed context or artifacts.
3. No normalized **execution replay projection** distinct from current activity state.
4. No first-class **context capsule lineage** for resume, compaction, and handoff quality.
5. No durable **decision/outcome learning loop** across projects.
6. No explicit **independence/correlation metadata** for multi-review evidence; agent agreement may be falsely treated as corroboration.
7. No generic **idempotent resume receipt** describing completed effects, pending effects, and safe continuation point.
8. No common **truth-source label** spanning live, replay, fixture, deterministic, and model-generated evidence.

## Ranked shinycapabilities opportunities

| Rank | Primitive | Classification | Why now |
|---:|---|---|---|
| 1 | `execution_replay()` | **Build next** | Complements rather than duplicates Agent Activity Monitor; supports failure recovery, audit, and provenance investigation. |
| 2 | `review_workbench()` | **Build next** | Makes human authority usable and precise; reusable for code, plans, artifacts, exports, and analytical judgments. |
| 3 | `judgment_comparator()` | **Strong candidate** | Directly supports challenge/adjudication and AutoQuant's epistemic judgment direction. |
| 4 | `decision_receipt()` | **Strong candidate** | Creates a durable learning loop beyond generated reports and chat history. |
| 5 | `context_capsule_inspector()` | **Adapt later** | Valuable after Workstation defines the canonical context/resume contract. |
| 6 | `readiness_matrix()` | **Later** | Useful, but should follow authoritative readiness and permission schemas. |

## Ranked Workstation architecture implications

1. Define artifact-bound review receipts with content identity and stale detection.
2. Define a replay-safe event envelope with causation, subject, source mode, evidence references, and redaction class.
3. Define context capsules and lineage independently of model transcripts.
4. Add idempotent pause/resume receipts for human interruption and failure recovery.
5. Add truth-source labels and evidence-independence metadata to artifacts, findings, and judgments.
6. Treat capability validators and authority policy versions as evidence addressable from review surfaces.
7. Preserve branches not taken and counter-evidence in plan/execution records.

## Top five actions

1. **Specify the Review Subject and Approval Receipt contracts before adding approval UI.** Include subject hash, artifact/evidence IDs, policy/version, intended effects, reviewer authority, decision, timestamp, expiry, and stale rules.
2. **Specify the Execution Replay projection, then build `execution_replay()` in the lab.** Reuse monitor events and Relationship Graph navigation, but add temporal state, evidence-at-the-time, before/after inspection, and failure-window focus.
3. **Add Context Capsule and Resume Receipt contracts to Workstation architecture.** Store curated state and lineage; do not make raw conversation history the recovery contract.
4. **Build an Artifact-Bound Review Workbench after the contracts exist.** It should emit bounded intents only and prove stale-review behavior in QA.
5. **Add source-mode and evidence-independence fields to the artifact/judgment architecture.** This prevents fixtures from masquerading as live evidence and correlated agent opinions from masquerading as corroboration.

## Research boundary

This report is architecture and interaction research. It does not endorse exposing chain-of-thought, creating a second execution system, or moving permissions, scheduling, provenance, review authority, or analytical semantics into `shinycapabilities`. Components remain projections over host-owned governed state and emit bounded user intents only.
