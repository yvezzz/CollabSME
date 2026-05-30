const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ 
    headless: true,
    channel: 'chrome',
    args: ['--no-sandbox', '--use-gl=angle', '--use-angle=swiftshader', '--enable-webgl', '--ignore-gpu-blocklist']
  });
  const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });

  // Block service worker and intercept SW registration
  page.on('console', msg => {
    const text = msg.text();
    if (text.includes('Error') || text.includes('error') || text.includes('Exception') || text.includes('Failed') || text.includes('canvas') || text.includes('Canvas') || text.includes('webgl') || text.includes('WebGL') || msg.type() === 'error') {
      console.log(`[${msg.type()}] ${text.substring(0, 300)}`);
    }
  });
  page.on('pageerror', err => console.log('[PAGE_ERROR]', err.message.substring(0, 300)));

  // Bypass service worker: mock navigator.serviceWorker
  await page.addInitScript(() => {
    // Speed up service worker by mocking it to resolve immediately
    const origRegister = navigator.serviceWorker?.register;
    if (navigator.serviceWorker) {
      navigator.serviceWorker.register = () => Promise.resolve({
        active: null,
        installing: null,
        waiting: null,
        addEventListener: () => {},
        removeEventListener: () => {},
      });
    }
    // Also override ready to resolve quickly
    if (navigator.serviceWorker) {
      navigator.serviceWorker.ready = Promise.resolve({
        active: null,
        installing: null,
        waiting: null,
      });
    }
  });

  console.log('Loading app (with SW bypass)...');
  await page.goto('https://collabsme-7e261.web.app', { waitUntil: 'load', timeout: 30000 });
  
  for (let i = 0; i < 30; i++) {
    await page.waitForTimeout(1000);
    const state = await page.evaluate(() => ({
      hasCanvas: document.querySelectorAll('canvas').length,
      hasFlutterFrame: !!document.querySelector('flt-glass-pane, flt-scene, .flt-renderer'),
      hasFlutterLoaded: typeof _flutter !== 'undefined' && _flutter.loader && _flutter.loader.didCreateEngineInitializer,
      bodyHTML: document.body.innerHTML.substring(0, 300),
    }));
    if (state.hasCanvas > 0 || state.hasFlutterFrame) {
      console.log(`Canvas/Frame found at ${i+1}s!`);
      console.log('State:', JSON.stringify(state));
      break;
    }
    if (i === 29) {
      console.log(`No canvas after 30s. State:`, JSON.stringify(state));
    }
  }

  await page.screenshot({ path: 'screenshots/flutter-sw-bypass.png' });
  console.log('Screenshot saved');
  
  await browser.close();
})().catch(e => {
  console.error('FATAL:', e.message);
  process.exit(1);
});
