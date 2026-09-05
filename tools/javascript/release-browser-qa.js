async page => {
  const fresh = await page.context().newCDPSession(page);
  await fresh.send('Network.clearBrowserCache'); await fresh.detach();
  await page.goto(page.url());
  await page.locator('#status').filter({hasText: 'selected'}).waitFor();
  await page.evaluate(() => {
    window.releaseQA = {atomic: [], layouts: [], overlays: []};
    document.getElementById('threshold-workbench').addEventListener('parameter-workbench:change', e => {
      const value = e.currentTarget._pwValue;
      if (value.event) window.releaseQA.atomic.push(JSON.parse(JSON.stringify(value)));
    });
  });
  const field = page.getByRole('spinbutton', {name: 'Downtime threshold'});
  for (const value of ['60', '65', '70']) {
    await field.fill(value);
    await page.getByRole('button', {name: 'Apply', exact: true}).click();
    await field.fill('-1');
    if (!(await page.getByRole('button', {name: 'Apply', exact: true}).isDisabled()))
      throw new Error('Invalid draft permits Apply');
    await page.getByRole('button', {name: 'Reset', exact: true}).click();
  }
  await field.fill('72');
  await page.getByRole('button', {name: 'Refresh host criteria'}).click();
  await page.waitForFunction(() => {
    const s = document.getElementById('threshold-workbench')._pwValue;
    return s.conflict && s.draft.downtime === 72 && s.applied.downtime === 35;
  });
  await page.getByRole('button', {name: 'Reset', exact: true}).click();
  await page.evaluate(() => {
    const seen = new Set();
    const first = window.releaseQA.atomic.filter(s => {
      if (seen.has(s.event.nonce)) return false;
      seen.add(s.event.nonce); return true;
    });
    if (first.length < 7) throw new Error('Missing Apply/Reset events');
    for (const s of first) {
      if (s.dirty || s.conflict || !s.valid || s.errors.length ||
          JSON.stringify(s.draft) !== JSON.stringify(s.applied) ||
          JSON.stringify(s.applied) !== JSON.stringify(s.event.values))
        throw new Error('Non-atomic event snapshot: ' + JSON.stringify(s));
    }
    window.releaseQA.atomicEvents = first.length;
  });
  await page.getByRole('button', {name: 'Open details', exact: true}).focus();
  await page.keyboard.press('Enter');
  await page.locator('#detail_dialog').waitFor({state: 'visible'});
  await page.keyboard.press('Control+k');
  const focusInside = await page.evaluate(() => document.getElementById('detail_dialog').contains(document.activeElement));
  if (!focusInside) throw new Error('Palette shortcut escaped modal focus');
  await page.getByRole('button', {name: 'Nested help', exact: true}).click();
  await page.keyboard.press('Escape');
  await page.keyboard.press('Escape');
  await page.locator('#detail_dialog').waitFor({state: 'hidden'});
  const returned = await page.evaluate(() => document.activeElement.id === 'open_details');
  await page.evaluate(value => {window.releaseQA.focusReturned = value;}, returned);
  if (!returned) throw new Error('Dialog did not return focus');
  await page.getByRole('button', {name: 'Context help', exact: true}).click();
  await page.keyboard.press('Escape');
  await page.getByRole('button', {name: 'Record actions'}).click({button: 'right'});
  await page.keyboard.press('Escape');
  const separator = page.getByRole('separator');
  await separator.focus(); await page.keyboard.press('ArrowRight'); await page.keyboard.press('ArrowLeft');
  await page.emulateMedia({reducedMotion: 'reduce', forcedColors: 'active'});
  for (const width of [1600, 1366, 900, 640]) {
    await page.setViewportSize({width, height: 1000});
    await page.waitForTimeout(700);
    const layout = await page.evaluate(() => ({width: innerWidth,
      documentWidth: document.documentElement.scrollWidth,
      plotWidth: document.querySelector('#distribution img')?.getBoundingClientRect().width,
      separatorFocus: getComputedStyle(document.querySelector('[role=separator]')).outlineStyle}));
    await page.evaluate(value => window.releaseQA.layouts.push(value), layout);
    await page.screenshot({path: `sc-release-${width}.png`, fullPage: true});
  }
  await page.emulateMedia({reducedMotion: 'no-preference', forcedColors: 'none'});
  await page.setViewportSize({width: 1366, height: 1000});
  const cdp = await page.context().newCDPSession(page);
  await cdp.send('Emulation.setTouchEmulationEnabled', {enabled: true, maxTouchPoints: 1});
  await page.getByRole('button', {name: 'Mark inspected', exact: true}).scrollIntoViewIfNeeded();
  const box = await page.getByRole('button', {name: 'Mark inspected', exact: true}).boundingBox();
  await cdp.send('Input.dispatchTouchEvent', {type: 'touchStart', touchPoints: [{x: box.x + 10, y: box.y + 10}]});
  await cdp.send('Input.dispatchTouchEvent', {type: 'touchEnd', touchPoints: []});
  await page.locator('#status').filter({hasText: '1 inspected'}).waitFor();
  await cdp.send('Emulation.setTouchEmulationEnabled', {enabled: false});
  await cdp.detach();
  await page.evaluate(() => {window.releaseQA.touchAction = 'PASS';});
}
