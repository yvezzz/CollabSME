import { test, expect } from '@playwright/test';

test('CollabSME - Test complet de l\'application', async ({ page }) => {
  // 1. Ouvrir l'app (déployée sur Firebase)
  await page.goto('https://collabsme-7e261.web.app');
  await page.screenshot({ path: 'screenshots/01-landing.png' });

  // 2. Login
  await page.click('text=Connexion');
  await page.fill('input[name="email"]', 'admin@collabsme.com');
  await page.fill('input[name="password"]', 'Admin1234');
  await page.click('button[type="submit"]');
  await expect(page).toHaveURL(/dashboard/);
  await page.screenshot({ path: 'screenshots/02-dashboard.png' });

  // 3. Vérifier le dashboard
  await expect(page.locator('text=Projets')).toBeVisible();
  await expect(page.locator('text=Tâches')).toBeVisible();

  // 4. Aller dans Projets
  await page.click('text=Projets');
  await page.screenshot({ path: 'screenshots/03-projets.png' });

  // 5. Créer un nouveau projet (modale)
  await page.click('text=Nouveau Projet');
  await expect(page.locator('.modal, [role="dialog"]')).toBeVisible();
  await page.fill('input[name="title"]', 'Projet Test Automatique');
  await page.fill('textarea[name="description"]', 'Description du projet test');
  await page.click('button:has-text("Créer")');
  await page.screenshot({ path: 'screenshots/04-projet-cree.png' });

  // 6. Aller sur le Kanban
  await page.click('text=Kanban');
  await expect(page.locator('text=À faire')).toBeVisible();
  await expect(page.locator('text=En cours')).toBeVisible();
  await expect(page.locator('text=Terminé')).toBeVisible();
  await page.screenshot({ path: 'screenshots/05-kanban.png' });

  // 7. Créer une tâche
  await page.click('text=Nouvelle tâche');
  await page.fill('input[name="title"]', 'Tâche test IA');
  await page.click('button:has-text("Créer")');
  await page.screenshot({ path: 'screenshots/06-tache-creee.png' });

  // 8. Tester drag & drop (simulation)
  const task = page.locator('.task-card:first-child');
  const targetColumn = page.locator('.kanban-column:has-text("En cours")');
  await task.dragTo(targetColumn);
  await page.screenshot({ path: 'screenshots/07-drag-drop.png' });

  // 9. Tester l'assistant IA
  await page.click('text=Assistant IA');
  await page.fill('textarea[placeholder*="question"]', 'Résume mon projet');
  await page.click('button:has-text("Envoyer")');
  await expect(page.locator('.ai-response')).toBeVisible();
  await page.screenshot({ path: 'screenshots/08-ia-assistant.png' });

  // 10. Vérifier les paramètres
  await page.click('text=Paramètres');
  await page.screenshot({ path: 'screenshots/09-parametres.png' });

  // 11. Vérifier les rapports
  await page.click('text=Rapports');
  await expect(page.locator('text=Taux complétion')).toBeVisible();
  await page.screenshot({ path: 'screenshots/10-rapports.png' });

  console.log('✅ Tests terminés avec succès !');
});