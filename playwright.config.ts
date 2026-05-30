import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './tests',
  timeout: 30000,
  use: {
    channel: 'chrome',
    headless: false,
    viewport: { width: 1280, height: 720 },
  },
});
