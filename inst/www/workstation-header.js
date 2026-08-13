(function () {
  "use strict";
  const roots = new WeakSet();
  function bind(root) {
    if (roots.has(root)) return;
    roots.add(root);
    const menu = root.querySelector(".sc-workstation-overflow-menu");
    const input = root.dataset.commandInput;
    function publish(button) {
      if (button.disabled || !window.Shiny?.setInputValue) return;
      let payload = {};
      try { payload = JSON.parse(button.dataset.payload || "{}"); } catch (_) {}
      window.Shiny.setInputValue(input, { command_id: button.dataset.scCommandId,
        payload: payload, active: button.getAttribute("aria-pressed") === "true", nonce: Date.now() },
        { priority: "event" });
    }
    root.addEventListener("click", event => {
      const button = event.target instanceof Element ? event.target.closest("[data-sc-command-id]") : null;
      if (button) publish(button);
    });
    root.addEventListener("keydown", event => {
      if (!["ArrowLeft", "ArrowRight", "Home", "End"].includes(event.key)) return;
      const direct = Array.from(root.querySelectorAll(".sc-workstation-header-rows [data-sc-command-id]:not([hidden]):not(.is-overflowed):not(:disabled)"));
      const overflow = root.querySelector(".sc-workstation-overflow")?.open ?
        Array.from(menu.querySelectorAll("[data-sc-command-id]:not(:disabled)")) : [];
      const items = direct.concat(overflow);
      const current = items.indexOf(document.activeElement);
      if (!items.length || current < 0) return;
      event.preventDefault();
      const next = event.key === "Home" ? 0 : event.key === "End" ? items.length - 1 :
        (current + (event.key === "ArrowRight" ? 1 : -1) + items.length) % items.length;
      items[next].focus();
    });
    let frame = 0;
    function schedule() {
      if (frame) return;
      frame = requestAnimationFrame(() => { frame = 0; layout(); });
    }
    function layout() {
      if (!root.isConnected || !menu) return;
      const rowsHost = root.querySelector(".sc-workstation-header-rows");
      if (!rowsHost) return;
      const rows = Array.from(rowsHost.querySelectorAll(".sc-workstation-header-row"));
      const groups = Array.from(rowsHost.querySelectorAll(".sc-workstation-command-group"));
      const commands = Array.from(rowsHost.querySelectorAll("[data-sc-command-id]"));
      commands.forEach(item => item.classList.remove("is-overflowed", "is-compacted"));
      groups.forEach(group => group.classList.remove("is-collapsed"));
      menu.replaceChildren();
      const visible = item => !item.hidden && !item.closest("[hidden]");
      const refreshGroups = () => groups.forEach(group => {
        const direct = Array.from(group.querySelectorAll("[data-sc-command-id]"))
          .some(command => visible(command) && !command.classList.contains("is-overflowed"));
        group.classList.toggle("is-collapsed", !direct);
      });
      commands.filter(command => visible(command) && command.dataset.overflowOnly === "true")
        .forEach(command => command.classList.add("is-overflowed"));
      refreshGroups();
      const pressured = row => row.scrollWidth > row.clientWidth + 1;
      const priority = command => Number(command.closest(".sc-workstation-command-group")?.dataset.priority || 50) * 1000 + Number(command.dataset.priority || 50);
      rows.forEach(row => {
        const owned = commands.filter(command => command.closest(".sc-workstation-header-row") === row && visible(command) && !command.classList.contains("is-overflowed"));
        owned.filter(command => command.dataset.compactEligible === "true")
          .sort((a, b) => priority(b) - priority(a)).forEach(command => {
            if (pressured(row)) command.classList.add("is-compacted");
          });
        owned.filter(command => command.dataset.overflowEligible === "true")
          .sort((a, b) => priority(b) - priority(a)).forEach(command => {
            if (!pressured(row)) return;
            command.classList.add("is-overflowed");
            refreshGroups();
          });
      });
      commands.filter(command => visible(command) && command.classList.contains("is-overflowed"))
        .forEach(command => {
          const copy = command.cloneNode(true);
          copy.classList.remove("is-overflowed", "is-compacted");
          copy.classList.add("is-overflow-command");
          copy.removeAttribute("hidden");
          menu.appendChild(copy);
        });
      const compacted = commands.filter(command => command.classList.contains("is-compacted")).length;
      const pressureOverflow = commands.filter(command => command.classList.contains("is-overflowed") && command.dataset.overflowOnly !== "true").length;
      root.dataset.layoutState = pressureOverflow > commands.length / 2 ? "very-narrow" : pressureOverflow ? "narrow" : compacted ? "medium" : "wide";
      root.classList.toggle("has-overflow", menu.childElementCount > 0);
      rows.forEach(row => row.classList.toggle("is-empty", !Array.from(row.querySelectorAll(".sc-workstation-command-group")).some(group => !group.hidden && !group.classList.contains("is-collapsed"))));
    }
    new ResizeObserver(schedule).observe(root);
    new MutationObserver(schedule).observe(root, { subtree: true, attributes: true, attributeFilter: ["hidden"] });
    root.addEventListener("shinycapabilities:workstation-header-layout", schedule);
    schedule();
  }
  const scan = () => document.querySelectorAll(".sc-workstation-header").forEach(bind);
  new MutationObserver(scan).observe(document.documentElement, { childList: true, subtree: true });
  document.addEventListener("shiny:connected", scan);
  scan();
}());
