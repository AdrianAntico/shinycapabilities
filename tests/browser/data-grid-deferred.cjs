// Presentation-only tests against the shipped grid bundle, not an analytical oracle.
const assert=require('node:assert/strict'),path=require('node:path');
const {chromium}=require(path.join(process.env.USERPROFILE,'.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright'));
(async()=>{const browser=await chromium.launch({channel:'chrome',headless:true});try{
 const page=await browser.newPage({viewport:{width:768,height:1024}});
 await page.setContent('<div id="first" style="height:280px"></div><div style="height:2000px"></div><div id="last" style="height:280px"></div><div id="hidden" hidden></div>');
 await page.evaluate(()=>{window.events=[];window.Shiny={setInputValue:(...x)=>events.push(x),addCustomMessageHandler(){}};window.ShinyCapabilitiesDirectTransport={register:(name,api)=>window.grid=api};});
 await page.addStyleTag({path:path.resolve(__dirname,'../../inst/www/direct-transport/data-grid.css')});
 await page.addScriptTag({path:path.resolve(__dirname,'../../inst/www/direct-transport/data-grid.js')});
 await page.evaluate(()=>{window.payload={rows:[{id:'a',value:17,'.sc_row_id':'a'}],columns:[{field:'id',scType:'text'},{field:'value',scType:'number'}],options:{defer_until_visible:true,selection:'none',quick_filter:true,density:'compact',empty_message:'No rows',loading_message:'Loading'}};
   window.handles=['first','last','hidden'].map(id=>grid.mount(document.getElementById(id),structuredClone(payload)));});
 await page.locator('#first .ag-root').waitFor();
 assert.equal(await page.locator('#last .ag-root').count(),0);
 assert.equal(await page.locator('#hidden .ag-root').count(),0);
 await page.evaluate(()=>grid.update(handles[1],{rows:[{id:'b',value:29,'.sc_row_id':'b'}],quickFilter:'b'}));
 await page.locator('#last').scrollIntoViewIfNeeded();
 await page.locator('#last .ag-root').waitFor();
 assert.equal(await page.locator('#last input').first().inputValue(),'b');
 assert.equal(await page.locator('#last [col-id="value"]').last().innerText(),'29');
 // Opening a previously hidden tab admits it. Focus never gets lost on mount.
 await page.evaluate(()=>{document.getElementById('hidden').hidden=false;document.querySelector('#hidden button').focus();});
 await page.locator('#hidden .ag-root').waitFor();
 assert(await page.evaluate(()=>document.getElementById('hidden').contains(document.activeElement)));
 await page.evaluate(()=>{grid.destroy(handles[1]);document.getElementById('last').remove();});
 await page.evaluate(()=>{const el=document.createElement('div');el.id='print';el.style.cssText='height:280px;margin-top:2000px';document.body.append(el);window.printHandle=grid.mount(el,structuredClone(payload));});
 assert.equal(await page.locator('#print .ag-root').count(),0);
 await page.evaluate(()=>window.dispatchEvent(new Event('beforeprint')));
 await page.locator('#print .ag-root').waitFor();
 // Unsupported observer falls back to existing eager mounting.
 await page.evaluate(()=>{window.IntersectionObserver=undefined;const el=document.createElement('div');el.id='fallback';document.body.append(el);window.fallback=grid.mount(el,structuredClone(payload));});
 assert.equal(await page.locator('#fallback .ag-root').count(),1);
 // Destroy before exposure must not later mount or retain its callbacks.
 await page.evaluate(()=>{for(const h of [handles[0],handles[2],printHandle,fallback])grid.destroy(h);});
 assert.equal(await page.locator('.ag-root').count(),0);
 console.log(JSON.stringify({status:'PASS',checks:['visible','offscreen','hidden','pending rows/filter','exposure','focus retention','print','fallback','destroy'],analyticalCalls:0}));
}finally{await browser.close();}})().catch(e=>{console.error(e);process.exitCode=1});
