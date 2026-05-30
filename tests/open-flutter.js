const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ 
    headless: false, 
    channel: 'chrome'
  });
  const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
  
  page.on('console', msg => console.log('CONSOLE:', msg.text()));
  page.on('pageerror', err => console.log('PAGE ERROR:', err.message));

  console.log('1. Opening app...');
  await page.goto('https://collabsme-7e261.web.app', { waitUntil: 'load', timeout: 30000 });
  await page.waitForTimeout(30000);

  console.log('2. Checking DOM...');
  const info = await page.evaluate(() => ({
    tags: [...new Set([...document.querySelectorAll('*')].map(e => e.tagName))],
    canvas: document.querySelectorAll('canvas').length,
    bodyHTML: document.body.innerHTML.substring(0, 3000),
    title: document.title,
  }));
  console.log('Page info:', JSON.stringify(info, null, 2));
  
  await page.screenshot({ path: 'screenshots/flutter-app.png' });
  console.log('3. Screenshot saved to screenshots/flutter-app.png');

  // If canvas exists, try interacting with it
  if (info.canvas > 0) {
    console.log('4. Canvas found, trying to interact...');
    const canvas = await page.$('canvas');
    if (canvas) {
      const box = await canvas.boundingBox();
      console.log('Canvas bounding box:', JSON.stringify(box));
      
      // Click center of canvas
      if (box) {
        await page.mouse.click(box.x + box.width/2, box.y + box.height/2);
        await page.waitForTimeout(2000);
        await page.screenshot({ path: 'screenshots/flutter-after-click.png' });
        console.log('5. Clicked center, screenshot saved');
      }
    }
  }

  console.log('6. Browser will stay open for 2 minutes for manual inspection...');
  await page.waitForTimeout(120000);
  await browser.close();
})().catch(e => {
  console.error('FATAL:', e.message);
  process.exit(1);
});
