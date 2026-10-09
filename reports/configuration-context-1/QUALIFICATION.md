# Checkpoint-scoped configuration inputs

Base: `af685bc9894bba3e3bedf2118472a7e1fb779585` (0.2.1).
Candidate: 0.2.1.1, isolated `codex/workflow-configuration-context-1` branch.

The previous node-only input namespace allowed a host switching between two
workflow graphs with the same node ID to consume retained field/change values
from the previous graph. A host can now explicitly activate a configuration
context. Every activation (including the same context restored from History)
and selected-node transition rotates a session-local inspector generation.
Field values, change envelopes, ownership handshake and Apply/Discard actions
must belong to that generation. Old events cannot update the new graph.

The setter clears only transient selection/drafts. It does not change graph,
configuration, cache signatures, native results or scientific identities. Hosts
restore their intended checkpoint drafts after activating the context. Existing
hosts that never activate the context retain their previous input contract.

Source qualification: **227 passed assertions, 0 failures, 0 errors, 0 skips**.
One environment warning: installed `shiny` was built under R 4.5.3; tests ran on
R 4.5.2. Tests covered context isolation, late change envelopes with nonce,
stale Apply/Discard, matching-generation ownership, same-context History,
node reselection, two independent sessions, draft restoration, legacy callers,
host compatibility, graph publication, canvas ownership, and unchanged canonical
workflow identity/migration. No analytical owners were called. The neutral
test capability fails immediately if execution is attempted.

The host must install this exact dependency before claiming installed browser
qualification. A host whose capability fingerprint includes the dependency SHA
must retain old cache authority as historical; this UI patch grants no cache
equivalence or identity migration.
