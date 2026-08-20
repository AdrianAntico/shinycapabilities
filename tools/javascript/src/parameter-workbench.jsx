import React, { useEffect, useMemo, useRef, useState } from "react";
import { createRoot } from "react-dom/client";
import "./parameter-workbench.css";

const equal = (a, b) => JSON.stringify(a) === JSON.stringify(b);
const nonce = (() => { let value = 0; return () => `${Date.now()}-${++value}`; })();
const choiceValues = field => (field.choices || []).map(choice => choice.value);

function validate(schema, values) {
  const errors = [];
  schema.forEach(field => {
    const value = values[field.key];
    const empty = value === null || value === undefined || (typeof value === "string" && value.trim() === "") || (Array.isArray(value) && !value.length);
    if (field.required && empty) errors.push({ key: field.key, code: "required", message: `${field.label} is required.` });
    if (empty) return;
    if (["numeric", "integer", "slider", "range"].includes(field.type)) {
      const numbers = Array.isArray(value) ? value : [value];
      if (numbers.some(item => typeof item !== "number" || !Number.isFinite(item)))
        errors.push({ key: field.key, code: "type", message: `${field.label} must be numeric.` });
      else {
        if (field.type === "integer" && numbers.some(item => !Number.isInteger(item))) errors.push({ key: field.key, code: "integer", message: `${field.label} must be an integer.` });
        if (field.min != null && numbers.some(item => item < field.min)) errors.push({ key: field.key, code: "min", message: `${field.label} must be at least ${field.min}.` });
        if (field.max != null && numbers.some(item => item > field.max)) errors.push({ key: field.key, code: "max", message: `${field.label} must be at most ${field.max}.` });
      }
    }
    if (["choice", "multi_choice"].includes(field.type)) {
      const allowed = choiceValues(field).map(String);
      const selected = (Array.isArray(value) ? value : [value]).map(String);
      if (selected.some(item => !allowed.includes(item))) errors.push({ key: field.key, code: "choice", message: `${field.label} contains an unavailable choice.` });
    }
    if (field.type === "boolean" && typeof value !== "boolean") errors.push({ key: field.key, code: "type", message: `${field.label} must be true or false.` });
    if (field.type === "date" && !/^\d{4}-\d{2}-\d{2}$/.test(String(value))) errors.push({ key: field.key, code: "date", message: `${field.label} must be a valid date.` });
  });
  return errors;
}

const conditionMet = (condition, values) => {
  if (!condition) return true;
  const current = values[condition.key];
  return condition.operator === "equals" ? equal(current, condition.value) : (condition.value || []).some(value => equal(current, value));
};

function Field({ field, value, error, onChange, enabled }) {
  const id = `${field._host}-${field.key}`;
  const disabled = !enabled || field.disabled;
  const common = { id, disabled, readOnly: field.readOnly, "aria-invalid": !!error,
    "aria-describedby": `${id}-description${error ? ` ${id}-error` : ""}` };
  let control;
  if (field.type === "boolean") control = <input {...common} type="checkbox" checked={!!value} onChange={event => onChange(event.target.checked)} />;
  else if (field.type === "choice") control = <select {...common} value={value ?? ""} onChange={event => onChange(event.target.value)}><option value="">Select...</option>{field.choices.map(choice => <option key={String(choice.value)} value={choice.value}>{choice.label}</option>)}</select>;
  else if (field.type === "multi_choice") control = <select {...common} multiple value={value || []} onChange={event => onChange([...event.target.selectedOptions].map(option => option.value))}>{field.choices.map(choice => <option key={String(choice.value)} value={choice.value}>{choice.label}</option>)}</select>;
  else if (field.type === "range") control = <div className="sc-pw-range">{[0, 1].map(index => <input key={index} {...common} id={`${id}-${index}`} type="number" min={field.min} max={field.max} step={field.step || "any"} value={(value || [field.min, field.max])[index]} onChange={event => { const next = [...(value || [field.min, field.max])]; next[index] = Number(event.target.value); onChange(next); }} aria-label={`${field.label} ${index ? "maximum" : "minimum"}`} />)}</div>;
  else if (field.type === "slider") control = <div className="sc-pw-slider"><input {...common} type="range" min={field.min} max={field.max} step={field.step || 1} value={value ?? field.min} onChange={event => onChange(Number(event.target.value))}/><output>{value}</output></div>;
  else {
    const type = field.type === "text" ? "text" : field.type === "date" ? "date" : field.type === "datetime" ? "datetime-local" : "number";
    control = <input {...common} type={type} min={field.min} max={field.max} step={field.type === "integer" ? 1 : (field.step || "any")} value={value ?? ""} onChange={event => onChange(["numeric", "integer"].includes(field.type) ? (event.target.value === "" ? null : Number(event.target.value)) : event.target.value)} />;
  }
  return <div className={`sc-pw-field${error ? " is-invalid" : ""}${field.readOnly ? " is-readonly" : ""}`}>
    <label htmlFor={id}>{field.label}{field.required && <span aria-hidden="true"> *</span>}</label>
    {control}
    {field.description && <small id={`${id}-description`}>{field.description}</small>}
    {error && <small id={`${id}-error`} className="sc-pw-error" role="alert">{error.message}</small>}
  </div>;
}

function Workbench({ host, initialModel }) {
  const [model, setModel] = useState(initialModel);
  const [applied, setApplied] = useState(initialModel.values || {});
  const [draft, setDraft] = useState(initialModel.values || {});
  const [query, setQuery] = useState("");
  const [collapsed, setCollapsed] = useState(new Set());
  const [conflict, setConflict] = useState(false);
  const eventRef = useRef(null);
  const schema = model.schema || [];
  const errors = useMemo(() => validate(schema.filter(field => conditionMet(field.condition, draft)), draft), [schema, draft]);
  const dirty = !equal(draft, applied), valid = errors.length === 0;

  const publish = event => {
    eventRef.current = event;
    host._pwValue = { draft, applied, valid, dirty, errors, conflict, event };
    host.dispatchEvent(new CustomEvent("parameter-workbench:change"));
  };
  useEffect(() => { host._pwController = message => {
    setModel(previous => ({ ...previous, ...message }));
    if (message.values !== undefined) {
      if (!dirty || message.conflictPolicy === "replace") { setApplied(message.values); setDraft(message.values); setConflict(false); }
      else { setApplied(message.values); setConflict(true); }
    }
  }; return () => { delete host._pwController; }; }, [dirty, host]);
  useEffect(() => {
    host._pwValue = { draft, applied, valid, dirty, errors, conflict, event: eventRef.current };
    const timer = window.setTimeout(() => host.dispatchEvent(new CustomEvent("parameter-workbench:change")), 120);
    return () => window.clearTimeout(timer);
  }, [applied, conflict, dirty, draft, errors, host, valid]);

  const sections = useMemo(() => {
    const term = query.trim().toLowerCase(), groups = new Map();
    schema.filter(field => conditionMet(field.condition, draft)).filter(field => !term || `${field.label} ${field.key} ${field.description} ${field.section}`.toLowerCase().includes(term)).forEach(field => {
      if (!groups.has(field.section)) groups.set(field.section, []); groups.get(field.section).push({ ...field, _host: host.id });
    }); return [...groups.entries()];
  }, [draft, host.id, query, schema]);
  const update = (key, value) => setDraft(previous => ({ ...previous, [key]: value }));
  const apply = () => { if (!valid) { host.querySelector("[aria-invalid=true]")?.focus(); return; } const next = { type: "apply", nonce: nonce(), values: draft }; setApplied(draft); setConflict(false); publish(next); };
  const reset = () => { setDraft(applied); setConflict(false); publish({ type: "reset", nonce: nonce(), values: applied }); };

  return <section className="sc-pw" aria-labelledby={`${host.id}-title`} data-dirty={dirty} data-valid={valid}>
    <header><div><h2 id={`${host.id}-title`}>{model.title || "Parameters"}</h2>{model.subtitle && <p>{model.subtitle}</p>}</div><div className="sc-pw-state" aria-live="polite"><span className={valid ? "is-valid" : "is-invalid"}>{valid ? "Valid" : `${errors.length} issue${errors.length === 1 ? "" : "s"}`}</span>{dirty && <span className="is-dirty">Unapplied changes</span>}{conflict && <span className="is-conflict">Host values changed</span>}</div></header>
    {model.searchable !== false && schema.length > 12 && <label className="sc-pw-search"><span className="sc-pw-visually-hidden">Search parameters</span><input type="search" value={query} onChange={event => setQuery(event.target.value)} placeholder="Search parameters..." /></label>}
    <div className="sc-pw-sections">{sections.map(([section, fields]) => <section key={section} className="sc-pw-section"><button type="button" className="sc-pw-section-toggle" aria-expanded={!collapsed.has(section)} onClick={() => setCollapsed(previous => { const next = new Set(previous); next.has(section) ? next.delete(section) : next.add(section); return next; })}><span>{section}</span><small>{fields.length} parameters</small></button>{!collapsed.has(section) && <div className="sc-pw-fields">{fields.map(field => <Field key={field.key} field={field} value={draft[field.key]} error={errors.find(error => error.key === field.key)} onChange={value => update(field.key, value)} enabled={model.enabled !== false} />)}</div>}</section>)}</div>
    {!sections.length && <p className="sc-pw-empty">No matching parameters.</p>}
    <footer><span>{dirty ? "Draft differs from applied configuration." : "Applied configuration is current."}</span><div><button type="button" onClick={reset} disabled={!dirty}>Reset</button><button type="button" className="is-primary" onClick={apply} disabled={!dirty || !valid || model.enabled === false}>Apply</button></div></footer>
  </section>;
}

const binding = new Shiny.InputBinding();
Object.assign(binding, {
  find(scope) { return window.jQuery(scope).find(".sc-parameter-workbench"); },
  initialize(element) { if (element._pwRoot) return; const script = element.querySelector(`script[data-for="${CSS.escape(element.id)}"]`); const model = JSON.parse(script?.textContent || "{}"); element._pwValue = { draft: {}, applied: {}, valid: false, dirty: false, errors: [], conflict: false, event: null }; element._pwRoot = createRoot(element.querySelector(".sc-parameter-workbench-mount")); element._pwRoot.render(<Workbench host={element} initialModel={model} />); },
  getValue(element) { return element._pwValue; },
  subscribe(element, callback) { element._pwListener = () => callback(); element.addEventListener("parameter-workbench:change", element._pwListener); },
  unsubscribe(element) { element.removeEventListener("parameter-workbench:change", element._pwListener); },
  receiveMessage(element, message) { element._pwController?.(message); },
  getState(element) { return element._pwValue; }
});
Shiny.inputBindings.register(binding, "shinycapabilities.parameterWorkbench");
if (window.Shiny) window.Shiny.addCustomMessageHandler("shinycapabilities:parameter-workbench:update", message => document.getElementById(message.id)?._pwController?.(message));
