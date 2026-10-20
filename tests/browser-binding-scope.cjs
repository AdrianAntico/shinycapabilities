// Exercise the delivered binding against Shiny's DOM/jQuery scope protocol.
// No Product actions, renderer state, or synthetic click count is injected.
const fs = require("node:fs"), vm = require("node:vm"), assert = require("node:assert/strict");
const path = require("node:path");
const asset = process.argv[2] || path.join(__dirname, "../inst/www/browser-controls/browser-controls.js");
const bindings = {};
let normalizations = 0;
const window = {
  jQuery(scope) {
    normalizations++;
    if (scope.jquery) return scope;
    return {find: selector => scope.querySelectorAll(selector)};
  },
  Shiny: {InputBinding: function(){}, inputBindings: {register(binding, name){bindings[name]=binding;}}}
};
const document = {readyState:"complete", addEventListener(){}};
vm.runInNewContext(fs.readFileSync(asset,"utf8"), {window,document,Shiny:window.Shiny,WeakMap,WeakSet,console});
let assertions=0;
for (const [name, selector] of [
  ["browserControls",".sc-browser-control[data-sc-control]"],
  ["browserActions",".sc-browser-action[data-sc-action]"]
]) {
  const binding=bindings["shinycapabilities."+name];
  for (const kind of ["document","element","fragment","jquery"]) {
    const inside=[{id:"inside"}];
    const query=s=>s===selector?inside:[];
    const scope=kind==="jquery"?{jquery:"3.x",find:query}:{nodeType:kind==="document"?9:kind==="fragment"?11:1,querySelectorAll:query};
    assert.equal(binding.find(scope),inside,`${name}: ${kind} retains scoped membership`);
    assertions++;
  }
  assert.deepEqual(binding.find({jquery:"3.x",find:()=>[]}),[]);
  assertions++;
}
assert.equal(normalizations,10);
assert.equal(bindings["shinycapabilities.browserActions"].getValue({id:"unacted"}),null);
console.log(JSON.stringify({pass:true,scope_assertions:assertions,no_initial_synthetic_click:true}));
