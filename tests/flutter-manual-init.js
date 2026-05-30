const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ 
    headless: true,
    channel: 'chrome',
    args: ['--no-sandbox', '--use-gl=angle', '--use-angle=swiftshader', '--enable-webgl', '--ignore-gpu-blocklist']
  });
  const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });

  page.on('pageerror', err => console.log('[PAGE_ERROR]', err.message.substring(0, 300)));

  // Override Flutter engine init to be faster
  await page.addInitScript(() => {
    // Store original Flutter loader
    const origPushState = history.pushState;
    
    // Speed up timeouts
    const origSetTimeout = window.setTimeout;
    window.setTimeout = (fn, ms, ...args) => origSetTimeout(fn, Math.min(ms, 50), ...args);
  });

  await page.goto('https://collabsme-7e261.web.app', { waitUntil: 'load', timeout: 30000 });

  // Inject a test to manually try initializing the engine if it doesn't auto-init
  for (let i = 0; i < 60; i++) {
    await page.waitForTimeout(1000);
    const state = await page.evaluate(() => {
      const f = window._flutter;
      return {
        canvas: document.querySelectorAll('canvas').length,
        hasInit: !!f?.loader?.didCreateEngineInitializer,
        hasBoot: !!f?.bootstrap,
        bodyLen: document.body.innerHTML.length,
      };
    });
    if (state.canvas > 0) {
      console.log(`CANVAS RENDERED at ${i+1}s!`);
      break;
    }
    if (i === 10 || i === 30 || i === 50) {
      console.log(`State at ${i+1}s:`, JSON.stringify(state));
      if (state.hasInit && state.canvas === 0 && i === 50) {
        // Try to manually init the engine
        console.log('Trying manual engine init...');
        await page.evaluate(async () => {
          try {
            const f = window._flutter;
            if (f?.loader?.didCreateEngineInitializer) {
              const init = f.loader.didCreateEngineInitializer;
              f.loader.didCreateEngineInitializer = null;
              const engine = await init();
              if (engine?.initializeEngine) {
                await engine.initializeEngine({});
              }
              if (engine?.runApp) {
                engine.runApp();
              }
            }
          } catch(e) {
            console.error('Manual init error:', e);
          }
        });
      }
    }
  }

  await page.screenshot({ path: 'screenshots/flutter-manual-init.png' });
  console.log('Final screenshot saved');
  
  // Check what's in the body now
  const finalHTML = await page.evaluate(() => document.body.innerHTML.substring(0, 500));
  console.log('Final body:', finalHTML);
  
  await browser.close();
})().catch(e => {
  console.error('FATAL:', e.message);
  process.exit(1);
});
