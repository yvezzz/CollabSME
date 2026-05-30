const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ 
    headless: true,
    channel: 'chrome',
    args: ['--no-sandbox', '--use-gl=angle', '--use-angle=swiftshader', '--enable-webgl', '--ignore-gpu-blocklist']
  });
  const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });

  // Check WebGL support first
  const webglInfo = await page.evaluate(() => {
    const canvas = document.createElement('canvas');
    const gl = canvas.getContext('webgl2') || canvas.getContext('webgl');
    if (!gl) return { supported: false, error: 'No WebGL context' };
    return {
      supported: true,
      version: gl instanceof WebGL2RenderingContext ? '2' : '1',
      vendor: gl.getParameter(gl.VENDOR),
      renderer: gl.getParameter(gl.RENDERER),
    };
  });
  console.log('WebGL info:', JSON.stringify(webglInfo, null, 2));

  // Check WasmGC support
  const wasmInfo = await page.evaluate(() => {
    try {
      const bytes = [0, 97, 115, 109, 1, 0, 0, 0, 1, 5, 1, 95, 1, 120, 0];
      return WebAssembly.validate(new Uint8Array(bytes));
    } catch (e) {
      return false;
    }
  });
  console.log('WasmGC support:', wasmInfo);

  // Now load the Flutter app with error tracking
  page.on('console', msg => {
    if (msg.type() === 'error') {
      console.log('[ERROR]', msg.text().substring(0, 500));
    }
  });
  page.on('pageerror', err => console.log('[PAGE_ERROR]', err.message.substring(0, 500)));

  // Intercept main.dart.js to check if it's loaded correctly
  await page.route('**/main.dart.js', async route => {
    const response = await route.fetch();
    const body = await response.text();
    console.log('main.dart.js loaded: length=' + body.length + ', startsWith=' + body.substring(0, 100));
    await route.fulfill({ response, body });
  });

  await page.goto('https://collabsme-7e261.web.app', { waitUntil: 'load', timeout: 30000 });
  
  for (let i = 0; i < 40; i++) {
    await page.waitForTimeout(1000);
    const state = await page.evaluate(() => {
      const flutter = window._flutter;
      return {
        hasCanvas: document.querySelectorAll('canvas').length,
        engineInitializer: flutter?.loader?.didCreateEngineInitializer ? 'yes' : 'no',
        bodyLen: document.body.innerHTML.length,
        scripts: [...document.querySelectorAll('script')].map(s => ({ src: (s.src || '').substring(0, 60), id: s.id })),
        errCount: window.__flutterErrors ? window.__flutterErrors.length : -1,
      };
    });
    if (state.hasCanvas > 0) {
      console.log(`Canvas found at ${i+1}s!`, JSON.stringify(state));
      break;
    }
    if (i === 0 || i === 10 || i === 20 || i === 30) {
      console.log(`State at ${i+1}s:`, JSON.stringify(state));
    }
  }

  await page.screenshot({ path: 'screenshots/flutter-webgl-check.png' });
  console.log('Done');
  await browser.close();
})().catch(e => {
  console.error('FATAL:', e.message);
  process.exit(1);
});
