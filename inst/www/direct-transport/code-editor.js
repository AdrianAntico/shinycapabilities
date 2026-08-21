import { a as e, i as t, n, o as r, t as i } from "./editor.api-C42HJdlU.js";
import { s as a } from "./wordPartOperations-CdbVIW6A.js";
//#region node_modules/monaco-editor/esm/vs/features/find/register.js
var o = "__monacoFindWidgetTabIndexPatchApplied", s = "__monacoFindWidgetOriginalTabIndex";
function c(e, t) {
	let n = e?._domNode;
	if (!n) return;
	let r = n.querySelectorAll("input, textarea, [tabindex], [role=\"button\"], [role=\"checkbox\"]");
	for (let e of r) if (e instanceof HTMLElement) if (t) {
		if (!(s in e.dataset)) continue;
		let t = e.dataset[s];
		t === "" ? e.removeAttribute("tabindex") : e.tabIndex = Number(t), delete e.dataset[s];
	} else s in e.dataset || (e.dataset[s] = e.getAttribute("tabindex") ?? ""), e.tabIndex = -1;
}
if (!a[o]) {
	let e = a.prototype._reveal, t = a.prototype._hide;
	a.prototype._reveal = function(...t) {
		e.apply(this, t), c(this, !0);
	}, a.prototype._hide = function(...e) {
		t.apply(this, e), c(this, !1);
	}, a[o] = !0;
}
//#endregion
//#region node_modules/monaco-editor/esm/vs/languages/definitions/_.contribution.js
var l = {}, u = {}, d = class e {
	static getOrCreate(t) {
		return u[t] || (u[t] = new e(t)), u[t];
	}
	constructor(e) {
		this._languageId = e, this._loadingTriggered = !1, this._lazyLoadPromise = new Promise((e, t) => {
			this._lazyLoadPromiseResolve = e, this._lazyLoadPromiseReject = t;
		});
	}
	load() {
		return this._loadingTriggered || (this._loadingTriggered = !0, l[this._languageId].loader().then((e) => this._lazyLoadPromiseResolve(e), (e) => this._lazyLoadPromiseReject(e))), this._lazyLoadPromise;
	}
};
function f(e) {
	let t = e.id;
	l[t] = e, r.register(e);
	let n = d.getOrCreate(t);
	r.registerTokensProviderFactory(t, { create: async () => (await n.load()).language }), r.onLanguageEncountered(t, async () => {
		let e = await n.load();
		r.setLanguageConfiguration(t, e.conf);
	});
}
//#endregion
//#region node_modules/monaco-editor/esm/vs/languages/definitions/markdown/register.js
f({
	id: "r",
	extensions: [
		".r",
		".rhistory",
		".rmd",
		".rprofile",
		".rt"
	],
	aliases: ["R", "r"],
	loader: () => import("./r-DF_g8_2l.js")
}), f({
	id: "julia",
	extensions: [".jl"],
	aliases: ["julia", "Julia"],
	loader: () => import("./julia-CVutXSdh.js")
}), f({
	id: "python",
	extensions: [
		".py",
		".rpy",
		".pyw",
		".cpy",
		".gyp",
		".gypi"
	],
	aliases: ["Python", "py"],
	firstLine: "^#!/.*\\bpython[0-9.-]*\\b",
	loader: () => import("./python-dYKiQkNZ.js")
}), f({
	id: "sql",
	extensions: [".sql"],
	aliases: ["SQL"],
	loader: () => import("./sql-DHvzW7ba.js")
}), f({
	id: "yaml",
	extensions: [".yaml", ".yml"],
	aliases: [
		"YAML",
		"yaml",
		"YML",
		"yml"
	],
	mimetypes: ["application/x-yaml", "text/x-yaml"],
	loader: () => import("./yaml-Cesp2-EM.js")
}), f({
	id: "markdown",
	extensions: [
		".md",
		".markdown",
		".mdown",
		".mkdn",
		".mkd",
		".mdwn",
		".mdtxt",
		".mdtext"
	],
	aliases: ["Markdown", "markdown"],
	loader: () => import("./markdown-CCGC2kAW.js")
});
var p = new class {
	constructor(e, t, n) {
		this._onDidChange = new i(), this._languageId = e, this.setDiagnosticsOptions(t), this.setModeConfiguration(n);
	}
	get onDidChange() {
		return this._onDidChange.event;
	}
	get languageId() {
		return this._languageId;
	}
	get modeConfiguration() {
		return this._modeConfiguration;
	}
	get diagnosticsOptions() {
		return this._diagnosticsOptions;
	}
	setDiagnosticsOptions(e) {
		this._diagnosticsOptions = e || /* @__PURE__ */ Object.create(null), this._onDidChange.fire(this);
	}
	setModeConfiguration(e) {
		this._modeConfiguration = e || /* @__PURE__ */ Object.create(null), this._onDidChange.fire(this);
	}
}("json", {
	validate: !0,
	allowComments: !0,
	schemas: [],
	enableSchemaRequest: !1,
	schemaRequest: "warning",
	schemaValidation: "warning",
	comments: "error",
	trailingCommas: "error"
}, {
	documentFormattingEdits: !0,
	documentRangeFormattingEdits: !0,
	completionItems: !0,
	hovers: !0,
	documentSymbols: !0,
	tokens: !0,
	colors: !0,
	foldingRanges: !0,
	diagnostics: !0,
	selectionRanges: !0
});
function m() {
	return import("./jsonMode-Bn5QGl5P.js");
}
r.register({
	id: "json",
	extensions: [
		".json",
		".bowerrc",
		".jshintrc",
		".jscsrc",
		".eslintrc",
		".babelrc",
		".har"
	],
	aliases: ["JSON", "json"],
	mimetypes: ["application/json"]
}), r.onLanguage("json", () => {
	m().then((e) => e.setupMode(p));
});
//#endregion
//#region node_modules/monaco-editor/esm/vs/editor/editor.worker.js?worker
function h(e) {
	return new Worker("" + new URL("assets/editor.worker-9QSOQoZV.js", import.meta.url).href, { name: e?.name });
}
//#endregion
//#region node_modules/monaco-editor/esm/vs/language/json/json.worker.js?worker
function g(e) {
	return new Worker("" + new URL("assets/json.worker-JEhOftSC.js", import.meta.url).href, { name: e?.name });
}
//#endregion
//#region src/code-editor.js
var _ = window.ShinyCapabilitiesDirectTransport;
if (!_) throw Error("Direct Component Transport was not loaded.");
self.MonacoEnvironment = { getWorker(e, t) {
	return t === "json" ? new g() : new h();
} };
var v = Object.freeze([
	"r",
	"julia",
	"python",
	"sql",
	"json",
	"yaml",
	"markdown"
]), y = Object.freeze({
	r: "R",
	julia: "jl",
	python: "py",
	sql: "sql",
	json: "json",
	yaml: "yaml",
	markdown: "md"
}), b = Object.freeze({
	error: n.Error,
	warning: n.Warning,
	information: n.Info,
	info: n.Info,
	hint: n.Hint
}), x = /* @__PURE__ */ new Map(), S = (e) => v.includes(String(e).toLowerCase()) ? String(e).toLowerCase() : "r", C = (e, n, r = "main") => t.parse(`inmemory://shinycapabilities/${encodeURIComponent(e.id)}/${encodeURIComponent(n.documentId || e.id)}-${r}.${y[S(n.language)]}`), w = (e) => e.theme === "dark" ? "vs-dark" : e.theme === "light" ? "vs" : matchMedia("(prefers-color-scheme: dark)").matches ? "vs-dark" : "vs", T = (e, t = 500) => String(e ?? "").slice(0, t), E = () => `${Date.now()}-${Math.random().toString(36).slice(2, 9)}`;
function D(e) {
	return (Array.isArray(e) ? e : []).map((e, t) => ({
		severity: b[String(e.severity || "error").toLowerCase()] || n.Error,
		startLineNumber: Math.max(1, Number(e.startLineNumber || e.line || 1)),
		startColumn: Math.max(1, Number(e.startColumn || e.column || 1)),
		endLineNumber: Math.max(1, Number(e.endLineNumber || e.line || 1)),
		endColumn: Math.max(1, Number(e.endColumn || (e.column || 1) + 1)),
		message: T(e.message || "Diagnostic", 2e3),
		source: e.source ? T(e.source, 100) : "host",
		code: e.code == null ? void 0 : T(e.code, 100),
		tags: void 0,
		relatedInformation: void 0,
		_index: t
	}));
}
function O(t) {
	let r = D(t.model.diagnostics);
	for (let n of t.textModels) e.setModelMarkers(n, "shinycapabilities", r);
	t.statusDiagnostics.textContent = `${r.length} diagnostic${r.length === 1 ? "" : "s"}`, t.statusDiagnostics.classList.toggle("is-error", r.some((e) => e.severity === n.Error));
}
function k(e, t, n) {
	!window.Shiny?.setInputValue || !e.host.id || window.Shiny.setInputValue(`${e.host.id}_${t}`, n, { priority: "event" });
}
function A(e, t) {
	let n = e.editor.getModifiedEditor ? e.editor.getModifiedEditor() : e.editor, r = e.currentModel.getValue(), i = n.getSelection();
	return {
		reason: t,
		language: e.model.language,
		dirty: r !== e.appliedValue,
		conflict: !!e.pendingHost,
		readOnly: !!e.model.readOnly,
		length: r.length,
		lines: e.currentModel.getLineCount(),
		hostRevision: e.hostRevision,
		selection: i ? {
			startLine: i.startLineNumber,
			startColumn: i.startColumn,
			endLine: i.endLineNumber,
			endColumn: i.endColumn
		} : null,
		nonce: E()
	};
}
function j(e, t = "state") {
	let n = e.currentModel.getValue() !== e.appliedValue;
	e.root.classList.toggle("is-dirty", n), e.root.classList.toggle("is-conflict", !!e.pendingHost), e.statusState.textContent = e.pendingHost ? "Conflict" : n ? "Draft" : "Applied", e.applyButton.disabled = !n || !!e.model.readOnly, e.resetButton.disabled = !n && !e.pendingHost || !!e.model.readOnly, e.conflict.hidden = !e.pendingHost, clearTimeout(e.stateTimer), e.stateTimer = setTimeout(() => e.emit("state", A(e, t)), 180);
}
function M(e, t, n = !1) {
	let r = String(t ?? "");
	e.currentModel.getValue() !== r && (n ? (e.currentModel.pushStackElement(), e.currentModel.pushEditOperations([], [{
		range: e.currentModel.getFullModelRange(),
		text: r
	}], () => null), e.currentModel.pushStackElement()) : e.currentModel.setValue(r));
}
function N(e) {
	let t = e.currentModel.getValue();
	e.appliedValue = t, e.pendingHost = null, k(e, "apply", {
		value: t,
		language: e.model.language,
		documentId: e.model.documentId,
		hostRevision: e.hostRevision,
		length: t.length,
		lines: e.currentModel.getLineCount(),
		nonce: E()
	}), j(e, "apply");
}
function P(e) {
	if (!e.pendingHost) return;
	let t = e.pendingHost;
	e.pendingHost = null, e.hostRevision = t.revision, e.appliedValue = t.value, M(e, t.value), j(e, "accept_host");
}
function F(e) {
	e.pendingHost && (e.appliedValue = e.pendingHost.value, e.hostRevision = e.pendingHost.revision, e.pendingHost = null, j(e, "keep_draft"));
}
function I(e) {
	e.completionDisposable?.dispose(), e.completionDisposable = r.registerCompletionItemProvider(e.model.language, {
		triggerCharacters: [
			".",
			"$",
			"_",
			":"
		],
		provideCompletionItems(t, n) {
			if (t !== e.currentModel || !e.model.completionEnabled) return { suggestions: [] };
			let r = E(), i = T(t.getLineContent(n.lineNumber).slice(0, n.column - 1));
			return e.emit("completion_request", {
				requestId: r,
				language: e.model.language,
				documentId: e.model.documentId,
				line: n.lineNumber,
				column: n.column,
				prefix: i,
				nonce: E()
			}), new Promise((i) => {
				let a = setTimeout(() => {
					e.completionRequests.delete(r), i({ suggestions: [] });
				}, 1500);
				e.completionRequests.set(r, {
					resolve: i,
					timer: a,
					model: t,
					position: n
				});
			});
		}
	});
}
function L(e, t, n) {
	let i = e.completionRequests.get(t);
	if (!i) return;
	clearTimeout(i.timer), e.completionRequests.delete(t);
	let a = i.model.getWordUntilPosition(i.position), o = {
		startLineNumber: i.position.lineNumber,
		endLineNumber: i.position.lineNumber,
		startColumn: a.startColumn,
		endColumn: i.position.column
	}, s = (Array.isArray(n) ? n : []).slice(0, 100).map((e) => ({
		label: T(e.label, 200),
		kind: r.CompletionItemKind[e.kind] || r.CompletionItemKind.Text,
		insertText: String(e.insertText ?? e.label ?? ""),
		detail: e.detail ? T(e.detail, 500) : void 0,
		documentation: e.documentation ? T(e.documentation, 1e3) : void 0,
		sortText: e.sortText ? T(e.sortText, 100) : void 0,
		range: o
	}));
	i.resolve({ suggestions: s });
}
function R(e) {
	return {
		automaticLayout: !1,
		readOnly: !!e.readOnly,
		domReadOnly: !!e.readOnly,
		ariaLabel: e.ariaLabel || "Code editor",
		lineNumbers: e.lineNumbers === !1 ? "off" : "on",
		wordWrap: e.wrap ? "on" : "off",
		minimap: { enabled: !!e.minimap },
		tabSize: Number(e.tabSize || 2),
		insertSpaces: e.insertSpaces !== !1,
		scrollBeyondLastLine: !1,
		renderValidationDecorations: "on",
		accessibilitySupport: e.accessibilitySupport || "auto",
		theme: w(e),
		padding: {
			top: 8,
			bottom: 8
		},
		fixedOverflowWidgets: !0,
		readOnlyMessage: { value: e.readOnlyMessage || "This document is read-only." }
	};
}
function z(e, t) {
	e.replaceChildren();
	let n = document.createElement("div");
	n.className = "sc-code-editor";
	let r = document.createElement("div");
	r.className = "sc-code-editor-toolbar", r.setAttribute("role", "toolbar");
	let i = document.createElement("span");
	i.className = "sc-code-editor-title", i.textContent = t.title || "Editor";
	let a = document.createElement("span");
	a.dataset.language = "", a.textContent = t.language.toUpperCase();
	let o = document.createElement("span");
	o.className = "sc-code-editor-spacer";
	let s = document.createElement("button");
	s.type = "button", s.textContent = "Reset";
	let c = document.createElement("button");
	c.type = "button", c.className = "is-primary", c.textContent = "Apply", r.append(i, a, o, s, c);
	let l = document.createElement("div");
	l.className = "sc-code-editor-conflict", l.hidden = !0;
	let u = document.createElement("span");
	u.textContent = "The host has a newer value while this draft has unsaved changes.";
	let d = document.createElement("button");
	d.type = "button", d.textContent = "Use host";
	let f = document.createElement("button");
	f.type = "button", f.textContent = "Keep draft", l.append(u, d, f);
	let p = document.createElement("div");
	p.className = "sc-code-editor-surface";
	let m = document.createElement("div");
	m.className = "sc-code-editor-status", m.setAttribute("role", "status"), m.setAttribute("aria-live", "polite");
	let h = document.createElement("span");
	h.dataset.status = "";
	let g = document.createElement("span");
	return m.append(h, g), n.append(r, l, p, m), e.append(n), {
		root: n,
		surface: p,
		title: i,
		language: a,
		reset: s,
		apply: c,
		conflict: l,
		useHost: d,
		keep: f,
		state: h,
		diagnostics: g
	};
}
function B(t, n, r) {
	let i = {
		...n,
		language: S(n.language)
	};
	i.mode === "diff" && (i.readOnly = i.modifiedReadOnly !== !1);
	let a = z(t, i), o = {
		host: t,
		model: i,
		emit: r.emit,
		root: a.root,
		surface: a.surface,
		statusState: a.state,
		statusDiagnostics: a.diagnostics,
		applyButton: a.apply,
		resetButton: a.reset,
		conflict: a.conflict,
		pendingHost: null,
		appliedValue: String(i.mode === "diff" ? i.modifiedValue ?? i.value ?? "" : i.value ?? ""),
		hostRevision: Number(i.hostRevision || 1),
		completionRequests: /* @__PURE__ */ new Map(),
		textModels: [],
		disposables: []
	};
	if (i.mode === "diff") {
		let n = e.createModel(String(i.originalValue ?? ""), i.language, C(t, i, "original")), r = e.createModel(String(i.modifiedValue ?? i.value ?? ""), i.language, C(t, i, "modified"));
		o.editor = e.createDiffEditor(a.surface, {
			...R(i),
			originalEditable: !1,
			readOnly: i.modifiedReadOnly !== !1,
			renderSideBySide: i.renderSideBySide !== !1,
			diffAlgorithm: "advanced"
		}), o.editor.setModel({
			original: n,
			modified: r
		}), o.currentModel = r, o.textModels = [n, r];
	} else {
		let n = e.createModel(String(i.value ?? ""), i.language, C(t, i));
		o.editor = e.create(a.surface, {
			...R(i),
			model: n
		}), o.currentModel = n, o.textModels = [n];
	}
	return o.disposables.push(o.currentModel.onDidChangeContent(() => j(o, "edit"))), a.apply.addEventListener("click", () => N(o)), a.reset.addEventListener("click", () => {
		o.pendingHost = null, M(o, o.appliedValue), j(o, "reset");
	}), a.useHost.addEventListener("click", () => P(o)), a.keep.addEventListener("click", () => F(o)), I(o), O(o), j(o, "mount"), x.set(t.id, o), o;
}
function V(t, n) {
	if (t.model = {
		...t.model,
		...n
	}, n.language && S(n.language) !== t.currentModel.getLanguageId()) {
		t.model.language = S(n.language);
		for (let n of t.textModels) e.setModelLanguage(n, t.model.language);
		t.root.querySelector("[data-language]").textContent = t.model.language.toUpperCase(), I(t);
	}
	if (n.value != null || n.modifiedValue != null) {
		let e = String(n.value ?? n.modifiedValue), r = Number(n.hostRevision ?? t.hostRevision), i = t.currentModel.getValue() !== t.appliedValue;
		i && e !== t.appliedValue && e !== t.currentModel.getValue() ? (t.pendingHost = {
			value: e,
			revision: r
		}, t.emit("conflict", {
			language: t.model.language,
			hostRevision: r,
			draftLength: t.currentModel.getValueLength(),
			hostLength: e.length,
			nonce: E()
		})) : i || (t.appliedValue = e, t.hostRevision = r, M(t, e));
	}
	return n.originalValue != null && t.editor.getOriginalEditor && t.editor.getOriginalEditor().getModel().setValue(String(n.originalValue)), (t.editor.getModifiedEditor ? t.editor.getModifiedEditor() : t.editor).updateOptions(R(t.model)), t.editor.updateOptions && t.editor.getModifiedEditor && t.editor.updateOptions({
		renderSideBySide: t.model.renderSideBySide !== !1,
		readOnly: t.model.modifiedReadOnly !== !1
	}), e.setTheme(w(t.model)), n.diagnostics && O(t), n.completionRequestId && L(t, n.completionRequestId, n.completions), j(t, "host_update"), t;
}
_.register("code_editor", {
	mount(e, t, n) {
		return B(e, t, n);
	},
	update(e, t, n) {
		return e.emit = n.emit, V(e, t);
	},
	resize(e) {
		e.editor.layout();
	},
	destroy(e) {
		clearTimeout(e.stateTimer), e.completionDisposable?.dispose();
		for (let t of e.completionRequests.values()) clearTimeout(t.timer), t.resolve({ suggestions: [] });
		e.disposables.forEach((e) => e.dispose()), e.editor.dispose(), e.textModels.forEach((e) => e.dispose()), x.delete(e.host.id);
	}
}), window.ShinyCapabilitiesCodeEditor = Object.freeze({
	version: "1.0.0",
	monacoVersion: "0.56.0",
	languages: v,
	liveInstances: () => x.size
});
//#endregion
