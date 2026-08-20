(function () {
  "use strict";
  const transport = window.ShinyCapabilitiesDirectTransport;
  if (!transport) throw new Error("Direct component transport was not loaded.");
  const stateByElement = new WeakMap();
  const tagFor = type => ({ section: "section", row: "div", text: "p", value: "div",
    badge: "span", field: "label", action: "button" })[type] || "div";
  const setText = (element, text) => { if (element.textContent !== String(text ?? "")) element.textContent = String(text ?? ""); };
  const create = (node, context, local) => {
    const element = document.createElement(tagFor(node.type));
    element.dataset.scPersistentId = node.id; element.dataset.scPersistentType = node.type;
    element.id = `${context.element.id}-node-${node.id}`;
    if (node.type === "section") {
      const heading = document.createElement("button"); heading.type = "button"; heading.className = "sc-persistent-section-toggle";
      heading.setAttribute("aria-controls", `${element.id}-body`);
      const title = document.createElement("strong"); heading.appendChild(title); element.appendChild(heading);
      const body = document.createElement("div"); body.id = `${element.id}-body`; body.className = "sc-persistent-children"; element.appendChild(body);
      heading.addEventListener("click", () => { const current = local.nodeById.get(node.id) || node; local.expanded.set(node.id, !(local.expanded.get(node.id) ?? true)); patch(current, element, context, local);
        context.emit("event", { id: node.id, type: "toggle", expanded: local.expanded.get(node.id), revision: local.revision, source: "user", nonce: Date.now() }); });
    } else if (node.type === "field") {
      const label = document.createElement("span"); label.className = "sc-persistent-label"; element.appendChild(label);
      const input = document.createElement("input"); input.id = `${element.id}-input`; element.appendChild(input);
      input.addEventListener("input", () => {
        const value = input.type === "checkbox" ? input.checked : input.value; local.drafts.set(node.id, value);
        clearTimeout(local.draftTimers.get(node.id)); local.draftTimers.set(node.id, setTimeout(() => context.emit("event", {
          id: node.id, type: "draft", value, revision: local.revision, source: "user", nonce: Date.now()
        }), 180));
      });
      input.addEventListener("change", () => context.emit("event", { id: node.id, type: "change",
        value: input.type === "checkbox" ? input.checked : input.value, revision: local.revision, source: "user", nonce: Date.now() }));
    } else if (node.type === "action") {
      element.type = "button"; element.addEventListener("click", () => context.emit("event", {
        id: node.id, type: "action", revision: local.revision, source: "user", metadata: local.nodeById.get(node.id)?.metadata || {}, nonce: Date.now()
      }));
    } else if (node.type === "row") element.className = "sc-persistent-row sc-persistent-children";
    else if (node.type === "value") {
      const label = document.createElement("span"); label.className = "sc-persistent-label"; element.appendChild(label);
      element.appendChild(document.createElement("strong"));
    }
    return element;
  };
  const patch = (node, element, context, local) => {
    element.hidden = node.visible === false;
    element.classList.toggle("is-disabled", node.enabled === false);
    element.classList.toggle("is-selected", local.selected === node.id || node.selected === true);
    element.dataset.status = node.status || "neutral";
    if (node.type === "section") {
      setText(element.querySelector("strong"), node.label);
      const expanded = local.expanded.has(node.id) ? local.expanded.get(node.id) : node.expanded !== false;
      local.expanded.set(node.id, expanded); const button = element.querySelector("button"), body = element.querySelector(".sc-persistent-children");
      button.setAttribute("aria-expanded", String(expanded)); button.disabled = node.enabled === false; body.hidden = !expanded;
    } else if (node.type === "field") {
      setText(element.querySelector(".sc-persistent-label"), node.label);
      const input = element.querySelector("input"); input.type = node.inputType || "text"; input.disabled = node.enabled === false;
      const priorHost = local.hostValues.get(node.id); if (local.hostValues.has(node.id) && priorHost !== node.value) local.drafts.delete(node.id);
      local.hostValues.set(node.id, node.value); const value = local.drafts.has(node.id) ? local.drafts.get(node.id) : node.value;
      if (input.type === "checkbox") input.checked = Boolean(value); else if (input.value !== String(value ?? "")) input.value = String(value ?? "");
    }
    if (node.type === "value") { setText(element.querySelector("span"), node.label); setText(element.querySelector("strong"), node.value); }
    else if (node.type === "badge") { element.className = `sc-persistent-badge is-${String(node.status || "neutral").replace(/[^a-z0-9-]/gi, "-")}`; setText(element, node.label || node.value); }
    else if (node.type === "text") { setText(element, node.value ?? node.label); }
    else if (node.type === "action") { setText(element, node.label); element.disabled = node.enabled === false; }
    element.title = node.description || "";
  };
  const reconcile = (host, model, context, local) => {
    const started = performance.now(); const scrollTop = host.scrollTop;
    local.revision = context.revision ?? local.revision; const nodes = model.nodes || [], keep = new Set(nodes.map(node => node.id));
    local.nodeById = new Map(nodes.map(node => [node.id, node]));
    local.elements.forEach((element, id) => { if (!keep.has(id)) { element.remove(); local.elements.delete(id); local.expanded.delete(id); local.drafts.delete(id);
      clearTimeout(local.draftTimers.get(id)); local.draftTimers.delete(id); local.hostValues.delete(id); local.removed += 1; } });
    const byParent = new Map(); nodes.forEach(node => { const parent = node.parentId || ""; if (!byParent.has(parent)) byParent.set(parent, []); byParent.get(parent).push(node); });
    byParent.forEach(group => group.sort((a, b) => Number(a.order || 0) - Number(b.order || 0)));
    const place = (parentId, container) => (byParent.get(parentId) || []).forEach((node, position) => {
      let element = local.elements.get(node.id); if (!element) { element = create(node, context, local); local.elements.set(node.id, element); local.added += 1; }
      patch(node, element, context, local);
      if (container.children[position] !== element) container.insertBefore(element, container.children[position] || null);
      local.patched += 1;
      if (node.type === "section") place(node.id, element.querySelector(".sc-persistent-children"));
      else if (node.type === "row") place(node.id, element);
    });
    place("", host); host.scrollTop = scrollTop; host.setAttribute("aria-label", model.options?.ariaLabel || "Dynamic analytical interface");
    host.dataset.scPersistentLastMs = (performance.now() - started).toFixed(3);
  };
  transport.register("persistent_ui", {
    mount(element, model, context) { element.innerHTML = ""; element.classList.add("sc-persistent-ui");
      const local = { elements: new Map(), nodeById: new Map(), expanded: new Map(), drafts: new Map(), draftTimers: new Map(), hostValues: new Map(), selected: null,
        revision: 0, added: 0, removed: 0, patched: 0, model: {} };
      const click = event => { const row = event.target.closest('[data-sc-persistent-type="row"]'); if (!row) return;
        local.selected = row.dataset.scPersistentId; local.elements.forEach((el, id) => {
          const selected = id === local.selected; el.classList.toggle("is-selected", selected);
          if (el.dataset.scPersistentType === "row") el.setAttribute("aria-selected", String(selected));
        });
        context.emit("event", { id: local.selected, type: "selection", revision: local.revision, source: "user", nonce: Date.now() }); };
      element.addEventListener("click", click); local.click = click; local.model = model; reconcile(element, model, context, local);
      stateByElement.set(element, local); return { local, model };
    },
    update(handle, patchModel, context) {
      if (patchModel.patch) {
        const nodes = new Map((handle.model.nodes || []).map(node => [node.id, node]));
        (patchModel.patch.remove || []).forEach(id => nodes.delete(id));
        (patchModel.patch.upsert || []).forEach(node => nodes.set(node.id, node));
        patchModel = { ...patchModel, nodes: Array.from(nodes.values()) }; delete patchModel.patch;
      }
      handle.model = { ...handle.model, ...patchModel,
      options: { ...(handle.model.options || {}), ...(patchModel.options || {}) } };
      reconcile(context.element, handle.model, context, handle.local); return handle; },
    resize(handle, rect, element) { element.dataset.scPersistentWidth = String(Math.round(rect?.width || element.clientWidth)); },
    destroy(handle, element) { element.removeEventListener("click", handle.local.click); handle.local.elements.clear();
      handle.local.expanded.clear(); handle.local.drafts.clear(); handle.local.draftTimers.forEach(clearTimeout);
      handle.local.draftTimers.clear(); handle.local.hostValues.clear(); stateByElement.delete(element); element.innerHTML = ""; },
    diagnostics(element) { const local = stateByElement.get(element); return local ? { added: local.added, removed: local.removed,
      patched: local.patched, elements: local.elements.size, revision: local.revision } : null; }
  });
})();
