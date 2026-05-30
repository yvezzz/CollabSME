const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true, channel: 'chrome' });
  const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
  
  page.on('console', msg => {
    const t = msg.text();
    if (msg.type() === 'error' || t.includes('Exception') || t.includes('Error')) 
      console.log('[ERR]', t.substring(0, 300));
  });
  page.on('pageerror', err => console.log('[PAGE_ERR]', err.message.substring(0, 200)));

  await page.goto('https://collabsme-7e261.web.app', { waitUntil: 'load', timeout: 30000 });
  
  let foundHtml = false;
  for (let i = 0; i < 30; i++) {
    await page.waitForTimeout(2000);
    const state = await page.evaluate(() => ({
      hasCanvas: document.querySelectorAll('canvas').length,
      hasFlutterText: document.body.innerText.length > 0,
      hasFlutterEls: document.querySelectorAll('flt-glass-pane, [class*=flt], a, button').length > 5,
      bodyLen: document.body.innerHTML.length,
      text: document.body.innerText.substring(0, 200),
    }));
    if (state.hasFlutterText || state.hasCanvas || state.hasFlutterEls) {
      console.log(`Flutter content found at ${(i+1)*2}s`);
      console.log('State:', JSON.stringify(state, null, 2));
      foundHtml = true;
      break;
    }
    if (i === 5 || i === 10 || i === 14) 
      console.log(`State at ${(i+1)*2}s:`, JSON.stringify(state));
  }
  
  await page.screenshot({ path: 'screenshots/flutter-html-renderer.png' });
  console.log('Screenshot saved');
  
  if (foundHtml) {
    // Try finding login elements
    const links = await page.evaluate(() => {
      return [...document.querySelectorAll('a, button, span, div')]
        .filter(el => el.textContent.toLowerCase().includes('connexion') || el.textContent.toLowerCase().includes('login'))
        .slice(0, 5)
        .map(el => ({ tag: el.tagName, text: el.textContent.substring(0, 30), id: el.id, class: el.className?.substring(0, 40) }));
    });
    console.log('Login elements found:', links);
  }
  
  await browser.close();
})().catch(e => {
  console.error('FATAL:', e.message);
  process.exit(1);
});
