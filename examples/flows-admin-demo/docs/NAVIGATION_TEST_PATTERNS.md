# Navigation Test Patterns - Best Practices

## Overview

This document provides concrete patterns and examples for implementing robust navigation tests that won't break when demo content changes.

## Key Patterns

### 1. Use Data Attributes Instead of Content

```svelte
<!-- In your Svelte components -->
<button 
  data-testid="tab-offboarding"
  data-active={activeTab === 'offboarding'}
  class="tab-button"
>
  Offboarding
</button>

<div data-testid="view-overview" data-view-active={offboardingView === 'overview'}>
  <!-- Overview content -->
</div>
```

```javascript
// In your tests
test('navigate to offboarding overview', async ({ page }) => {
  // Don't rely on text content
  // BAD: await page.click('text=Offboarding');
  
  // Use data-testid
  await page.click('[data-testid="tab-offboarding"]');
  
  // Verify navigation succeeded
  await expect(page.locator('[data-testid="view-overview"]')).toBeVisible();
  await expect(page.locator('[data-testid="tab-offboarding"]')).toHaveAttribute('data-active', 'true');
});
```

### 2. Create Navigation Helper Functions

```javascript
// tests/helpers/navigation.js
export class NavigationHelper {
  constructor(page) {
    this.page = page;
  }

  async navigateToOffboarding() {
    await this.page.click('[data-testid="tab-offboarding"]');
    await this.page.waitForSelector('[data-testid="view-overview"]');
    return this.verifyOffboardingActive();
  }

  async navigateToOffboardingView(view) {
    await this.page.click(`[data-testid="offboarding-view-${view}"]`);
    await this.page.waitForSelector(`[data-testid="view-${view}"]`);
    return this.verifyViewActive(view);
  }

  async verifyOffboardingActive() {
    const tab = this.page.locator('[data-testid="tab-offboarding"]');
    await expect(tab).toHaveAttribute('data-active', 'true');
  }

  async verifyViewActive(view) {
    const viewElement = this.page.locator(`[data-testid="view-${view}"]`);
    await expect(viewElement).toHaveAttribute('data-view-active', 'true');
  }
}
```

### 3. Mock Data for Consistent Testing

```javascript
// tests/fixtures/offboarding.fixtures.js
export const mockOffboardingData = {
  templates: [
    {
      id: 'template-1',
      name: 'Standard Offboarding',
      type: 'company_wide',
      task_count: 15
    }
  ],
  processes: [
    {
      id: 'process-1',
      process_name: 'Test Employee Offboarding',
      status: 'active',
      completion_percentage: 45
    }
  ],
  metrics: {
    activeProcesses: 3,
    endingSoon: 1,
    recentlyCompleted: 5,
    needsAttention: 2
  }
};

// In your test
test.beforeEach(async ({ page }) => {
  // Mock API responses
  await page.route('**/api/offboarding/metrics', route => 
    route.fulfill({ json: mockOffboardingData.metrics })
  );
});
```

### 4. Test Navigation State Transitions

```javascript
test('navigation maintains state correctly', async ({ page }) => {
  const nav = new NavigationHelper(page);
  
  // Track navigation state
  const navigationState = {
    previousTab: null,
    currentTab: null,
    previousView: null,
    currentView: null
  };

  // Listen to navigation events
  await page.evaluate(() => {
    window.addEventListener('navigation', (e) => {
      window.navigationHistory = window.navigationHistory || [];
      window.navigationHistory.push(e.detail);
    });
  });

  // Perform navigation sequence
  await nav.navigateToOffboarding();
  navigationState.currentTab = 'offboarding';
  navigationState.currentView = 'overview';

  await nav.navigateToOffboardingView('templates');
  navigationState.previousView = 'overview';
  navigationState.currentView = 'templates';

  // Verify state
  const history = await page.evaluate(() => window.navigationHistory);
  expect(history).toHaveLength(2);
  expect(navigationState.currentView).toBe('templates');
});
```

### 5. Handle Dynamic Content

```javascript
test('handles dynamic application tabs', async ({ page }) => {
  // Don't assume specific apps exist
  const tabs = await page.locator('[data-testid^="tab-"]').all();
  
  // Test whatever tabs are present
  for (const tab of tabs) {
    const tabId = await tab.getAttribute('data-testid');
    await tab.click();
    
    // Verify tab activated
    await expect(tab).toHaveAttribute('data-active', 'true');
    
    // Verify corresponding view loaded
    const viewId = tabId.replace('tab-', 'view-');
    await expect(page.locator(`[data-testid="${viewId}"]`)).toBeVisible();
  }
});
```

### 6. Test Error Recovery

```javascript
test('recovers from navigation errors', async ({ page }) => {
  // Simulate network failure
  await page.route('**/api/offboarding/processes', route => 
    route.abort('failed')
  );

  // Attempt navigation
  await page.click('[data-testid="tab-offboarding"]');
  
  // Verify error handling
  await expect(page.locator('[data-testid="error-message"]')).toBeVisible();
  await expect(page.locator('[data-testid="retry-button"]')).toBeEnabled();
  
  // Fix network and retry
  await page.unroute('**/api/offboarding/processes');
  await page.click('[data-testid="retry-button"]');
  
  // Verify recovery
  await expect(page.locator('[data-testid="view-overview"]')).toBeVisible();
});
```

### 7. Performance Testing Pattern

```javascript
test('navigation performance meets targets', async ({ page }) => {
  const metrics = [];
  
  // Monitor navigation timing
  page.on('framenavigated', () => {
    metrics.push({
      timestamp: Date.now(),
      url: page.url()
    });
  });

  // Measure tab switches
  const tabSwitchTime = await measureAction(page, async () => {
    await page.click('[data-testid="tab-offboarding"]');
    await page.waitForSelector('[data-testid="view-overview"]');
  });
  
  expect(tabSwitchTime).toBeLessThan(500);

  // Measure view transitions
  const viewSwitchTime = await measureAction(page, async () => {
    await page.click('[data-testid="offboarding-view-templates"]');
    await page.waitForSelector('[data-testid="view-templates"]');
  });
  
  expect(viewSwitchTime).toBeLessThan(300);
});

async function measureAction(page, action) {
  const startTime = performance.now();
  await action();
  return performance.now() - startTime;
}
```

### 8. Mobile Navigation Testing

```javascript
test.describe('Mobile Navigation', () => {
  test.use({ viewport: { width: 375, height: 667 } });

  test('mobile menu navigation', async ({ page }) => {
    await page.goto('/');
    
    // Mobile menu might be hidden
    const mobileMenu = page.locator('[data-testid="mobile-menu-button"]');
    if (await mobileMenu.isVisible()) {
      await mobileMenu.click();
      await expect(page.locator('[data-testid="mobile-menu"]')).toBeVisible();
    }
    
    // Navigate using mobile menu
    await page.click('[data-testid="mobile-tab-offboarding"]');
    await expect(page.locator('[data-testid="view-overview"]')).toBeVisible();
    
    // Verify menu closes after navigation
    await expect(page.locator('[data-testid="mobile-menu"]')).toBeHidden();
  });
});
```

### 9. Accessibility Navigation Testing

```javascript
test('keyboard navigation', async ({ page }) => {
  await page.goto('/');
  
  // Start from known position
  await page.locator('body').press('Tab');
  
  // Navigate through tabs
  const focusedElement = page.locator(':focus');
  await expect(focusedElement).toHaveAttribute('data-testid', 'tab-people');
  
  // Use arrow keys for tab navigation
  await page.keyboard.press('ArrowRight');
  await expect(page.locator(':focus')).toHaveAttribute('data-testid', 'tab-offboarding');
  
  // Activate with Enter
  await page.keyboard.press('Enter');
  await expect(page.locator('[data-testid="view-overview"]')).toBeVisible();
  
  // Verify focus management
  await expect(page.locator(':focus')).toHaveAttribute('data-testid', 'offboarding-content');
});
```

### 10. Visual Regression for Navigation States

```javascript
test('navigation visual states', async ({ page }) => {
  // Capture navigation states
  const states = [
    { action: () => page.goto('/'), name: 'initial-state' },
    { action: () => page.click('[data-testid="tab-offboarding"]'), name: 'offboarding-active' },
    { action: () => page.click('[data-testid="offboarding-view-templates"]'), name: 'templates-view' },
    { action: () => page.hover('[data-testid="tab-people"]'), name: 'hover-state' }
  ];

  for (const state of states) {
    await state.action();
    await page.waitForLoadState('networkidle');
    
    await expect(page).toHaveScreenshot(`navigation-${state.name}.png`, {
      clip: { x: 0, y: 0, width: 1200, height: 200 }, // Just navigation area
      animations: 'disabled'
    });
  }
});
```

## Implementation Checklist

### Component Updates Required

```svelte
<!-- src/routes/+page.svelte -->
<script>
  // Add navigation tracking
  function handleNavigation(tab) {
    activeTab = tab;
    // Dispatch custom event for testing
    window.dispatchEvent(new CustomEvent('navigation', { 
      detail: { tab, timestamp: Date.now() } 
    }));
  }
</script>

<!-- Update all navigation elements -->
<button
  data-testid="tab-people"
  data-active={activeTab === 'people'}
  on:click={() => handleNavigation('people')}
>
  People
</button>

<div data-testid="view-overview" data-view-active={offboardingView === 'overview'}>
  <OffboardingDashboard 
    data-testid="offboarding-dashboard"
    {processes}
    {employees}
  />
</div>
```

### Test Infrastructure Setup

```javascript
// playwright.config.js
export default {
  use: {
    // Consistent viewport
    viewport: { width: 1280, height: 720 },
    
    // Navigation helpers
    baseURL: 'http://localhost:3000',
    
    // Screenshot settings
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    
    // Timeouts
    navigationTimeout: 30000,
    actionTimeout: 10000,
  },
  
  // Projects for different scenarios
  projects: [
    { name: 'Desktop Chrome', use: { ...devices['Desktop Chrome'] } },
    { name: 'Mobile Safari', use: { ...devices['iPhone 12'] } },
    { name: 'High Contrast', use: { colorScheme: 'dark' } },
  ],
};
```

### CI/CD Integration

```yaml
# .github/workflows/navigation-tests.yml
name: Navigation Tests

on:
  pull_request:
    paths:
      - 'src/routes/**'
      - 'src/lib/components/**'
      - 'tests/navigation/**'

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Install dependencies
        run: npm ci
        
      - name: Install Playwright
        run: npx playwright install --with-deps
        
      - name: Run navigation tests
        run: npm run test:navigation
        
      - name: Upload test results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: navigation-test-results
          path: |
            test-results/
            playwright-report/
```

## Common Pitfalls to Avoid

1. **Don't use dynamic selectors**
   ```javascript
   // BAD
   await page.click('.tab-button:nth-child(2)');
   
   // GOOD
   await page.click('[data-testid="tab-offboarding"]');
   ```

2. **Don't assume content**
   ```javascript
   // BAD
   await expect(page.locator('.metric-value')).toHaveText('5');
   
   // GOOD
   await expect(page.locator('[data-testid="metric-active"]')).toBeVisible();
   ```

3. **Don't skip state verification**
   ```javascript
   // BAD
   await page.click('[data-testid="tab-offboarding"]');
   // Continues without verification...
   
   // GOOD
   await page.click('[data-testid="tab-offboarding"]');
   await expect(page.locator('[data-testid="view-overview"]')).toBeVisible();
   ```

4. **Don't ignore timing**
   ```javascript
   // BAD
   await page.click(button);
   await page.click(anotherButton); // May click too fast
   
   // GOOD
   await page.click(button);
   await page.waitForSelector('[data-loaded="true"]');
   await page.click(anotherButton);
   ```

## Maintenance Guidelines

1. **Regular Test Review**
   - Weekly review of failed tests
   - Monthly selector audit
   - Quarterly pattern updates

2. **Documentation Updates**
   - Document new patterns
   - Update examples with real scenarios
   - Share learnings with team

3. **Continuous Improvement**
   - Monitor test execution time
   - Reduce flaky tests
   - Improve error messages