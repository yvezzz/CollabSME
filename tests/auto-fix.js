const { execSync } = require('child_process');
const fs = require('fs-extra');
const axios = require('axios');

// Configuration
const BASE_URL = 'http://localhost:8000'; // Spring Boot (port 8000)
const TOKEN_FILE = './.test-token.json';
const BACKEND_DIR = '../backend';

// Couleurs pour logs
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

// ==================== PHASE 1 : TESTS API ====================

async function testAPI() {
  log('\n🔍 PHASE 1 : Tests des endpoints API...', 'blue');

  const tests = [
    { name: 'POST /api/auth/login/', method: 'post', url: '/api/auth/login/', data: { email: 'demo@collabsme.com', password: 'Demo123' }, expectedStatus: 200 },
    { name: 'GET /api/auth/me/', method: 'get', url: '/api/auth/me/', expectedStatus: 200, needsAuth: true },
    { name: 'GET /api/projects/', method: 'get', url: '/api/projects/', expectedStatus: 200, needsAuth: true },
    { name: 'GET /api/companies/detail/', method: 'get', url: '/api/companies/detail/', expectedStatus: 200, needsAuth: true },
    { name: 'POST /api/companies/members/', method: 'post', url: '/api/companies/members/', data: { email: 'test@example.com', role: 'MEMBER' }, expectedStatus: 200, needsAuth: true },
    { name: 'POST /api/ai/generate-task/', method: 'post', url: '/api/ai/generate-task/', data: { title: 'Test', project_id: 'dummy' }, expectedStatus: 200, needsAuth: true },
  ];

  let token = null;
  const results = [];

  for (const test of tests) {
    try {
      const headers = {};
      if (test.needsAuth && token) {
        headers['Authorization'] = `Bearer ${token}`;
      }

      let response;
      if (test.method === 'get') {
        response = await axios.get(`${BASE_URL}${test.url}`, { headers, validateStatus: false });
      } else {
        response = await axios[test.method](`${BASE_URL}${test.url}`, test.data || {}, { headers, validateStatus: false });
      }

      const passed = response.status === test.expectedStatus;
      results.push({ name: test.name, passed, status: response.status, expected: test.expectedStatus });
      log(`  ${passed ? '✅' : '❌'} ${test.name} (${response.status})`, passed ? 'green' : 'red');

      if (test.name === 'POST /api/auth/login/' && response.status === 200 && response.data?.tokens?.access) {
        token = response.data.tokens.access;
        fs.writeJSONSync(TOKEN_FILE, { token });
        log(`  📝 Token JWT sauvegardé`, 'green');
      }
    } catch (error) {
      results.push({ name: test.name, passed: false, error: error.message });
      log(`  ❌ ${test.name} - Erreur: ${error.message}`, 'red');
    }
  }

  return { results, token };
}

// ==================== PHASE 2 : CORRECTIONS BACKEND AUTOMATIQUES ====================

async function fixBackendErrors(apiResults) {
  log('\n🔧 PHASE 2 : Correction automatique du backend...', 'blue');

  const fixes = [];

  // Vérifier les erreurs courantes via les logs
  try {
    const logPath = '../backend/spring.log';
    const logContent = fs.existsSync(logPath) ? fs.readFileSync(logPath, 'utf8').slice(-5000) : '';
    const fixesToApply = [];

    // Correction 1 : LazyInitializationException
    if (logContent.includes('LazyInitializationException')) {
      log('  ⚠️ Détecté: LazyInitializationException', 'yellow');
      const companyServicePath = '../backend/src/main/java/com/collabsme/company/CompanyService.java';
      if (fs.existsSync(companyServicePath)) {
        let content = fs.readFileSync(companyServicePath, 'utf8');
        if (!content.includes('@Transactional')) {
          content = content.replace(
            'public class CompanyService {',
            '@Transactional\npublic class CompanyService {'
          );
          fs.writeFileSync(companyServicePath, content);
          fixes.push('Ajout de @Transactional dans CompanyService');
          log('  ✅ Correction: @Transactional ajouté dans CompanyService', 'green');
        }
      }
    }

    // Correction 2 : TransactionRequiredException dans AIController
    if (logContent.includes('TransactionRequiredException') && logContent.includes('AIController')) {
      log('  ⚠️ Détecté: TransactionRequiredException dans AIController', 'yellow');
      const aiControllerPath = '../backend/src/main/java/com/collabsme/ai/AIController.java';
      if (fs.existsSync(aiControllerPath)) {
        let content = fs.readFileSync(aiControllerPath, 'utf8');
        if (!content.includes('@Transactional')) {
          content = content.replace(
            '@DeleteMapping("/clear")',
            '@DeleteMapping("/clear")\n    @Transactional'
          );
          fs.writeFileSync(aiControllerPath, content);
          fixes.push('Ajout de @Transactional dans AIController.clear()');
          log('  ✅ Correction: @Transactional ajouté dans AIController', 'green');
        }
      }
    }

    // Correction 3 : Repository delete sans @Modifying
    if (logContent.includes('TransactionRequiredException') && logContent.includes('deleteByUser')) {
      log('  ⚠️ Détecté: TransactionRequiredException dans repository deleteByUser', 'yellow');
      const repoPath = '../backend/src/main/java/com/collabsme/ai/AIChatRepository.java';
      if (fs.existsSync(repoPath)) {
        let content = fs.readFileSync(repoPath, 'utf8');
        if (!content.includes('@Modifying')) {
          content = content.replace(
            'void deleteByUser(User user);',
            '@Modifying\n    @Transactional\n    void deleteByUser(User user);'
          );
          fs.writeFileSync(repoPath, content);
          fixes.push('Ajout de @Modifying et @Transactional dans deleteByUser');
          log('  ✅ Correction: @Modifying ajouté dans AIChatRepository', 'green');
        }
      }
    }

  } catch (error) {
    log(`  ⚠️ Impossible de lire les logs: ${error.message}`, 'yellow');
  }

  // Recompiler après corrections
  if (fixes.length > 0) {
    log('\n  🔨 Recompilation du backend...', 'blue');
    try {
      execSync('mvnw.cmd clean compile', { cwd: '../backend', stdio: 'inherit', timeout: 120000 });
      log('  ✅ Recompilation réussie', 'green');
    } catch (error) {
      log(`  ❌ Erreur recompilation: ${error.message}`, 'red');
    }
  } else {
    log('  ℹ️ Aucune correction backend nécessaire', 'green');
  }

  return fixes;
}

// ==================== PHASE 3 : TESTS PLAYWRIGHT ====================

async function runPlaywrightTests() {
  log('\n🧪 PHASE 3 : Tests frontend avec Playwright...', 'blue');

  try {
    execSync('npx playwright test', { cwd: '..', stdio: 'inherit', timeout: 60000 });
    log('  ✅ Tests Playwright réussis', 'green');
    return true;
  } catch (error) {
    log(`  ❌ Tests Playwright échoués`, 'red');
    return false;
  }
}

// ==================== PHASE 4 : CORRECTIONS FRONTEND ====================

async function fixFrontendErrors() {
  log('\n🔧 PHASE 4 : Correction automatique du frontend...', 'blue');

  const fixes = [];

  // Correction 1 : Supprimer le champ photo URL du profil
  const profilePath = '../lib/presentation/screens/profile/profile_screen.dart';
  if (fs.existsSync(profilePath)) {
    let content = fs.readFileSync(profilePath, 'utf8');
    if (content.includes('Photo de profil') && content.includes('URL')) {
      const cleaned = content.replace(
        /TextField.*Photo de profil.*URL.*\n.*\n.*\n.*\n.*\n.*/g,
        ''
      );
      fs.writeFileSync(profilePath, cleaned);
      fixes.push('Suppression du champ "Photo de profil (URL)"');
      log('  ✅ Correction: Champ photo URL supprimé', 'green');
    }
  }

  // Correction 2 : Remplacer l'export CSV
  const reportPath = '../lib/presentation/screens/reports/reports_screen.dart';
  if (fs.existsSync(reportPath)) {
    let content = fs.readFileSync(reportPath, 'utf8');
    if (content.includes('_Namespace') || content.includes('Unsupported operation')) {
      const exportFunction = `
  void exportToCsv(List<List<dynamic>> rows) {
    final String csv = const ListToCsvConverter().convert(rows);
    final blob = html.Blob([csv], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', 'rapport.csv')
      ..click();
    html.Url.revokeObjectUrl(url);
  }`;
      content = content.replace(
        /void _exportCsv\(\) \{.*?\}/s,
        exportFunction
      );
      fs.writeFileSync(reportPath, content);
      fixes.push('Correction export CSV');
      log('  ✅ Correction: Export CSV réparé', 'green');
    }
  }

  return fixes;
}

// ==================== PHASE 5 : RAPPORT FINAL ====================

function generateReport(apiResults, backendFixes, frontendFixes, testsPassed) {
  log('\n📊 RAPPORT FINAL', 'blue');
  console.log('═'.repeat(60));

  // Résumé des tests API
  const apiPassed = apiResults.filter(r => r.passed).length;
  const apiTotal = apiResults.length;
  log(`\n📡 Tests API: ${apiPassed}/${apiTotal} réussis`, apiPassed === apiTotal ? 'green' : 'yellow');

  // Corrections appliquées
  if (backendFixes.length > 0) {
    log(`\n🔧 Corrections backend (${backendFixes.length}):`, 'green');
    backendFixes.forEach(f => log(`  - ${f}`, 'green'));
  }

  if (frontendFixes.length > 0) {
    log(`\n🎨 Corrections frontend (${frontendFixes.length}):`, 'green');
    frontendFixes.forEach(f => log(`  - ${f}`, 'green'));
  }

  // Statut global
  const allPassed = apiPassed === apiTotal && testsPassed;
  log(`\n🏁 STATUT GLOBAL: ${allPassed ? '✅ TOUT FONCTIONNE' : '⚠️ CORRECTIONS APPLIQUÉES, RELANCEZ LES TESTS'}`, allPassed ? 'green' : 'yellow');

  // Export JSON
  const report = {
    timestamp: new Date().toISOString(),
    api: { total: apiTotal, passed: apiPassed, details: apiResults },
    backendFixes,
    frontendFixes,
    testsPassed,
    allPassed,
  };
  fs.writeJSONSync('./test-report.json', report, { spaces: 2 });
  log(`\n📁 Rapport sauvegardé: test-report.json`, 'blue');
}

// ==================== MAIN ====================

async function main() {
  log('\n🚀 AUTO-CORRECTEUR COLLABSME - DÉMARRAGE', 'blue');
  console.log('═'.repeat(60));

  // 1. Tests API
  const { results: apiResults, token } = await testAPI();

  // 2. Corrections backend
  const backendFixes = await fixBackendErrors(apiResults);

  // 3. Relancer Spring Boot si corrections effectuées
  if (backendFixes.length > 0) {
    log('\n♻️ Redémarrage du backend...', 'blue');
    // Ici, vous pouvez ajouter la commande pour relancer Spring Boot
  }

  // 4. Corrections frontend
  const frontendFixes = await fixFrontendErrors();

  // 5. Tests Playwright
  const testsPassed = await runPlaywrightTests();

  // 6. Rapport final
  generateReport(apiResults, backendFixes, frontendFixes, testsPassed);
}

// Lancer le script
main().catch(console.error);