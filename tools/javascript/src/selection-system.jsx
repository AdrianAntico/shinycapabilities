import React, { useEffect, useLayoutEffect, useMemo, useRef, useState } from "react";
import { createRoot } from "react-dom/client";
import { createPortal } from "react-dom";
import { useVirtualizer } from "@tanstack/react-virtual";
import { autoUpdate, computePosition, flip, offset, shift, size } from "@floating-ui/dom";
import "./selection-system.css";

const metrics = window.ShinyCapabilitiesSelectionMetrics ||= {
  initialized: 0, destroyed: 0, live: 0, subscriptions: 0, publications: 0,
  opened: 0, closed: 0, livePopups: 0, mountedRows: 0, longTasks: []
};
let activeClose = null;
if (window.PerformanceObserver && !window.__scSelectionLongTaskObserver) {
  try { window.__scSelectionLongTaskObserver = new PerformanceObserver(list => list.getEntries().forEach(entry =>
    metrics.longTasks.push({ duration: Math.round(entry.duration * 100) / 100, start: Math.round(entry.startTime) })));
    window.__scSelectionLongTaskObserver.observe({ type: "longtask", buffered: true }); } catch (_) {}
}
const unique = value => [...new Set((Array.isArray(value) ? value : value ? [value] : []).map(String))];
const same = (a, b) => JSON.stringify(unique(a)) === JSON.stringify(unique(b));

function SelectionInput({ host, model }) {
  const multiple = model.multiple !== false;
  const [value, setValue] = useState(unique(model.value));
  const [open, setOpen] = useState(false);
  const [query, setQuery] = useState("");
  const [active, setActive] = useState(0);
  const popupRef = useRef(null), scrollRef = useRef(null), searchRef = useRef(null);
  const triggerRef = useRef(null), cleanupRef = useRef(null);
  useEffect(() => { setValue(unique(model.value)); }, [model.revision, JSON.stringify(model.value)]);
  useEffect(() => { host._selectionValue = value.slice(); }, [host, value]);

  const selected = useMemo(() => new Set(value), [value]);
  const rows = useMemo(() => {
    const needle = query.trim().toLocaleLowerCase();
    const result = [];
    (model.groups || []).forEach(group => {
      const options = (group.options || []).filter(option => !needle ||
        `${option.label || option.value} ${option.search || ""}`.toLocaleLowerCase().includes(needle));
      if (options.length) {
        result.push({ kind: "heading", key: `h:${group.id}`, label: group.label });
        options.forEach(option => result.push({ kind: "option", key: `o:${option.value}`, ...option }));
      }
    });
    return result;
  }, [model.groups, query]);
  const optionRows = rows.filter(row => row.kind === "option");
  const virtualizer = useVirtualizer({ count: rows.length, getScrollElement: () => scrollRef.current,
    estimateSize: index => rows[index]?.kind === "heading" ? 30 : 38, overscan: 8 });
  const virtual = rows.length > (model.virtualThreshold ?? 200);
  const mountedRows = virtual ? virtualizer.getVirtualItems() : rows.map((row, index) => ({
    index, key: row.key, size: row.kind === "heading" ? 30 : 38,
    start: rows.slice(0, index).reduce((total, item) => total + (item.kind === "heading" ? 30 : 38), 0)
  }));
  const totalSize = virtual ? virtualizer.getTotalSize() : mountedRows.reduce((total, item) => total + item.size, 0);
  useEffect(() => { if (open) metrics.mountedRows = mountedRows.length; }, [open, mountedRows.length]);
  useEffect(() => {
    if (!model.serverSearch || !window.Shiny) return;
    const timer = setTimeout(() => Shiny.setInputValue(`${host.id}_search`, query, { priority: "event" }), 180);
    return () => clearTimeout(timer);
  }, [query, model.serverSearch, host.id]);

  const publish = next => {
    const normalized = multiple ? unique(next) : unique(next).slice(0, 1);
    setValue(normalized); host._selectionValue = normalized.slice(); metrics.publications++;
    host.dispatchEvent(new CustomEvent("selection:change", { detail: normalized }));
  };
  const choose = row => {
    if (!row || row.kind !== "option" || row.disabled) return;
    if (!multiple) { publish([row.value]); close(); return; }
    publish(selected.has(String(row.value)) ? value.filter(item => item !== String(row.value)) : [...value, String(row.value)]);
  };
  const applyBulk = command => {
    if (command.scope === "clear") return publish([]);
    const additions = command.scope === "visible" ? optionRows.filter(row => !row.disabled).map(row => row.value) : command.values || [];
    publish(command.replace ? additions : [...value, ...additions]);
  };
  const move = (index, delta) => {
    const target = index + delta; if (target < 0 || target >= value.length) return;
    const next = value.slice(); [next[index], next[target]] = [next[target], next[index]]; publish(next);
  };
  const close = () => { setOpen(false); setQuery(""); metrics.closed++; metrics.livePopups = Math.max(0, metrics.livePopups - 1);
    if (activeClose === close) activeClose = null; requestAnimationFrame(() => triggerRef.current?.focus()); };
  const show = () => { if (model.disabled || model.loading) return; activeClose?.(); activeClose = close;
    setOpen(true); metrics.opened++; metrics.livePopups++; };
  const labelFor = id => model.labels?.[id] || id;
  const stale = value.filter(id => model.stale?.includes(id)).length;
  const summary = !value.length ? (model.emptyLabel || "Nothing selected") : value.length === 1 ? labelFor(value[0]) :
    `${value.length} fields selected${stale ? ` · ${stale} stale` : ""}`;

  useLayoutEffect(() => {
    if (!open || !popupRef.current) return;
    cleanupRef.current = autoUpdate(triggerRef.current, popupRef.current, () => computePosition(triggerRef.current,
      popupRef.current, { placement: "bottom-start", strategy: "fixed", middleware: [offset(6), flip({ padding: 8 }),
        shift({ padding: 8 }), size({ padding: 8, apply({ availableHeight, rects, elements }) {
          Object.assign(elements.floating.style, { width: `${Math.max(280, rects.reference.width)}px`,
            maxHeight: `${Math.max(240, availableHeight)}px` });
        }})] }).then(({ x, y }) => Object.assign(popupRef.current.style,
          { left: `${x}px`, top: `${y}px` })));
    requestAnimationFrame(() => (searchRef.current || popupRef.current)?.focus());
    return () => { cleanupRef.current?.(); cleanupRef.current = null; };
  }, [open]);
  useEffect(() => {
    if (!open) return;
    const outside = event => { if (!popupRef.current?.contains(event.target) && !triggerRef.current?.contains(event.target)) close(); };
    document.addEventListener("pointerdown", outside); return () => document.removeEventListener("pointerdown", outside);
  }, [open]);

  const onKey = event => {
    if (event.key === "Escape") { event.preventDefault(); close(); return; }
    if (event.key === "ArrowDown" || event.key === "ArrowUp") {
      event.preventDefault(); const delta = event.key === "ArrowDown" ? 1 : -1;
      let next = Math.max(0, Math.min(rows.length - 1, active + delta));
      while (rows[next]?.kind !== "option" && next > 0 && next < rows.length - 1) next += delta;
      setActive(next); virtualizer.scrollToIndex(next, { align: "auto" });
    } else if (event.key === "Home") { event.preventDefault(); setActive(0); virtualizer.scrollToIndex(0); }
    else if (event.key === "End") { event.preventDefault(); setActive(rows.length - 1); virtualizer.scrollToIndex(rows.length - 1); }
    else if (event.key === "Enter" || event.key === " ") { event.preventDefault(); choose(rows[active]); }
  };

  const popup = open && createPortal(<div ref={popupRef} className="sc-selection-popup" data-selection-popup={host.id}
    role="dialog" tabIndex="-1" aria-label={model.popupLabel || model.label} onKeyDown={onKey}>
    <div className="sc-selection-search-row">{model.searchable && <input ref={searchRef} type="search" value={query}
      onChange={event => { setQuery(event.target.value); setActive(0); }} placeholder={model.searchPlaceholder || "Search fields"}
      aria-label={model.searchLabel || "Search choices"}/>}<button type="button" onClick={close} aria-label="Close selection">×</button></div>
    {!!model.commands?.length && <div className="sc-selection-commands" role="toolbar" aria-label={model.commandsLabel || "Selection actions"}>
      {model.commands.map(command => <button type="button" key={command.id} onClick={() => applyBulk(command)}>{command.label}</button>)}</div>}
    <div ref={scrollRef} className="sc-selection-scroll" role="listbox" aria-multiselectable={multiple || undefined}
      data-mounted-rows={mountedRows.length} data-virtualized={virtual}>
      <div className="sc-selection-spacer" style={{ height: `${totalSize}px` }}>
        {mountedRows.map(item => { const row = rows[item.index]; return <div key={row.key}
          className={`sc-selection-row is-${row.kind}${item.index === active ? " is-active" : ""}${row.stale ? " is-stale" : ""}`}
          style={{ height: `${item.size}px`, transform: `translateY(${item.start}px)` }} role={row.kind === "heading" ? "presentation" : "option"}
          aria-selected={row.kind === "option" ? selected.has(String(row.value)) : undefined}
          aria-disabled={row.disabled || undefined} onMouseMove={() => setActive(item.index)} onClick={() => choose(row)}>
          {row.kind === "heading" ? row.label : <><span className="sc-selection-check" aria-hidden="true">{selected.has(String(row.value)) ? "✓" : ""}</span><span>{row.label}</span>{row.stale && <span className="sc-selection-stale">Stale</span>}</>}
        </div>; })}
      </div>
    </div><div className="sc-selection-status" role="status">{optionRows.length} matching fields · {value.length} selected</div>
  </div>, document.body);

  return <div className={`sc-selection-shell${!same(value, model.applied) ? " is-dirty" : ""}${model.disabled ? " is-disabled" : ""}`}>
    <label id={`${host.id}-label`}>{model.label}</label>
    <button ref={triggerRef} type="button" className="sc-selection-trigger" onClick={() => open ? close() : show()}
      aria-haspopup="dialog" aria-expanded={open} aria-required={model.required || undefined}
      aria-labelledby={`${host.id}-label ${host.id}-summary`} disabled={model.disabled || model.loading}>
      <span id={`${host.id}-summary`}>{model.loading ? (model.loadingLabel || "Loading fields…") : summary}</span><span aria-hidden="true">⌄</span>
    </button>
    {!same(value, model.applied) && <span className="sc-selection-draft">Draft</span>}
    {model.ordered && !!value.length && <section className="sc-selection-order" aria-label={model.orderLabel || "Selected field order"}>
      <strong>Effective order</strong>{value.length > (model.orderDisplayLimit || 100) &&
        <span className="sc-selection-order-count">Showing first {model.orderDisplayLimit || 100} of {value.length}; search the picker to inspect any field.</span>}
      <ol>{value.slice(0, model.orderDisplayLimit || 100).map((id, index) => <li key={id} tabIndex="0"
        onKeyDown={event => { if (event.altKey && ["ArrowUp", "ArrowDown"].includes(event.key)) { event.preventDefault(); move(index, event.key === "ArrowUp" ? -1 : 1); } }}>
        <span>{labelFor(id)}{model.stale?.includes(id) && " · Stale"}</span><span><button type="button" onClick={() => move(index, -1)} aria-label={`Move ${labelFor(id)} earlier`}>↑</button>
        <button type="button" onClick={() => move(index, 1)} aria-label={`Move ${labelFor(id)} later`}>↓</button></span></li>)}</ol></section>}
    {popup}
  </div>;
}

const binding = new Shiny.InputBinding();
Object.assign(binding, {
  find(scope) { return window.jQuery(scope).find(".sc-selection"); },
  initialize(element) {
    if (element._selectionRoot) return;
    const script = element.querySelector(`script[data-for="${CSS.escape(element.id)}"]`);
    element._selectionModel = JSON.parse(script?.textContent || "{}");
    element._selectionValue = unique(element._selectionModel.value);
    element._selectionRoot = createRoot(element.querySelector(".sc-selection-mount"));
    element._selectionRoot.render(<SelectionInput host={element} model={element._selectionModel}/>); metrics.initialized++; metrics.live++;
  },
  getValue(element) { return element._selectionValue || []; },
  setValue(element, value) { element._selectionModel = { ...element._selectionModel, value: unique(value) };
    element._selectionRoot?.render(<SelectionInput host={element} model={element._selectionModel}/>); },
  subscribe(element, callback) { element._selectionListener = () => callback(); element.addEventListener("selection:change", element._selectionListener); metrics.subscriptions++; },
  unsubscribe(element) { if (element._selectionListener) element.removeEventListener("selection:change", element._selectionListener); element._selectionListener = null; metrics.subscriptions--; },
  receiveMessage(element, message) { element._selectionModel = { ...element._selectionModel, ...message,
    value: message.value === undefined ? element._selectionValue : unique(message.value) };
    element._selectionRoot?.render(<SelectionInput host={element} model={element._selectionModel}/>); },
  getState(element) { return { value: element._selectionValue || [] }; }
});
Shiny.inputBindings.register(binding, "shinycapabilities.selectionInput");

new MutationObserver(records => records.forEach(record => record.removedNodes.forEach(node => {
  const removed = node.nodeType === 1 ? [node, ...node.querySelectorAll?.(".sc-selection") || []] : [];
  removed.filter(element => element.matches?.(".sc-selection")).forEach(element => {
    element._selectionRoot?.unmount(); element._selectionRoot = null; metrics.destroyed++; metrics.live = Math.max(0, metrics.live - 1);
  });
}))).observe(document.documentElement, { childList: true, subtree: true });

window.ShinyCapabilitiesSelectionSystem = { version: "1.0.0", owner: "shinycapabilities.selectionInput", metrics };
