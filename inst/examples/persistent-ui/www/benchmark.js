(function () {
  "use strict";

  var state = {
    traditionalAdded: 0,
    traditionalRemoved: 0,
    persistentAdded: 0,
    persistentRemoved: 0,
    persistentKeyedAdded: 0,
    persistentKeyedRemoved: 0,
    traditionalBound: 0,
    traditionalUnbound: 0,
    persistentBound: 0,
    persistentUnbound: 0
  };

  function belongs(target, id) {
    return target && target.closest && target.closest("#" + id);
  }

  function countMutations(id, prefix) {
    var root = document.getElementById(id);
    if (!root || root.dataset.benchmarkObserved) return;
    root.dataset.benchmarkObserved = "true";
    new MutationObserver(function (records) {
      records.forEach(function (record) {
        state[prefix + "Added"] += record.addedNodes.length;
        state[prefix + "Removed"] += record.removedNodes.length;
        if (prefix === "persistent") {
          record.addedNodes.forEach(function (node) {
            if (node.nodeType === 1 && node.matches("[data-sc-persistent-id]")) state.persistentKeyedAdded += 1;
          });
          record.removedNodes.forEach(function (node) {
            if (node.nodeType === 1 && node.matches("[data-sc-persistent-id]")) state.persistentKeyedRemoved += 1;
          });
        }
      });
    }).observe(root, { childList: true, subtree: true });
  }

  if (window.jQuery) {
    window.jQuery(document).on("shiny:bound", function (event) {
      if (belongs(event.target, "traditional")) state.traditionalBound += 1;
      if (belongs(event.target, "persistent")) state.persistentBound += 1;
    }).on("shiny:unbound", function (event) {
      if (belongs(event.target, "traditional")) state.traditionalUnbound += 1;
      if (belongs(event.target, "persistent")) state.persistentUnbound += 1;
    });
  }

  setInterval(function () {
    countMutations("traditional", "traditional");
    countMutations("persistent", "persistent");
    var persistent = document.getElementById("persistent");
    var metrics = document.getElementById("browser_metrics");
    if (!metrics) return;
    var memory = window.performance && window.performance.memory;
    metrics.textContent = JSON.stringify(Object.assign({}, state, {
      persistentRevision: persistent ? persistent.dataset.scDirectRevision : null,
      persistentLastRenderMs: persistent ? persistent.dataset.scPersistentLastMs : null,
      persistentNodes: persistent ? persistent.querySelectorAll("[data-sc-persistent-id]").length : 0,
      heapUsedBytes: memory ? memory.usedJSHeapSize : null
    }), null, 2);
  }, 250);
})();
