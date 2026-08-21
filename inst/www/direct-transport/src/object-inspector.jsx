const runtime = window.ShinyCapabilitiesBrowserRuntimeV1;
if (!runtime) throw new Error("Shared shinycapabilities browser runtime v1 was not loaded.");
runtime.assertCompatible(1);
const { React, createRoot, useVirtualizer } = runtime;
const { useEffect, useMemo, useRef, useState } = React;
import "./object-inspector.css";

const transport = window.ShinyCapabilitiesDirectTransport;
if (!transport) throw new Error("Direct Component Transport was not loaded.");

const escapePart = value => String(value).replaceAll("~", "~0").replaceAll("/", "~1");
const parentPath = path => path === "" ? null : path.slice(0, path.lastIndexOf("/"));
const displayKey = key => key === "" ? "$" : key;
const scalarText = node => {
  if (node.valueType === "redacted") return "[redacted]";
  if (node.valueType === "missing") return "[missing]";
  if (node.valueType === "null") return "null";
  if (node.valueType === "boolean") return node.value ? "true" : "false";
  if (node.valueType === "string") return JSON.stringify(node.value ?? "");
  return String(node.value ?? "");
};

function indexTree(root) {
  const all = [], byPath = new Map();
  const walk = (node, path = "", key = "", depth = 0, ancestors = []) => {
    if (!node) return;
    const record = { node, path, key, depth, ancestors, parent: parentPath(path),
      branch: node.nodeType === "object" || node.nodeType === "array" };
    all.push(record); byPath.set(path, record);
    for (const child of node.children || []) {
      const next = `${path}/${escapePart(child.key)}`;
      walk(child.node, next, child.key, depth + 1, [...ancestors, path]);
    }
  };
  walk(root); return { all, byPath };
}

function visibleRows(index, expanded, query) {
  const needle = query.trim().toLowerCase();
  if (needle) {
    const matches = new Set();
    for (const row of index.all) {
      const searchable = row.node.valueType === "redacted" ? "" : scalarText(row.node);
      if (`${row.key} ${row.path} ${searchable}`.toLowerCase().includes(needle)) {
        matches.add(row.path); row.ancestors.forEach(path => matches.add(path));
      }
    }
    return index.all.filter(row => matches.has(row.path));
  }
  return index.all.filter(row => row.ancestors.every(path => expanded.has(path)));
}

function replaceAtPath(root, path, value, remove = false) {
  if (path === "") return remove ? null : value;
  const parts = path.slice(1).split("/").map(x => x.replaceAll("~1", "/").replaceAll("~0", "~"));
  const clone = structuredClone(root); let node = clone;
  for (let i = 0; i < parts.length - 1; i++) {
    const child = (node.children || []).find(x => String(x.key) === parts[i]);
    if (!child) return clone; node = child.node;
  }
  const key = parts.at(-1), children = node.children || [];
  const at = children.findIndex(x => String(x.key) === key);
  if (remove) { if (at >= 0) children.splice(at, 1); }
  else if (at >= 0) children[at].node = value;
  else children.push({ key, node: value });
  return clone;
}

function TypeValue({ node }) {
  if (node.nodeType !== "scalar") return <span className="sc-oi-summary">{node.nodeType === "array" ?
    `[${node.children?.length || 0}]` : `{${node.children?.length || 0}}`}</span>;
  return <><span className={`sc-oi-type is-${node.valueType}`}>{node.valueType}</span>
    <span className={`sc-oi-value is-${node.valueType}`}>{scalarText(node)}</span></>;
}

function ObjectInspector({ host, model, emit, controllerRef }) {
  const [root, setRoot] = useState(model.root), [query, setQuery] = useState(model.search || "");
  const [expanded, setExpanded] = useState(() => new Set(model.expandedPaths || [""]));
  const [selected, setSelected] = useState(model.selectedPath ?? "");
  const viewport = useRef(null), searchRef = useRef(null);
  const index = useMemo(() => indexTree(root), [root]);
  const rows = useMemo(() => visibleRows(index, expanded, query), [index, expanded, query]);
  const virtual = useVirtualizer({ count: rows.length, getScrollElement: () => viewport.current,
    estimateSize: () => 30, overscan: 10, getItemKey: i => rows[i]?.path || i });
  const select = (path, source = "user") => {
    const row = index.byPath.get(path); if (!row) return;
    setSelected(path); emit("selection", { path, key: row.key, nodeType: row.node.nodeType,
      valueType: row.node.valueType || null, source, nonce: Date.now() });
  };
  const reveal = path => {
    const row = index.byPath.get(path); if (!row) return false;
    setExpanded(old => new Set([...old, ...row.ancestors])); setSelected(path);
    requestAnimationFrame(() => { const at = rows.findIndex(x => x.path === path); if (at >= 0) virtual.scrollToIndex(at, { align: "auto" }); });
    return true;
  };
  useEffect(() => {
    setRoot(model.root); setExpanded(old => new Set([...old].filter(path => indexTree(model.root).byPath.has(path))));
  }, [model.root]);
  useEffect(() => { if (!index.byPath.has(selected)) setSelected(""); }, [index, selected]);
  useEffect(() => {
    controllerRef.current = message => {
      if (message.root !== undefined) setRoot(message.root);
      if (message.patches?.length) setRoot(current => message.patches.reduce((next, patch) =>
        replaceAtPath(next, patch.path, patch.value, patch.operation === "remove"), current));
      if (message.focusPath != null) setTimeout(() => reveal(message.focusPath), 0);
    };
    return () => { controllerRef.current = null; };
  }, [index]);
  const toggle = path => setExpanded(old => { const next = new Set(old); next.has(path) ? next.delete(path) : next.add(path); return next; });
  const onKeyDown = event => {
    const at = Math.max(0, rows.findIndex(row => row.path === selected)); let target = at;
    if (event.key === "ArrowDown") target = Math.min(rows.length - 1, at + 1);
    else if (event.key === "ArrowUp") target = Math.max(0, at - 1);
    else if (event.key === "Home") target = 0;
    else if (event.key === "End") target = rows.length - 1;
    else if (event.key === "ArrowRight") { const row = rows[at]; if (row?.branch && !expanded.has(row.path)) toggle(row.path); else if (rows[at + 1]?.parent === row?.path) target = at + 1; }
    else if (event.key === "ArrowLeft") { const row = rows[at]; if (row?.branch && expanded.has(row.path)) toggle(row.path); else if (row?.parent != null) return void reveal(row.parent); }
    else if (event.key === "Enter" || event.key === " ") return void (rows[at]?.branch ? toggle(rows[at].path) : select(rows[at]?.path));
    else return;
    event.preventDefault(); if (rows[target]) { select(rows[target].path); virtual.scrollToIndex(target, { align: "auto" }); }
  };
  const selectedRow = index.byPath.get(selected);
  const copy = async () => {
    if (!selectedRow || selectedRow.node.nodeType !== "scalar" || selectedRow.node.valueType === "redacted") return;
    await navigator.clipboard.writeText(scalarText(selectedRow.node));
    emit("copy", { path: selected, valueType: selectedRow.node.valueType, nonce: Date.now() });
  };
  if (model.state !== "ready") return <div className={`sc-object-inspector-state is-${model.state}`} role={model.state === "error" ? "alert" : "status"}>
    <strong>{model.state === "loading" ? "Loading object" : model.state === "error" ? "Object unavailable" : "No object to inspect"}</strong>
    {model.message && <span>{model.message}</span>}</div>;
  return <div className="sc-object-inspector">
    <header><strong>{model.title || "Object inspector"}</strong><span>{model.nodeCount || index.all.length} nodes</span>
      {model.truncated > 0 && <span className="is-warning">{model.truncated} truncated</span>}</header>
    <div className="sc-oi-search"><label htmlFor={`${host.id}-search`}>Search object</label>
      <input ref={searchRef} id={`${host.id}-search`} type="search" value={query}
        onChange={e => setQuery(e.target.value)} placeholder="Key, path, or value" />
      <span role="status">{query ? `${rows.filter(x => !x.branch).length} matching values` : `${rows.length} visible`}</span></div>
    <nav className="sc-oi-breadcrumb" aria-label="Selected object path">{(selected === "" ? [""] : ["", ...selected.slice(1).split("/")]).map((part, i, parts) => {
      const path = i === 0 ? "" : `/${parts.slice(1, i + 1).join("/")}`;
      return <button key={path} type="button" onClick={() => reveal(path)}>{i === 0 ? "$" : part}</button>;
    })}</nav>
    <div ref={viewport} className="sc-oi-viewport" role="tree" aria-label={model.title || "Structured object"}
      tabIndex="0" aria-activedescendant={selected ? `${host.id}-row-${btoa(unescape(encodeURIComponent(selected))).replaceAll("=", "")}` : undefined}
      onKeyDown={onKeyDown}>
      <div style={{ height: virtual.getTotalSize(), position: "relative" }}>{virtual.getVirtualItems().map(item => {
        const row = rows[item.index], active = row.path === selected;
        const id = `${host.id}-row-${btoa(unescape(encodeURIComponent(row.path))).replaceAll("=", "")}`;
        return <div id={id} key={row.path} role="treeitem" aria-level={row.depth + 1}
          aria-expanded={row.branch ? expanded.has(row.path) : undefined} aria-selected={active}
          className={`sc-oi-row${active ? " is-selected" : ""}`}
          style={{ transform: `translateY(${item.start}px)`, paddingLeft: 8 + row.depth * 18 }}
          onClick={() => select(row.path)} onDoubleClick={() => row.branch && toggle(row.path)}>
          <button type="button" className="sc-oi-toggle" tabIndex="-1" aria-label={`${expanded.has(row.path) ? "Collapse" : "Expand"} ${displayKey(row.key)}`}
            disabled={!row.branch} onClick={e => { e.stopPropagation(); toggle(row.path); }}>{row.branch ? (expanded.has(row.path) ? "−" : "+") : "·"}</button>
          <span className="sc-oi-key">{displayKey(row.key)}</span><TypeValue node={row.node} />
        </div>;
      })}</div>
    </div>
    <footer><span>{selected || "$"}</span><button type="button" onClick={copy}
      disabled={!selectedRow || selectedRow.node.nodeType !== "scalar" || selectedRow.node.valueType === "redacted"}>Copy value</button></footer>
  </div>;
}

transport.register("object_inspector", {
  runtimeMajor: 1,
  mount(element, model, context) {
    const root = createRoot(element), controllerRef = { current: null };
    const render = next => root.render(<ObjectInspector host={element} model={next} emit={context.emit} controllerRef={controllerRef} />);
    render(model); return { root, model, render, controllerRef };
  },
  update(handle, message, context) {
    handle.model = { ...handle.model, ...message }; handle.controllerRef.current?.(message);
    handle.render(handle.model); return handle;
  },
  resize(handle, rect, element) { element.dataset.scInspectorWidth = String(Math.round(rect?.width || element.clientWidth)); },
  destroy(handle) { handle.root.unmount(); handle.controllerRef.current = null; }
});
