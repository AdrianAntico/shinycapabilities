# Workflow identity v2 and retained-cache migration

Base: e28770d37c4ce10ec489def94894cf814486cb22. The previous node signature used insertion-ordered JSON. Only workflow signatures change; browser/document stable_hash contracts do not change.

## Canonical specification

SHA-256 over a typed, recursive canonical R encoding, serialization version 2. Fully named mappings sort UTF-8 keys in radix order recursively. Unnamed lists and atomic vectors preserve sequence order. Duplicate, partial, or missing mapping names fail closed. Named atomic vectors remain distinct from named lists. Null, list, character, logical, numeric, raw and complex types remain distinct. Attributes are canonical mappings: factor class/levels, ordered factors, dimensions and other execution-relevant attributes are retained. Unsupported functions, environments, language objects and S4 values fail closed.

Integer/double storage is intentionally neutral, matching the existing JSON workflow semantics; both encode as doubles, including numeric missing values. Numeric values do not become strings or booleans. Nothing changes finite-number validation at capability admission. This is an identity encoder, not an execution validator.

The envelope includes schema version, node ID, capability ID/version, exact implementation fingerprint, resource hints, execution contract, configuration, and dependencies. Dependency records bind exact edge ID, source node, source port, target port and upstream signature; multiple ports from the same source are not collapsed. Dataset/revision and owner authority present in configuration/resource hints remain exact. Host-owned project/workflow/input/owner authority checks remain mandatory; this domain-neutral library does not invent missing analytical provenance.

## Migration authority

`migrate_workflow_cache()` requires a retained witness containing original graph, complete original succeeded cache, execution-time capability identity records, exact authority, and immutable provenance. A trusted provenance adapter must authenticate that witness against retained history. Missing authentication defaults to `LEGACY_PROVENANCE_UNVERIFIABLE`; a self-created object or available package is not evidence.

Current authority must include project_id, workflow_id, input_revision, and attributable owners (package/version/SHA). Every supplied authority field must match. The complete normalized graphs must be canonically equivalent (a conservative boundary that also refuses unrelated graph changes). Every current capability identity must equal its authenticated execution-time identity. Every original signature is independently recomputed with the unchanged legacy algorithm, including original dependency signatures. An absent, failed, changed or unverifiable node refuses the entire migration atomically.

Every original cache field, output, summary, timestamp and legacy signature remains unchanged. Each cache item receives a native R `workflow_identity_migration` attribute containing the canonical successor signature, original signature, exact original cache fingerprint, witness fingerprint, authority, immutable provenance and zero execution count. The complete witness is returned alongside the audit. The planner validates this metadata and the original cache fingerprint before reuse. Dropped metadata, edited results or an invalid successor fail closed. Persist the returned native record and its witness; no host signature rewriting, cache-current override, or host fingerprint is needed.

This is provenance migration, not authorization. The API never invokes a capability validator or executor. A trusted host adapter remains responsible for session/event authorization and immutable-store authentication; this library cannot authenticate an arbitrary application's storage by itself.

## Qualification

Owner suite: 809 assertions, zero failures/errors, one Shiny R-build-version warning. New tests cover recursive reordering, ordered arrays, numeric storage neutrality and other scalar types, categorical levels, capability/version/implementation/owner/node/input changes, immutable result migration, tampering, missing metadata, foreign authority and unverifiable provenance. Existing planner/runtime, fanout and browser contracts remain covered.

`tools/qualify-retained-workflow-migration.R` authenticates the original Workstation RDS artifacts by exact SHA-256 and checks execution-time native receipts (configuration, upstream inputs, owner, capability, executor and native artifact fingerprints). It migrates all three original/integer/reordered variants and the actual reopened graph. The queue, valuation and risk native outputs remain identical; execution/provider functions are trapped and no calls occur. Existing Workstation evidence identity remains unchanged because no legacy cache fields change. Workstation browser and durable publication acceptance are separate gates, not awarded by these owner tests.
