const { chromium } = require('@playwright/test');
(async () => {
  const browser = await chromium.launch({ headless: true, channel: 'chrome' });
  const page = await browser.newPage();
  await page.goto('https://collabsme-7e261.web.app', { waitUntil: 'networkidle', timeout: 30000 });
  await page.screenshot({ path: 'screenshots/landing.png', fullPage: true });
  
  const html = await page.evaluate(() => document.body.innerHTML.substring(0, 5000));
  console.log('BODY HTML (first 5000 chars):');
  console.log(html);
  
  const texts = await page.evaluate(() => {
    const els = document.querySelectorAll('*');
    return Array.from(els).filter(e => e.children.length === 0 && e.textContent.trim()).slice(0, 30).map(e => e.tagName + ': "' + e.textContent.trim().substring(0, 50) + '"');
  });
  console.log('\nLeaf text elements:');
  texts.forEach(t => console.log(t));
  
  await browser.close();
})();
