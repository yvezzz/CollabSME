const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ 
    headless: false, 
    channel: 'chrome',
    args: ['--no-sandbox', '--disable-web-security']
  });
  const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
  
  // Track network requests
  const requests = [];
  page.on('request', req => requests.push({ url: req.url().substring(0, 100), status: 'pending' }));
  page.on('requestfinished', req => {
    const r = requests.find(r => r.url === req.url().substring(0, 100));
    if (r) r.status = req.response()?.status() || '?';
  });
  page.on('requestfailed', req => {
    const r = requests.find(r => r.url === req.url().substring(0, 100));
    if (r) r.status = 'FAILED: ' + req.failure()?.errorText;
  });
  
  page.on('console', msg => console.log('CONSOLE[' + msg.type() + ']', msg.text().substring(0, 200)));
  page.on('pageerror', err => console.log('PAGE_ERROR:', err.message.substring(0, 200)));

  console.log('Navigating...');
  await page.goto('https://collabsme-7e261.web.app', { waitUntil: 'load', timeout: 45000 });
  console.log('Page loaded, waiting for Flutter...');
  
  // Wait up to 45 seconds for canvas or errors
  for (let i = 0; i < 45; i++) {
    await page.waitForTimeout(1000);
    const hasCanvas = await page.evaluate(() => document.querySelectorAll('canvas').length);
    const bodyHTML = await page.evaluate(() => document.body.innerHTML.substring(0, 500));
    if (hasCanvas > 0) {
      console.log('Canvas found after ' + (i+1) + ' seconds!');
      break;
    }
  }
  
  const finalInfo = await page.evaluate(() => ({
    tags: [...new Set([...document.querySelectorAll('*')].map(e => e.tagName))],
    canvas: document.querySelectorAll('canvas').length,
    bodyLen: document.body.innerHTML.length,
    scripts: [...document.querySelectorAll('script')].map(s => s.src.substring(0, 80)),
  }));
  console.log('Final DOM:', JSON.stringify(finalInfo, null, 2));
  
  // Print network requests summary
  console.log('\nNetwork requests:');
  requests.forEach(r => {
    if (r.status !== 200) console.log('  ' + r.status + ' ' + r.url.substring(0, 100));
  });
  
  await page.screenshot({ path: 'screenshots/flutter-final.png' });
  console.log('Screenshot saved');
  
  await page.waitForTimeout(5000);
  await browser.close();
})().catch(e => {
  console.error('FATAL:', e.message);
  process.exit(1);
});
