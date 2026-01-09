// SPDX-License-Identifier: PolyForm-Shield-1.0.0
// Copyright (c) 2025-present Richard Mann
// Licensed under the PolyForm Shield License 1.0.0
// https://polyformproject.org/licenses/shield/1.0.0/

import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
    // Test directory - uses absolute path matching host path
    testDir: '/Users/claude-code/tests/playwright',

    // TypeScript configuration
    fullyParallel: true,
    forbidOnly: !!process.env.CI,
    retries: process.env.CI ? 2 : 0,
    workers: process.env.CI ? 1 : undefined,

    // Reporter configuration
    reporter: 'html',

    use: {
        baseURL: 'http://127.0.0.1:3000',
        trace: 'on-first-retry',
    },

    // Configure projects for major browsers
    projects: [
        {
            name: 'chromium',
            use: { ...devices['Desktop Chrome'] },
        },
        {
            name: 'firefox',
            use: { ...devices['Desktop Firefox'] },
        },
        {
            name: 'webkit',
            use: { ...devices['Desktop Safari'] },
        },
    ],
});