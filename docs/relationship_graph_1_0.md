# Relationship Graph 1.0

## Boundary

`relationship_graph()` is a read-only visualization and navigation primitive. It owns validation, bounded metadata projection, layout, pan/zoom, filtering, selection, neighborhood focus, and bounded interaction events. The host owns every node and edge meaning and remains the only authority that may mutate graph truth.

## Contract

Nodes require `id`, `label`, and `type`, with optional `status`, `group`, and bounded metadata. Edges require `id`, `source`, `target`, and `type`, with optional `label`, `status`, and bounded metadata. Duplicate identities and missing endpoints fail deterministically. Cycles and disconnected components are valid and reported as diagnostics.

The widget emits only `<id>_node_selection`, `<id>_edge_selection`, `<id>_filter_state`, `<id>_neighborhood_request`, and `<id>_navigation`. Navigation intents identify the selected node or edge but remain host-handled. It never executes, edits, retries, approves, or schedules work.

The host may project `ready`, `loading`, or `error` state with an optional bounded message. These states describe supplied graph data only; the component does not infer operational state or fabricate progress.

## Layout and scale

Dagre 3.1.1 (MIT) provides deterministic directed layout for branching, multiple-root, disconnected, and cyclic projections. React Flow 12.11.2 provides pan, zoom, fit-to-view, viewport culling, and selection. Above `max_render_nodes`, the widget shows a deterministic bounded projection and asks the user to focus a node neighborhood. This is progressive disclosure, not a claim of unlimited visual scalability.

Qualification on the development workstation measured R validation and diagnostics at approximately 0.06 seconds for 100 nodes, 0.70 seconds for 1,000 nodes, and 2.56 seconds for 3,000 nodes. Isolated Dagre layout measured approximately 47 ms for 100 nodes, 104 ms for the default 350-node browser projection, 340 ms for 1,000 nodes, and 1.14 seconds for 3,000 nodes. Browser QA loaded a 1,000-node/999-edge host graph without console errors, rendered the bounded 350-node projection with viewport culling, and reduced it interactively to a focused neighborhood. These observations are not universal performance guarantees.

## Accessibility

The visual canvas supports focusable React Flow nodes and controls. A coordinated structured relationship view is the semantic equivalent for keyboard and assistive-technology navigation. Edge types are written as text, selection has a visible outline, and status/type are not encoded by color alone. Complex spatial layout itself is not claimed to be fully screen-reader accessible.

## Promotion readiness

Candidate Workstation seams include dataset lineage, artifact provenance, evidence support/challenge relationships, model-to-scoring lineage, and governed execution dependencies. The host must supply stable identities, typed relationships, bounded safe metadata, and any authorization-aware navigation handling.

Before promotion, Grok integration must qualify source-record authorization, metadata redaction, event routing, maximum graph size, expected update rate, identity stability, and whether neighborhood requests are local projections or host-side queries. Agent Activity Monitor work/dependency records can map into the same node/edge contract without coupling either component.

Unsupported concerns include graph editing, host mutations, workflow execution, semantic inference, unbounded metadata, server-side graph querying, and guaranteed all-node rendering above the configured projection limit.
