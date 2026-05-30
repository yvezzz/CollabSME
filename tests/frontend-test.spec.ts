import { test, expect } from '@playwright/test';

const BASE_URL = 'https://collabsme-7e261.web.app';

test.describe('CollabSME Frontend QA', () => {

  test('Complet: chargement, rendu, responsive, navigation', async ({ page }) => {
    test.setTimeout(300000); // 5 min max

    // --- Helper: attendre le canvas Flutter ---
    async function waitCanvas(timeout = 120000) {
      await page.waitForSelector('canvas', { timeout });
      await page.waitForTimeout(3000);
      const box = await page.locator('canvas').boundingBox();
      expect(box?.width).toBeGreaterThan(100);
      expect(box?.height).toBeGreaterThan(100);
      return box;
    }

    // 1. Titre
    await page.goto(BASE_URL, { waitUntil: 'domcontentloaded' });
    const title = await page.title();
    expect(title).toContain('CollabSME');
    console.log(`Title: "${title}"`);

    // 2. Attente canvas (1er chargement = ~30-60s)
    console.log('Attente du canvas...');
    const canvas1 = await waitCanvas(180000);
    console.log(`Canvas initial: ${canvas1.width}x${canvas1.height}`);
    await page.screenshot({ path: 'screenshots/01-loaded.png', fullPage: true });

    // 3. Vérification absence crash
    const html = await page.locator('html').innerHTML();
    expect(html).not.toContain('flutter-error');
    expect(html).not.toContain('Error:');
    console.log('Aucun crash détecté');

    // 4. Éléments sémantiques Flutter
    const tabbable = await page.locator('[tabindex]').count();
    console.log(`Éléments focusables: ${tabbable}`);

    // 5. Test responsive desktop
    await page.setViewportSize({ width: 1280, height: 720 });
    await page.goto(BASE_URL, { waitUntil: 'domcontentloaded' });
    const canvasD = await waitCanvas(60000);
    console.log(`Desktop: ${canvasD.width}x${canvasD.height}`);
    await page.screenshot({ path: 'screenshots/02-desktop.png', fullPage: true });

    // 6. Test responsive tablette
    await page.setViewportSize({ width: 768, height: 1024 });
    await page.goto(BASE_URL, { waitUntil: 'domcontentloaded' });
    const canvasT = await waitCanvas(60000);
    console.log(`Tablette: ${canvasT.width}x${canvasT.height}`);
    await page.screenshot({ path: 'screenshots/03-tablet.png', fullPage: true });

    // 7. Test responsive mobile
    await page.setViewportSize({ width: 375, height: 812 });
    await page.goto(BASE_URL, { waitUntil: 'domcontentloaded' });
    const canvasM = await waitCanvas(60000);
    console.log(`Mobile: ${canvasM.width}x${canvasM.height}`);
    await page.screenshot({ path: 'screenshots/04-mobile.png', fullPage: true });

    // 8. Navigation clavier (tentative d'atteindre login)
    await page.setViewportSize({ width: 1280, height: 720 });
    await page.goto(BASE_URL, { waitUntil: 'domcontentloaded' });
    await waitCanvas(60000);
    // Tabuler à travers les éléments Flutter
    for (let i = 0; i < 30; i++) {
      await page.keyboard.press('Tab');
      await page.waitForTimeout(150);
    }
    await page.keyboard.press('Enter');
    await page.waitForTimeout(3000);
    await page.screenshot({ path: 'screenshots/05-navigation.png', fullPage: true });
    console.log('Test navigation clavier terminé');

    // 9. Capture scroll complet
    await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));
    await page.waitForTimeout(1000);
    await page.screenshot({ path: 'screenshots/06-scroll-bottom.png', fullPage: true });

    console.log('✅ Tous les tests frontend terminés');
  });

});
