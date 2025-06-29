# Flows Admin Demo - Test Suite

This directory contains comprehensive end-to-end tests for the Flows Admin Demo application, focusing on the offboarding functionality.

## 📁 Test Structure

```
tests/
├── README.md                          # This file
├── global-setup.js                    # Global test setup
├── global-teardown.js                 # Global test cleanup
├── offboarding.spec.js                # Main offboarding tests
├── fixtures/
│   └── offboarding.fixtures.js        # Mock data for tests
└── helpers/
    ├── navigation.js                   # Navigation helper functions
    └── test-setup.js                   # Test setup utilities
```

## 🚀 Running Tests

### Prerequisites

1. Install dependencies:
   ```bash
   pnpm install
   ```

2. Install Playwright browsers:
   ```bash
   pnpm exec playwright install
   ```

### Test Commands

```bash
# Run all tests
pnpm run test

# Run offboarding tests specifically  
pnpm run test:navigation

# Run tests with UI (interactive mode)
pnpm run test:ui

# Run tests in headed mode (see browser)
pnpm run test:headed

# Debug tests step by step
pnpm run test:debug

# View test report
pnpm run test:report
```

## 🧪 Test Coverage

### Current Test Scenarios (80+ tests)

#### ✅ Navigation Tests
- [ ] Main tab navigation (People ↔ Offboarding)
- [ ] Offboarding sub-navigation (Overview → Templates → Processes → Tasks)
- [ ] Navigation state persistence
- [ ] Keyboard navigation
- [ ] Mobile navigation

#### ✅ Overview Dashboard Tests
- [ ] Display all metric cards with correct data
- [ ] Navigate to processes when clicking metric cards
- [ ] Create offboarding button functionality
- [ ] Processes requiring action display
- [ ] Performance insights display
- [ ] Quick filters functionality

#### ✅ Template Management Tests
- [ ] Display template grid
- [ ] Template filtering by department/type
- [ ] Template search functionality
- [ ] Template selection
- [ ] Template details display

#### ✅ Process Management Tests
- [ ] Display process list with details
- [ ] Process progress indicators
- [ ] Status filtering
- [ ] Process selection for task management

#### ✅ Task Management Tests
- [ ] Kanban board display
- [ ] Task details and metadata
- [ ] Task status columns
- [ ] Dependency indicators

#### ✅ Responsive Design Tests
- [ ] Mobile viewport compatibility
- [ ] Tablet viewport compatibility
- [ ] Touch interactions

#### ✅ Error Handling Tests
- [ ] API error recovery
- [ ] Loading states
- [ ] Network failure handling
- [ ] Retry functionality

#### ✅ Performance Tests
- [ ] Navigation timing
- [ ] Large dataset handling
- [ ] Load time verification

#### ✅ Accessibility Tests
- [ ] Keyboard navigation
- [ ] ARIA labels
- [ ] Focus management
- [ ] Screen reader compatibility

## 🔧 Test Architecture

### Data-Driven Testing
Tests use consistent mock data that doesn't break when real data changes:

```javascript
// ❌ Bad - breaks when data changes
await page.click('text=Active Processes: 5');

// ✅ Good - stable selector
await page.click('[data-testid="metric-card-active"]');
```

### Helper Functions
Reusable navigation and setup functions reduce duplication:

```javascript
const nav = new NavigationHelper(page);
await nav.navigateToOffboarding();
await nav.navigateToOffboardingView('templates');
```

### Mock API Responses
Consistent test data ensures reliable tests:

```javascript
await setup.setupMockApiResponses();
// All API calls now return predictable data
```

## 📊 Test Data

### Mock Fixtures
- **Templates**: 3 sample templates (company-wide, department-specific)
- **Processes**: 3 sample processes (active, pending, completed)
- **Tasks**: 4 sample tasks (different statuses)
- **Metrics**: Calculated metrics for dashboard
- **Employees**: Sample employee data

### Test IDs
All components use `data-testid` attributes for stable element selection:

```svelte
<button data-testid="create-offboarding-button">Create Offboarding</button>
<div data-testid="view-overview"><!-- content --></div>
<card data-testid="metric-card-active"><!-- metrics --></card>
```

## 🎯 Best Practices

### 1. Stable Selectors
- Use `data-testid` attributes
- Avoid CSS selectors that might change
- Don't rely on text content

### 2. State Verification
Always verify navigation succeeded:
```javascript
await page.click('[data-testid="tab-offboarding"]');
await expect(page.locator('[data-testid="view-overview"]')).toBeVisible();
```

### 3. Error Handling
Test both success and failure scenarios:
```javascript
await setup.setupErrorResponses();
await expect(page.locator('[data-testid="error-message"]')).toBeVisible();
```

### 4. Performance
Measure and assert timing:
```javascript
const navigationTime = await nav.measureNavigationTime(action);
expect(navigationTime).toBeLessThan(1000);
```

## 🔍 Debugging Tests

### Visual Debugging
- Use `pnpm run test:headed` to see browser actions
- Use `pnpm run test:ui` for interactive debugging
- Add `await page.pause()` to stop execution

### Screenshots
Failed tests automatically capture screenshots in `test-results/`

### Test Reports
View detailed HTML reports with `pnpm run test:report`

### Debugging Tips
```javascript
// Add debug logging
console.log('Current URL:', page.url());

// Take manual screenshots
await page.screenshot({ path: 'debug.png' });

// Inspect element state
const element = page.locator('[data-testid="button"]');
console.log('Visible:', await element.isVisible());
console.log('Enabled:', await element.isEnabled());
```

## 🚨 Common Issues

### 1. Element Not Found
- Check data-testid spelling
- Verify element is rendered
- Wait for element to appear

### 2. Test Timeout
- Increase timeout in playwright.config.js
- Add proper wait conditions
- Check for slow API responses

### 3. Flaky Tests
- Add proper waits
- Use stable selectors
- Handle race conditions

### 4. Mobile Test Failures
- Set viewport in test
- Check touch interactions
- Verify responsive layout

## 📈 Continuous Integration

Tests run automatically on:
- Pull requests
- Pushes to main branch
- Scheduled nightly runs

See `.github/workflows/tests.yml` for CI configuration.

## 🔮 Future Enhancements

### Planned Test Additions
- [ ] Multi-user collaboration tests
- [ ] Real-time updates testing
- [ ] Advanced process workflow tests
- [ ] Integration with external systems
- [ ] Performance regression testing
- [ ] Cross-browser compatibility matrix

### Test Infrastructure
- [ ] Parallel test execution
- [ ] Test result trending
- [ ] Flaky test detection
- [ ] Performance benchmarking
- [ ] Visual regression testing

## 📚 Resources

- [Playwright Documentation](https://playwright.dev/)
- [Test Strategy Document](../docs/TEST_STRATEGY.md)
- [Test Scenarios Document](../docs/TEST_SCENARIOS.md)
- [Navigation Patterns](../docs/NAVIGATION_TEST_PATTERNS.md)