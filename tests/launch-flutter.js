const { chromium } = require('@playwright/test');
(async () => {
  const browser = await chromium.launch({ headless: false, channel: 'chrome' });
  const page = await browser.newPage();
  
  page.on('console', msg => console.log('CONSOLE:', msg.type(), msg.text()));
  page.on('pageerror', err => console.log('PAGE ERROR:', err.message));
  
  await page.goto('https://collabsme-7e261.web.app', { waitUntil: 'load', timeout: 60000 });
  console.log('Page loaded, waiting for Flutter init...');
  await page.waitForTimeout(20000);
  
  await page.screenshot({ path: 'screenshots/frontend.png', fullPage: false });
  console.log('Screenshot saved');
  
  // Check DOM
  const info = await page.evaluate(() => ({
    tags: Array.from(document.querySelectorAll('*')).map(e => e.tagName).filter((v,i,a)=>a.indexOf(v)===i),
    canvasCount: document.querySelectorAll('canvas').length,
    bodyHTML: document.body.innerHTML.substring(0, 2000)
  }));
  console.log('Tags:', info.tags);
  console.log('Canvas count:', info.canvasCount);
  console.log('Body HTML:', info.bodyHTML);
  
  // Try to inject JS bridge for Flutter
  const hasFlutter = await page.evaluate(() => typeof window._flutter !== 'undefined');
  console.log('Has Flutter bridge:', hasFlutter);
  
  // Close after 10 more seconds
  await page.waitForTimeout(10000);
  await browser.close();
})();
