import * as monaco from "monaco-editor/editor";
import "monaco-editor/features/register.all";
import "monaco-editor/languages/definitions/r/register";
import "monaco-editor/languages/definitions/julia/register";
import "monaco-editor/languages/definitions/python/register";
import "monaco-editor/languages/definitions/sql/register";
import "monaco-editor/languages/definitions/yaml/register";
import "monaco-editor/languages/definitions/markdown/register";
import "monaco-editor/languages/features/json/register";
import EditorWorker from "monaco-editor/editor/editor.worker?worker";
import JsonWorker from "monaco-editor/language/json/json.worker?worker";
import "./code-editor.css";

const transport = window.ShinyCapabilitiesDirectTransport;
if (!transport) throw new Error("Direct Component Transport was not loaded.");

self.MonacoEnvironment = {
  getWorker(_moduleId, label) {
    return label === "json" ? new JsonWorker() : new EditorWorker();
  }
};

const LANGUAGES = Object.freeze(["r", "julia", "python", "sql", "json", "yaml", "markdown"]);
const EXTENSIONS = Object.freeze({ r: "R", julia: "jl", python: "py", sql: "sql",
  json: "json", yaml: "yaml", markdown: "md" });
const SEVERITY = Object.freeze({ error: monaco.MarkerSeverity.Error,
  warning: monaco.MarkerSeverity.Warning, information: monaco.MarkerSeverity.Info,
  info: monaco.MarkerSeverity.Info, hint: monaco.MarkerSeverity.Hint });
const instances = new Map();

const safeLanguage = value => LANGUAGES.includes(String(value).toLowerCase()) ?
  String(value).toLowerCase() : "r";
const modelUri = (host, model, role = "main") => monaco.Uri.parse(
  `inmemory://shinycapabilities/${encodeURIComponent(host.id)}/${encodeURIComponent(model.documentId || host.id)}-${role}.${EXTENSIONS[safeLanguage(model.language)]}`);
const editorTheme = model => model.theme === "dark" ? "vs-dark" :
  model.theme === "light" ? "vs" : (matchMedia("(prefers-color-scheme: dark)").matches ? "vs-dark" : "vs");
const boundedText = (value, max = 500) => String(value ?? "").slice(0, max);
const nonce = () => `${Date.now()}-${Math.random().toString(36).slice(2, 9)}`;

function normalizeDiagnostics(items) {
  return (Array.isArray(items) ? items : []).map((item, index) => ({
    severity: SEVERITY[String(item.severity || "error").toLowerCase()] || monaco.MarkerSeverity.Error,
    startLineNumber: Math.max(1, Number(item.startLineNumber || item.line || 1)),
    startColumn: Math.max(1, Number(item.startColumn || item.column || 1)),
    endLineNumber: Math.max(1, Number(item.endLineNumber || item.line || 1)),
    endColumn: Math.max(1, Number(item.endColumn || (item.column || 1) + 1)),
    message: boundedText(item.message || "Diagnostic", 2000),
    source: item.source ? boundedText(item.source, 100) : "host",
    code: item.code == null ? undefined : boundedText(item.code, 100),
    tags: undefined,
    relatedInformation: undefined,
    _index: index
  }));
}

function applyDiagnostics(handle) {
  const markers = normalizeDiagnostics(handle.model.diagnostics);
  for (const textModel of handle.textModels) monaco.editor.setModelMarkers(textModel, "shinycapabilities", markers);
  handle.statusDiagnostics.textContent = `${markers.length} diagnostic${markers.length === 1 ? "" : "s"}`;
  handle.statusDiagnostics.classList.toggle("is-error", markers.some(x => x.severity === monaco.MarkerSeverity.Error));
}

function emitDocument(handle, suffix, payload) {
  if (!window.Shiny?.setInputValue || !handle.host.id) return;
  window.Shiny.setInputValue(`${handle.host.id}_${suffix}`, payload, { priority: "event" });
}

function statePayload(handle, reason) {
  const editor = handle.editor.getModifiedEditor ? handle.editor.getModifiedEditor() : handle.editor;
  const value = handle.currentModel.getValue();
  const selection = editor.getSelection();
  return { reason, language: handle.model.language, dirty: value !== handle.appliedValue,
    conflict: !!handle.pendingHost, readOnly: !!handle.model.readOnly,
    length: value.length, lines: handle.currentModel.getLineCount(), hostRevision: handle.hostRevision,
    selection: selection ? { startLine: selection.startLineNumber, startColumn: selection.startColumn,
      endLine: selection.endLineNumber, endColumn: selection.endColumn } : null,
    nonce: nonce() };
}

function renderState(handle, reason = "state") {
  const dirty = handle.currentModel.getValue() !== handle.appliedValue;
  handle.root.classList.toggle("is-dirty", dirty);
  handle.root.classList.toggle("is-conflict", !!handle.pendingHost);
  handle.statusState.textContent = handle.pendingHost ? "Conflict" : dirty ? "Draft" : "Applied";
  handle.applyButton.disabled = !dirty || !!handle.model.readOnly;
  handle.resetButton.disabled = (!dirty && !handle.pendingHost) || !!handle.model.readOnly;
  handle.conflict.hidden = !handle.pendingHost;
  clearTimeout(handle.stateTimer);
  handle.stateTimer = setTimeout(() => handle.emit("state", statePayload(handle, reason)), 180);
}

function setDraftValue(handle, value, preserveUndo = false) {
  const next = String(value ?? "");
  if (handle.currentModel.getValue() === next) return;
  if (preserveUndo) {
    handle.currentModel.pushStackElement();
    handle.currentModel.pushEditOperations([], [{ range: handle.currentModel.getFullModelRange(), text: next }], () => null);
    handle.currentModel.pushStackElement();
  } else handle.currentModel.setValue(next);
}

function applyDraft(handle) {
  const value = handle.currentModel.getValue();
  handle.appliedValue = value;
  handle.pendingHost = null;
  emitDocument(handle, "apply", { value, language: handle.model.language,
    documentId: handle.model.documentId, hostRevision: handle.hostRevision,
    length: value.length, lines: handle.currentModel.getLineCount(), nonce: nonce() });
  renderState(handle, "apply");
}

function useHostValue(handle) {
  if (!handle.pendingHost) return;
  const pending = handle.pendingHost;
  handle.pendingHost = null;
  handle.hostRevision = pending.revision;
  handle.appliedValue = pending.value;
  setDraftValue(handle, pending.value);
  renderState(handle, "accept_host");
}

function keepDraft(handle) {
  if (!handle.pendingHost) return;
  handle.appliedValue = handle.pendingHost.value;
  handle.hostRevision = handle.pendingHost.revision;
  handle.pendingHost = null;
  renderState(handle, "keep_draft");
}

function registerCompletion(handle) {
  handle.completionDisposable?.dispose();
  handle.completionDisposable = monaco.languages.registerCompletionItemProvider(handle.model.language, {
    triggerCharacters: [".", "$", "_", ":"],
    provideCompletionItems(model, position) {
      if (model !== handle.currentModel || !handle.model.completionEnabled) return { suggestions: [] };
      const requestId = nonce();
      const prefix = boundedText(model.getLineContent(position.lineNumber).slice(0, position.column - 1));
      handle.emit("completion_request", { requestId, language: handle.model.language,
        documentId: handle.model.documentId, line: position.lineNumber, column: position.column,
        prefix, nonce: nonce() });
      return new Promise(resolve => {
        const timer = setTimeout(() => { handle.completionRequests.delete(requestId); resolve({ suggestions: [] }); }, 1500);
        handle.completionRequests.set(requestId, { resolve, timer, model, position });
      });
    }
  });
}

function resolveCompletions(handle, requestId, items) {
  const pending = handle.completionRequests.get(requestId);
  if (!pending) return;
  clearTimeout(pending.timer);
  handle.completionRequests.delete(requestId);
  const word = pending.model.getWordUntilPosition(pending.position);
  const range = { startLineNumber: pending.position.lineNumber, endLineNumber: pending.position.lineNumber,
    startColumn: word.startColumn, endColumn: pending.position.column };
  const suggestions = (Array.isArray(items) ? items : []).slice(0, 100).map(item => ({
    label: boundedText(item.label, 200),
    kind: monaco.languages.CompletionItemKind[item.kind] || monaco.languages.CompletionItemKind.Text,
    insertText: String(item.insertText ?? item.label ?? ""),
    detail: item.detail ? boundedText(item.detail, 500) : undefined,
    documentation: item.documentation ? boundedText(item.documentation, 1000) : undefined,
    sortText: item.sortText ? boundedText(item.sortText, 100) : undefined,
    range
  }));
  pending.resolve({ suggestions });
}

function editorOptions(model) {
  return { automaticLayout: false, readOnly: !!model.readOnly, domReadOnly: !!model.readOnly,
    ariaLabel: model.ariaLabel || "Code editor", lineNumbers: model.lineNumbers === false ? "off" : "on",
    wordWrap: model.wrap ? "on" : "off", minimap: { enabled: !!model.minimap },
    tabSize: Number(model.tabSize || 2), insertSpaces: model.insertSpaces !== false,
    scrollBeyondLastLine: false, renderValidationDecorations: "on", accessibilitySupport: model.accessibilitySupport || "auto",
    theme: editorTheme(model), padding: { top: 8, bottom: 8 }, fixedOverflowWidgets: true,
    readOnlyMessage: { value: model.readOnlyMessage || "This document is read-only." } };
}

function makeChrome(host, model) {
  host.replaceChildren();
  const root = document.createElement("div"); root.className = "sc-code-editor";
  const toolbar = document.createElement("div"); toolbar.className = "sc-code-editor-toolbar"; toolbar.setAttribute("role", "toolbar");
  const title = document.createElement("span"); title.className = "sc-code-editor-title"; title.textContent = model.title || "Editor";
  const language = document.createElement("span"); language.dataset.language = ""; language.textContent = model.language.toUpperCase();
  const spacer = document.createElement("span"); spacer.className = "sc-code-editor-spacer";
  const reset = document.createElement("button"); reset.type = "button"; reset.textContent = "Reset";
  const apply = document.createElement("button"); apply.type = "button"; apply.className = "is-primary"; apply.textContent = "Apply";
  toolbar.append(title, language, spacer, reset, apply);
  const conflict = document.createElement("div"); conflict.className = "sc-code-editor-conflict"; conflict.hidden = true;
  const conflictText = document.createElement("span"); conflictText.textContent = "The host has a newer value while this draft has unsaved changes.";
  const useHost = document.createElement("button"); useHost.type = "button"; useHost.textContent = "Use host";
  const keep = document.createElement("button"); keep.type = "button"; keep.textContent = "Keep draft";
  conflict.append(conflictText, useHost, keep);
  const surface = document.createElement("div"); surface.className = "sc-code-editor-surface";
  const status = document.createElement("div"); status.className = "sc-code-editor-status"; status.setAttribute("role", "status"); status.setAttribute("aria-live", "polite");
  const state = document.createElement("span"); state.dataset.status = "";
  const diagnostics = document.createElement("span");
  status.append(state, diagnostics);
  root.append(toolbar, conflict, surface, status); host.append(root);
  return { root, surface, title, language, reset, apply, conflict, useHost, keep, state, diagnostics };
}

function createEditor(host, incoming, context) {
  const model = { ...incoming, language: safeLanguage(incoming.language) };
  if (model.mode === "diff") model.readOnly = model.modifiedReadOnly !== false;
  const chrome = makeChrome(host, model);
  const handle = { host, model, emit: context.emit, root: chrome.root, surface: chrome.surface,
    statusState: chrome.state, statusDiagnostics: chrome.diagnostics, applyButton: chrome.apply,
    resetButton: chrome.reset, conflict: chrome.conflict, pendingHost: null,
    appliedValue: String(model.mode === "diff" ? (model.modifiedValue ?? model.value ?? "") : (model.value ?? "")),
    hostRevision: Number(model.hostRevision || 1),
    completionRequests: new Map(), textModels: [], disposables: [] };
  if (model.mode === "diff") {
    const original = monaco.editor.createModel(String(model.originalValue ?? ""), model.language, modelUri(host, model, "original"));
    const modified = monaco.editor.createModel(String(model.modifiedValue ?? model.value ?? ""), model.language, modelUri(host, model, "modified"));
    handle.editor = monaco.editor.createDiffEditor(chrome.surface, { ...editorOptions(model),
      originalEditable: false, readOnly: model.modifiedReadOnly !== false,
      renderSideBySide: model.renderSideBySide !== false, diffAlgorithm: "advanced" });
    handle.editor.setModel({ original, modified }); handle.currentModel = modified; handle.textModels = [original, modified];
  } else {
    const textModel = monaco.editor.createModel(String(model.value ?? ""), model.language, modelUri(host, model));
    handle.editor = monaco.editor.create(chrome.surface, { ...editorOptions(model), model: textModel });
    handle.currentModel = textModel; handle.textModels = [textModel];
  }
  handle.disposables.push(handle.currentModel.onDidChangeContent(() => renderState(handle, "edit")));
  chrome.apply.addEventListener("click", () => applyDraft(handle));
  chrome.reset.addEventListener("click", () => { handle.pendingHost = null; setDraftValue(handle, handle.appliedValue); renderState(handle, "reset"); });
  chrome.useHost.addEventListener("click", () => useHostValue(handle));
  chrome.keep.addEventListener("click", () => keepDraft(handle));
  registerCompletion(handle); applyDiagnostics(handle); renderState(handle, "mount");
  instances.set(host.id, handle); return handle;
}

function updateEditor(handle, update) {
  handle.model = { ...handle.model, ...update };
  if (update.language && safeLanguage(update.language) !== handle.currentModel.getLanguageId()) {
    handle.model.language = safeLanguage(update.language);
    for (const textModel of handle.textModels) monaco.editor.setModelLanguage(textModel, handle.model.language);
    handle.root.querySelector("[data-language]").textContent = handle.model.language.toUpperCase();
    registerCompletion(handle);
  }
  if (update.value != null || update.modifiedValue != null) {
    const next = String(update.value ?? update.modifiedValue);
    const revision = Number(update.hostRevision ?? handle.hostRevision);
    const dirty = handle.currentModel.getValue() !== handle.appliedValue;
    if (dirty && next !== handle.appliedValue && next !== handle.currentModel.getValue()) {
      handle.pendingHost = { value: next, revision };
      handle.emit("conflict", { language: handle.model.language, hostRevision: revision,
        draftLength: handle.currentModel.getValueLength(), hostLength: next.length, nonce: nonce() });
    } else if (!dirty) {
      handle.appliedValue = next; handle.hostRevision = revision; setDraftValue(handle, next);
    }
  }
  if (update.originalValue != null && handle.editor.getOriginalEditor) {
    handle.editor.getOriginalEditor().getModel().setValue(String(update.originalValue));
  }
  const activeEditor = handle.editor.getModifiedEditor ? handle.editor.getModifiedEditor() : handle.editor;
  activeEditor.updateOptions(editorOptions(handle.model));
  if (handle.editor.updateOptions && handle.editor.getModifiedEditor) handle.editor.updateOptions({
    renderSideBySide: handle.model.renderSideBySide !== false,
    readOnly: handle.model.modifiedReadOnly !== false
  });
  monaco.editor.setTheme(editorTheme(handle.model));
  if (update.diagnostics) applyDiagnostics(handle);
  if (update.completionRequestId) resolveCompletions(handle, update.completionRequestId, update.completions);
  renderState(handle, "host_update"); return handle;
}

transport.register("code_editor", {
  mount(host, model, context) { return createEditor(host, model, context); },
  update(handle, update, context) { handle.emit = context.emit; return updateEditor(handle, update); },
  resize(handle) { handle.editor.layout(); },
  destroy(handle) {
    clearTimeout(handle.stateTimer);
    handle.completionDisposable?.dispose();
    for (const pending of handle.completionRequests.values()) { clearTimeout(pending.timer); pending.resolve({ suggestions: [] }); }
    handle.disposables.forEach(x => x.dispose()); handle.editor.dispose(); handle.textModels.forEach(x => x.dispose());
    instances.delete(handle.host.id);
  }
});

window.ShinyCapabilitiesCodeEditor = Object.freeze({ version: "1.0.0", monacoVersion: "0.56.0",
  languages: LANGUAGES, liveInstances: () => instances.size });
