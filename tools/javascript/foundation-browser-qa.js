async page => {
  const cdp=await page.context().newCDPSession(page);await cdp.send('Network.clearBrowserCache');await cdp.detach();await page.reload();
  await page.locator('#status').filter({hasText:'selected'}).waitFor();
  await page.locator('#record-search').waitFor();
  await page.locator('#review_commands input').waitFor();
  await page.waitForFunction(()=>!document.querySelector('#review_commands').classList.contains('recalculating'));
  const baseline=await page.evaluate(()=>({commands:ShinyCapabilitiesFoundation.commands('review_app'),
    values:[document.querySelector('#due-control').value,document.querySelector('#appointment-control').value],
    fields:[...document.querySelectorAll('#review_app input')].map(x=>x.id).sort()}));
  const results=[];
  for(const width of [1600,1366,900,640]) for(const theme of ['light','dark','auto']) for(const density of ['comfortable','compact','dense']) {
    await page.setViewportSize({width,height:1000});
    await page.evaluate(({theme,density})=>{document.querySelector('#theme').selectize.setValue(theme);document.querySelector('#density').selectize.setValue(density);},{theme,density});
    await page.waitForFunction(({theme,density})=>{const f=document.querySelector('#review_app');return f.dataset.scTheme===theme&&f.dataset.scDensity===density;},{theme,density});
    const data=await page.evaluate(()=>({commands:ShinyCapabilitiesFoundation.commands('review_app'),
      values:[document.querySelector('#due-control').value,document.querySelector('#appointment-control').value],
      fields:[...document.querySelectorAll('#review_app input')].map(x=>x.id).sort(),
      controlHeight:document.querySelector('#due-control').getBoundingClientRect().height,
      gridHeight:document.querySelector('.ag-row')?.getBoundingClientRect().height,
      background:getComputedStyle(document.querySelector('#review_app')).backgroundColor,
      overflow:document.documentElement.scrollWidth>innerWidth}));
    if(JSON.stringify(data.commands)!==JSON.stringify(baseline.commands)||JSON.stringify(data.values)!==JSON.stringify(baseline.values)||JSON.stringify(data.fields)!==JSON.stringify(baseline.fields))throw Error('Presentation changed capability/state: '+JSON.stringify({baseline,data,width,theme,density}));
    if(data.overflow)throw Error(`Page overflow ${width}/${theme}/${density}`);
    results.push({width,theme,density,...data});
  }
  await page.getByRole('button',{name:'Priority Routine service',exact:true}).click();
  await page.getByRole('option',{name:'Urgent repair',exact:true}).click();
  await page.getByRole('button',{name:'Priority Urgent repair',exact:true}).waitFor();
  await page.waitForFunction(()=>document.activeElement.getAttribute('aria-labelledby')==='priority-label priority-summary');
  await page.keyboard.press('Control+k');
  await page.waitForFunction(()=>document.querySelector('#find').contains(document.activeElement));
  await page.getByRole('button',{name:'Review details',exact:true}).click();
  await page.locator('#review_details[open]').waitFor();
  await page.getByRole('button',{name:'Assignee Service team',exact:true}).click();
  await page.locator('#review_details [data-selection-popup=assignee]').waitFor();
  await page.keyboard.press('Escape');
  await page.waitForFunction(()=>document.activeElement.getAttribute('aria-labelledby')==='assignee-label assignee-summary');
  if(!await page.locator('#review_details').evaluate(x=>x.open))throw Error('Escape crossed modal boundary');
  await page.keyboard.press('Control+k');
  if(!await page.locator('#review_details').evaluate(x=>x.contains(document.activeElement)))throw Error('Palette escaped modal');
  await page.keyboard.press('Escape');
  await page.waitForFunction(()=>document.activeElement.id==='open_review');
  const invocation=await page.evaluate(()=>({allowed:ShinyCapabilitiesFoundation.invoke('review_app','review'),denied:ShinyCapabilitiesFoundation.invoke('review_app','export')}));
  if(!invocation.allowed.accepted||invocation.allowed.event.authorized||invocation.denied.accepted)throw Error('Invocation authority mismatch');
  await page.getByRole('button',{name:'Request review',exact:true}).click();
  await page.locator('#command_status').filter({hasText:'human'}).waitFor();
  const field=await page.evaluate(()=>{
    const root=document.querySelector('#note'), binding=window.jQuery(root).data('shiny-input-binding');
    binding.receiveMessage(root,{warning:'Watch',error:'Required evidence',loading:true,disabled:true,help:'Details',required:true});
    const blocked=binding.getState(root);
    binding.receiveMessage(root,{error:null,loading:false,disabled:false,value:'Reviewed'});
    const ready=binding.getState(root);
    return {blocked,ready,described:document.querySelector('#note-control').getAttribute('aria-describedby')};
  });
  if(field.blocked.valid||!field.blocked.disabled||!field.blocked.loading||field.ready.error||!field.ready.valid||field.ready.warning!=='Watch'||!field.described.includes('note-warning'))throw Error('Field state lost');
  await page.evaluate(value=>window.foundationQA=value,{results,invocation});
  await page.screenshot({path:'sc-foundation-640.png',fullPage:true});
}
