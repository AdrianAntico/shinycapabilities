import {
  createGrid,
  themeQuartz,
  CellStyleModule,
  ClientSideRowModelModule,
  ColumnApiModule,
  DateFilterModule,
  NumberFilterModule,
  PaginationModule,
  QuickFilterModule,
  RenderApiModule,
  RowApiModule,
  RowSelectionModule,
  TextFilterModule
} from "ag-grid-community";
import "./data-grid.css";

const modules = [
  CellStyleModule,
  ClientSideRowModelModule,
  ColumnApiModule,
  DateFilterModule,
  NumberFilterModule,
  PaginationModule,
  QuickFilterModule,
  RenderApiModule,
  RowApiModule,
  RowSelectionModule,
  TextFilterModule
];

const gridInstances = new Map();
const numberFormatter = new Intl.NumberFormat(undefined, { maximumFractionDigits: 4 });
const compactFormatter = new Intl.NumberFormat(undefined, { notation: "compact", maximumFractionDigits: 2 });

function rowRecords(value) {
  if (Array.isArray(value)) return value;
  if (!value || typeof value !== "object") return [];
  if (window.HTMLWidgets?.dataframeToD3) return window.HTMLWidgets.dataframeToD3(value);
  const fields = Object.keys(value);
  const count = fields.length ? value[fields[0]].length : 0;
  return Array.from({ length: count }, (_, index) => Object.fromEntries(fields.map(field => [field, value[field][index]])));
}

function publish(element, suffix, value, priority = "event") {
  if (!window.Shiny?.setInputValue || !element.id) return;
  window.Shiny.setInputValue(`${element.id}_${suffix}`, value, { priority });
}

function cleanColumnState(api) {
  return api.getColumnState().map(({ colId, hide, pinned, sort, sortIndex, width }) => ({
    colId, hide: Boolean(hide), pinned: pinned || null, sort: sort || null,
    sortIndex: Number.isInteger(sortIndex) ? sortIndex : null, width
  }));
}

function formatValue(value, definition) {
  if (value === null || value === undefined || value === "") return "";
  const format = definition.format || (definition.scType === "number" || definition.scType === "integer" ? "number" : "raw");
  const digits = Number.isInteger(definition.digits) ? definition.digits : 3;
  if (format === "compact") return compactFormatter.format(Number(value));
  if (format === "percent") return new Intl.NumberFormat(undefined, { style: "percent", maximumFractionDigits: digits }).format(Number(value));
  if (format === "currency") return new Intl.NumberFormat(undefined, { style: "currency", currency: definition.currency || "USD", maximumFractionDigits: digits }).format(Number(value));
  if (format === "number") return new Intl.NumberFormat(undefined, { maximumFractionDigits: digits }).format(Number(value));
  if (format === "date") return new Intl.DateTimeFormat(undefined, { dateStyle: "medium" }).format(new Date(`${value}T00:00:00`));
  if (format === "datetime") return new Intl.DateTimeFormat(undefined, { dateStyle: "medium", timeStyle: "short" }).format(new Date(value));
  if (definition.scType === "logical") return value ? "Yes" : "No";
  return String(value);
}

function columnDefinition(definition) {
  const numeric = ["number", "integer"].includes(definition.scType);
  const date = ["date", "datetime"].includes(definition.scType);
  return {
    ...definition,
    filter: definition.filter === false ? false : numeric ? "agNumberColumnFilter" : date ? "agDateColumnFilter" : "agTextColumnFilter",
    valueFormatter: params => formatValue(params.value, definition),
    comparator: definition.scType === "date" || definition.scType === "datetime"
      ? (a, b) => String(a || "").localeCompare(String(b || "")) : undefined,
    cellClass: numeric ? "sc-grid-number" : definition.scType === "logical" ? "sc-grid-logical" : undefined
  };
}

function toolbar(element, options) {
  const root = document.createElement("div");
  root.className = "sc-grid-toolbar";
  root.setAttribute("role", "toolbar");
  root.setAttribute("aria-label", "Data grid controls");
  if (options.quick_filter) {
    const search = document.createElement("input");
    search.type = "search";
    search.className = "sc-grid-search";
    search.placeholder = "Filter all columns";
    search.setAttribute("aria-label", "Filter all grid columns");
    root.append(search);
  }
  const status = document.createElement("span");
  status.className = "sc-grid-status";
  status.setAttribute("aria-live", "polite");
  root.append(status);
  const actions = document.createElement("div");
  actions.className = "sc-grid-actions";
  if (options.column_controls) actions.append(button("Columns", "columns"));
  if (options.copy_selected) actions.append(button("Copy selected", "copy"));
  root.append(actions);
  element.append(root);
  return { root, search: root.querySelector(".sc-grid-search"), status, actions };
}

function button(label, action) {
  const result = document.createElement("button");
  result.type = "button";
  result.className = "sc-grid-button";
  result.dataset.action = action;
  result.textContent = label;
  return result;
}

function createColumnPopover(api, columnsButton) {
  const popover = document.createElement("div");
  popover.className = "sc-grid-columns";
  popover.hidden = true;
  popover.setAttribute("role", "menu");
  popover.setAttribute("aria-label", "Visible columns");
  const refresh = () => {
    popover.replaceChildren(...api.getColumns().filter(column => column.getColId() !== ".sc_row_id").map(column => {
      const label = document.createElement("label");
      label.className = "sc-grid-column-choice";
      const input = document.createElement("input");
      input.type = "checkbox";
      input.checked = column.isVisible();
      input.addEventListener("change", () => api.setColumnsVisible([column.getColId()], input.checked));
      label.append(input, document.createTextNode(column.getColDef().headerName || column.getColId()));
      return label;
    }));
  };
  columnsButton.after(popover);
  columnsButton.addEventListener("click", () => {
    popover.hidden = !popover.hidden;
    columnsButton.setAttribute("aria-expanded", String(!popover.hidden));
    if (!popover.hidden) refresh();
  });
  document.addEventListener("pointerdown", event => {
    if (!popover.hidden && !popover.contains(event.target) && event.target !== columnsButton) popover.hidden = true;
  }, { signal: gridInstances.get(columnsButton.closest(".html-widget"))?.controller?.signal });
}

function selectionPayload(api) {
  return {
    rowIds: api.getSelectedNodes().map(node => node.id),
    count: api.getSelectedNodes().length,
    timestamp: new Date().toISOString()
  };
}

function statePayload(api) {
  return {
    columns: cleanColumnState(api),
    filters: api.getFilterModel(),
    timestamp: new Date().toISOString()
  };
}

function renderGrid(element, payload) {
  const previous = gridInstances.get(element);
  previous?.controller.abort();
  previous?.api.destroy();
  element.replaceChildren();
  element.className = `html-widget sc-data-grid sc-data-grid--${payload.options.density}`;
  const controller = new AbortController();
  const rows = rowRecords(payload.rows);
  gridInstances.set(element, { controller });
  const controls = toolbar(element, payload.options);
  const grid = document.createElement("div");
  grid.className = "sc-grid-surface";
  grid.setAttribute("aria-label", "Analytical data grid");
  element.append(grid);
  const multiple = payload.options.selection === "multiple";
  const selectable = payload.options.selection !== "none";
  let stateTimer;
  const emitState = api => {
    if (!payload.options.publish_state) return;
    clearTimeout(stateTimer);
    stateTimer = setTimeout(() => publish(element, "state", statePayload(api)), 120);
  };
  const api = createGrid(grid, {
    theme: themeQuartz.withParams({ spacing: payload.options.density === "compact" ? 4 : 7 }),
    rowData: rows,
    columnDefs: payload.columns.map(columnDefinition),
    defaultColDef: { sortable: true, filter: true, resizable: true, minWidth: 96 },
    getRowId: params => params.data[".sc_row_id"],
    rowSelection: selectable ? { mode: multiple ? "multiRow" : "singleRow", enableClickSelection: true, checkboxes: multiple, headerCheckbox: multiple } : undefined,
    suppressCellFocus: false,
    enableCellTextSelection: true,
    ensureDomOrder: payload.options.accessibility_mode === "paginated",
    pagination: payload.options.accessibility_mode === "paginated",
    paginationPageSize: payload.options.accessibility_mode === "paginated" ? 50 : undefined,
    suppressColumnVirtualisation: payload.options.accessibility_mode === "paginated",
    animateRows: Boolean(payload.options.animate_rows),
    rowHeight: payload.options.row_height || (payload.options.density === "compact" ? 32 : 40),
    headerHeight: payload.options.header_height || (payload.options.density === "compact" ? 36 : 42),
    overlayNoRowsTemplate: `<span class="sc-grid-overlay">${payload.options.empty_message}</span>`,
    loadingOverlayComponent: () => {
      const output = document.createElement("span");
      output.className = "sc-grid-overlay";
      output.textContent = payload.options.loading_message;
      return output;
    },
    onGridReady: event => {
      controls.status.textContent = `${rows.length.toLocaleString()} rows`;
      if (!rows.length) event.api.showNoRowsOverlay();
    },
    onSelectionChanged: event => publish(element, "selection", selectionPayload(event.api)),
    onCellDoubleClicked: event => publish(element, "action", {
      type: "cell_activate", rowId: event.node.id, columnId: event.column.getColId(),
      value: event.value ?? null, timestamp: new Date().toISOString()
    }),
    onSortChanged: event => emitState(event.api),
    onFilterChanged: event => emitState(event.api),
    onColumnMoved: event => event.finished && emitState(event.api),
    onColumnVisible: event => emitState(event.api),
    onColumnPinned: event => emitState(event.api),
    onColumnResized: event => event.finished && emitState(event.api)
  }, { modules });
  gridInstances.set(element, { api, controller, controls });
  controls.search?.addEventListener("input", event => api.setGridOption("quickFilterText", event.target.value), { signal: controller.signal });
  const columnsButton = controls.actions.querySelector('[data-action="columns"]');
  if (columnsButton) createColumnPopover(api, columnsButton);
  controls.actions.querySelector('[data-action="copy"]')?.addEventListener("click", async () => {
    const rows = api.getSelectedRows();
    if (!rows.length) return;
    const fields = payload.columns.filter(column => !column.hide).map(column => column.field);
    const text = [fields.join("\t"), ...rows.map(row => fields.map(field => row[field] ?? "").join("\t"))].join("\n");
    await navigator.clipboard.writeText(text);
    controls.status.textContent = `Copied ${rows.length.toLocaleString()} selected row${rows.length === 1 ? "" : "s"}`;
  }, { signal: controller.signal });
}

window.HTMLWidgets.widget({
  name: "data_grid",
  type: "output",
  factory(element) {
    return {
      renderValue(payload) { renderGrid(element, payload); },
      resize() { gridInstances.get(element)?.api?.doLayout(); }
    };
  }
});

if (window.Shiny?.addCustomMessageHandler) {
  window.Shiny.addCustomMessageHandler("shinycapabilities:data-grid:update", message => {
    const element = document.getElementById(message.id);
    const instance = gridInstances.get(element);
    if (!instance?.api) return;
    if (message.rows) {
      const rows = rowRecords(message.rows);
      instance.api.setGridOption("rowData", rows);
      instance.controls.status.textContent = `${rows.length.toLocaleString()} rows`;
    }
    if (message.quickFilter !== undefined) {
      instance.api.setGridOption("quickFilterText", message.quickFilter);
      if (instance.controls.search) instance.controls.search.value = message.quickFilter;
    }
    if (message.columnState) instance.api.applyColumnState({ state: message.columnState, applyOrder: true });
    if (message.selectedRows) {
      const selected = new Set(message.selectedRows);
      instance.api.forEachNode(node => node.setSelected(selected.has(node.id)));
    }
    if (message.loading === true) instance.api.showLoadingOverlay();
    if (message.loading === false) instance.api.hideOverlay();
  });
}
