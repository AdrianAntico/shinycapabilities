const test=require('node:test'),assert=require('node:assert/strict'),vm=require('node:vm'),fs=require('node:fs'),path=require('node:path');
const source=fs.readFileSync(path.join(__dirname,'../../inst/www/foundation/foundation.js'),'utf8');
function fixture(){
  const listeners={},messages=[],handlers={},records=[{id:'a',enabled:true,payload:{expert:42}},{id:'b',enabled:false}];
  const root={id:'app',dataset:{},querySelector:()=>({textContent:JSON.stringify(records)}),dispatchEvent:()=>{}};
  const document={addEventListener:(name,fn)=>{listeners[name]=fn;},getElementById:()=>root,querySelectorAll:()=>[]};
  const Shiny={setInputValue:(id,event)=>messages.push({id,event}),addCustomMessageHandler:(id,fn)=>{handlers[id]=fn;}};
  const window={Shiny,dispatchEvent:()=>{}};
  vm.runInNewContext(source,{window,document,Shiny,crypto:{randomUUID:()=>String(messages.length)},CustomEvent:class{constructor(type,options){this.type=type;Object.assign(this,options);}},Event:class{}});
  return {api:window.ShinyCapabilitiesFoundation,listeners,messages,handlers,root};
}
test('command invocation retains payload and cannot imply authorization',()=>{
  const f=fixture(),r=f.api.invoke('app','a');assert.equal(r.accepted,true);assert.equal(r.event.payload.expert,42);
  assert.equal(r.event.stage,'INVOCATION');assert.equal(r.event.authorized,false);assert.equal(f.messages.length,1);
});
test('disabled and absent commands do not publish',()=>{
  const f=fixture();assert.equal(f.api.invoke('app','b').accepted,false);assert.equal(f.api.invoke('app','absent').accepted,false);assert.equal(f.messages.length,0);
});
test('Escape belongs to last live overlay',()=>{
  const f=fixture(),closed=[];const a={isConnected:true,contains:()=>false},b={isConnected:true,contains:()=>false};
  f.api.overlayOpen(a,()=>closed.push('a'));f.api.overlayOpen(b,()=>closed.push('b'));
  f.listeners.keydown({key:'Escape',preventDefault(){},stopImmediatePropagation(){}});assert.deepEqual(closed,['b']);
});
test('density message changes only presentation attributes',()=>{
  const f=fixture();f.handlers['shinycapabilities:frame']({id:'app',density:'dense',theme:'dark'});
  assert.deepEqual(f.root.dataset,{scTheme:'dark',scDensity:'dense'});assert.equal(f.messages.length,0);
  assert.equal(f.api.commands('app').length,2);
});
