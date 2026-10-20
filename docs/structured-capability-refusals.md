# Retaining capability refusals

An executor may signal an R condition inheriting from
`shinycap_capability_refusal`, `error`, and `condition`, with a list-valued
`refusal` member. The condition message remains the human-facing failure.
The runtime carries the unmodified refusal list under
`error$details$owner_refusal` in the failed node receipt for both inline and
background execution. It never exposes successful outputs for that execution.

The producing capability owns the refusal ontology, applicability and
provenance. This transport does not validate scientific meaning, turn refusals
into successful results, or authorize retries. Ordinary exceptions retain
their prior message-only behavior. Refusal payloads must be serializable data,
as with other worker results.
