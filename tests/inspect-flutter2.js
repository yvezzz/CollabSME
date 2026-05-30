const { chromium } = require('@playwright/test');
(async () => {
  const browser = await chromium.launch({ headless: true, channel: 'chrome' });
  const page = await browser.newPage();
  await page.goto('https://collabsme-7e261.web.app', { waitUntil: 'domcontentloaded', timeout: 30000 });
  
  // Wait for Flutter to initialize (canvas or flt-tree)
  try {
    await page.waitForSelector('canvas, flt-glass-pane, [class*="flt"]', { timeout: 20000 });
  } catch(e) {
    console.log('No canvas/flt element found after 20s');
  }
  
  await page.screenshot({ path: 'screenshots/landing2.png', fullPage: true });
  console.log('Screenshot saved');
  
  // Full HTML
  const html = await page.evaluate(() => document.body.innerHTML.substring(0, 10000));
  console.log('HTML:', html);
  
  // Check for canvas
  const hasCanvas = await page.evaluate(() => !!document.querySelector('canvas'));
  console.log('Has canvas:', hasCanvas);
  
  // Check all tags
  const tags = await page.evaluate(() => {
    const all = document.querySelectorAll('*');
    const tagSet = new Set();
    all.forEach(el => tagSet.add(el.tagName));
    return Array.from(tagSet);
  });
  console.log('Tags:', tags);
  
  await browser.close();
})();
