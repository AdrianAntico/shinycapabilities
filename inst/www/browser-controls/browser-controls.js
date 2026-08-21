(function () {
  "use strict";

  const roots = new WeakMap();

  function field(root) {
    return root.querySelector("input, textarea, select");
  }

  function value(root) {
    const radios = root.querySelectorAll('input[type="radio"]');
    if (radios.length) return root.querySelector('input[type="radio"]:checked')?.value ?? null;
    const control = field(root);
    if (!control) return null;
    if (control.type === "checkbox") return control.checked;
    if (control.type === "number" || control.type === "range") {
      return control.value === "" ? null : Number(control.value);
    }
    return control.value;
  }

  function setValue(root, next) {
    const radios = root.querySelectorAll('input[type="radio"]');
    if (radios.length) {
      radios.forEach((radio) => { radio.checked = String(radio.value) === String(next); });
      return;
    }
    const control = field(root);
    if (!control) return;
    if (control.type === "checkbox") control.checked = Boolean(next);
    else control.value = next == null ? "" : String(next);
    updateRangeOutput(root);
  }

  function updateRangeOutput(root) {
    const range = root.querySelector('input[type="range"]');
    const output = root.querySelector(".sc-range-value");
    if (range && output) output.value = range.value;
  }

  function setState(root, message) {
    if (Object.prototype.hasOwnProperty.call(message, "value")) setValue(root, message.value);
    const controls = root.querySelectorAll("input, textarea, select, button");
    if (Object.prototype.hasOwnProperty.call(message, "disabled")) {
      controls.forEach((control) => { control.disabled = Boolean(message.disabled); });
      root.dataset.disabled = String(Boolean(message.disabled));
    }
    if (Object.prototype.hasOwnProperty.call(message, "readonly")) {
      controls.forEach((control) => {
        if ("readOnly" in control) control.readOnly = Boolean(message.readonly);
      });
      root.dataset.readonly = String(Boolean(message.readonly));
    }
    ["min", "max", "step", "placeholder"].forEach((name) => {
      if (Object.prototype.hasOwnProperty.call(message, name) && field(root)) {
        field(root).setAttribute(name, String(message[name]));
      }
    });
    if (Object.prototype.hasOwnProperty.call(message, "label")) {
      const label = root.querySelector(".sc-control-label");
      if (label) label.firstChild.textContent = String(message.label);
    }
    if (Object.prototype.hasOwnProperty.call(message, "error")) {
      let error = root.querySelector(".sc-control-error");
      if (message.error == null || message.error === "") {
        error?.remove();
        root.classList.remove("is-invalid");
        const control = field(root);
        control?.removeAttribute("aria-invalid");
        if (control) {
          const help = root.querySelector(".sc-control-help");
          if (help) control.setAttribute("aria-describedby", help.id);
          else control.removeAttribute("aria-describedby");
        }
      } else {
        if (!error) {
          error = document.createElement("div");
          error.className = "sc-control-error";
          error.id = `${root.id}-error`;
          error.setAttribute("role", "alert");
          root.append(error);
        }
        error.textContent = String(message.error);
        root.classList.add("is-invalid");
        const control = field(root);
        control?.setAttribute("aria-invalid", "true");
        if (control) {
          const help = root.querySelector(".sc-control-help");
          control.setAttribute("aria-describedby",
            [help?.id, error.id].filter(Boolean).join(" "));
        }
      }
    }
  }

  function bindRoot(root, callback) {
    const listener = (event) => {
      updateRangeOutput(root);
      callback(event.type === "change");
    };
    root.addEventListener("input", listener);
    root.addEventListener("change", listener);
    roots.set(root, listener);
    updateRangeOutput(root);
  }

  function unbindRoot(root) {
    const listener = roots.get(root);
    if (!listener) return;
    root.removeEventListener("input", listener);
    root.removeEventListener("change", listener);
    roots.delete(root);
  }

  function register() {
    if (!window.Shiny || window.__scBrowserControlsRegistered) return;
    window.__scBrowserControlsRegistered = true;

    const controls = new Shiny.InputBinding();
    controls.find = (scope) => scope.querySelectorAll(".sc-browser-control[data-sc-control]");
    controls.getId = (root) => root.id;
    controls.getValue = value;
    controls.setValue = setValue;
    controls.subscribe = bindRoot;
    controls.unsubscribe = unbindRoot;
    controls.receiveMessage = (root, message) => setState(root, message || {});
    controls.getState = (root) => ({ value: value(root) });
    Shiny.inputBindings.register(controls, "shinycapabilities.browserControls");

    const actionCounts = new WeakMap();
    const actions = new Shiny.InputBinding();
    actions.find = (scope) => scope.querySelectorAll(".sc-browser-action[data-sc-action]");
    actions.getId = (button) => button.id;
    actions.getValue = (button) => actionCounts.get(button) || 0;
    actions.subscribe = (button, callback) => {
      const listener = () => {
        actionCounts.set(button, (actionCounts.get(button) || 0) + 1);
        callback(true);
      };
      button.addEventListener("click", listener);
      roots.set(button, listener);
    };
    actions.unsubscribe = (button) => {
      const listener = roots.get(button);
      if (listener) button.removeEventListener("click", listener);
      roots.delete(button);
      actionCounts.delete(button);
    };
    actions.receiveMessage = (button, message) => {
      if (Object.prototype.hasOwnProperty.call(message, "disabled")) button.disabled = Boolean(message.disabled);
      if (Object.prototype.hasOwnProperty.call(message, "label")) {
        const label = button.querySelector("span:last-child");
        if (label) label.textContent = String(message.label);
      }
    };
    Shiny.inputBindings.register(actions, "shinycapabilities.browserActions");
  }

  document.addEventListener("shiny:connected", register, { once: true });
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", register, { once: true });
  else register();
})();
