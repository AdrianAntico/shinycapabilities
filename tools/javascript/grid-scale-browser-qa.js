async page => {
  const result = await page.evaluate(async () => {
    const results = [];
    for (const count of [10, 1000, 10000, 100000]) {
      const host = document.createElement('div'); document.body.appendChild(host);
      const rows = Array.from({length: count}, (_, i) => ({'.sc_row_id': `asset-${i}`,
        site: ['North', 'South', 'West'][i % 3], hours: 800 + (i * 137) % 5000,
        downtime: (i * 17) % 90, status: i % 7 ? 'available' : 'review'}));
      const payload = {component: 'data_grid', revision: 1, payload: {rows,
        columns: ['site', 'hours', 'downtime', 'status'].map(field => ({field, header_name: field})),
        options: {selection: 'single', density: 'compact', quick_filter: true,
          column_controls: true, publish_state: false, accessibility_mode: 'virtualized'}}};
      const start = performance.now();
      const element = document.createElement('div');
      element.id = `scale-${count}`; element.className = 'sc-direct-component-output';
      element.style.height = '360px'; element.dataset.scDirectComponent = 'data_grid';
      const script = document.createElement('script'); script.type = 'application/json';
      script.dataset.scDirectPayload = element.id; script.textContent = JSON.stringify(payload);
      element.appendChild(script); host.appendChild(element);
      await new Promise(resolve => setTimeout(resolve, 500));
      if (!element.querySelector('.ag-row')) throw new Error(`Grid ${count} did not render`);
      const mountedAt = performance.now();
      const search = element.querySelector('input[type=search]');
      if (!search) throw new Error('Missing quick filter');
      search.value = 'review'; search.dispatchEvent(new Event('input', {bubbles: true}));
      await new Promise(resolve => setTimeout(resolve, 100));
      const statuses = [...element.querySelectorAll('.ag-row [col-id=status]')].map(e => e.textContent);
      if (!statuses.length || statuses.some(value => value !== 'review')) throw new Error('Quick filtering failed');
      results.push({rows: count, millisecondsIncluding500msWait: mountedAt - start,
        filterMsIncluding100msWait: performance.now() - mountedAt,
        payloadBytes: new TextEncoder().encode(script.textContent).length,
        renderedRows: element.querySelectorAll('.ag-row').length});
      host.remove(); await new Promise(resolve => setTimeout(resolve, 50));
    }
    window.scScaleQA = results;
    return results;
  });
  console.log(JSON.stringify(result));
}
