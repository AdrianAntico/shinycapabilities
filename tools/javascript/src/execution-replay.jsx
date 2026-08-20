import React, { useEffect, useMemo, useRef, useState } from "react";
import { createRoot } from "react-dom/client";
import { useVirtualizer } from "@tanstack/react-virtual";
import "./execution-replay.css";

const instances = new Map();
const arrays = value => Array.isArray(value) ? value : [];
const forbidden = new Set(["thinking", "scratchpad", "hidden_reasoning", "chain_of_thought", "cot",
  "tool_trace", "hidden_trace", "raw_prompt", "raw_response", "credentials", "credential", "password", "token", "secret"]);
const importantTypes = new Set(["failure", "failed", "retry", "intervention", "review", "attention"]);
const symbols = { start: "▶", started: "▶", completion: "✓", completed: "✓", failure: "!", failed: "!",
  retry: "↻", intervention: "◆", review: "◇", attention: "△", artifact: "▣", evidence: "◈", state_transition: "→" };

function publish(element, suffix, payload) {
  if (!window.Shiny?.setInputValue || !element.id) return;
  element._executionReplayNonce = (element._executionReplayNonce || 0) + 1;
  window.Shiny.setInputValue(`${element.id}_${suffix}`, { ...payload,
    nonce: element._executionReplayNonce, emitted_at: new Date().toISOString() }, { priority: "event" });
}

const safeEntries = value => Object.entries(value || {}).filter(([key]) => !forbidden.has(key.toLowerCase())).slice(0, 24);
const labelize = value => String(value || "unknown").replaceAll("_", " ");
const className = value => String(value || "unknown").toLowerCase().replace(/[^a-z0-9_-]/g, "-");
const timeLabel = value => {
  if (!value) return "Time not supplied";
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? String(value) : new Intl.DateTimeFormat(undefined,
    { dateStyle: "medium", timeStyle: "medium" }).format(date);
};
const eventSymbol = type => symbols[String(type || "").toLowerCase()] || "•";
const atSequence = (record, sequence) => Number(record.sequence) <= Number(sequence);

function mergeById(current, incoming, key, maximum) {
  const map = new Map(arrays(current).map(item => [item[key], item]));
  arrays(incoming).forEach(item => map.set(item[key], item));
  const merged = [...map.values()].sort((a, b) => Number(a.sequence) - Number(b.sequence) || String(a[key]).localeCompare(String(b[key])));
  return maximum ? merged.slice(-maximum) : merged;
}

function stateAt(snapshots, related, sequence) {
  const latest = new Map();
  arrays(snapshots).filter(item => atSequence(item, sequence)).forEach(item => {
    const prior = latest.get(item.entity_id);
    if (!prior || Number(prior.sequence) <= Number(item.sequence)) latest.set(item.entity_id, item);
  });
  return { states: [...latest.values()].sort((a, b) => a.entity_id.localeCompare(b.entity_id)),
    related: arrays(related).filter(item => atSequence(item, sequence)) };
}

function changesAt(snapshots, selected) {
  if (!selected) return [];
  const byEntity = new Map();
  arrays(snapshots).filter(item => atSequence(item, selected.sequence)).forEach(item => {
    const list = byEntity.get(item.entity_id) || []; list.push(item); byEntity.set(item.entity_id, list);
  });
  const result = [];
  byEntity.forEach((list, entityId) => {
    list.sort((a, b) => Number(a.sequence) - Number(b.sequence));
    const after = list[list.length - 1];
    if (Number(after.sequence) !== Number(selected.sequence)) return;
    const before = list[list.length - 2];
    if (!before || before.state !== after.state || before.version !== after.version ||
      before.fingerprint !== after.fingerprint || JSON.stringify(before.metadata) !== JSON.stringify(after.metadata)) {
      result.push({ entityId, before, after });
    }
  });
  return result;
}

function Badge({ value, type = "status" }) {
  return <span className={`sc-er-badge is-${className(value)} is-${type}`}>
    <span aria-hidden="true">{type === "event" ? eventSymbol(value) : "•"}</span>{labelize(value)}
  </span>;
}

function EventTimeline({ events, selectedId, onSelect }) {
  const scrollRef = useRef(null);
  const virtualizer = useVirtualizer({ count: events.length, getScrollElement: () => scrollRef.current,
    estimateSize: () => 70, overscan: 12 });
  const active = Math.max(0, events.findIndex(item => item.event_id === selectedId));
  const selectedVisible = events.some(item => item.event_id === selectedId);
  useEffect(() => { if (events.length && active >= 0) virtualizer.scrollToIndex(active, { align: "auto" }); }, [selectedId]);
  const move = (event, index) => {
    event.preventDefault();
    const next = Math.max(0, Math.min(events.length - 1, index));
    if (events[next]) { onSelect(events[next], "keyboard"); virtualizer.scrollToIndex(next, { align: "auto" }); }
  };
  return <div ref={scrollRef} className="sc-er-timeline-scroll" role="listbox" aria-label="Execution timeline"
    aria-activedescendant={selectedVisible ? `sc-er-event-${selectedId}` : undefined} tabIndex={events.length ? undefined : 0}>
    {!events.length && <div className="sc-er-empty" role="status">No events match the current filters.</div>}
    <div className="sc-er-virtual" style={{ height: virtualizer.getTotalSize() }}>
      {virtualizer.getVirtualItems().map(virtual => {
        const item = events[virtual.index]; const selected = item.event_id === selectedId;
        return <button id={`sc-er-event-${item.event_id}`} key={item.event_id} type="button" role="option"
          aria-selected={selected} tabIndex={selected || (!selectedId && virtual.index === 0) ? 0 : -1}
          className={`sc-er-event ${selected ? "is-selected" : ""} is-${className(item.event_type)}`}
          style={{ transform: `translateY(${virtual.start}px)`, height: virtual.size }}
          onClick={() => onSelect(item, "timeline")} onKeyDown={event => {
            if (event.key === "ArrowDown" || event.key === "ArrowRight") move(event, virtual.index + 1);
            else if (event.key === "ArrowUp" || event.key === "ArrowLeft") move(event, virtual.index - 1);
            else if (event.key === "Home") move(event, 0);
            else if (event.key === "End") move(event, events.length - 1);
            else if (event.key === "Enter" || event.key === " ") { event.preventDefault(); onSelect(item, "keyboard"); }
          }}>
          <span className="sc-er-marker" aria-hidden="true">{eventSymbol(item.event_type)}</span>
          <span className="sc-er-event-copy"><strong>{item.summary}</strong>
            <small>#{item.sequence} · {timeLabel(item.occurred_at)}{item.actor_id ? ` · ${item.actor_id}` : ""}</small></span>
          <Badge value={item.event_type} type="event"/>
        </button>;
      })}
    </div>
  </div>;
}

function Details({ title, record, onNavigate }) {
  if (!record) return <div className="sc-er-empty">{title} is not available at this position.</div>;
  const ignored = new Set(["metadata", "entity_ids", "artifact_ids", "evidence_ids", "related_ids"]);
  const entries = Object.entries(record).filter(([key, value]) => !ignored.has(key) && value !== "" && value != null);
  const links = [
    ...arrays(record.entity_ids).map(id => [id, "entity"]),
    ...arrays(record.artifact_ids).map(id => [id, "artifact"]),
    ...arrays(record.evidence_ids).map(id => [id, "evidence"]),
    ...arrays(record.related_ids).map(id => [id, "related"])
  ];
  return <div className="sc-er-details"><h3>{title}</h3><dl>
    {entries.map(([key, value]) => <React.Fragment key={key}><dt>{labelize(key)}</dt><dd>{String(value)}</dd></React.Fragment>)}
    {safeEntries(record.metadata).map(([key, value]) => <React.Fragment key={`m-${key}`}><dt>{labelize(key)}</dt>
      <dd>{typeof value === "object" ? JSON.stringify(value) : String(value)}</dd></React.Fragment>)}
  </dl>{links.length > 0 && <section><h4>Related identities</h4>{links.map(([id, type]) =>
    <button className="sc-er-link" type="button" key={`${type}-${id}`} onClick={() => onNavigate(id, type)}>{type}: {id}</button>)}</section>}</div>;
}

function StateAtTime({ projection, selected, selectedRecord, setSelectedRecord, onNavigate }) {
  return <section className="sc-er-state" aria-label="State at selected replay position">
    <header><h3>State at event #{selected?.sequence ?? "-"}</h3><span>{projection.states.length} entities · {projection.related.length} related records</span></header>
    <div className="sc-er-state-groups">
      <div><h4>Entity state</h4>{!projection.states.length && <p className="sc-er-muted">No supplied state existed yet.</p>}
        {projection.states.map(item => <button type="button" key={item.snapshot_id} className={selectedRecord?.snapshot_id === item.snapshot_id ? "is-selected" : ""}
          onClick={() => setSelectedRecord(item)}><span><strong>{item.entity_id}</strong><small>{item.version || item.fingerprint || "No version supplied"}</small></span><Badge value={item.state}/></button>)}</div>
      <div><h4>Artifacts, evidence, and interventions</h4>{!projection.related.length && <p className="sc-er-muted">No supplied related records existed yet.</p>}
        {projection.related.slice(-100).reverse().map(item => <button type="button" key={item.record_id} className={selectedRecord?.record_id === item.record_id ? "is-selected" : ""}
          onClick={() => { setSelectedRecord(item); onNavigate(item.record_id, item.record_type, false); }}><span><strong>{item.label}</strong><small>{item.record_type} · #{item.sequence}</small></span>{item.status && <Badge value={item.status}/>}</button>)}</div>
    </div>
  </section>;
}

function ChangeView({ changes }) {
  return <section className="sc-er-changes" aria-label="Changes at selected replay position"><h3>Changes at this point</h3>
    {!changes.length && <div className="sc-er-empty">No supplied state snapshot changed at this event.</div>}
    {changes.map(change => <article key={change.entityId}><h4>{change.entityId}</h4>
      <div><span>Before</span><strong>{change.before?.state || "Not previously supplied"}</strong>
        <small>{change.before?.version || change.before?.fingerprint || "-"}</small></div>
      <div><span>After</span><strong>{change.after.state}</strong><small>{change.after.version || change.after.fingerprint || "-"}</small></div>
    </article>)}</section>;
}

function Replay({ element, initial }) {
  const [model, setModel] = useState(initial);
  const allEvents = arrays(model.events);
  const initialId = initial.selectedEventId || allEvents[allEvents.length - 1]?.event_id || null;
  const [selectedId, setSelectedId] = useState(initialId);
  const [selectedRecord, setSelectedRecord] = useState(null);
  const [playing, setPlaying] = useState(false);
  const [query, setQuery] = useState("");
  const [typeFilter, setTypeFilter] = useState("all");
  const [sourceFilter, setSourceFilter] = useState("all");
  const [statusFilter, setStatusFilter] = useState("all");
  const [importantOnly, setImportantOnly] = useState(false);
  const pending = useRef(null); const frame = useRef(null);

  useEffect(() => {
    setModel(initial);
    setSelectedId(current => {
      const events = arrays(initial.events);
      if (current && events.some(item => item.event_id === current)) return current;
      return initial.selectedEventId || events.at(-1)?.event_id || null;
    });
    setSelectedRecord(null);
  }, [initial]);

  useEffect(() => {
    element._executionReplayUpdate = patch => {
      pending.current = { ...(pending.current || {}), ...patch };
      if (frame.current) return;
      frame.current = requestAnimationFrame(() => {
        const next = pending.current || {}; pending.current = null; frame.current = null;
        setModel(current => {
          const wasLatest = selectedId === arrays(current.events).at(-1)?.event_id;
          const maximum = next.maxEvents || current.options?.maxEvents || 10000;
          const append = next.mode === "append";
          const events = next.events ? (append ? mergeById(current.events, next.events, "event_id", maximum) : arrays(next.events).slice(-maximum)) : current.events;
          const snapshots = next.snapshots ? (append ? mergeById(current.snapshots, next.snapshots, "snapshot_id") : next.snapshots) : current.snapshots;
          const relatedRecords = next.relatedRecords ? (append ? mergeById(current.relatedRecords, next.relatedRecords, "record_id") : next.relatedRecords) : current.relatedRecords;
          if (next.selectedEventId) setSelectedId(next.selectedEventId);
          else if (wasLatest && events.length) setSelectedId(events.at(-1).event_id);
          return { ...current, ...next, events, snapshots, relatedRecords,
            options: { ...current.options, maxEvents: maximum } };
        });
      });
    };
    return () => { delete element._executionReplayUpdate; if (frame.current) cancelAnimationFrame(frame.current); };
  }, [element, selectedId]);

  const selected = allEvents.find(item => item.event_id === selectedId) || allEvents.at(-1);
  const selectedIndex = Math.max(0, allEvents.findIndex(item => item.event_id === selected?.event_id));
  const latest = selectedIndex === allEvents.length - 1;
  const types = useMemo(() => [...new Set(allEvents.map(item => item.event_type).filter(Boolean))].sort(), [allEvents]);
  const sources = useMemo(() => [...new Set(allEvents.map(item => item.source || item.actor_id).filter(Boolean))].sort(), [allEvents]);
  const statuses = useMemo(() => [...new Set(allEvents.map(item => item.status).filter(Boolean))].sort(), [allEvents]);
  const filtered = useMemo(() => allEvents.filter(item => {
    const text = `${item.summary} ${item.event_type} ${item.actor_id} ${item.source} ${item.status}`.toLowerCase();
    return (!query || text.includes(query.toLowerCase())) && (typeFilter === "all" || item.event_type === typeFilter) &&
      (sourceFilter === "all" || (item.source || item.actor_id) === sourceFilter) &&
      (statusFilter === "all" || item.status === statusFilter) && (!importantOnly || importantTypes.has(item.event_type));
  }), [allEvents, query, typeFilter, sourceFilter, statusFilter, importantOnly]);
  const projection = useMemo(() => stateAt(model.snapshots, model.relatedRecords, selected?.sequence ?? -1),
    [model.snapshots, model.relatedRecords, selected?.sequence]);
  const changes = useMemo(() => changesAt(model.snapshots, selected), [model.snapshots, selected]);

  const select = (event, origin = "control") => {
    if (!event) return; setSelectedId(event.event_id); setSelectedRecord(null);
    publish(element, "position", { execution_id: model.execution.execution_id, event_id: event.event_id,
      sequence: event.sequence, occurred_at: event.occurred_at, origin });
    publish(element, "event_selection", { event_id: event.event_id, sequence: event.sequence, event_type: event.event_type });
  };
  const move = offset => select(allEvents[Math.max(0, Math.min(allEvents.length - 1, selectedIndex + offset))]);
  const returnLatest = () => { const event = allEvents.at(-1); if (event) select(event, "return_to_latest");
    publish(element, "return_to_latest", { execution_id: model.execution.execution_id, latest_event_id: event?.event_id || null }); };
  useEffect(() => {
    if (!playing) return undefined;
    if (latest) { setPlaying(false); return undefined; }
    const timer = setTimeout(() => move(1), model.options?.playbackInterval || 1000);
    return () => clearTimeout(timer);
  }, [playing, selectedIndex, latest]);

  const navigate = (id, type, emit = true) => { if (emit) publish(element, "entity_selection", { id, type, sequence: selected?.sequence ?? null }); };
  const inspected = selectedRecord || selected;
  return <div className="sc-er" data-shinycap-component="execution-replay">
    <header className="sc-er-header"><div><span>Execution replay · {model.execution.type}</span><h2>{model.execution.label}</h2></div>
      <div><Badge value={model.execution.status}/><small>{model.execution.source_mode}</small></div></header>
    <div className="sc-er-controls" aria-label="Replay controls">
      <button type="button" onClick={() => move(-1)} disabled={!allEvents.length || selectedIndex <= 0} aria-label="Previous event">←</button>
      <button type="button" onClick={() => setPlaying(value => !value)} disabled={allEvents.length < 2} aria-pressed={playing}>{playing ? "Pause" : "Play"}</button>
      <button type="button" onClick={() => move(1)} disabled={!allEvents.length || latest} aria-label="Next event">→</button>
      <label className="sc-er-position"><span className="sc-er-visually-hidden">Replay position</span><input type="range" min="0" max={Math.max(0, allEvents.length - 1)} value={selectedIndex}
        onChange={event => select(allEvents[Number(event.target.value)], "slider")}/><output aria-live="polite">Event {allEvents.length ? selectedIndex + 1 : 0} of {allEvents.length}</output></label>
      <button type="button" className="sc-er-latest" onClick={returnLatest} disabled={latest}>Return to latest</button>
    </div>
    <div className="sc-er-filters"><input type="search" value={query} onChange={event => setQuery(event.target.value)} placeholder="Search history" aria-label="Search execution history"/>
      <select value={typeFilter} onChange={event => setTypeFilter(event.target.value)} aria-label="Filter event type"><option value="all">All event types</option>{types.map(value => <option key={value}>{value}</option>)}</select>
      <select value={sourceFilter} onChange={event => setSourceFilter(event.target.value)} aria-label="Filter actor or source"><option value="all">All actors/sources</option>{sources.map(value => <option key={value}>{value}</option>)}</select>
      <select value={statusFilter} onChange={event => setStatusFilter(event.target.value)} aria-label="Filter status"><option value="all">All statuses</option>{statuses.map(value => <option key={value}>{value}</option>)}</select>
      <label><input type="checkbox" checked={importantOnly} onChange={event => setImportantOnly(event.target.checked)}/> Failures, retries, reviews</label></div>
    <main className="sc-er-body">
      <section className="sc-er-timeline"><div className="sc-er-section-title"><h3>Timeline</h3><span>{filtered.length} shown</span></div>
        <EventTimeline events={filtered} selectedId={selected?.event_id} onSelect={select}/></section>
      <section className="sc-er-center"><div className="sc-er-position-summary" role="status" aria-live="polite">
        <span>Selected position</span><strong>#{selected?.sequence ?? "-"} · {selected?.summary || "No events supplied"}</strong>
        <small>{selected ? timeLabel(selected.occurred_at) : ""}{!latest && <em> Historical view · new events will not move this position</em>}</small></div>
        <StateAtTime projection={projection} selected={selected} selectedRecord={selectedRecord} setSelectedRecord={setSelectedRecord} onNavigate={navigate}/>
        <ChangeView changes={changes}/></section>
      <aside className="sc-er-inspector" aria-label="Replay inspector" aria-live="polite"><Details title={selectedRecord ? "Record detail" : "Event detail"} record={inspected} onNavigate={navigate}/></aside>
    </main>
    {arrays(model.diagnostics).length > 0 && <details className="sc-er-diagnostics"><summary>Projection diagnostics ({model.diagnostics.length})</summary><ul>{model.diagnostics.map((item, index) => <li key={index}>{item}</li>)}</ul></details>}
  </div>;
}

HTMLWidgets.widget({ name: "execution_replay", type: "output", factory(element) {
  let root;
  return { renderValue(model) { if (!root) root = createRoot(element); root.render(<Replay element={element} initial={model}/>); instances.set(element.id, element); }, resize() {} };
} });

if (window.Shiny) window.Shiny.addCustomMessageHandler("shinycapabilities:execution-replay:update", message => {
  const element = instances.get(message.id) || document.getElementById(message.id);
  element?._executionReplayUpdate?.(message);
});
