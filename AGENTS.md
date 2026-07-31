# Agent instructions

## Purpose and map

This repository contains the generic `shinycapabilities` R package. Read
`ARCHITECTURE.md` before changing contracts or runtime behavior. Primary areas
are `R/`, `tools/javascript/src/`, generated `inst/htmlwidgets/lib/`, generated
`man/` and `NAMESPACE`, tests, examples, and governance files.

## Invariants

React Flow owns browser graph interaction. R owns registration, validation,
planning, scheduling, execution, caching, staleness, cancellation, and artifact
registration. JavaScript receives bounded presentation metadata, never full
datasets, fitted models, credentials, arbitrary R objects, or executable
payloads. Proposed nodes require host acceptance. Serialized workflows exclude
process handles and transient runtime state. Background output becomes an
artifact only after success. Host applications own domain-specific analytics.

Do not introduce host-application-specific capabilities, domain-specific
models or reports, arbitrary JavaScript or R execution from node payloads, full
dataset/model transfer into JavaScript, secrets in workflow state, generic
opaque payload passthrough, breaking serialization without migration, or large
architectural rewrites without prior approval.

## Authored and generated files

Authored browser sources live in `tools/javascript/src/`; do not hand-edit
`inst/htmlwidgets/lib/shinycapabilities.js` or `.css`. Rebuild them:

```powershell
Set-Location tools/javascript
npm ci
npm run build
```

R documentation sources are roxygen comments. Do not hand-edit `NAMESPACE` or
`man/*.Rd`; regenerate them:

```powershell
Rscript -e "roxygen2::roxygenise('.', roclets = c('rd', 'namespace'))"
```

## Validation

Before reporting completion, run:

```powershell
Rscript -e "devtools::test()"
npm --prefix tools/javascript ci
npm --prefix tools/javascript run build
R CMD build .
R CMD check shinycapabilities_<version>.tar.gz
```

Also verify bundle drift, formatting, `git diff --check`, dependency attribution,
and that forbidden generated output is excluded.

Preserve dirty worktrees and unrelated changes. Report unrelated changes rather
than overwriting them. Do not stage, commit, push, tag, release, change public
APIs, or change serialized contracts unless the user explicitly authorizes it.

## Dependencies and compatibility

Use locked dependencies. New dependencies require need, maintenance, security,
and license review. Bundled dependencies require attribution. Public R APIs,
typed ports, operations, runtime semantics, and serialized documents are
backward-compatible by default; breaking changes require prior design approval,
versioning, migration, and tests.

Host integrations use the contracts in `COMPATIBILITY.md`. Prefer supported
`data-shinycap-*` hooks, `--shinycap-*` variables, and returned module controls
over private selectors, internal input IDs, or React Flow implementation
classes.
