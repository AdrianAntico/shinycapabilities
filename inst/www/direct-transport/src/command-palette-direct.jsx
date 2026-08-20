const vendor = window.ShinyCapabilitiesBrowserRuntimeV1;
if (!vendor) throw new Error("Shared shinycapabilities browser runtime v1 was not loaded.");
vendor.assertCompatible(1);
const { React, createRoot, useVirtualizer } = vendor;
const { useEffect, useMemo, useRef, useState } = React;
import "./command-palette-direct.css";

const score = (item, term) => {
  if (!term) return 1;
  const label = item.label.toLowerCase(), group = (item.group || "").toLowerCase();
  const keywords = (item.keywords || []).join(" ").toLowerCase();
  if (label === term) return 100;
  if (label.startsWith(term)) return 60;
  if (label.includes(term)) return 30;
  if (keywords.includes(term)) return 15;
  if (group.includes(term)) return 8;
  return 0;
};

function Palette({ host, model, emit }) {
  const items = model.items || [], options = model.options || {};
  const [query, setQuery] = useState("");
  const [active, setActive] = useState(0);
  const input = useRef(null), scroll = useRef(null);
  const filtered = useMemo(() => {
    const term = query.trim().toLowerCase();
    return items.map((item, position) => ({ ...item, position, score: score(item, term) }))
      .filter(item => item.score > 0).sort((a, b) => b.score - a.score || a.position - b.position);
  }, [items, query]);
  const virtualizer = useVirtualizer({ count: filtered.length,
    getScrollElement: () => scroll.current, estimateSize: () => options.rowHeight || 54, overscan: 8 });
  useEffect(() => setActive(0), [query]);
  useEffect(() => { if (active >= filtered.length) setActive(Math.max(0, filtered.length - 1)); }, [active, filtered.length]);
  useEffect(() => {
    if (!options.shortcut) return;
    const handler = event => { if ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === "k") {
      event.preventDefault(); input.current?.focus();
    }};
    window.addEventListener("keydown", handler);
    return () => window.removeEventListener("keydown", handler);
  }, [options.shortcut]);
  useEffect(() => {
    if (!options.serverSearch) return;
    const timer = setTimeout(() => emit("query", { query, nonce: Date.now() }), 150);
    return () => clearTimeout(timer);
  }, [emit, options.serverSearch, query]);
  const activate = item => { if (item && !item.disabled) emit("command", {
    id: item.id, label: item.label, group: item.group || "Commands", query,
    metadata: item.metadata || {}, nonce: Date.now()
  }); };
  const keydown = event => {
    if (event.key === "ArrowDown") { event.preventDefault(); const next = Math.min(filtered.length - 1, active + 1); setActive(next); virtualizer.scrollToIndex(next); }
    else if (event.key === "ArrowUp") { event.preventDefault(); const next = Math.max(0, active - 1); setActive(next); virtualizer.scrollToIndex(next); }
    else if (event.key === "Enter") { event.preventDefault(); activate(filtered[active]); }
    else if (event.key === "Escape") { event.preventDefault(); setQuery(""); input.current?.blur(); }
    else if (event.key === "Home") { event.preventDefault(); setActive(0); virtualizer.scrollToIndex(0); }
    else if (event.key === "End") { event.preventDefault(); const last = Math.max(0, filtered.length - 1); setActive(last); virtualizer.scrollToIndex(last); }
  };
  const current = filtered[active];
  return <div className="sc-direct-palette" data-shinycap-component="command-palette-direct">
    <label className="sc-direct-palette-search"><span className="sc-direct-sr">Search commands</span><span aria-hidden="true">⌕</span>
      <input ref={input} role="combobox" aria-autocomplete="list" aria-expanded="true"
        aria-controls={`${host.id}-commands`} aria-activedescendant={current ? `${host.id}-command-${current.id}` : undefined}
        value={query} onChange={event => setQuery(event.target.value)} onKeyDown={keydown}
        placeholder={options.placeholder || "Search commands..."}/>{options.shortcut && <kbd>Ctrl K</kbd>}</label>
    <div className="sc-direct-palette-summary" aria-live="polite">{filtered.length} command{filtered.length === 1 ? "" : "s"}</div>
    <div id={`${host.id}-commands`} ref={scroll} className="sc-direct-palette-scroll" role="listbox" aria-label="Available commands">
      {!filtered.length ? <div role="status" className="sc-direct-empty">{options.emptyMessage || "No matching commands."}</div> :
        <div className="sc-direct-palette-space" style={{height: `${virtualizer.getTotalSize()}px`}}>{virtualizer.getVirtualItems().map(row => {
          const item = filtered[row.index];
          return <div key={item.id} id={`${host.id}-command-${item.id}`} role="option" aria-selected={row.index === active}
            aria-disabled={item.disabled || undefined} className={`sc-direct-command${row.index === active ? " is-active" : ""}${item.disabled ? " is-disabled" : ""}`}
            style={{transform: `translateY(${row.start}px)`}} onMouseMove={() => setActive(row.index)} onClick={() => activate(item)}>
            <span><small>{item.group || "Commands"}</small><strong>{item.label}</strong>{item.description && <em>{item.description}</em>}</span>
            {item.shortcut && <kbd>{item.shortcut}</kbd>}</div>;
        })}</div>}
    </div><div className="sc-direct-palette-help"><span>↑↓ Navigate</span><span>Enter Run</span><span>Esc Clear</span></div>
  </div>;
}

const definition = {
  runtimeMajor: 1,
  mount(element, model, context) {
    element.innerHTML = "";
    const root = createRoot(element);
    const handle = { root, model, emit: context.emit };
    root.render(<Palette host={element} model={model} emit={context.emit}/>);
    return handle;
  },
  update(handle, patch, context) {
    handle.model = { ...handle.model, ...patch,
      options: { ...(handle.model.options || {}), ...(patch.options || {}) } };
    handle.emit = context.emit;
    handle.root.render(<Palette host={context.element} model={handle.model} emit={context.emit}/>);
    return handle;
  },
  resize() {},
  destroy(handle) { handle.root.unmount(); }
};
window.ShinyCapabilitiesDirectTransport.register("command_palette_direct", definition);
