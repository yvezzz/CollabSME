const { chromium } = require('playwright');
(async () => {
  const browser = await chromium.launch({ headless: false, channel: 'chrome' });
  const page = await browser.newPage();
  page.on('console', msg => console.log('CONSOLE:', msg.text()));
  await page.goto('https://collabsme-7e261.web.app', { waitUntil: 'load', timeout: 30000 });
  console.log('Loaded. Waiting for Flutter...');
  await page.waitForTimeout(25000);
  
  const info = await page.evaluate(() => ({
    tags: [...new Set([...document.querySelectorAll('*')].map(e => e.tagName))],
    canvases: document.querySelectorAll('canvas').length,
    hasFlutter: typeof _flutter !== 'undefined',
  }));
  console.log('DOM info:', JSON.stringify(info, null, 2));
  await page.screenshot({ path: 'screenshots/flutter-render.png' });
  console.log('Screenshot saved to screenshots/flutter-render.png');
  
  await page.waitForTimeout(5000);
  await browser.close();
})();
