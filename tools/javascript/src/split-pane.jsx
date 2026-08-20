import React, { useEffect, useRef } from "react";
import { createRoot } from "react-dom/client";
import { Group, Panel, Separator } from "react-resizable-panels";
import "./split-pane.css";

const nextNonce=(()=>{let n=0;return()=>`${Date.now()}-${++n}`;})();
const asMap=(value,ids)=>{if(Array.isArray(value))return Object.fromEntries(ids.map((id,index)=>[id,value[index]]));return value||{};};
const asArray=value=>value==null?[]:(Array.isArray(value)?value:[value]);
const percentages=(sizes,ids)=>Object.fromEntries(ids.map(id=>{const value=String(sizes[id]??(100/ids.length));return[id,Number(value.replace("%",""))||0];}));

function PaneContent({host,id,html}){
  const ref=useRef(null);
  useEffect(()=>{const target=ref.current;if(!target)return;window.Shiny?.initializeInputs?.(target);window.Shiny?.bindAll?.(target);return()=>window.Shiny?.unbindAll?.(target);},[host,id]);
  return <div ref={ref} className="sc-split-pane-content" data-pane-content={id} dangerouslySetInnerHTML={{__html:html||""}}/>;
}

function SplitPane({host,initialModel}){
  const modelRef=useRef(initialModel),groupRef=useRef(null),panelRefs=useRef(new Map());
  const model=modelRef.current,ids=model.ids||[];
  const logicalLayout=layout=>Object.fromEntries(ids.map(id=>[id,layout?.[`${host.id}-pane-${id}`]??layout?.[id]??0]));
  const readState=(event=null)=>{const sizes=logicalLayout(groupRef.current?.getLayout?.()||percentages(model.sizes,ids));const collapsed=ids.filter(id=>panelRefs.current.get(id)?.isCollapsed?.());return{componentId:host.id,direction:model.direction,paneIds:ids,sizes,collapsed,event};};
  const notify=(type,extra={})=>{requestAnimationFrame(()=>{window.dispatchEvent(new Event("resize"));host._splitValue=readState({type,nonce:nextNonce(),...extra});host.dispatchEvent(new CustomEvent("split-pane:change"));});};
  const reset=()=>{ids.forEach(id=>panelRefs.current.get(id)?.resize?.(model.sizes[id]));notify("reset");};
  useEffect(()=>{model.collapsed?.forEach(id=>panelRefs.current.get(id)?.collapse?.());host._splitController=message=>{
    const sizes=asMap(message.sizes,ids);if(message.reset)reset();else Object.entries(sizes).forEach(([id,size])=>panelRefs.current.get(id)?.resize?.(typeof size==="number"?`${size}%`:size));
    asArray(message.collapse).forEach(id=>panelRefs.current.get(id)?.collapse?.());asArray(message.expand).forEach(id=>panelRefs.current.get(id)?.expand?.());
    if(message.sizes||message.collapse||message.expand)notify("update",{source:"host"});
  };return()=>{delete host._splitController;};},[]);
  return <Group id={`${host.id}-group`} groupRef={groupRef} orientation={model.direction} className={`sc-split-group is-${model.direction}`}
    onLayoutChanged={(layout,meta)=>{host._splitValue={...readState(),sizes:logicalLayout(layout)};requestAnimationFrame(()=>window.dispatchEvent(new Event("resize")));if(meta.isUserInteraction)notify("resize",{source:"user"});}}>
    {ids.flatMap((id,index)=>{const panel=<Panel key={`panel-${id}`} id={`${host.id}-pane-${id}`} panelRef={value=>value?panelRefs.current.set(id,value):panelRefs.current.delete(id)} defaultSize={model.sizes[id]} minSize={model.minSizes[id]} maxSize={model.maxSizes[id]} collapsible={!!model.collapsible[id]} className="sc-split-panel"><PaneContent host={host} id={id} html={model.html?.[id]}/></Panel>;
      if(index===ids.length-1)return[panel];const separator=<Separator key={`separator-${id}`} id={`${host.id}-separator-${index+1}`} className="sc-split-separator" disableDoubleClick aria-label={`Resize ${id} and ${ids[index+1]}`} onDoubleClick={model.resetOnDoubleClick?reset:undefined}><span aria-hidden="true"/></Separator>;return[panel,separator];})}
  </Group>;
}

const binding=new Shiny.InputBinding();
Object.assign(binding,{find(scope){return window.jQuery(scope).find(".sc-split-pane");},initialize(element){if(element._splitRoot)return;const script=element.querySelector(`script[data-for="${CSS.escape(element.id)}"]`),model=JSON.parse(script?.textContent||"{}");element._splitValue={componentId:element.id,direction:model.direction,paneIds:model.ids,sizes:percentages(model.sizes,model.ids),collapsed:model.collapsed||[],event:null};element._splitRoot=createRoot(element.querySelector(".sc-split-pane-mount"));element._splitRoot.render(<SplitPane host={element} initialModel={model}/>);},getValue(element){return element._splitValue;},subscribe(element,callback){element._splitListener=()=>callback();element.addEventListener("split-pane:change",element._splitListener);},unsubscribe(element){element.removeEventListener("split-pane:change",element._splitListener);},receiveMessage(element,message){element._splitController?.(message);},getState(element){return element._splitValue;}});
Shiny.inputBindings.register(binding,"shinycapabilities.splitPane");
