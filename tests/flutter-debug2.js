const { chromium } = require('playwright');
const fs = require('fs');

(async () => {
  const browser = await chromium.launch({ 
    headless: true,
    channel: 'chrome',
    args: [
      '--no-sandbox',
      '--disable-setuid-sandbox',
      '--use-gl=angle',
      '--use-angle=swiftshader',
      '--enable-webgl',
      '--ignore-gpu-blocklist',
    ]
  });
  const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });

  const errors = [];
  page.on('console', msg => {
    const text = msg.text();
    if (msg.type() === 'error' || text.includes('Error') || text.includes('Failed') || text.includes('Exception')) {
      errors.push(`[${msg.type()}] ${text.substring(0, 300)}`);
    }
  });
  page.on('pageerror', err => errors.push(`[PAGE_ERROR] ${err.message.substring(0, 300)}`));

  // Check main.dart.js first
  console.log('Checking main.dart.js...');
  const mainJsResponse = await page.goto('https://collabsme-7e261.web.app/main.dart.js', { waitUntil: 'load', timeout: 15000 });
  const mainJsContent = await page.evaluate(() => document.body?.innerText || document.documentElement?.innerText || '');
  console.log('main.dart.js status:', mainJsResponse?.status(), 'size:', mainJsContent.length);

  // Go to the app
  console.log('\nLoading app...');
  await page.goto('https://collabsme-7e261.web.app', { waitUntil: 'load', timeout: 30000 });
  
  for (let i = 0; i < 30; i++) {
    await page.waitForTimeout(1000);
    const state = await page.evaluate(() => ({
      hasCanvas: document.querySelectorAll('canvas').length,
      hasFlutter: typeof _flutter !== 'undefined',
      hasFlutterApp: typeof _flutter !== 'undefined' && _flutter.loader !== undefined,
      bodyLen: document.body.innerHTML.length,
      scriptCount: document.querySelectorAll('script').length,
    }));
    if (state.hasCanvas > 0) {
      console.log(`Canvas found at ${i+1}s!`);
      console.log('State:', JSON.stringify(state));
      break;
    }
    if (i === 29) {
      console.log('No canvas after 30s. Final state:', JSON.stringify(state));
    }
  }

  console.log('\nErrors captured:', errors.length);
  errors.forEach(e => console.log('  ' + e));
  
  await page.screenshot({ path: 'screenshots/flutter-headless.png' });
  console.log('Screenshot saved');
  
  await browser.close();
})().catch(e => {
  console.error('FATAL:', e.message);
  process.exit(1);
});
