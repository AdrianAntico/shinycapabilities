(function () {
  "use strict";

  const state = new WeakMap();
  const notificationState = new WeakMap();
  let layer = null;

  function emit(root, type, detail) {
    const value = Object.assign({ type, surface_id: root.id, timestamp: new Date().toISOString() }, detail || {});
    root.dispatchEvent(new CustomEvent("shinycapabilities:surface", { bubbles: true, detail: value }));
    if (window.Shiny && root.id) Shiny.setInputValue(`${root.id}_event`, value, { priority: "event" });
  }

  function ensureLayer() {
    if (!layer) {
      layer = document.createElement("div");
      layer.className = "sc-overlay-layer";
      layer.dataset.scOverlayLayer = "true";
      document.body.appendChild(layer);
    }
    return layer;
  }

  function place(anchor, panel, placement) {
    const a = anchor.getBoundingClientRect();
    const p = panel.getBoundingClientRect();
    const gap = 8;
    let top = a.bottom + gap;
    let left = placement.includes("end") ? a.right - p.width : a.left;
    if (placement.startsWith("top")) top = a.top - p.height - gap;
    if (placement.startsWith("right")) { top = a.top; left = a.right + gap; }
    if (placement.startsWith("left")) { top = a.top; left = a.left - p.width - gap; }
    left = Math.max(gap, Math.min(left, window.innerWidth - p.width - gap));
    if (top + p.height > window.innerHeight - gap) top = Math.max(gap, a.top - p.height - gap);
    if (top < gap) top = gap;
    panel.style.position = "fixed";
    panel.style.left = `${Math.round(left)}px`;
    panel.style.top = `${Math.round(top)}px`;
    panel.style.zIndex = "10000";
  }

  function focusables(root) {
    return [...root.querySelectorAll('button:not([disabled]), [href], input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])')];
  }

  function closeOverlay(root, restore = true) {
    const current = state.get(root);
    if (!current || !current.panel) return;
    current.panel.hidden = true;
    if (current.placeholder) current.placeholder.replaceWith(current.panel);
    current.trigger?.setAttribute("aria-expanded", "false");
    if (restore) current.trigger?.focus({ preventScroll: true });
    state.set(root, Object.assign(current, { open: false, placeholder: null }));
    emit(root, "close", {});
  }

  function openOverlay(root, trigger, panel, placement) {
    document.querySelectorAll('[data-sc-surface="popover"], [data-sc-surface="context-menu"]').forEach((other) => {
      if (other !== root) closeOverlay(other, false);
    });
    const placeholder = document.createComment("sc-overlay-home");
    panel.replaceWith(placeholder);
    ensureLayer().appendChild(panel);
    panel.hidden = false;
    trigger.setAttribute("aria-expanded", "true");
    place(trigger, panel, placement || "bottom-start");
    state.set(root, { open: true, panel, trigger, placeholder });
    const first = focusables(panel)[0];
    if (first && root.dataset.scSurface === "context-menu") first.focus();
    emit(root, "open", {});
  }

  function initTooltip(root) {
    const trigger = root.querySelector(".sc-overlay-trigger");
    const panel = root.querySelector(".sc-tooltip");
    if (!trigger || !panel) return;
    const show = () => { panel.hidden = false; place(trigger, panel, root.dataset.placement || "top"); };
    const hide = () => { panel.hidden = true; };
    panel.hidden = true;
    trigger.addEventListener("mouseenter", show);
    trigger.addEventListener("mouseleave", hide);
    trigger.addEventListener("focus", show);
    trigger.addEventListener("blur", hide);
    state.set(root, { destroy: () => {
      trigger.removeEventListener("mouseenter", show); trigger.removeEventListener("mouseleave", hide);
      trigger.removeEventListener("focus", show); trigger.removeEventListener("blur", hide);
    }});
  }

  function initPopover(root) {
    const trigger = root.querySelector(".sc-overlay-trigger");
    const panel = root.querySelector(".sc-popover");
    if (!trigger || !panel) return;
    const toggle = () => state.get(root)?.open ? closeOverlay(root) : openOverlay(root, trigger, panel, root.dataset.placement);
    trigger.addEventListener("click", toggle);
    state.set(root, { open: false, panel, trigger, destroy: () => trigger.removeEventListener("click", toggle) });
  }

  function initContext(root) {
    const panel = root.querySelector(".sc-context-menu");
    const show = (event) => { event.preventDefault(); openOverlay(root, root, panel, "bottom-start"); };
    const keys = (event) => { if (event.key === "ContextMenu" || (event.shiftKey && event.key === "F10")) show(event); };
    root.addEventListener("contextmenu", show); root.addEventListener("keydown", keys);
    state.set(root, { open: false, panel, trigger: root, destroy: () => {
      root.removeEventListener("contextmenu", show); root.removeEventListener("keydown", keys);
    }});
  }

  function openDialog(root) {
    if (root.open) return;
    state.set(root, Object.assign(state.get(root) || {}, { previousFocus: document.activeElement }));
    root.showModal();
    focusables(root)[0]?.focus();
    emit(root, "open", {});
  }

  function closeDialog(root, reason) {
    if (!root.open) return;
    root.close();
    state.get(root)?.previousFocus?.focus?.({ preventScroll: true });
    emit(root, "close", { reason: reason || "programmatic" });
  }

  function initDialog(root) {
    const click = (event) => {
      const action = event.target.closest("[data-sc-event]");
      if (action) { emit(root, "action", { action_id: action.dataset.scEvent }); return; }
      if (event.target.closest("[data-sc-dialog-close]")) closeDialog(root, "close_button");
      if (event.target === root && root.dataset.dismissible === "true") closeDialog(root, "backdrop");
    };
    const cancel = (event) => {
      event.preventDefault();
      if (root.dataset.dismissible === "true") closeDialog(root, "escape");
    };
    root.addEventListener("click", click); root.addEventListener("cancel", cancel);
    state.set(root, { previousFocus: null, destroy: () => { root.removeEventListener("click", click); root.removeEventListener("cancel", cancel); }});
  }

  function normalizeNotification(x, i) {
    return {
      id: String(x.id || `notification-${i}`), severity: String(x.severity || "info"),
      title: String(x.title || "Notification"), message: String(x.message || ""),
      persistent: Boolean(x.persistent), timeout: Number(x.timeout || 0),
      count: Number(x.count || 1), actions: Array.isArray(x.actions) ? x.actions : []
    };
  }

  function renderNotifications(root) {
    const store = notificationState.get(root); if (!store) return;
    const region = root.querySelector(".sc-toast-region"); region.replaceChildren();
    store.items.slice(-store.maxVisible).forEach((item) => {
      const toast = document.createElement("article");
      toast.className = `sc-toast is-${item.severity}`;
      toast.dataset.notificationId = item.id;
      toast.setAttribute("role", item.severity === "error" ? "alert" : "status");
      const copy = document.createElement("div");
      const title = document.createElement("strong"); title.textContent = item.title;
      const message = document.createElement("p"); message.textContent = item.message;
      copy.append(title, message);
      if (item.count > 1) { const count = document.createElement("small"); count.textContent = `Repeated ${item.count} times`; copy.append(count); }
      const actions = document.createElement("div"); actions.className = "sc-toast-actions";
      item.actions.forEach((a) => { const b = document.createElement("button"); b.type = "button"; b.dataset.actionId = a.id; b.textContent = a.label || a.id; actions.append(b); });
      const dismiss = document.createElement("button"); dismiss.type = "button"; dismiss.dataset.dismiss = item.id; dismiss.setAttribute("aria-label", `Dismiss ${item.title}`); dismiss.textContent = "\u00d7"; actions.append(dismiss);
      toast.append(copy, actions); region.append(toast);
      if (!item.persistent && item.timeout > 0) window.setTimeout(() => dismissNotification(root, item.id, "timeout"), item.timeout);
    });
  }

  function setNotifications(root, incoming, mode) {
    const store = notificationState.get(root); if (!store) return;
    if (mode === "dismiss") { (incoming || []).forEach((x) => dismissNotification(root, typeof x === "string" ? x : x.id, "host")); return; }
    const records = (incoming || []).map(normalizeNotification);
    if (mode === "replace") store.items = [];
    records.forEach((item) => {
      const existing = store.items.find((x) => x.id === item.id);
      if (existing) Object.assign(existing, item, { count: existing.count + 1 }); else store.items.push(item);
    });
    store.items = store.items.slice(-store.maxHistory);
    renderNotifications(root);
  }

  function dismissNotification(root, id, reason) {
    const store = notificationState.get(root); if (!store) return;
    store.items = store.items.filter((x) => x.id !== id); renderNotifications(root);
    emit(root, "dismiss", { notification_id: id, reason });
  }

  function initNotifications(root) {
    const data = root.querySelector(".sc-notification-data");
    let initial = []; try { initial = JSON.parse(data?.textContent || "[]"); } catch (_) {}
    notificationState.set(root, { items: [], maxVisible: Number(root.dataset.maxVisible || 4), maxHistory: Number(root.dataset.maxHistory || 100) });
    setNotifications(root, initial, "replace");
    const click = (event) => {
      const dismiss = event.target.closest("[data-dismiss]"); if (dismiss) return dismissNotification(root, dismiss.dataset.dismiss, "user");
      const action = event.target.closest("[data-action-id]"); const toast = event.target.closest("[data-notification-id]");
      if (action && toast) emit(root, "action", { notification_id: toast.dataset.notificationId, action_id: action.dataset.actionId });
    };
    root.addEventListener("click", click); state.set(root, { destroy: () => root.removeEventListener("click", click) });
  }

  function selectTab(root, id, focus) {
    const list = root.querySelector(":scope > .sc-tab-list");
    const tabs = list ? [...list.querySelectorAll(":scope > [role=tab]")] : [];
    tabs.forEach((tab) => {
      const on = tab.dataset.tabId === id; tab.setAttribute("aria-selected", String(on)); tab.tabIndex = on ? 0 : -1;
      if (on && focus) tab.focus();
    });
    root.querySelectorAll(":scope > .sc-tab-panel").forEach((panel) => { panel.hidden = panel.id !== `${root.id}-panel-${id}`; });
    emit(root, "select", { selected: id });
  }

  function initTabs(root) {
    const click = (event) => { const tab = event.target.closest('[role="tab"]'); if (tab && tab.closest(".sc-tabs") === root) selectTab(root, tab.dataset.tabId, false); };
    const keys = (event) => {
      const tab = event.target.closest('[role="tab"]'); if (!tab) return;
      if (tab.closest(".sc-tabs") !== root) return;
      const tabs = [...root.querySelectorAll(":scope > .sc-tab-list > [role=tab]")]; let index = tabs.indexOf(tab);
      if (event.key === "ArrowRight" || event.key === "ArrowDown") index = (index + 1) % tabs.length;
      else if (event.key === "ArrowLeft" || event.key === "ArrowUp") index = (index - 1 + tabs.length) % tabs.length;
      else if (event.key === "Home") index = 0; else if (event.key === "End") index = tabs.length - 1; else return;
      event.preventDefault(); selectTab(root, tabs[index].dataset.tabId, true);
    };
    root.addEventListener("click", click); root.addEventListener("keydown", keys);
    state.set(root, { destroy: () => { root.removeEventListener("click", click); root.removeEventListener("keydown", keys); }});
  }

  function initAccordion(root) {
    const toggle = (event) => {
      if (!event.target.open || root.dataset.multiple === "true") return;
      root.querySelectorAll("details").forEach((x) => { if (x !== event.target) x.open = false; });
      emit(root, "toggle", { section_id: event.target.dataset.sectionId, open: event.target.open });
    };
    root.addEventListener("toggle", toggle, true); state.set(root, { destroy: () => root.removeEventListener("toggle", toggle, true) });
  }

  function initPagination(root) {
    const click = (event) => {
      const button = event.target.closest("[data-sc-page]"); if (!button) return;
      const current = Number(root.dataset.page); const pages = Number(root.dataset.pages);
      const next = Math.max(1, Math.min(pages, current + (button.dataset.scPage === "next" ? 1 : -1)));
      root.dataset.page = String(next); root.querySelector("output").textContent = `Page ${next} of ${pages}`;
      root.querySelector('[data-sc-page="previous"]').disabled = next <= 1;
      root.querySelector('[data-sc-page="next"]').disabled = next >= pages;
      emit(root, "select", { page: next });
    };
    root.addEventListener("click", click); state.set(root, { destroy: () => root.removeEventListener("click", click) });
  }

  function formatSize(bytes) {
    if (!Number.isFinite(bytes)) return ""; const units = ["B", "KB", "MB", "GB"]; let value = bytes; let unit = 0;
    while (value >= 1024 && unit < units.length - 1) { value /= 1024; unit += 1; }
    return `${value < 10 && unit ? value.toFixed(1) : Math.round(value)} ${units[unit]}`;
  }

  function initFile(root) {
    const input = root.querySelector('input[type="file"]'); const drop = root.querySelector(".sc-file-drop");
    const list = root.querySelector(".sc-file-list"); const clear = root.querySelector(".sc-file-clear"); const error = root.querySelector(".sc-file-error");
    if (!input || !drop) return;
    const present = () => {
      const files = [...input.files]; const max = Number(root.dataset.maxSize || 0); const tooLarge = max && files.some((f) => f.size > max);
      error.textContent = tooLarge ? `One or more files exceed ${formatSize(max)}.` : "";
      list.replaceChildren(...files.map((file) => { const row = document.createElement("div"); row.textContent = `${file.name} \u00b7 ${formatSize(file.size)}`; return row; }));
      clear.disabled = files.length === 0; emit(root, "selection", { count: files.length, valid: !tooLarge, files: files.map((f) => ({ name: f.name, size: f.size, type: f.type })) });
    };
    const browse = () => { if (root.dataset.disabled !== "true") input.click(); };
    const key = (event) => { if (event.key === "Enter" || event.key === " ") { event.preventDefault(); browse(); }};
    const drag = (event) => { event.preventDefault(); drop.classList.toggle("is-dragging", event.type === "dragover"); };
    const dropped = (event) => { event.preventDefault(); drop.classList.remove("is-dragging"); if (root.dataset.disabled === "true") return; input.files = event.dataTransfer.files; input.dispatchEvent(new Event("change", { bubbles: true })); };
    const clearFiles = () => { input.value = ""; input.dispatchEvent(new Event("change", { bubbles: true })); };
    drop.addEventListener("click", browse); drop.addEventListener("keydown", key); drop.addEventListener("dragover", drag); drop.addEventListener("dragleave", drag); drop.addEventListener("drop", dropped); input.addEventListener("change", present); clear.addEventListener("click", clearFiles);
    state.set(root, { destroy: () => { drop.removeEventListener("click", browse); drop.removeEventListener("keydown", key); drop.removeEventListener("dragover", drag); drop.removeEventListener("dragleave", drag); drop.removeEventListener("drop", dropped); input.removeEventListener("change", present); clear.removeEventListener("click", clearFiles); }});
  }

  function notifyResize(root) {
    root.querySelectorAll(".html-widget, .shiny-bound-output, [data-shinycap-component]").forEach((child) => child.dispatchEvent(new CustomEvent("shinycapabilities:resize", { bubbles: false })));
    window.dispatchEvent(new Event("resize"));
  }

  function initOutput(root) {
    const click = async (event) => {
      const action = event.target.closest("[data-sc-event]"); if (!action) return;
      const id = action.dataset.scEvent;
      if (id === "fullscreen") {
        if (document.fullscreenElement === root) await document.exitFullscreen(); else await root.requestFullscreen();
        notifyResize(root);
      } else if (id === "spotlight") {
        root.classList.toggle("is-spotlight"); document.body.classList.toggle("sc-has-spotlight", root.classList.contains("is-spotlight"));
        if (root.classList.contains("is-spotlight")) root.focus?.(); notifyResize(root);
      }
      emit(root, "action", { action_id: id });
    };
    const observer = new ResizeObserver(() => notifyResize(root)); observer.observe(root.querySelector(".sc-output-body"));
    root.addEventListener("click", click); state.set(root, { observer, destroy: () => { observer.disconnect(); root.removeEventListener("click", click); }});
  }

  function initGeneric(root) {
    const click = (event) => { const action = event.target.closest("[data-sc-event]"); if (action) emit(root, "action", { action_id: action.dataset.scEvent }); };
    root.addEventListener("click", click); state.set(root, { destroy: () => root.removeEventListener("click", click) });
  }

  function mount(root) {
    if (!root || state.has(root)) return;
    switch (root.dataset.scSurface) {
      case "tooltip": initTooltip(root); break; case "popover": initPopover(root); break; case "context-menu": initContext(root); break;
      case "dialog": initDialog(root); break; case "notifications": initNotifications(root); break; case "tabs": initTabs(root); break;
      case "accordion": initAccordion(root); break; case "pagination": initPagination(root); break; case "file-upload": initFile(root); break;
      case "output-shell": initOutput(root); break; default: initGeneric(root);
    }
  }

  function unmount(root) { const current = state.get(root); current?.destroy?.(); current?.observer?.disconnect?.(); state.delete(root); notificationState.delete(root); }
  function scan(node) { if (node.nodeType !== 1) return; if (node.matches?.("[data-sc-surface]")) mount(node); node.querySelectorAll?.("[data-sc-surface]").forEach(mount); }

  document.addEventListener("click", (event) => {
    document.querySelectorAll('[data-sc-surface="popover"], [data-sc-surface="context-menu"]').forEach((root) => {
      const current = state.get(root); if (current?.open && !root.contains(event.target) && !current.panel.contains(event.target)) closeOverlay(root, false);
    });
    const menuAction = event.target.closest(".sc-context-menu [data-sc-event]");
    if (menuAction) { const root = [...document.querySelectorAll('[data-sc-surface="context-menu"]')].find((x) => state.get(x)?.panel?.contains(menuAction)); if (root) { emit(root, "action", { action_id: menuAction.dataset.scEvent }); closeOverlay(root); }}
  });
  document.addEventListener("keydown", (event) => {
    if (event.key !== "Escape") return;
    const dialogs = [...document.querySelectorAll('dialog.sc-dialog[open][data-dismissible="true"]')];
    if (dialogs.length) closeDialog(dialogs[dialogs.length - 1], "escape");
    document.querySelectorAll('[data-sc-surface="popover"], [data-sc-surface="context-menu"]').forEach((root) => closeOverlay(root));
    document.querySelectorAll('.sc-output-shell.is-spotlight').forEach((root) => { root.classList.remove("is-spotlight"); document.body.classList.remove("sc-has-spotlight"); notifyResize(root); });
  });

  const observer = new MutationObserver((mutations) => mutations.forEach((m) => {
    m.addedNodes.forEach(scan); m.removedNodes.forEach((node) => { if (node.nodeType === 1) { if (state.has(node)) unmount(node); node.querySelectorAll?.("[data-sc-surface]").forEach(unmount); }});
  }));
  function start() { document.querySelectorAll("[data-sc-surface]").forEach(mount); observer.observe(document.documentElement, { childList: true, subtree: true }); }
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", start, { once: true }); else start();

  let messageHandlerRegistered = false;
  function registerMessageHandler() {
    if (messageHandlerRegistered || !window.Shiny) return;
    messageHandlerRegistered = true;
    Shiny.addCustomMessageHandler("shinycapabilities:surface", (message) => {
      const root = document.getElementById(message.id); if (!root) return; const payload = message.payload || {};
      if (message.action === "open" && root.matches("dialog")) openDialog(root);
      else if (message.action === "close" && root.matches("dialog")) closeDialog(root, "host");
      else if (message.action === "notifications") setNotifications(root, payload.notifications || [], payload.mode || "replace");
      else if (message.action === "select" && root.dataset.scSurface === "tabs") selectTab(root, payload.selected, false);
      else if (message.action === "state" && root.dataset.scSurface === "output-shell") { root.dataset.state = payload.state; root.className = `sc-output-shell is-${payload.state}`; }
      else if (message.action === "page" && root.dataset.scSurface === "pagination") { root.dataset.page = String(payload.page); root.querySelector("output").textContent = `Page ${payload.page} of ${root.dataset.pages}`; }
    });
  }
  registerMessageHandler();
  document.addEventListener("shiny:connected", registerMessageHandler, { once: true });

  window.ShinyCapabilitiesSurfaces = { mount, unmount, openDialog, closeDialog, notifyResize };
})();
