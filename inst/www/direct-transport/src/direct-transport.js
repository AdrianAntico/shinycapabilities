(function () {
  "use strict";
  if (window.ShinyCapabilitiesDirectTransport) return;

  const components = new Map();
  const instances = new Map();
  const pending = new Map();
  const metrics = { mounts: 0, updates: 0, resizes: 0, destroys: 0, errors: 0 };
  let bindingRegistered = false;
  let observer = null;

  const now = () => window.performance?.now?.() || Date.now();
  const findElement = id => document.getElementById(id);
  const bounded = value => {
    const text = JSON.stringify(value ?? null);
    if (text.length <= 16384) return value;
    return { id: value?.id || null, label: value?.label || null,
      truncated: true, nonce: value?.nonce || Date.now() };
  };
  const emit = (element, suffix, value) => {
    if (!window.Shiny?.setInputValue || !element?.id) return;
    window.Shiny.setInputValue(`${element.id}_${suffix}`, bounded(value), { priority: "event" });
  };
  const showError = (element, error) => {
    metrics.errors += 1;
    element.setAttribute("aria-busy", "false");
    element.innerHTML = "";
    const message = document.createElement("div");
    message.className = "sc-direct-error";
    message.setAttribute("role", "alert");
    message.textContent = `Component could not be rendered: ${error?.message || error}`;
    element.appendChild(message);
    console.error("[shinycapabilities direct transport]", error);
  };
  const destroy = element => {
    const instance = instances.get(element.id);
    if (!instance) return;
    try { instance.resizeObserver?.disconnect(); instance.definition.destroy?.(instance.handle, element); }
    catch (error) { console.warn("Direct component teardown failed", error); }
    instances.delete(element.id);
    metrics.destroys += 1;
  };
  const deliver = (element, value, source = "render") => {
    const started = now();
    try {
      const type = value?.component || element.dataset.scDirectComponent;
      const definition = components.get(type);
      if (!definition) {
        pending.set(element.id, { element, value, source });
        element.setAttribute("aria-busy", "true");
        return;
      }
      pending.delete(element.id);
      const current = instances.get(element.id);
      if (current && current.type !== type) destroy(element);
      const active = instances.get(element.id);
      if (active) {
        active.handle = definition.update(active.handle, value.payload || {}, {
          element, emit: (suffix, payload) => emit(element, suffix, payload), source,
          revision: value.revision
        }) || active.handle;
        active.revision = value.revision;
        metrics.updates += 1;
      } else {
        element.setAttribute("aria-busy", "true");
        const handle = definition.mount(element, value.payload || {}, {
          element, emit: (suffix, payload) => emit(element, suffix, payload), source,
          revision: value.revision
        });
        const resizeObserver = new ResizeObserver(entries => {
          const entry = entries[0];
          definition.resize?.(handle, entry?.contentRect, element);
          metrics.resizes += 1;
        });
        resizeObserver.observe(element);
        instances.set(element.id, { type, definition, handle, resizeObserver,
          revision: value.revision });
        metrics.mounts += 1;
      }
      element.setAttribute("aria-busy", "false");
      element.dataset.scDirectRevision = String(value.revision ?? "");
      element.dataset.scDirectLastMs = (now() - started).toFixed(3);
    } catch (error) { showError(element, error); }
  };
  const mountStatic = root => {
    root.querySelectorAll?.(".sc-direct-component-output [data-sc-direct-payload]").forEach(script => {
      const element = script.parentElement;
      if (!element || instances.has(element.id)) return;
      try { deliver(element, JSON.parse(script.textContent || "{}"), "static"); }
      catch (error) { showError(element, error); }
    });
  };
  const registerBinding = () => {
    if (bindingRegistered || !window.Shiny?.OutputBinding || !window.jQuery) return;
    const binding = new window.Shiny.OutputBinding();
    Object.assign(binding, {
      find(scope) { return window.jQuery(scope).find(".sc-direct-component-output"); },
      renderValue(element, value) { deliver(element, value, "shiny-output"); },
      renderError(element, error) { showError(element, error); },
      clearError(element) { element.querySelector(".sc-direct-error")?.remove(); },
      resize(element, width, height) {
        const instance = instances.get(element.id);
        instance?.definition.resize?.(instance.handle, { width, height }, element);
      }
    });
    window.Shiny.outputBindings.register(binding, "shinycapabilities.direct");
    window.Shiny.addCustomMessageHandler("shinycapabilities.direct.update", message => {
      const element = findElement(message.id);
      if (!element) return;
      const current = instances.get(message.id);
      if (current && Number(message.revision) < Number(current.revision || 0)) return;
      const existing = current?.handle?.model || {};
      const payload = { ...existing, ...(message.payload || {}),
        options: { ...(existing.options || {}), ...(message.payload?.options || {}) } };
      deliver(element, { component: message.component, payload, revision: message.revision }, "custom-message");
    });
    bindingRegistered = true;
  };
  const observeRemoval = () => {
    if (observer || !document.body) return;
    observer = new MutationObserver(records => records.forEach(record => record.removedNodes.forEach(node => {
      if (!(node instanceof Element)) return;
      if (node.matches?.(".sc-direct-component-output")) destroy(node);
      node.querySelectorAll?.(".sc-direct-component-output").forEach(destroy);
    })));
    observer.observe(document.body, { childList: true, subtree: true });
  };
  const initialize = () => { registerBinding(); observeRemoval(); mountStatic(document); };

  window.ShinyCapabilitiesDirectTransport = {
    version: "1.1.0",
    register(name, definition) {
      if (!name || !definition?.mount || !definition?.update || !definition?.destroy) {
        throw new Error("Direct components require mount, update, and destroy methods.");
      }
      if (definition.runtimeMajor != null) {
        const runtime = window.ShinyCapabilitiesBrowserRuntimeV1;
        if (!runtime) throw new Error(`Component ${name} requires the shared browser runtime.`);
        runtime.assertCompatible(definition.runtimeMajor);
      }
      components.set(name, definition);
      for (const [id, item] of pending) {
        const type = item.value?.component || item.element?.dataset?.scDirectComponent;
        if (type === name && item.element?.isConnected) deliver(item.element, item.value, item.source);
        else if (!item.element?.isConnected) pending.delete(id);
      }
      mountStatic(document);
    },
    emit,
    destroyById(id) { const element = findElement(id); if (element) destroy(element); },
    diagnostics() { return { ...metrics, liveInstances: instances.size,
      registeredComponents: Array.from(components.keys()), bindingRegistered }; }
  };
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", initialize, { once: true });
  else initialize();
  document.addEventListener("shiny:connected", initialize);
})();
