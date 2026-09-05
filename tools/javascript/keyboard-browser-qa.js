async page => {
  await page.goto(page.url());
  await page.locator('#status').filter({hasText: 'selected'}).waitFor();
  await page.keyboard.press('Control+k');
  await page.keyboard.type('asset-012');
  await page.keyboard.press('Enter');
  await page.locator('#status').filter({hasText: 'asset-012 selected'}).waitFor();
  const root = page.locator('#sites [role=treeitem]').first();
  await root.focus();
  await page.keyboard.press('ArrowRight');
  await page.keyboard.press('ArrowDown');
  await page.keyboard.press('Enter');
  await page.locator('#status').filter({hasText: 'asset-001 selected'}).waitFor();
  const cell = page.locator('#equipment .ag-row [col-id=id]').first();
  await cell.focus(); await page.keyboard.press('ArrowRight');
  const moved = await page.evaluate(() => document.activeElement.getAttribute('col-id') === 'site');
  if (!moved) throw new Error('Grid keyboard navigation failed');
  await page.getByRole('button', {name: 'Mark inspected', exact: true}).focus();
  await page.keyboard.press('Enter');
  await page.locator('#status').filter({hasText: '1 inspected'}).waitFor();
}
