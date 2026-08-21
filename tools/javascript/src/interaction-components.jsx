import React, { useEffect, useMemo, useRef, useState } from "react";
import { createRoot } from "react-dom/client";
import { useVirtualizer } from "@tanstack/react-virtual";
import "./interaction-components.css";

const emitters = new WeakMap();
const publish = (element, suffix, value) => emitters.get(element)?.(suffix, value);

const eventPayload = (item, extra = {}) => ({
  id: item.id,
  label: item.label,
  metadata: item.metadata || {},
  nonce: Date.now(),
  ...extra
});

function EmptyState({ message }) {
  return <div className="sc-lab-empty" role="status">{message}</div>;
}

function VirtualTreeBrowser({ element, model }) {
  const nodes = model.nodes || [];
  const options = model.options || {};
  const [expanded, setExpanded] = useState(() => new Set(model.expanded || []));
  const [selected, setSelected] = useState(model.selected || null);
  const [active, setActive] = useState(model.selected || null);
  const [query, setQuery] = useState("");
  const scrollRef = useRef(null);
  const rowRefs = useRef(new Map());

  const index = useMemo(() => {
    const byId = new Map(nodes.map((node, position) => [node.id, { ...node, position }]));
    const children = new Map();
    nodes.forEach(node => {
      const parent = node.parentId || "__root__";
      if (!children.has(parent)) children.set(parent, []);
      children.get(parent).push(node.id);
    });
    return { byId, children };
  }, [nodes]);

  const visible = useMemo(() => {
    const term = query.trim().toLowerCase();
    const matches = new Set();
    if (term) {
      nodes.forEach(node => {
        const haystack = `${node.label} ${node.description || ""} ${node.badge || ""} ${node.status || ""}`.toLowerCase();
        if (haystack.includes(term)) {
          let current = node;
          while (current) {
            matches.add(current.id);
            current = current.parentId ? index.byId.get(current.parentId) : null;
          }
        }
      });
    }
    const rows = [];
    const append = (id, level, path) => {
      const node = index.byId.get(id);
      if (!node || (term && !matches.has(id))) return;
      const childIds = index.children.get(id) || [];
      const nextPath = [...path, node.label];
      rows.push({ ...node, level, childIds, path: nextPath });
      if (term || expanded.has(id)) childIds.forEach(child => append(child, level + 1, nextPath));
    };
    (index.children.get("__root__") || []).forEach(id => append(id, 1, []));
    return rows;
  }, [expanded, index, nodes, query]);

  const virtualizer = useVirtualizer({
    count: visible.length,
    getScrollElement: () => scrollRef.current,
    estimateSize: () => options.rowHeight || 42,
    overscan: 8
  });

  useEffect(() => {
    if (!visible.length) return;
    if (!visible.some(node => node.id === active)) setActive(visible[0].id);
  }, [active, visible]);

  useEffect(() => {
    const node = rowRefs.current.get(active);
    if (node) node.focus({ preventScroll: true });
  }, [active]);

  const selectNode = (node, activate = false) => {
    if (!node || node.disabled) return;
    setSelected(node.id);
    setActive(node.id);
    const payload = eventPayload(node, { path: node.path });
    publish(element, "selection", payload);
    if (activate) publish(element, "activate", payload);
  };

  const toggleNode = node => {
    if (!node.childIds.length) return;
    const next = new Set(expanded);
    const isExpanded = !next.has(node.id);
    if (isExpanded) next.add(node.id); else next.delete(node.id);
    setExpanded(next);
    publish(element, "toggle", eventPayload(node, { expanded: isExpanded }));
  };

  const handleKey = (event, node, position) => {
    const move = offset => {
      const target = visible[Math.max(0, Math.min(visible.length - 1, position + offset))];
      if (target) {
        setActive(target.id);
        virtualizer.scrollToIndex(visible.indexOf(target), { align: "auto" });
      }
    };
    if (event.key === "ArrowDown") { event.preventDefault(); move(1); }
    else if (event.key === "ArrowUp") { event.preventDefault(); move(-1); }
    else if (event.key === "ArrowRight") {
      event.preventDefault();
      if (node.childIds.length && !expanded.has(node.id)) toggleNode(node);
      else if (node.childIds.length) setActive(node.childIds[0]);
    } else if (event.key === "ArrowLeft") {
      event.preventDefault();
      if (expanded.has(node.id)) toggleNode(node);
      else if (node.parentId) setActive(node.parentId);
    } else if (event.key === "Enter") { event.preventDefault(); selectNode(node, true); }
    else if (event.key === " ") { event.preventDefault(); selectNode(node); }
    else if (event.key === "Home") { event.preventDefault(); move(-visible.length); }
    else if (event.key === "End") { event.preventDefault(); move(visible.length); }
  };

  return <div className="sc-lab sc-tree-browser" data-shinycap-component="virtual-tree-browser">
    {options.searchable !== false && <label className="sc-lab-search">
      <span className="sc-lab-visually-hidden">Search hierarchy</span>
      <span aria-hidden="true">⌕</span>
      <input value={query} onChange={event => setQuery(event.target.value)} placeholder="Search hierarchy..." />
      {query && <button type="button" onClick={() => setQuery("")} aria-label="Clear tree search">×</button>}
    </label>}
    <div className="sc-tree-count" aria-live="polite">{visible.length} visible item{visible.length === 1 ? "" : "s"}</div>
    <div ref={scrollRef} className="sc-lab-scroll" role="tree" aria-label="Hierarchical browser">
      {!visible.length ? <EmptyState message={options.emptyMessage || "No matching items."} /> :
        <div className="sc-lab-virtual-space" style={{ height: `${virtualizer.getTotalSize()}px` }}>
          {virtualizer.getVirtualItems().map(virtualRow => {
            const node = visible[virtualRow.index];
            const hasChildren = node.childIds.length > 0;
            return <div key={node.id} ref={current => current ? rowRefs.current.set(node.id, current) : rowRefs.current.delete(node.id)}
              id={`${element.id}-treeitem-${node.id}`} role="treeitem" aria-level={node.level}
              aria-selected={selected === node.id} aria-expanded={hasChildren ? expanded.has(node.id) : undefined}
              aria-disabled={node.disabled || undefined} tabIndex={active === node.id ? 0 : -1}
              className={`sc-tree-row${selected === node.id ? " is-selected" : ""}${node.disabled ? " is-disabled" : ""}`}
              style={{ transform: `translateY(${virtualRow.start}px)`, paddingInlineStart: `${12 + (node.level - 1) * 18}px` }}
              onClick={() => selectNode(node)} onDoubleClick={() => selectNode(node, true)}
              onKeyDown={event => handleKey(event, node, virtualRow.index)}>
              <button type="button" className="sc-tree-toggle" tabIndex={-1} disabled={!hasChildren}
                aria-label={hasChildren ? `${expanded.has(node.id) ? "Collapse" : "Expand"} ${node.label}` : undefined}
                onClick={event => { event.stopPropagation(); toggleNode(node); }}>
                {hasChildren ? (expanded.has(node.id) ? "▾" : "▸") : ""}
              </button>
              <span className="sc-tree-copy"><strong>{node.label}</strong>{node.description && <small>{node.description}</small>}</span>
              {node.status && <span className={`sc-lab-status is-${node.status.toLowerCase().replace(/[^a-z0-9]+/g, "-")}`}>{node.status}</span>}
              {node.badge && <span className="sc-lab-badge">{node.badge}</span>}
            </div>;
          })}
        </div>}
    </div>
  </div>;
}

const scoreCommand = (item, term) => {
  if (!term) return 1;
  const label = item.label.toLowerCase();
  const group = (item.group || "").toLowerCase();
  const keywords = (item.keywords || []).join(" ").toLowerCase();
  if (label === term) return 100;
  if (label.startsWith(term)) return 60;
  if (label.includes(term)) return 30;
  if (keywords.includes(term)) return 15;
  if (group.includes(term)) return 8;
  return 0;
};

function CommandPalette({ element, model }) {
  const items = model.items || [];
  const options = model.options || {};
  const [query, setQuery] = useState("");
  const [activeIndex, setActiveIndex] = useState(0);
  const inputRef = useRef(null);
  const scrollRef = useRef(null);

  const filtered = useMemo(() => {
    const term = query.trim().toLowerCase();
    return items.map((item, position) => ({ ...item, position, score: scoreCommand(item, term) }))
      .filter(item => item.score > 0)
      .sort((a, b) => b.score - a.score || a.position - b.position);
  }, [items, query]);

  const virtualizer = useVirtualizer({
    count: filtered.length,
    getScrollElement: () => scrollRef.current,
    estimateSize: () => options.rowHeight || 54,
    overscan: 8
  });

  useEffect(() => setActiveIndex(0), [query]);
  useEffect(() => {
    if (activeIndex >= filtered.length) setActiveIndex(Math.max(0, filtered.length - 1));
  }, [activeIndex, filtered.length]);
  useEffect(() => {
    if (!options.shortcut) return undefined;
    const focusShortcut = event => {
      if (event.defaultPrevented) return;
      if ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === "k") {
        event.preventDefault(); inputRef.current?.focus();
      }
    };
    window.addEventListener("keydown", focusShortcut);
    return () => window.removeEventListener("keydown", focusShortcut);
  }, [options.shortcut]);

  useEffect(() => {
    if (!options.serverSearch) return undefined;
    const timer = window.setTimeout(() => publish(element, "query", { query, nonce: Date.now() }), 150);
    return () => window.clearTimeout(timer);
  }, [element, options.serverSearch, query]);

  const activate = item => {
    if (!item || item.disabled) return;
    publish(element, "command", eventPayload(item, { group: item.group || "Commands", query }));
  };

  const handleKey = event => {
    if (event.key === "ArrowDown") {
      event.preventDefault();
      const next = Math.min(filtered.length - 1, activeIndex + 1);
      setActiveIndex(next); virtualizer.scrollToIndex(next, { align: "auto" });
    } else if (event.key === "ArrowUp") {
      event.preventDefault();
      const next = Math.max(0, activeIndex - 1);
      setActiveIndex(next); virtualizer.scrollToIndex(next, { align: "auto" });
    } else if (event.key === "Enter") {
      event.preventDefault(); activate(filtered[activeIndex]);
    } else if (event.key === "Escape") {
      event.preventDefault(); setQuery(""); inputRef.current?.blur();
    } else if (event.key === "Home") {
      event.preventDefault(); setActiveIndex(0); virtualizer.scrollToIndex(0);
    } else if (event.key === "End") {
      event.preventDefault(); const last = Math.max(0, filtered.length - 1); setActiveIndex(last); virtualizer.scrollToIndex(last);
    }
  };

  const active = filtered[activeIndex];
  return <div className="sc-lab sc-command-palette" data-shinycap-component="command-palette">
    <label className="sc-command-search">
      <span className="sc-lab-visually-hidden">Search commands</span>
      <span aria-hidden="true">⌕</span>
      <input ref={inputRef} role="combobox" aria-autocomplete="list" aria-expanded="true"
        aria-controls={`${element.id}-commands`} aria-activedescendant={active ? `${element.id}-command-${active.id}` : undefined}
        value={query} onChange={event => setQuery(event.target.value)} onKeyDown={handleKey}
        placeholder={options.placeholder || "Search commands..."} />
      {options.shortcut && <kbd>Ctrl K</kbd>}
    </label>
    <div className="sc-command-summary" aria-live="polite">{filtered.length} command{filtered.length === 1 ? "" : "s"}</div>
    <div id={`${element.id}-commands`} ref={scrollRef} className="sc-lab-scroll" role="listbox" aria-label="Available commands">
      {!filtered.length ? <EmptyState message={options.emptyMessage || "No matching commands."} /> :
        <div className="sc-lab-virtual-space" style={{ height: `${virtualizer.getTotalSize()}px` }}>
          {virtualizer.getVirtualItems().map(virtualRow => {
            const item = filtered[virtualRow.index];
            return <div key={item.id} id={`${element.id}-command-${item.id}`} role="option"
              aria-selected={virtualRow.index === activeIndex} aria-disabled={item.disabled || undefined}
              className={`sc-command-row${virtualRow.index === activeIndex ? " is-active" : ""}${item.disabled ? " is-disabled" : ""}`}
              style={{ transform: `translateY(${virtualRow.start}px)` }}
              onMouseMove={() => setActiveIndex(virtualRow.index)} onClick={() => activate(item)}>
              <span className="sc-command-copy"><span className="sc-command-group">{item.group || "Commands"}</span><strong>{item.label}</strong>{item.description && <small>{item.description}</small>}</span>
              {item.shortcut && <kbd>{item.shortcut}</kbd>}
            </div>;
          })}
        </div>}
    </div>
    <div className="sc-command-help"><span>↑↓ Navigate</span><span>Enter Run</span><span>Esc Clear</span></div>
  </div>;
}

window.ShinyCapabilitiesDirectTransport.register("virtual_tree_browser", {
  runtimeMajor: 1,
  mount(element, model, context) {
    const root = createRoot(element);
    emitters.set(element, context.emit);
    root.render(<VirtualTreeBrowser element={element} model={model || {}} />);
    return { root, model };
  },
  update(handle, model, context) {
    handle.model = { ...handle.model, ...model };
    emitters.set(context.element, context.emit);
    handle.root.render(<VirtualTreeBrowser element={context.element} model={handle.model} />);
    return handle;
  },
  resize() {},
  destroy(handle, element) { handle.root.unmount(); emitters.delete(element); }
});
