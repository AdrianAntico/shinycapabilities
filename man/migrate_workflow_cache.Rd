\name{migrate_workflow_cache}
\alias{migrate_workflow_cache}
\title{Migrate an authenticated retained workflow cache}
\usage{migrate_workflow_cache(registry, graph, witness, authority, verify = NULL)}
\arguments{
\item{registry}{Current capability registry.}
\item{graph}{Current workflow graph.}
\item{witness}{Authenticated retained graph, cache, execution-time capability definitions, authority and provenance.}
\item{authority}{Exact project_id, workflow_id, input_revision and nonempty owners records (package, version, sha), plus any additional host authority fields.}
\item{verify}{Trusted provenance adapter authenticating the witness against immutable execution history. Must return TRUE. Default refuses migration.}
}
\description{Verifies the legacy signatures and unchanged canonical semantics without calling any execution callback. Returns a typed refusal or migrated cache, audit and original witness.}
\details{Legacy cache fields remain unchanged. Versioned workflow_identity_migration attributes carry canonical successor signatures. Native R serialization preserves them; losing or tampering with migration metadata fails closed. The host must authenticate the witness, not approve it from package availability. Migration does not authorize execution.}
\value{A list with ok, code, and cache; successful migration also retains audit, legacy and analytical_execution_count (zero).}
