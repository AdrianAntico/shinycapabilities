import React, { memo, useCallback, useEffect, useMemo, useRef, useState } from "react";
import { createRoot } from "react-dom/client";
import {
  Background,
  Controls,
  Handle,
  MiniMap,
  NodeResizer,
  Position,
  ReactFlow,
  ReactFlowProvider,
  addEdge,
  applyEdgeChanges,
  applyNodeChanges,
  useReactFlow
} from "@xyflow/react";
import "@xyflow/react/dist/style.css";
import "./widget.css";

const clone = (value) => JSON.parse(JSON.stringify(value));
const byId = (values) => new Map(values.map((value) => [value.id, value]));
const friendlyPort = (name) => ({
  bundle: "Data",
  dataset: "Data",
  analysis: "Analysis",
  evidence: "Evidence",
  research: "Research",
  synthesis: "Evidence synthesis",
  report: "Report",
  model: "Model"
}[name] || String(name).replaceAll("_", " "));

function emit(element, type, payload, graph) {
  if (!window.Shiny?.setInputValue) return;
  window.Shiny.setInputValue(
    `${element.id}_event`,
    { type, ...payload, graph, nonce: `${Date.now()}-${Math.random()}` },
    { priority: "event" }
  );
}

const CapabilityNode = memo(({ id, data, selected }) => (
  <article
      className={`sc-node sc-state-${String(data.state || "unconfigured").replace(/[^\w-]/g, "-")}${data.metadata?.proposal_status === "proposed" ? " sc-node-proposed" : ""}${data.metadata?.composite ? " sc-node-composite" : ""}`}
    aria-label={`${data.displayName}, ${data.state || "unconfigured"}`}
  >
    {!data.readOnly && <NodeResizer minWidth={220} minHeight={110} isVisible={selected} />}
    <header>
      <span className="sc-node-icon" aria-hidden="true">{data.icon || "◇"}</span>
      <div>
        <strong>{data.displayName}</strong>
        <small>{data.category}</small>
      </div>
      <span className="sc-node-state">{data.state || "unconfigured"}</span>
    </header>
    <p className="sc-node-summary">{data.summary || data.description?.split(/[.!?]/)[0]}</p>
    <div className="sc-node-ports sc-node-inputs">
      {Object.entries(data.inputs || {}).map(([name, port], index) => (
        <div className="sc-port-row" key={`in-${name}`}>
          <Handle
            type="target"
            position={Position.Left}
            id={name}
            style={{ top: 82 + index * 22 }}
            aria-label={`Input ${name}, ${port.type}`}
          />
          <span>{friendlyPort(name)}</span><code>{port.type}</code>
        </div>
      ))}
    </div>
    <div className="sc-node-ports sc-node-outputs">
      {Object.entries(data.outputs || {}).map(([name, port], index) => (
        <div className="sc-port-row" key={`out-${name}`}>
          <span>{friendlyPort(name)}</span><code>{port.type}</code>
          <Handle
            type="source"
            position={Position.Right}
            id={name}
            style={{ top: 82 + index * 22 }}
            aria-label={`Output ${name}, ${port.type}`}
          />
        </div>
      ))}
    </div>
    <footer aria-label={`Status ${data.state || "unconfigured"}`}>
      {data.metadata?.cache_status ? `Cache: ${data.metadata.cache_status}` : "Ready for inspection"}
    </footer>
  </article>
));

const nodeTypes = { capability: CapabilityNode };

function serialize(nodes, edges) {
  return {
    schema_version: "1.0.0",
    nodes: [...nodes]
      .sort((a, b) => a.id.localeCompare(b.id))
      .map((node) => ({
        id: node.id,
        capability_id: node.data.capabilityId,
        position: node.position,
        size: {
          width: node.measured?.width || node.width || 260,
          height: node.measured?.height || node.height || 138
        },
        config: node.data.config || {},
        state: node.data.state || "unconfigured",
        parent_id: node.parentId || null,
        metadata: node.data.metadata || {}
      })),
    edges: [...edges]
      .sort((a, b) => a.id.localeCompare(b.id))
      .map((edge) => ({
        id: edge.id,
        source: edge.source,
        source_port: edge.sourceHandle,
        target: edge.target,
        target_port: edge.targetHandle
      })),
    groups: []
  };
}

function hydrate(graph, capabilities, readOnly) {
  const catalog = byId(capabilities);
  return {
    nodes: (graph?.nodes || []).map((node) => {
    const capability = catalog.get(node.capability_id) || {};
    const metadata = node.metadata || {};
    const configSummary = Object.entries(node.config || {})
      .filter(([, value]) => value !== null && value !== "" && value !== false)
      .slice(0, 2)
      .map(([name, value]) => `${name.replaceAll("_", " ")}: ${Array.isArray(value) ? value.join(", ") : value}`)
      .join(" · ");
    const compositeInputs = Object.fromEntries((metadata.input_mappings || []).map((mapping) => [
      mapping.exposed_port,
      { type: "composite_input", required: true }
    ]));
    const compositeOutputs = Object.fromEntries((metadata.output_mappings || []).map((mapping) => [
      mapping.exposed_port,
      { type: "composite_output", required: true }
    ]));
      return {
        id: node.id,
        type: "capability",
        position: node.position || { x: 0, y: 0 },
        width: node.size?.width || 260,
        height: node.size?.height || 138,
        parentId: node.parent_id || undefined,
        data: {
          capabilityId: node.capability_id,
        displayName: metadata.display_name || capability.displayName || node.capability_id,
        description: metadata.composite ? "Collapsed executable workflow" : capability.description || "",
        category: metadata.composite ? "Composite" : capability.category || "Unknown",
        inputs: metadata.composite ? compositeInputs : capability.inputs || {},
        outputs: metadata.composite ? compositeOutputs : capability.outputs || {},
          icon: capability.icon,
          summary: metadata.summary || configSummary || "Ready for configuration",
          config: node.config || {},
          state: node.state || "unconfigured",
        metadata,
          readOnly
        }
      };
    }),
    edges: (graph?.edges || []).map((edge) => ({
      id: edge.id,
      source: edge.source,
      sourceHandle: edge.source_port,
      target: edge.target,
      targetHandle: edge.target_port,
      type: "smoothstep"
    }))
  };
}

function Canvas({ element, value }) {
  const readOnly = Boolean(value.options?.readOnly);
  const hydrated = useMemo(
    () => hydrate(value.graph, value.capabilities || [], readOnly),
    [value.graph, value.capabilities, readOnly]
  );
  const [nodes, setNodes] = useState(hydrated.nodes);
  const [edges, setEdges] = useState(hydrated.edges);
  const [pendingConnection, setPendingConnection] = useState(null);
  const wrapper = useRef(null);
  const flow = useReactFlow();
  const catalog = useMemo(() => byId(value.capabilities || []), [value.capabilities]);

  const graph = useCallback(
    (nextNodes = nodes, nextEdges = edges) => serialize(nextNodes, nextEdges),
    [nodes, edges]
  );

  useEffect(() => {
    const onSetGraph = (message) => {
      if (message.id !== element.id) return;
      const next = hydrate(message.graph, value.capabilities || [], readOnly);
      setNodes(next.nodes);
      setEdges(next.edges);
    };
    window.Shiny?.addCustomMessageHandler?.("shinycapabilities:set-graph", onSetGraph);
  }, [element.id, readOnly, value.capabilities]);

  useEffect(() => {
    const handler = (event) => {
      const button = event.target.closest(".sc-widget-command");
      if (!button || button.dataset.target !== element.id) return;
      if (button.dataset.command === "fitView") flow.fitView({ padding: 0.18, duration: 250 });
    };
    document.addEventListener("click", handler);
    return () => document.removeEventListener("click", handler);
  }, [element.id, flow]);

  useEffect(() => {
    const insert = (event) => {
      const capabilityId = event.detail?.capabilityId;
      const capability = catalog.get(capabilityId);
      if (!capability || readOnly) return;
      const bounds = wrapper.current?.getBoundingClientRect();
      const position = flow.screenToFlowPosition({
        x: (bounds?.left || 0) + (event.detail?.x || 200),
        y: (bounds?.top || 0) + (event.detail?.y || 160)
      });
      const id = `${capabilityId.replace(/[^\w-]/g, "-")}-${Date.now()}`;
      const nextNode = hydrate({ nodes: [{
        id, capability_id: capabilityId, position, config: {}, state: "unconfigured"
      }], edges: [] }, value.capabilities || [], readOnly).nodes[0];
      setNodes((current) => {
        const next = [...current, nextNode];
        emit(element, "capability_dropped", { nodeId: id, capabilityId }, serialize(next, edges));
        return next;
      });
    };
    element.addEventListener("shinycapabilities:insert", insert);
    return () => element.removeEventListener("shinycapabilities:insert", insert);
  }, [catalog, edges, element, flow, readOnly, value.capabilities]);

  useEffect(() => {
    if (!window.Shiny?.addCustomMessageHandler) return;
    window.Shiny.addCustomMessageHandler("shinycapabilities:connection-result", (message) => {
      if (message.id !== element.id || !pendingConnection) return;
      if (message.result?.valid) {
        setEdges((current) => {
          const next = addEdge({ ...pendingConnection, type: "smoothstep" }, current);
          emit(element, "connection_accepted", { edge: pendingConnection }, serialize(nodes, next));
          return next;
        });
      } else {
        emit(element, "connection_rejected", {
          edge: pendingConnection,
          finding: message.result
        }, graph());
      }
      setPendingConnection(null);
    });
  }, [element, graph, nodes, pendingConnection]);

  const onNodesChange = useCallback((changes) => {
    if (readOnly) return;
    setNodes((current) => applyNodeChanges(changes, current));
  }, [readOnly]);
  const onEdgesChange = useCallback((changes) => {
    if (readOnly) return;
    const removed = changes.filter((change) => change.type === "remove").map((change) => change.id);
    setEdges((current) => {
      const next = applyEdgeChanges(changes, current);
      if (removed.length) emit(element, "connection_removed", { edgeIds: removed }, serialize(nodes, next));
      return next;
    });
  }, [element, nodes, readOnly]);

  const onConnect = useCallback((connection) => {
    if (readOnly) return;
    const edge = {
      ...connection,
      id: `${connection.source}__${connection.sourceHandle}__${connection.target}__${connection.targetHandle}`
    };
    setPendingConnection(edge);
    emit(element, "connection_proposed", { edge }, graph());
  }, [element, graph, readOnly]);

  const onDrop = useCallback((event) => {
    event.preventDefault();
    if (readOnly) return;
    const capabilityId = event.dataTransfer.getData("application/x-shinycapability");
    const capability = catalog.get(capabilityId);
    if (!capability) return;
    const position = flow.screenToFlowPosition({ x: event.clientX, y: event.clientY });
    const ordinal = nodes.filter((node) => node.data.capabilityId === capabilityId).length + 1;
    const id = `${capabilityId.replace(/[^a-z0-9]+/gi, "_")}_${ordinal}`;
    const node = {
      id,
      type: "capability",
      position,
      width: 260,
      height: 138,
      data: {
        capabilityId,
        displayName: capability.displayName,
        description: capability.description,
        category: capability.category,
        inputs: capability.inputs || {},
        outputs: capability.outputs || {},
        icon: capability.icon,
        config: Object.fromEntries(
          Object.entries(capability.config || {}).map(([key, field]) => [key, field.default ?? null])
        ),
        state: Object.values(capability.inputs || {}).some((port) => port.required)
          ? "unconfigured"
          : "ready",
        readOnly
      }
    };
    setNodes((current) => {
      const next = [...current, node];
      emit(element, "capability_dropped", { nodeId: id, capabilityId }, serialize(next, edges));
      return next;
    });
  }, [catalog, edges, element, flow, nodes, readOnly]);

  const duplicateSelected = useCallback(() => {
    if (readOnly) return;
    const selected = nodes.filter((node) => node.selected);
    if (!selected.length) return;
    const copies = selected.map((node, index) => ({
      ...clone(node),
      id: `${node.id}_copy_${Date.now()}_${index}`,
      selected: false,
      position: { x: node.position.x + 32, y: node.position.y + 32 }
    }));
    setNodes((current) => {
      const next = [...current, ...copies];
      emit(element, "node_duplicated", { nodeIds: copies.map((node) => node.id) }, serialize(next, edges));
      return next;
    });
  }, [edges, element, nodes, readOnly]);

  return (
    <div
      className="sc-flow"
      ref={wrapper}
      onDrop={onDrop}
      onDragOver={(event) => {
        event.preventDefault();
        event.dataTransfer.dropEffect = "copy";
      }}
      onKeyDown={(event) => {
        if ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === "d") {
          event.preventDefault();
          duplicateSelected();
        }
      }}
    >
      <ReactFlow
        nodes={nodes}
        edges={edges}
        nodeTypes={nodeTypes}
        onNodesChange={onNodesChange}
        onEdgesChange={onEdgesChange}
        onConnect={onConnect}
        onNodeClick={(_, node) => emit(element, "node_selected", { nodeId: node.id }, graph())}
        onPaneClick={() => emit(element, "node_selected", { nodeId: null }, graph())}
        onNodeDragStop={(_, node) => emit(element, "move_completed", { nodeId: node.id }, graph())}
        onNodeResizeEnd={(_, node) => emit(element, "resize_completed", { nodeId: node.id }, graph())}
        onNodesDelete={(deleted) => emit(element, "node_removed", {
          nodeIds: deleted.map((node) => node.id)
        }, graph(nodes.filter((node) => !deleted.some((item) => item.id === node.id)), edges))}
        nodesDraggable={!readOnly}
        nodesConnectable={!readOnly}
        elementsSelectable
        deleteKeyCode={readOnly ? null : ["Backspace", "Delete"]}
        multiSelectionKeyCode={["Control", "Meta", "Shift"]}
        selectionOnDrag
        panOnDrag={[1, 2]}
        fitView
        minZoom={0.15}
        maxZoom={2.5}
        proOptions={{ hideAttribution: false }}
      >
        <Background gap={24} size={1} />
        <Controls showInteractive={!readOnly} />
        {value.options?.minimap && <MiniMap pannable zoomable />}
      </ReactFlow>
    </div>
  );
}

function renderWidget(element, value) {
  if (!element.__shinyCapabilitiesRoot) {
    element.__shinyCapabilitiesRoot = createRoot(element);
  }
  element.__shinyCapabilitiesRoot.render(
    <ReactFlowProvider><Canvas element={element} value={value} /></ReactFlowProvider>
  );
}

window.HTMLWidgets.widget({
  name: "capability_canvas",
  type: "output",
  factory(element) {
    return {
      renderValue(value) {
        renderWidget(element, value);
      },
      resize() {}
    };
  }
});
