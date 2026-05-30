const { chromium } = require('@playwright/test');
(async () => {
  const browser = await chromium.launch({ headless: true, channel: 'chrome', args: ['--no-sandbox'] });
  const page = await browser.newPage();
  
  page.on('console', msg => console.log('CONSOLE:', msg.type(), msg.text()));
  page.on('pageerror', err => console.log('PAGE ERROR:', err.message));
  
  await page.goto('https://collabsme-7e261.web.app', { waitUntil: 'load', timeout: 30000 });
  console.log('Page loaded, waiting for Flutter init...');
  await page.waitForTimeout(15000);
  
  await page.screenshot({ path: 'screenshots/landing3.png', fullPage: true });
  console.log('Screenshot saved');
  
  const html = await page.evaluate(() => document.body.innerHTML.substring(0, 5000));
  console.log('HTML:', html.substring(0, 1000));
  
  const tags = await page.evaluate(() => {
    const all = document.querySelectorAll('*');
    const tagSet = new Set();
    all.forEach(el => tagSet.add(el.tagName));
    return Array.from(tagSet);
  });
  console.log('Tags:', tags);
  
  await browser.close();
})();
