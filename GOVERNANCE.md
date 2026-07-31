# Governance

Adrian Antico is the current maintainer and final design authority for
`shinycapabilities`.

The maintainer reviews releases, public contracts, compatibility, architecture,
security boundaries, dependencies, licensing, and contributor access. Decisions
favor a small generic framework, explicit ownership, deterministic contracts,
and backward compatibility.

Routine bug fixes, accessibility, documentation, tests, performance work,
backward-compatible generic features, safe presentation changes, and Shiny
integration hooks may proceed through normal review.

Public API or serialization changes, port/type contracts, execution and caching
semantics, cancellation, new dependencies, JavaScript framework changes,
security-boundary changes, and major UI architecture require prior design
discussion and maintainer approval.

Host-specific analytics, arbitrary executable payloads, full data/model browser
transfer, secrets, breaking formats without migrations, unattributed
dependencies, unexplained generated bundle changes, and broad rewrites are not
accepted.
