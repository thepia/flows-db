# Navigation Testing System

This directory contains a comprehensive navigation testing system for the flows-admin-demo app that is designed to be resilient to demo data changes.

## Overview

The navigation testing system consists of:

1. **Navigation Contract** (`contracts/navigation.contract.js`) - Defines expected navigation behaviors
2. **Navigation Tests** (`navigation.spec.js`) - Comprehensive test suite covering all navigation paths
3. **Resilient Tests** (`navigation-resilient.spec.js`) - Data-agnostic tests that won't break with content changes
4. **Test Helpers** (`helpers/navigation-test-data.js`) - Utilities for consistent test data and patterns

## Key Features

### 1. Data-Testid Based Selection

All navigation elements use `data-testid` attributes for reliable selection:

```html
<!-- Tab navigation -->
<button data-testid="tab-people" data-active="true">People</button>
<button data-testid="tab-offboarding-standard" data-active="false">Standard Offboarding</button>

<!-- Offboarding views -->
<button data-testid="offboarding-view-overview" data-active="true">Overview</button>
<button data-testid="offboarding-view-templates" data-active="false">Templates</button>

<!-- Actions -->
<button data-testid="action-create-offboarding">Create Offboarding</button>
<button data-testid="metric-active-processes">Active Processes</button>
```

### 2. Navigation Contract

The contract defines:
- Expected navigation structure
- State preservation rules
- Navigation patterns
- Test helpers

```javascript
// Example usage
await NavigationContract.testHelpers.verifyActiveTab(page, 'tab-people');
await NavigationActions.switchOffboardingView(page, 'templates');
```

### 3. Resilient Testing Patterns

Tests are written to handle:
- Missing data gracefully
- Dynamic content
- Variable number of tabs/applications
- Optional features

```javascript
// Example: Test navigation regardless of available tabs
const tabs = await page.locator('[data-testid^="tab-"]').all();
for (const tab of tabs) {
  await tab.click();
  // Verify navigation occurred
}
```

## Running Tests

```bash
# Install dependencies
npm install

# Run all tests
npm test

# Run navigation tests only
npm run test:navigation

# Run tests with UI mode
npm run test:ui

# Run tests in headed mode (see browser)
npm run test:headed

# Debug tests
npm run test:debug

# View test report
npm run test:report
```

## Test Coverage

### Main Navigation
- [x] Tab switching between People and Applications
- [x] Active tab state persistence
- [x] Tab state reset on navigation

### Offboarding Navigation
- [x] View switching (Overview, Templates, Processes, Tasks)
- [x] Conditional Tasks view (only when process selected)
- [x] View state persistence within tab

### Dashboard Actions
- [x] Metric card navigation
- [x] Quick filter navigation
- [x] Create offboarding button
- [x] Process selection navigation
- [x] View all needs attention

### State Management
- [x] Tab state persistence
- [x] View state reset on tab switch
- [x] Process selection persistence

### Accessibility
- [x] Keyboard navigation
- [x] Focus management
- [x] ARIA attributes

### Performance
- [x] Navigation timing
- [x] Loading states

### Responsive
- [x] Mobile navigation
- [x] Touch interactions

## Adding New Tests

### 1. Add data-testid to new elements

```svelte
<button 
  data-testid="my-new-action"
  data-active={isActive}
  on:click={handleClick}
>
  My Action
</button>
```

### 2. Update Navigation Contract

```javascript
// In navigation.contract.js
myNewFeature: {
  actions: {
    myNewAction: {
      id: 'my-new-action',
      navigatesToView: 'target-view'
    }
  }
}
```

### 3. Write resilient tests

```javascript
test('should handle my new feature', async ({ page }) => {
  // Use data-testid selectors
  const myAction = page.locator('[data-testid="my-new-action"]');
  
  // Check if feature exists before testing
  if (await myAction.count() > 0) {
    await myAction.click();
    // Verify expected behavior
  }
});
```

## Best Practices

1. **Always use data-testid** - Never rely on text content or CSS classes
2. **Check element existence** - Use `.count() > 0` before interacting
3. **Handle optional features** - Use `test.skip()` when features aren't available
4. **Wait for transitions** - Use proper wait conditions after navigation
5. **Test patterns, not data** - Focus on navigation behavior, not specific content

## Troubleshooting

### Tests failing due to content changes

1. Check if data-testid attributes are still present
2. Verify navigation structure hasn't changed
3. Update contract if new navigation patterns added

### Flaky tests

1. Add proper wait conditions
2. Check for race conditions
3. Use `waitForNavigation` helper

### Performance issues

1. Run tests in parallel when possible
2. Use focused test runs during development
3. Mock heavy data operations if needed