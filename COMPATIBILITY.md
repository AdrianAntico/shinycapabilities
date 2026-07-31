# Host Integration Compatibility Layer 1.0

`shinycapabilities` is a host-neutral workflow engine and Shiny presentation
layer. Hosts own every domain catalog, label, icon, group, summary, port label,
and product-specific style. The package owns graph contracts, execution,
persistence, browser transport, and stable integration hooks.

## Versioned contracts

Call `shinycapabilities_compatibility_manifest()` to inspect supported contract
versions.

- Package API: `1.0.0`
- Browser bridge: `1.0.0`
- Workflow document read/write: `1.0.0`
- Presentation hooks: `1.0.0`
- Runtime controls: `1.0.0`

Workflow documents are validated by `validate_workflow_document()` before
restoration. Schema `1.0.0` remains readable and writable.

## Host-supplied presentation

`register_capability()` accepts an additive `presentation` list with these
closed fields: `group_id`, `group_label`, `group_order`, `display_order`,
`icon_id`, `short_summary`, `compact_summary`, `input_port_labels`,
`output_port_labels`, `emphasis`, and `accessibility_label`.

Unknown fields fail closed. Presentation metadata changes appearance only; it
does not change capability identity, ports, execution, caching, serialization,
or graph semantics.

The package performs no semantic inference from capability IDs, labels,
categories, ports, or descriptions. Hosts must supply presentation metadata
explicitly whenever the neutral fallback is insufficient.

`icon_id` is resolved only through `shinycapabilities_icon_allowlist()`. The
generic package renders the locally available Bootstrap 3 Glyphicon font,
licensed under the MIT license as distributed with Shiny's Bootstrap assets.
Unknown identifiers and markup-like input resolve to the neutral `asterisk`
fallback; arbitrary SVG, HTML, URLs, and user-provided classes are never
rendered. Domain-specific icon assignments remain host-owned.

## Stable browser hooks

Hosts should prefer `data-shinycap-*` attributes and documented
`--shinycap-*` CSS custom properties. Existing `.sc-*` classes and legacy
Shiny message/input names remain compatibility aliases. React Flow
implementation classes are not a supported host API.

Supported layout variables are `--shinycap-palette-width`,
`--shinycap-inspector-width`, `--shinycap-panel-padding`,
`--shinycap-item-gap`, `--shinycap-node-radius`,
`--shinycap-density-compact-min`, and `--shinycap-density-icon-min`.
Supported colors use the `--shinycap-color-*` variables declared by the
widget stylesheet.

## Runtime controls

The module server return value retains all existing fields and adds
`contract_version` and `controls`. The control object provides supported
functions for execution, cancellation, cache maintenance, graph replacement,
plan inspection, Fit View, selection, and runtime state. Set
`bind_internal_controls = FALSE` when a host binds its own UI.

Runtime snapshots are process-local inspection values. They can contain
arbitrary R objects and are not necessarily persistable or process-portable;
only workflow documents use the portable serialization contract.

## Browser bridge

Versioned messages and events use `shinycapabilities:v1:*` names and include
`bridgeVersion = "1.0.0"`. Legacy names remain accepted and emitted during the
compatibility period.

## Examples

`example_document_catalog()` is the neutral package example.
`default_capability_catalog()` returns that same neutral example.

Built-in configuration primitives are domain-neutral: `resource` selects a
host-provided resource identity, `property` selects a host-provided property,
and `expression` edits an opaque host-validated expression. The package does
not interpret their values. Hosts needing richer controls may use `custom`
configuration hooks.

## Installed-package support

Hosts must load `shinycapabilities` as an installed package. Source-directory
discovery is a host-owned development convenience and is not required at
runtime.
