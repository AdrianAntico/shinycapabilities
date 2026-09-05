async page => {
  const result = await page.evaluate(async () => {
    const transport = window.ShinyCapabilitiesDirectTransport;
    const value = Shiny.shinyapp.$values.record;
    if (!value?.payload) throw new Error('No real inspector payload');
    const baseline = transport.diagnostics();
    for (let i = 0; i < 3; i++) document.dispatchEvent(new Event('shiny:connected'));
    if (transport.diagnostics().mounts !== baseline.mounts) throw new Error('Reconnect initialization duplicated mounts');
    for (let i = 0; i < 120; i++) {
      const holder = document.createElement('div'); document.body.appendChild(holder);
      const element = document.createElement('div'); element.id = 'stress-inspector';
      element.className = 'sc-direct-component-output'; element.style.height = '180px';
      element.dataset.scDirectComponent = value.component;
      const script = document.createElement('script'); script.type = 'application/json';
      script.dataset.scDirectPayload = element.id; script.textContent = JSON.stringify(value);
      element.appendChild(script); holder.appendChild(element);
      await new Promise(resolve => setTimeout(resolve, 20));
      if (!element.querySelector('[role=tree]')) throw new Error('Inspector failed at cycle ' + i);
      element.style.display = 'none'; element.style.display = '';
      document.body.appendChild(element); holder.appendChild(element);
      holder.remove();
      await new Promise(resolve => setTimeout(resolve, 5));
      if (transport.diagnostics().liveInstances !== baseline.liveInstances) throw new Error('Leak at ' + i);
    }
    return {baseline, final: transport.diagnostics(), cycles: 120};
  });
  await page.evaluate(value => {window.lifecycleStress = value;}, result);
}
