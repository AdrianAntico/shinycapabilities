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
const BRIDGE_VERSION = "1.0.0";
const INSERT_EVENT = "shinycapabilities:v1:insert";
const LEGACY_INSERT_EVENT = "shinycapabilities:insert";
const CAPABILITY_MIME = "application/vnd.shinycapabilities.capability+json;version=1";
const LEGACY_CAPABILITY_MIME = "application/x-shinycapability";
const friendlyPort = (name, port) =>
  port?.displayLabel || String(name).replaceAll("_", " ");
const ALLOWED_ICONS = new Set([
  "adjust", "asterisk", "ban-circle", "barcode", "bell", "book", "bookmark", "briefcase",
  "bullhorn", "calendar", "camera", "certificate", "check", "cloud", "cog", "comment",
  "dashboard", "edit", "eye-open", "file", "filter", "fire", "flag", "flash", "folder-open",
  "globe", "hdd", "heart", "inbox", "leaf", "link", "list-alt", "lock", "magnet",
  "map-marker", "move", "ok-circle", "paperclip", "picture", "pushpin", "qrcode", "random",
  "refresh", "repeat", "road", "saved", "search", "send", "signal", "sort", "stats", "tag",
  "tasks", "th", "th-large", "th-list", "time", "tower", "transfer", "tree-deciduous",
  "tree-conifer", "user", "warning-sign", "wrench", "zoom-in"
]);
const safeIcon = (value) => ALLOWED_ICONS.has(value) ? value : "asterisk";
const FONT_AWESOME_ALIASES = {
  adjust: "sliders", "ban-circle": "ban", cog: "gear", dashboard: "gauge",
  edit: "pen", "eye-open": "eye", flash: "bolt", hdd: "hard-drive",
  "list-alt": "rectangle-list", "map-marker": "location-dot",
  move: "up-down-left-right", "ok-circle": "circle-check", picture: "image",
  pushpin: "thumbtack", random: "shuffle", refresh: "rotate", saved: "floppy-disk",
  search: "magnifying-glass", send: "paper-plane", stats: "chart-column",
  tasks: "list-check", th: "table-cells", "th-large": "table-cells-large",
  "th-list": "list", time: "clock", tower: "tower-broadcast", transfer: "right-left",
  "tree-deciduous": "tree", "tree-conifer": "tree",
  "warning-sign": "triangle-exclamation", "zoom-in": "magnifying-glass-plus"
};
const CapabilityIcon = ({ value, className = "" }) => {
  const icon = safeIcon(value);
  const rendered = FONT_AWESOME_ALIASES[icon] || icon;
  return <i className={`${className} sc-rendered-icon fas fa-${rendered}`} data-shinycap-icon={icon} aria-hidden="true" />;
};

function emit(element, type, payload, graph) {
  if (!window.Shiny?.setInputValue) return;
  const nonce = `${Date.now()}-${Math.random()}`;
  const event = { type, ...payload, graph, nonce };
  window.Shiny.setInputValue(
    `${element.id}_event`,
    event,
    { priority: "event" }
  );
  window.Shiny.setInputValue(
    `${element.id}_event_v1`,
    { bridgeVersion: BRIDGE_VERSION, ...event },
    { priority: "event" }
  );
}

const CapabilityNode = memo(({ id, data, selected }) => (
  <article
    className={`sc-node sc-state-${String(data.state || "unconfigured").replace(/[^\w-]/g, "-")}${data.metadata?.proposal_status === "proposed" ? " sc-node-proposed" : ""}${data.metadata?.composite ? " sc-node-composite" : ""}`}
    data-shinycap-part="node"
    data-shinycap-state={data.state || "unconfigured"}
    data-shinycap-selected={selected ? "true" : "false"}
    data-shinycap-node-id={id}
    data-testid={`shinycap-node-card-${id}`}
    aria-label={`${data.displayName}, ${data.state || "unconfigured"}`}
  >
    {!data.readOnly && <NodeResizer
      minWidth={240}
      minHeight={150}
      isVisible={selected}
      handleClassName="sc-node-resize-handle"
      lineClassName="sc-node-resize-line"
      onResizeEnd={(_, dimensions) => data.onResizeEnd?.(id, dimensions)}
    />}
    <header
      className="sc-node-drag-handle"
      data-shinycap-action="select-node"
      data-shinycap-node-id={id}
      tabIndex={0}
      onKeyDown={(event) => {
        if (event.key === "Enter" || event.key === " ") {
          event.preventDefault();
          data.onSelect?.(id);
        }
      }}
    >
      <CapabilityIcon className="sc-node-icon" value={data.icon} />
      <div>
        <strong>{data.displayName}</strong>
        <small>{data.category}</small>
      </div>
      <span className="sc-node-state">{data.state || "unconfigured"}</span>
    </header>
    <p className="sc-node-summary">{data.summary || data.description?.split(/[.!?]/)[0]}</p>
    <div className="sc-node-port-grid">
      <div className="sc-node-ports sc-node-inputs">
        {Object.entries(data.inputs || {}).map(([name, port], index) => (
          <div className="sc-port-row" key={`in-${name}`}>
            <Handle
              type="target"
              position={Position.Left}
              id={name}
              data-shinycap-handle="input"
              data-shinycap-node-id={id}
              data-shinycap-port-id={name}
              data-testid={`shinycap-handle-input-${id}-${name}`}
              style={{ top: 82 + index * 22 }}
              aria-label={`Input ${name}, ${port.type}`}
              title={`Connect ${port.type} to ${friendlyPort(name, port)}`}
              className={data.connectionSource ?
                (data.connectionSource.nodeId !== id && data.connectionSource.type === port.type
                  ? "sc-handle-compatible" : "sc-handle-incompatible") : ""}
            />
            <span>{friendlyPort(name, port)}</span><code>{port.type}</code>
          </div>
        ))}
      </div>
      <div className="sc-node-ports sc-node-outputs">
        {Object.entries(data.outputs || {}).map(([name, port], index) => (
          <div className="sc-port-row" key={`out-${name}`}>
            <span>{friendlyPort(name, port)}</span><code>{port.type}</code>
            <Handle
              type="source"
              position={Position.Right}
              id={name}
              data-shinycap-handle="output"
              data-shinycap-node-id={id}
              data-shinycap-port-id={name}
              data-testid={`shinycap-handle-output-${id}-${name}`}
              style={{ top: 82 + index * 22 }}
              aria-label={`Output ${name}, ${port.type}`}
              title={`${friendlyPort(name, port)} output: ${port.type}`}
            />
          </div>
        ))}
      </div>
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
          width: Math.max(240, node.width || node.measured?.width || 260),
          height: Math.max(150, node.height || node.measured?.height || 150)
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
        width: Math.max(240, node.size?.width || 260),
        height: Math.max(150, node.size?.height || 150),
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
      ariaLabel: `Connection ${edge.id}: ${edge.source} ${edge.source_port} to ${edge.target} ${edge.target_port}`,
      data: { shinycapEdgeId: edge.id, sourcePort: edge.source_port, targetPort: edge.target_port },
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
  const [connectionSource, setConnectionSource] = useState(null);
  const [connectionFeedback, setConnectionFeedback] = useState(null);
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
    window.Shiny?.addCustomMessageHandler?.("shinycapabilities:v1:set-graph", onSetGraph);
  }, [element.id, readOnly, value.capabilities]);

  useEffect(() => {
    const handler = (event) => {
      const button = event.target.closest(".sc-widget-command");
      if (!button || button.dataset.target !== element.id) return;
      if (button.dataset.command === "fitView" || button.dataset.shinycapCommand === "fit-view") {
        flow.fitView({ padding: 0.18, duration: 250 });
      }
    };
    document.addEventListener("click", handler);
    return () => document.removeEventListener("click", handler);
  }, [element.id, flow]);

  useEffect(() => {
    const onCommand = (message) => {
      if (message.id !== element.id) return;
      if (message.command === "fit-view") {
        flow.fitView({ padding: 0.18, duration: 250 });
      }
    };
    window.Shiny?.addCustomMessageHandler?.("shinycapabilities:v1:command", onCommand);
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
    element.addEventListener(INSERT_EVENT, insert);
    element.addEventListener(LEGACY_INSERT_EVENT, insert);
    return () => {
      element.removeEventListener(INSERT_EVENT, insert);
      element.removeEventListener(LEGACY_INSERT_EVENT, insert);
    };
  }, [catalog, edges, element, flow, readOnly, value.capabilities]);

  useEffect(() => {
    if (!window.Shiny?.addCustomMessageHandler) return;
    const onConnectionResult = (message) => {
      if (message.id !== element.id || !pendingConnection) return;
      if (message.result?.valid) {
        setEdges((current) => {
          const next = addEdge({ ...pendingConnection, type: "smoothstep" }, current);
          emit(element, "connection_accepted", { edge: pendingConnection }, serialize(nodes, next));
          return next;
        });
        setConnectionFeedback({ valid: true, message: message.result.message });
      } else {
        emit(element, "connection_rejected", {
          edge: pendingConnection,
          finding: message.result
        }, graph());
        setConnectionFeedback({ valid: false, message: message.result?.message || "Connection rejected." });
      }
      setPendingConnection(null);
    };
    window.Shiny.addCustomMessageHandler("shinycapabilities:connection-result", onConnectionResult);
    window.Shiny.addCustomMessageHandler("shinycapabilities:v1:connection-result", onConnectionResult);
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
    setConnectionFeedback({ valid: null, message: "Checking connection with the R workflow authority…" });
    emit(element, "connection_proposed", { edge }, graph());
  }, [element, graph, readOnly]);

  const onConnectStart = useCallback((_, params) => {
    if (params.handleType !== "source") return;
    const node = nodes.find((candidate) => candidate.id === params.nodeId);
    setConnectionSource({
      nodeId: params.nodeId,
      handleId: params.handleId,
      type: node?.data?.outputs?.[params.handleId]?.type
    });
  }, [nodes]);

  const onConnectEnd = useCallback(() => setConnectionSource(null), []);

  const onNodeResizeEnd = useCallback((id, resized) => {
    setNodes((current) => {
      const next = current.map((node) => node.id === id ? {
        ...node,
        width: Math.max(240, resized.width || 240),
        height: Math.max(150, resized.height || 150)
      } : node);
      emit(element, "resize_completed", { nodeId: id }, serialize(next, edges));
      return next;
    });
  }, [edges, element]);

  const presentedNodes = useMemo(() => nodes.map((node) => ({
    ...node,
    data: {
      ...node.data,
      connectionSource,
      onResizeEnd: onNodeResizeEnd,
      onSelect: (nodeId) => emit(element, "node_selected", { nodeId }, graph())
    }
  })), [connectionSource, element, graph, nodes, onNodeResizeEnd]);

  const onDrop = useCallback((event) => {
    event.preventDefault();
    if (readOnly) return;
    const versioned = event.dataTransfer.getData(CAPABILITY_MIME);
    const capabilityId = versioned
      ? JSON.parse(versioned).capabilityId
      : event.dataTransfer.getData(LEGACY_CAPABILITY_MIME);
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
      data-shinycap-part="canvas"
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
        nodes={presentedNodes}
        edges={edges}
        nodeTypes={nodeTypes}
        onNodesChange={onNodesChange}
        onEdgesChange={onEdgesChange}
        onConnect={onConnect}
        onConnectStart={onConnectStart}
        onConnectEnd={onConnectEnd}
        onNodeClick={(_, node) => emit(element, "node_selected", { nodeId: node.id }, graph())}
        onPaneClick={() => emit(element, "node_selected", { nodeId: null }, graph())}
        onNodeDragStop={(_, node) => emit(element, "move_completed", { nodeId: node.id }, graph())}
        onNodesDelete={(deleted) => emit(element, "node_removed", {
          nodeIds: deleted.map((node) => node.id)
        }, graph(nodes.filter((node) => !deleted.some((item) => item.id === node.id)), edges))}
        nodesDraggable={!readOnly}
        nodeDragHandle=".sc-node-drag-handle"
        nodeDragThreshold={8}
        nodesConnectable={!readOnly}
        edgesReconnectable={false}
        elementsSelectable
        deleteKeyCode={null}
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
      <div
        className={`sc-connection-feedback${connectionFeedback ? " is-visible" : ""}${connectionFeedback?.valid === false ? " is-rejected" : ""}`}
        role="status"
        aria-live="polite"
      >
        {connectionFeedback?.message || "Drag from an output handle to a compatible input handle."}
      </div>
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
