import React, { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { createRoot } from "react-dom/client";
import {
  Background, Controls, MarkerType, MiniMap, ReactFlow, ReactFlowProvider,
  useReactFlow
} from "@xyflow/react";
import "@xyflow/react/dist/style.css";
import dagre from "@dagrejs/dagre";
import "./relationship-graph.css";

const instances = new Map();
const forbidden = /thinking|scratchpad|hidden_reasoning|chain_of_thought|tool_trace|raw_prompt|raw_response|credential|secret/i;
const array = value => Array.isArray(value) ? value : [];
const classToken = value => String(value || "none").toLowerCase().replace(/[^a-z0-9_-]/g, "-");

function publish(element, suffix, payload) {
  if (!window.Shiny?.setInputValue || !element.id) return;
  window.Shiny.setInputValue(`${element.id}_${suffix}`,
    { ...payload, timestamp: new Date().toISOString() }, { priority: "event" });
}

function safeEntries(value) {
  return Object.entries(value || {}).filter(([key]) => !forbidden.test(key)).slice(0, 20);
}

function neighborhood(nodeId, edges, mode = "both", depth = 1) {
  if (!nodeId) return new Set();
  const visited = new Set([nodeId]);
  let frontier = new Set([nodeId]);
  for (let level = 0; level < depth; level += 1) {
    const next = new Set();
    edges.forEach(edge => {
      if ((mode === "both" || mode === "downstream") && frontier.has(edge.source)) next.add(edge.target);
      if ((mode === "both" || mode === "upstream") && frontier.has(edge.target)) next.add(edge.source);
    });
    next.forEach(id => visited.add(id));
    frontier = next;
  }
  return visited;
}

function progressiveGraph(nodes, edges, focusId, maxNodes, mode, depth) {
  if (focusId) {
    const ids = neighborhood(focusId, edges, mode, depth);
    const focusedNodes = nodes.filter(node => ids.has(node.id)).slice(0, maxNodes);
    const retained = new Set(focusedNodes.map(node => node.id));
    return { nodes: focusedNodes, edges: edges.filter(edge => retained.has(edge.source) && retained.has(edge.target)), limited: focusedNodes.length < ids.size };
  }
  if (nodes.length <= maxNodes) return { nodes, edges, limited: false };
  const selected = nodes.slice(0, maxNodes);
  const retained = new Set(selected.map(node => node.id));
  return { nodes: selected, edges: edges.filter(edge => retained.has(edge.source) && retained.has(edge.target)), limited: true };
}

function layoutGraph(nodes, edges, direction) {
  const graph = new dagre.graphlib.Graph({ multigraph: true });
  graph.setGraph({ rankdir: direction || "LR", ranksep: 82, nodesep: 42, marginx: 24, marginy: 24 });
  graph.setDefaultEdgeLabel(() => ({}));
  nodes.forEach(node => graph.setNode(node.id, { width: 190, height: 66 }));
  edges.forEach(edge => graph.setEdge(edge.source, edge.target, {}, edge.id));
  dagre.layout(graph);
  return {
    nodes: nodes.map(node => {
      const point = graph.node(node.id) || { x: 0, y: 0 };
      return { id: node.id, position: { x: point.x - 95, y: point.y - 33 },
        data: node, type: "relationshipNode", draggable: false, selectable: true };
    }),
    edges: edges.map(edge => ({ id: edge.id, source: edge.source, target: edge.target,
      label: edge.label || edge.type, data: edge, type: "smoothstep", selectable: true,
      markerEnd: { type: MarkerType.ArrowClosed }, className: `sc-rg-edge type-${classToken(edge.type)} status-${classToken(edge.status)}` }))
  };
}

function RelationshipNode({ data, selected }) {
  return <div className={`sc-rg-node type-${classToken(data.type)} status-${classToken(data.status)}${selected ? " is-selected" : ""}`}
    aria-label={`${data.label}, ${data.type}${data.status ? `, ${data.status}` : ""}`}>
    <span className="sc-rg-node-type">{data.type}</span><strong>{data.label}</strong>
    {data.status && <span className="sc-rg-node-status">Status: {data.status}</span>}
  </div>;
}

const nodeTypes = { relationshipNode: RelationshipNode };

function Inspector({ selected }) {
  if (!selected) return <aside className="sc-rg-inspector" aria-label="Relationship inspector"><div className="sc-rg-empty">Select a node or relationship.</div></aside>;
  const isEdge = Boolean(selected.source);
  return <aside className="sc-rg-inspector" aria-label="Relationship inspector" aria-live="polite">
    <span className="sc-rg-eyebrow">{isEdge ? "Relationship" : "Node"}</span>
    <h3>{selected.label || selected.id}</h3>
    <dl>
      <dt>ID</dt><dd>{selected.id}</dd><dt>Type</dt><dd>{selected.type}</dd>
      {selected.status && <><dt>Status</dt><dd>{selected.status}</dd></>}
      {selected.group && <><dt>Group</dt><dd>{selected.group}</dd></>}
      {isEdge && <><dt>Source</dt><dd>{selected.source}</dd><dt>Target</dt><dd>{selected.target}</dd></>}
      {safeEntries(selected.metadata).map(([key, value]) => <React.Fragment key={key}>
        <dt>{key.replaceAll("_", " ")}</dt><dd>{typeof value === "object" ? JSON.stringify(value) : String(value)}</dd>
      </React.Fragment>)}
    </dl>
  </aside>;
}

function AccessibleRelationships({ nodes, edges, selectedId, selectNode, selectEdge }) {
  const outgoing = useMemo(() => Object.fromEntries(nodes.map(node => [node.id,
    edges.filter(edge => edge.source === node.id)])), [nodes, edges]);
  return <section className="sc-rg-accessible" aria-label="Structured relationship navigation">
    {!nodes.length && <div className="sc-rg-empty">No matching relationships.</div>}
    {nodes.map(node => <article key={node.id}>
      <button type="button" aria-pressed={selectedId === node.id} onClick={() => selectNode(node)}>
        <strong>{node.label}</strong><span>{node.type}{node.status ? `; status ${node.status}` : ""}</span>
      </button>
      <ul>{outgoing[node.id].map(edge => {
        const target = nodes.find(item => item.id === edge.target);
        return <li key={edge.id}><button type="button" aria-pressed={selectedId === edge.id}
          onClick={() => selectEdge(edge)}>{edge.type}: {node.label} to {target?.label || edge.target}</button></li>;
      })}</ul>
    </article>)}
  </section>;
}

function GraphCanvas({ model, element, selectedId, setSelectedId, focusId, setFocusId,
    mode, depth, filters, search, direction, fitRequest }) {
  const reactFlow = useReactFlow();
  const filtered = useMemo(() => {
    const term = search.trim().toLowerCase();
    const nodes = array(model.nodes).filter(node => (!term || `${node.label} ${node.id} ${node.type}`.toLowerCase().includes(term)) &&
      (!filters.nodeType || node.type === filters.nodeType) && (!filters.status || node.status === filters.status));
    const ids = new Set(nodes.map(node => node.id));
    const edges = array(model.edges).filter(edge => ids.has(edge.source) && ids.has(edge.target) &&
      (!filters.edgeType || edge.type === filters.edgeType));
    return { nodes, edges };
  }, [model.nodes, model.edges, filters, search]);
  const projection = useMemo(() => progressiveGraph(filtered.nodes, filtered.edges, focusId,
    model.options?.maxRenderNodes || 500, mode, depth), [filtered, focusId, model.options?.maxRenderNodes, mode, depth]);
  const laidOut = useMemo(() => layoutGraph(projection.nodes, projection.edges, direction),
    [projection.nodes, projection.edges, direction]);
  useEffect(() => { if (fitRequest) requestAnimationFrame(() => reactFlow.fitView({ padding: 0.18, duration: 250 })); }, [fitRequest, reactFlow]);
  useEffect(() => { requestAnimationFrame(() => reactFlow.fitView({ padding: 0.18 })); }, [direction, focusId]);
  const chooseNode = useCallback((node) => {
    setSelectedId(node.id); publish(element, "node_selection", { id: node.id, type: node.data.type });
  }, [element, setSelectedId]);
  const chooseEdge = useCallback((edge) => {
    setSelectedId(edge.id); publish(element, "edge_selection", { id: edge.id, type: edge.data.type,
      source: edge.source, target: edge.target });
  }, [element, setSelectedId]);
  return <>
    {projection.limited && <div className="sc-rg-scale-note" role="status">Showing a bounded graph projection. Focus a node to inspect its neighborhood.</div>}
    <ReactFlow nodes={laidOut.nodes.map(node => ({ ...node, selected: node.id === selectedId }))}
      edges={laidOut.edges.map(edge => ({ ...edge, selected: edge.id === selectedId }))}
      nodeTypes={nodeTypes} onNodeClick={(_, node) => chooseNode(node)} onEdgeClick={(_, edge) => chooseEdge(edge)}
      onNodeDoubleClick={(_, node) => publish(element, "navigation", { id: node.id, kind: "node" })}
      onEdgeDoubleClick={(_, edge) => publish(element, "navigation", { id: edge.id, kind: "edge", source: edge.source, target: edge.target })}
      nodesDraggable={false} nodesConnectable={false} edgesReconnectable={false} elementsSelectable
      onlyRenderVisibleElements fitView minZoom={0.05} maxZoom={2.5} aria-label="Relationship graph visualization">
      <Background gap={22}/><Controls showInteractive={false}/>
      {model.options?.showMinimap && laidOut.nodes.length > 25 && <MiniMap pannable zoomable ariaLabel="Relationship graph overview"/>}
    </ReactFlow>
    {focusId && <button className="sc-rg-clear-focus" type="button" onClick={() => setFocusId(null)}>Show full graph</button>}
  </>;
}

function RelationshipGraph({ element, initial }) {
  const [model, setModel] = useState(initial);
  const [selectedId, setSelectedId] = useState(initial.selectedId || null);
  const [focusId, setFocusId] = useState(initial.focusId || null);
  const [filters, setFilters] = useState(initial.filters || {});
  const [search, setSearch] = useState(""); const [mode, setMode] = useState("both");
  const [depth, setDepth] = useState(1); const [view, setView] = useState("graph");
  const [direction, setDirection] = useState(initial.options?.direction || "LR");
  const [fitRequest, setFitRequest] = useState(null);
  const pending = useRef(null); const frame = useRef(null);
  useEffect(() => {
    setModel(initial);
    if (initial.selectedId !== undefined) setSelectedId(initial.selectedId);
    if (initial.focusId !== undefined) setFocusId(initial.focusId);
    setFilters(initial.filters || {});
    setDirection(initial.options?.direction || "LR");
  }, [initial]);
  useEffect(() => {
    element._relationshipGraphUpdate = patch => {
      pending.current = { ...(pending.current || {}), ...patch };
      if (frame.current) return;
      frame.current = requestAnimationFrame(() => {
        const next = pending.current || {}; pending.current = null; frame.current = null;
        setModel(current => ({ ...current, ...next, options: { ...current.options,
          maxRenderNodes: next.maxRenderNodes || current.options?.maxRenderNodes,
          state: next.state || current.options?.state,
          message: next.message === undefined ? current.options?.message : next.message } }));
        if (next.selectedId !== undefined) setSelectedId(next.selectedId);
        if (next.focusId !== undefined) setFocusId(next.focusId);
        if (next.filters) setFilters(next.filters);
        if (next.direction) setDirection(next.direction);
        if (next.fitRequest) setFitRequest(next.fitRequest);
      });
    };
    return () => { delete element._relationshipGraphUpdate; if (frame.current) cancelAnimationFrame(frame.current); };
  }, [element]);
  const nodes = array(model.nodes); const edges = array(model.edges);
  const selected = nodes.find(node => node.id === selectedId) || edges.find(edge => edge.id === selectedId);
  const nodeTypesAvailable = [...new Set(nodes.map(node => node.type))].sort();
  const edgeTypesAvailable = [...new Set(edges.map(edge => edge.type))].sort();
  const statuses = [...new Set(nodes.map(node => node.status).filter(Boolean))].sort();
  const accessibleProjection = useMemo(() => {
    const term = search.trim().toLowerCase();
    const visibleNodes = nodes.filter(node => (!term || `${node.label} ${node.id} ${node.type}`.toLowerCase().includes(term)) &&
      (!filters.nodeType || node.type === filters.nodeType) && (!filters.status || node.status === filters.status));
    const ids = new Set(visibleNodes.map(node => node.id));
    return { nodes: visibleNodes, edges: edges.filter(edge => ids.has(edge.source) && ids.has(edge.target) &&
      (!filters.edgeType || edge.type === filters.edgeType)) };
  }, [nodes, edges, filters, search]);
  const selectNode = node => { setSelectedId(node.id); publish(element, "node_selection", { id: node.id, type: node.type }); };
  const selectEdge = edge => { setSelectedId(edge.id); publish(element, "edge_selection", { id: edge.id, type: edge.type, source: edge.source, target: edge.target }); };
  const updateFilter = (key, value) => { const next = { ...filters, [key]: value || null }; setFilters(next);
    publish(element, "filter_state", next); };
  const requestFocus = (nextMode) => {
    if (!selected || selected.source) return;
    setMode(nextMode); setFocusId(selected.id);
    publish(element, "neighborhood_request", { id: selected.id, direction: nextMode, depth });
  };
  if (model.options?.state && model.options.state !== "ready") return <div className="sc-rg" data-shinycap-component="relationship-graph">
    <div className="sc-rg-projection-state" role={model.options.state === "error" ? "alert" : "status"}>
      <strong>{model.options.state === "error" ? "Relationship graph unavailable" : "Loading relationship graph"}</strong>
      <span>{model.options.message || (model.options.state === "error" ? "The host supplied an error state." : "Waiting for host-supplied relationships.")}</span>
    </div>
  </div>;
  return <div className="sc-rg" data-shinycap-component="relationship-graph">
    <header className="sc-rg-toolbar">
      <label className="sc-rg-search"><span className="sc-rg-visually-hidden">Search graph</span>
        <input type="search" value={search} placeholder="Search nodes" onChange={event => setSearch(event.target.value)}/></label>
      <label><span>Node type</span><select value={filters.nodeType || ""} onChange={event => updateFilter("nodeType", event.target.value)}><option value="">All</option>{nodeTypesAvailable.map(value => <option key={value}>{value}</option>)}</select></label>
      <label><span>Edge type</span><select value={filters.edgeType || ""} onChange={event => updateFilter("edgeType", event.target.value)}><option value="">All</option>{edgeTypesAvailable.map(value => <option key={value}>{value}</option>)}</select></label>
      <label><span>Status</span><select value={filters.status || ""} onChange={event => updateFilter("status", event.target.value)}><option value="">All</option>{statuses.map(value => <option key={value}>{value}</option>)}</select></label>
      <button type="button" onClick={() => setFitRequest(String(Date.now()))}>Fit view</button>
    </header>
    <div className="sc-rg-summary" role="status"><strong>{nodes.length} nodes</strong><span>{edges.length} relationships</span>
      {model.diagnostics?.hasCycle && <span>Cycles present</span>}{model.diagnostics?.disconnected && <span>{model.diagnostics.componentCount} components</span>}</div>
    <nav className="sc-rg-tabs" role="tablist" aria-label="Relationship views">
      <button type="button" role="tab" aria-selected={view === "graph"} onClick={() => setView("graph")}>Graph</button>
      <button type="button" role="tab" aria-selected={view === "structured"} onClick={() => setView("structured")}>Accessible relationships</button>
      <span className="sc-rg-focus-actions"><button type="button" disabled={!selected || Boolean(selected.source)} onClick={() => requestFocus("upstream")}>Upstream</button>
        <button type="button" disabled={!selected || Boolean(selected.source)} onClick={() => requestFocus("downstream")}>Downstream</button>
        <button type="button" disabled={!selected || Boolean(selected.source)} onClick={() => requestFocus("both")}>Neighborhood</button>
        <label><span>Depth</span><input type="number" min="1" max="5" value={depth} onChange={event => setDepth(Math.max(1, Math.min(5, Number(event.target.value))))}/></label></span>
    </nav>
    <div className="sc-rg-body">
      <main className="sc-rg-main" role="tabpanel">
        {view === "graph" ? <GraphCanvas model={model} element={element} selectedId={selectedId} setSelectedId={setSelectedId}
          focusId={focusId} setFocusId={setFocusId} mode={mode} depth={depth} filters={filters} search={search}
          direction={direction} fitRequest={fitRequest}/> :
          <AccessibleRelationships
            nodes={accessibleProjection.nodes}
            edges={accessibleProjection.edges}
            selectedId={selectedId}
            selectNode={selectNode}
            selectEdge={selectEdge}
          />}
      </main><Inspector selected={selected}/>
    </div>
  </div>;
}

window.ShinyCapabilitiesDirectTransport.register("relationship_graph", {
  mount(element, model) {
    const root = createRoot(element);
    root.render(<ReactFlowProvider><RelationshipGraph element={element} initial={model}/></ReactFlowProvider>);
    instances.set(element.id, element);
    return { root, model };
  },
  update(handle, patch, context) {
    handle.model = { ...handle.model, ...patch };
    context.element._relationshipGraphUpdate?.(patch);
    return handle;
  },
  resize() {},
  destroy(handle, element) { handle.root.unmount(); instances.delete(element.id); }
});

if (window.Shiny) window.Shiny.addCustomMessageHandler("shinycapabilities:relationship-graph:update", message => {
  const element = instances.get(message.id) || document.getElementById(message.id);
  element?._relationshipGraphUpdate?.(message);
});
