(function () {
  'use strict';
  if (window.ShinyCapabilitiesFoundation) return;
  const overlays = [];
  const prune = () => { for (let i=overlays.length-1;i>=0;i--) if (!overlays[i].element.isConnected) overlays.splice(i,1); };
  const top = () => {prune(); return overlays[overlays.length-1];};
  const frame = id => typeof id === 'string' ? document.getElementById(id) : id;
  const commands = id => JSON.parse(frame(id)?.querySelector(':scope > script[data-sc-commands]')?.textContent || '[]');
  const invoke = (id, commandId, source = 'programmatic') => {
    const root=frame(id), command=commands(root).find(c=>c.id===commandId);
    if (!root || !command || !command.enabled) return {accepted:false,code:'COMMAND_UNAVAILABLE'};
    const event={command_id:command.id,payload:command.payload,source,stage:'INVOCATION',authorized:false,nonce:crypto.randomUUID()};
    root.dispatchEvent(new CustomEvent('shinycapabilities:command',{bubbles:true,detail:event}));
    window.Shiny?.setInputValue?.(`${root.id}_command`,event,{priority:'event'});
    return {accepted:true,event};
  };
  const api = window.ShinyCapabilitiesFoundation = {
    commands, invoke,
    overlayOpen(element, close, trigger) {api.overlayClose(element,false);overlays.push({element,close,trigger});},
    overlayClose(element, restore=true) {
      for(const child of overlays.slice().reverse())if(child.element!==element&&(element.contains(child.element)||(child.trigger&&element.contains(child.trigger))))child.close();
      const i=overlays.findIndex(x=>x.element===element);if(i<0)return;
      const [entry]=overlays.splice(i,1);if(restore&&entry.trigger?.isConnected)entry.trigger.focus({preventScroll:true});},
    shortcutAllowed(element) {const modal=overlays.slice().reverse().find(x=>x.element.matches('dialog[open]'))?.element || [...document.querySelectorAll('dialog[open]')].pop();return !modal || modal.contains(element);},
    overlayRoot(element) {return element.closest('dialog[open]') || element.closest('.sc-application-frame')?.querySelector(':scope > [data-sc-overlay-layer]') || document.body;}
  };
  document.addEventListener('keydown',event=>{
    const active=top();
    if(event.key==='Escape'&&active){event.preventDefault();event.stopImmediatePropagation();active.close();}
  },true);
  document.addEventListener('click',event=>{
    const button=event.target.closest('[data-sc-command]');if(!button||button.disabled)return;
    const root=button.closest('.sc-application-frame');if(root)invoke(root,button.dataset.scCommand,'human');
  });
  const register=()=>{if(!window.Shiny||window.__scFoundationRegistered)return;
    window.__scFoundationRegistered=true;
    Shiny.addCustomMessageHandler('shinycapabilities:frame',message=>{
      const root=frame(message.id);if(!root)return;
      if(['auto','light','dark'].includes(message.theme))root.dataset.scTheme=message.theme;
      if(['comfortable','compact','dense'].includes(message.density))root.dataset.scDensity=message.density;
      root.dispatchEvent(new CustomEvent('shinycapabilities:presentation',{bubbles:true}));
      window.dispatchEvent(new Event('resize'));
    });
  };
  register();document.addEventListener('shiny:connected',register);
}());
