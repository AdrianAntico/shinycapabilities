const runtime = window.ShinyCapabilitiesBrowserRuntimeV1;
if (!runtime) throw new Error("Shared shinycapabilities browser runtime v1 was not loaded.");
runtime.assertCompatible(1);
const { React, createRoot } = runtime;
const { useEffect, useRef } = React;
import { Group, Panel, Separator } from "react-resizable-panels";
import "./split-pane.css";

const transport = window.ShinyCapabilitiesDirectTransport;
if (!transport) throw new Error("Direct Component Transport was not loaded.");
const asArray = value => value == null ? [] : (Array.isArray(value) ? value : [value]);
const asMap = (value, ids) => Array.isArray(value) ? Object.fromEntries(ids.map((id, i) => [id, value[i]])) : (value || {});

function PaneContent({ id, html }) {
  const ref = useRef(null);
  useEffect(() => {
    const target = ref.current; if (!target) return;
    window.Shiny?.initializeInputs?.(target); window.Shiny?.bindAll?.(target);
    return () => window.Shiny?.unbindAll?.(target);
  }, [id]);
  return <div ref={ref} className="sc-split-pane-content" data-pane-content={id}
    dangerouslySetInnerHTML={{ __html: html || "" }} />;
}

function SplitPaneDirect({ host, model, emit, controllerRef }) {
  const groupRef = useRef(null), panelRefs = useRef(new Map()), ids = model.ids || [];
  const logical = layout => Object.fromEntries(ids.map(id => [id, layout?.[`${host.id}-pane-${id}`] ?? layout?.[id] ?? 0]));
  const snapshot = (event = null) => ({ componentId: host.id, direction: model.direction,
    paneIds: ids, sizes: logical(groupRef.current?.getLayout?.() || {}),
    collapsed: ids.filter(id => panelRefs.current.get(id)?.isCollapsed?.()), event });
  const publish = (type, extra = {}) => requestAnimationFrame(() => {
    window.dispatchEvent(new Event("resize")); emit("event", snapshot({ type, source: "user", nonce: Date.now(), ...extra }));
  });
  const reset = () => { ids.forEach(id => panelRefs.current.get(id)?.resize?.(model.sizes[id])); publish("reset"); };
  useEffect(() => {
    asArray(model.collapsed).forEach(id => panelRefs.current.get(id)?.collapse?.());
    controllerRef.current = message => {
      const sizes = asMap(message.sizes, ids);
      if (message.reset) ids.forEach(id => panelRefs.current.get(id)?.resize?.(model.sizes[id]));
      else Object.entries(sizes).forEach(([id, size]) => panelRefs.current.get(id)?.resize?.(typeof size === "number" ? `${size}%` : size));
      asArray(message.collapse).forEach(id => panelRefs.current.get(id)?.collapse?.());
      asArray(message.expand).forEach(id => panelRefs.current.get(id)?.expand?.());
      window.dispatchEvent(new Event("resize"));
    };
    return () => { controllerRef.current = null; };
  }, [model]);
  return <Group id={`${host.id}-group`} groupRef={groupRef} orientation={model.direction}
    className={`sc-split-group is-${model.direction}`}
    onLayoutChanged={(layout, meta) => { if (meta.isUserInteraction) publish("resize", { sizes: logical(layout) }); }}>
    {ids.flatMap((id, index) => {
      const panel = <Panel key={`panel-${id}`} id={`${host.id}-pane-${id}`}
        panelRef={value => value ? panelRefs.current.set(id, value) : panelRefs.current.delete(id)}
        defaultSize={model.sizes[id]} minSize={model.minSizes[id]} maxSize={model.maxSizes[id]}
        collapsible={!!model.collapsible[id]} className="sc-split-panel">
        <PaneContent id={id} html={model.html?.[id]} />
      </Panel>;
      if (index === ids.length - 1) return [panel];
      return [panel, <Separator key={`separator-${id}`} id={`${host.id}-separator-${index + 1}`}
        className="sc-split-separator" disableDoubleClick aria-label={`Resize ${id} and ${ids[index + 1]}`}
        onDoubleClick={model.resetOnDoubleClick ? reset : undefined}><span aria-hidden="true" /></Separator>];
    })}
  </Group>;
}

transport.register("split_pane_direct", {
  runtimeMajor: 1,
  mount(element, model, context) {
    const root = createRoot(element), controllerRef = { current: null };
    const render = next => root.render(<SplitPaneDirect host={element} model={next}
      emit={context.emit} controllerRef={controllerRef} />);
    render(model); return { root, model, render, controllerRef };
  },
  update(handle, message) {
    if (message.ids || message.html || message.direction) {
      handle.model = { ...handle.model, ...message }; handle.render(handle.model);
    } else handle.controllerRef.current?.(message);
    return handle;
  },
  resize(handle, rect, element) { element.dataset.scSplitWidth = String(Math.round(rect?.width || element.clientWidth)); },
  destroy(handle) { handle.root.unmount(); handle.controllerRef.current = null; }
});
