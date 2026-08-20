import React, { useEffect, useMemo, useRef, useState } from "react";
import { createRoot } from "react-dom/client";
import { useVirtualizer } from "@tanstack/react-virtual";
import "./agent-activity-monitor.css";

const instances = new Map();
const attentionStates = new Set(["needs_input", "needs_approval", "needs_human", "failure"]);
const statusSymbols = { running: "▶", completed: "✓", failed: "!", blocked: "!", warning: "△",
  awaiting_human: "◆", waiting: "◷", queued: "○", interrupted: "!", cancelled: "×", paused: "Ⅱ" };
const forbidden = new Set(["thinking", "scratchpad", "hidden_reasoning", "chain_of_thought", "cot",
  "tool_trace", "hidden_trace", "raw_prompt", "raw_response", "credentials", "secret"]);

function publish(element, suffix, payload) {
  if (!window.Shiny?.setInputValue || !element.id) return;
  window.Shiny.setInputValue(`${element.id}_${suffix}`, { ...payload, timestamp: new Date().toISOString() }, { priority: "event" });
}

const arrays = value => Array.isArray(value) ? value : [];
const boundedEvents = (events, maximum) => arrays(events).slice(-Math.max(0, maximum || 500));
const safeEntries = value => Object.entries(value || {}).filter(([key]) => !forbidden.has(key.toLowerCase()));
const timeLabel = value => {
  if (!value) return "Not supplied";
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? String(value) : new Intl.DateTimeFormat(undefined,
    { dateStyle: "medium", timeStyle: "medium" }).format(date);
};
const statusClass = status => String(status || "unknown").toLowerCase().replace(/[^a-z0-9_-]/g, "-");

function Status({ value, attention }) {
  const label = String(value || "unknown").replaceAll("_", " ");
  return <span className={`sc-am-status is-${statusClass(value)}${attention ? " has-attention" : ""}`}>
    <span aria-hidden="true">{statusSymbols[value] || "•"}</span><span>{label}</span>
  </span>;
}

function Summary({ model }) {
  const supplied = model.summary || {};
  const computed = useMemo(() => {
    const work = arrays(model.workItems);
    return {
      active: work.filter(item => item.status === "running").length,
      queued: work.filter(item => ["queued", "ready", "planning"].includes(item.status)).length,
      awaiting_review: work.filter(item => attentionStates.has(item.attention)).length,
      failed: work.filter(item => ["failed", "blocked", "interrupted"].includes(item.status)).length
    };
  }, [model.workItems]);
  const entries = ["active", "queued", "awaiting_review", "failed", "completed"]
    .filter(key => supplied[key] !== undefined || computed[key] !== undefined)
    .map(key => [key, supplied[key] ?? computed[key]]);
  return <section className="sc-am-summary" aria-label="System summary">
    {entries.map(([key, value]) => <div key={key} className={`sc-am-metric is-${key}`}>
      <span>{key.replaceAll("_", " ")}</span><strong>{value}</strong>
    </div>)}
    {supplied.throughput !== undefined && <div className="sc-am-metric"><span>throughput</span><strong>{supplied.throughput}</strong></div>}
    {supplied.median_latency !== undefined && <div className="sc-am-metric"><span>median latency</span><strong>{supplied.median_latency}</strong></div>}
  </section>;
}

function VirtualRows({ rows, selectedId, onSelect, kind, rowHeight = 62 }) {
  const scrollRef = useRef(null);
  const [activeIndex, setActiveIndex] = useState(0);
  const virtualizer = useVirtualizer({ count: rows.length, getScrollElement: () => scrollRef.current,
    estimateSize: () => rowHeight, overscan: 10 });
  useEffect(() => { if (activeIndex >= rows.length) setActiveIndex(Math.max(0, rows.length - 1)); }, [activeIndex, rows.length]);
  const key = item => item.work_id || item.event_id;
  const move = (event, offset) => {
    event.preventDefault();
    const next = Math.max(0, Math.min(rows.length - 1, activeIndex + offset));
    setActiveIndex(next); virtualizer.scrollToIndex(next, { align: "auto" });
  };
  return <div ref={scrollRef} className="sc-am-scroll" role={kind === "event" ? "feed" : "listbox"}
    aria-label={kind === "event" ? "Activity feed" : "Activity overview"}>
    {!rows.length && <div className="sc-am-empty" role="status">No matching activity.</div>}
    <div className="sc-am-virtual" style={{ height: virtualizer.getTotalSize() }}>
      {virtualizer.getVirtualItems().map(virtual => {
        const item = rows[virtual.index]; const id = key(item); const attention = attentionStates.has(item.attention);
        return <button key={id} type="button" role={kind === "event" ? "article" : "option"}
          aria-selected={kind === "event" ? undefined : selectedId === id}
          tabIndex={virtual.index === activeIndex ? 0 : -1}
          className={`sc-am-row ${selectedId === id ? "is-selected" : ""} ${attention ? "has-attention" : ""}`}
          style={{ transform: `translateY(${virtual.start}px)`, height: virtual.size }}
          onFocus={() => setActiveIndex(virtual.index)} onClick={() => onSelect(item, kind)}
          onKeyDown={event => {
            if (event.key === "ArrowDown") move(event, 1);
            else if (event.key === "ArrowUp") move(event, -1);
            else if (event.key === "Home") move(event, -rows.length);
            else if (event.key === "End") move(event, rows.length);
            else if (event.key === "Enter" || event.key === " ") { event.preventDefault(); onSelect(item, kind); }
          }}>
          <span className="sc-am-row-main">
            <strong>{kind === "event" ? item.summary : item.label}</strong>
            <small>{kind === "event" ? `${item.event_type} · ${timeLabel(item.occurred_at)}` :
              `${item.kind} · ${item.source_contract}${item.progress_label ? ` · ${item.progress_label}` : ""}`}</small>
          </span>
          <Status value={kind === "event" ? item.severity : item.status} attention={attention}/>
          {attention && <span className="sc-am-attention-copy">Attention: {item.attention.replaceAll("_", " ")}</span>}
        </button>;
      })}
    </div>
  </div>;
}

function Inspector({ selected, actors, work, onNavigate }) {
  if (!selected) return <aside className="sc-am-inspector" aria-label="Activity inspector"><div className="sc-am-empty">Select activity to inspect it.</div></aside>;
  const actor = actors.find(item => item.actor_id === selected.actor_id);
  const related = work.filter(item => item.parent_id === selected.work_id || arrays(item.dependency_ids).includes(selected.work_id));
  const outputs = arrays(selected.output_ids);
  const metadata = safeEntries(selected.metadata).slice(0, 20);
  return <aside className="sc-am-inspector" aria-label="Activity inspector" aria-live="polite">
    <header><span className="sc-am-eyebrow">{selected.kind || selected.event_type || actor?.actor_type || "Activity"}</span>
      <h3>{selected.label || selected.summary || actor?.title || "Activity detail"}</h3></header>
    {selected.status && <Status value={selected.status} attention={attentionStates.has(selected.attention)}/>}
    <dl>
      {actor && <><dt>Actor</dt><dd>{actor.title} · {actor.role_id}</dd></>}
      {selected.raw_status && <><dt>Host state</dt><dd>{selected.raw_status}</dd></>}
      {selected.source_contract && <><dt>Source</dt><dd>{selected.source_contract}</dd></>}
      {selected.capability_id && <><dt>Capability</dt><dd>{selected.capability_id}</dd></>}
      {selected.authority_ref && <><dt>Authority</dt><dd>{selected.authority_ref}</dd></>}
      {selected.started_at && <><dt>Started</dt><dd>{timeLabel(selected.started_at)}</dd></>}
      {selected.ended_at && <><dt>Ended</dt><dd>{timeLabel(selected.ended_at)}</dd></>}
      {selected.error_summary && <><dt>Error</dt><dd className="sc-am-error">{selected.error_summary}</dd></>}
      {arrays(selected.dependency_ids).length > 0 && <><dt>Dependencies</dt><dd>{selected.dependency_ids.join(", ")}</dd></>}
      {related.length > 0 && <><dt>Dependents</dt><dd>{related.map(item => item.work_id).join(", ")}</dd></>}
      {!selected.progress_label && selected.progress_value == null && <><dt>Progress</dt><dd>Not supplied by host</dd></>}
      {metadata.map(([key, value]) => <React.Fragment key={key}><dt>{key.replaceAll("_", " ")}</dt><dd>{typeof value === "object" ? JSON.stringify(value) : String(value)}</dd></React.Fragment>)}
    </dl>
    {outputs.length > 0 && <section><h4>Produced outputs</h4>{outputs.map(id => <button key={id} type="button"
      className="sc-am-link" onClick={() => onNavigate(id, "output")}>{id}</button>)}</section>}
  </aside>;
}

function Topology({ work, selectedId, onSelect }) {
  const related = work.filter(item => item.parent_id || arrays(item.dependency_ids).length);
  return <div className="sc-am-topology" role="tree" aria-label="Dependency topology">
    {!related.length && <div className="sc-am-empty" role="status">No host-supplied relationships.</div>}
    {related.map(item => <button type="button" role="treeitem" key={item.work_id}
      aria-selected={selectedId === item.work_id} className={selectedId === item.work_id ? "is-selected" : ""}
      onClick={() => onSelect(item, "work")}>
      <span><strong>{item.label}</strong><small>{item.work_id}</small></span>
      <span className="sc-am-edge-copy">{item.parent_id ? `Parent: ${item.parent_id}` : ""}
        {arrays(item.dependency_ids).length ? ` Depends on: ${item.dependency_ids.join(", ")}` : ""}</span>
    </button>)}
  </div>;
}

function Monitor({ element, initial }) {
  const [model, setModel] = useState(initial);
  const [view, setView] = useState(initial.options?.views?.[0] || "overview");
  const [filter, setFilter] = useState("all");
  const [selectedId, setSelectedId] = useState(initial.selectedWorkId || null);
  const pending = useRef(null); const frame = useRef(null);
  useEffect(() => {
    element._agentActivityUpdate = patch => {
      pending.current = { ...(pending.current || {}), ...patch };
      if (frame.current) return;
      frame.current = requestAnimationFrame(() => {
        const next = pending.current || {}; pending.current = null; frame.current = null;
        setModel(current => ({ ...current, ...next,
          events: next.events ? boundedEvents(next.events, next.maxEvents || current.options?.maxEvents) : current.events,
          options: { ...current.options, maxEvents: next.maxEvents || current.options?.maxEvents } }));
        if (next.selectedWorkId) setSelectedId(next.selectedWorkId);
      });
    };
    return () => { delete element._agentActivityUpdate; if (frame.current) cancelAnimationFrame(frame.current); };
  }, [element]);
  const actors = arrays(model.actors); const work = arrays(model.workItems); const events = boundedEvents(model.events, model.options?.maxEvents);
  const visibleWork = useMemo(() => work.filter(item => filter === "all" ||
    (filter === "attention" ? attentionStates.has(item.attention) : item.status === filter)), [filter, work]);
  const selected = work.find(item => item.work_id === selectedId) || events.find(item => item.event_id === selectedId) || actors.find(item => item.actor_id === selectedId);
  const select = (item, kind) => { const id = item.work_id || item.event_id || item.actor_id; setSelectedId(id);
    publish(element, "selection", { type: kind, id, sourceContract: item.source_contract || null }); };
  const changeView = next => { setView(next); publish(element, "view_state", { view: next, filter }); };
  return <div className="sc-am" data-shinycap-component="agent-activity-monitor">
    <Summary model={model}/>
    <div className="sc-am-attention" role="status" aria-live="polite">
      <strong>{work.filter(item => attentionStates.has(item.attention)).length} need attention</strong>
      <span>Approval, input, human judgment, and failures remain distinct in the inspector.</span>
    </div>
    <nav className="sc-am-tabs" role="tablist" aria-label="Monitor views">
      {arrays(model.options?.views).map(name => <button key={name} type="button" role="tab" aria-selected={view === name}
        onClick={() => changeView(name)}>{name}</button>)}
      <label><span className="sc-am-visually-hidden">Filter overview</span><select value={filter}
        onChange={event => { setFilter(event.target.value); publish(element, "view_state", { view, filter: event.target.value }); }}>
        <option value="all">All activity</option><option value="attention">Needs attention</option>
        <option value="running">Running</option><option value="queued">Queued</option>
        <option value="completed">Completed</option><option value="failed">Failed</option>
      </select></label>
    </nav>
    <div className="sc-am-body">
      <main className="sc-am-main" role="tabpanel">
        {view === "overview" && <VirtualRows rows={visibleWork} selectedId={selectedId} onSelect={select} kind="work"/>}
        {view === "activity" && <VirtualRows rows={[...events].reverse()} selectedId={selectedId} onSelect={select} kind="event" rowHeight={70}/>}
        {view === "topology" && <Topology work={work} selectedId={selectedId} onSelect={select}/>}
      </main>
      <Inspector selected={selected} actors={actors} work={work} onNavigate={(id, type) => publish(element, "navigation", { id, type })}/>
    </div>
    {arrays(model.diagnostics).length > 0 && <details className="sc-am-diagnostics"><summary>Projection diagnostics ({model.diagnostics.length})</summary>
      <ul>{model.diagnostics.map((item, index) => <li key={index}>{item}</li>)}</ul></details>}
  </div>;
}

HTMLWidgets.widget({
  name: "agent_activity_monitor", type: "output", factory(element) {
    let root;
    return { renderValue(model) { if (!root) root = createRoot(element); root.render(<Monitor element={element} initial={model}/>);
      instances.set(element.id, element); }, resize() {} };
  }
});

if (window.Shiny) window.Shiny.addCustomMessageHandler("shinycapabilities:agent-activity-monitor:update", message => {
  const element = instances.get(message.id) || document.getElementById(message.id);
  element?._agentActivityUpdate?.(message);
});
