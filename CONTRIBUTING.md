# Contributing

Thank you for improving `shinycapabilities`.

## Setup and validation

Install R package dependencies, then install JavaScript dependencies from the
lockfile:

```powershell
npm --prefix tools/javascript ci
npm --prefix tools/javascript run build
Rscript -e "roxygen2::roxygenise('.', roclets = c('rd', 'namespace'))"
Rscript -e "devtools::test()"
R CMD build .
R CMD check shinycapabilities_<version>.tar.gz
```

Production browser assets are generated from `tools/javascript/src/` into
`inst/htmlwidgets/lib/`. Include both authored changes and rebuilt assets.
Installed users must not need Node.js.

## Pull requests

Keep changes focused and explain motivation, architecture impact, public API or
serialization impact, dependency/license impact, tests, archive check result,
and documentation. Add screenshots only for visible UI changes. Preserve
backward compatibility or provide an approved migration.

Bug fixes, accessibility, documentation, examples, tests, performance
improvements, backward-compatible generic workflow features, safe presentation
refinements, and Shiny integration hooks are generally welcome.

Discuss public APIs, serialization, typed ports, execution/cache/cancellation
semantics, dependencies, JavaScript frameworks, security boundaries, and major
UI architecture before implementation.

Host-specific analytics, arbitrary executable payloads, full browser data
transfer, embedded secrets, breaking formats without migration, unattributed
bundles, generated bundles without source changes, and broad unjustified
rewrites are generally rejected.
