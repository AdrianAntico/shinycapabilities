const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs'), vm = require('node:vm'), path = require('node:path');
// Exercise the actual renderer source; AG Grid numerical/UI internals are unchanged.
const source = fs.readFileSync(path.join(__dirname,'src/data-grid.js'),'utf8');
const start = source.indexOf('function renderGrid('), stop = source.indexOf('  const controller =',start);
const initialize = source.slice(start,stop)+'\n}';
for (const bound of [false,true]) test('grid activation preserves lifecycle ownership: bound='+bound,()=>{
  const classes = new Set(['sc-direct-component-output','host-owned','sc-data-grid--compact']);
  if(bound) classes.add('shiny-bound-output');
  const element = {classList:{[Symbol.iterator]:()=>classes.values(),add:(...x)=>x.forEach(y=>classes.add(y)),remove:x=>classes.delete(x)},replaceChildren(){},
    get className(){return [...classes].join(' ');},set className(x){classes.clear();x.split(/\s+/).forEach(y=>classes.add(y));}};
  const environment={gridInstances:new WeakMap()}; vm.runInNewContext(initialize+';this.render=renderGrid',environment);
  environment.render(element,{options:{density:'dense'}});
  assert.equal(classes.has('sc-direct-component-output'),true);
  assert.equal(classes.has('shiny-bound-output'),bound);
  assert.equal(classes.has('host-owned'),true);
  assert.equal(classes.has('sc-data-grid--compact'),false);
  assert.equal(classes.has('sc-data-grid--dense'),true);
});
