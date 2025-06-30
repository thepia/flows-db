# Client Switching Regression Tests

This document outlines the comprehensive testing strategy for client switching functionality to prevent regressions.

## Background

The client switching functionality has experienced regressions where:
1. Client selections don't persist across navigation
2. `loadDemoData()` overrides user selections by always defaulting to 'hygge-hvidlog'
3. Store synchronization issues between legacy and new domain stores
4. UI components not reflecting actual client state

## Test Coverage

### 1. localStorage Persistence Tests (`client-switching.test.ts`)

**Purpose**: Ensure client selections persist across page reloads and navigation.

**Key Tests**:
- ✅ `should persist client selection in localStorage`
- ✅ `should respect stored client selection on loadDemoData`
- ✅ `should not override stored selection with default priority`
- ✅ `should clear invalid stored selections`

**Critical Regression Prevention**: Tests that `loadDemoData()` checks localStorage **first** before falling back to priority list.

### 2. Store Synchronization Tests

**Purpose**: Ensure legacy and new domain stores stay synchronized.

**Key Tests**:
- ✅ `should synchronize new domain store changes with legacy store`
- ✅ `should not create infinite update loops between stores`

**Critical Regression Prevention**: Tests that changes in domain stores properly trigger legacy store updates via the store bridge.

### 3. Demo Client Switcher Integration Tests

**Purpose**: Ensure the central orchestrator coordinates data loading properly.

**Key Tests**:
- ✅ `should coordinate data loading across all domains`
- ✅ `should handle errors gracefully during switching`

### 4. Navigation Persistence Tests

**Purpose**: Prevent the specific regression where navigation resets client selection.

**Key Tests**:
- ✅ `should maintain client selection after navigation`
- ✅ `should prevent default client override of user selection`

**Critical Regression Prevention**: Specifically tests the scenario where user navigates away and back to main page.

### 5. UI Component Integration Tests (`FloatingStatusButton.test.ts`)

**Purpose**: Ensure the FloatingStatusButton component works correctly with client switching.

**Key Tests**:
- ✅ `should render client dropdown when clients are available`
- ✅ `should show current client as selected in dropdown`
- ✅ `should call demo client switcher when dropdown selection changes`
- ✅ `should show loading state during client switching`
- ✅ `should handle client switching errors gracefully`
- ✅ `should close status panel after successful client switch`

## Running Tests

### Unit Tests
```bash
# Run all client switching tests
pnpm test:client-switching

# Run FloatingStatusButton tests
pnpm test:floating-button

# Watch mode for development
pnpm test:client-switching:watch

# Run all unit tests
pnpm test:unit
```

### Coverage
```bash
# Run tests with coverage
pnpm test:unit --coverage
```

## Test Strategy

### 1. Mock Strategy
- **localStorage**: Fully mocked to test persistence scenarios
- **Supabase**: Mocked to control database responses
- **Navigation**: Mocked to test navigation scenarios
- **Stores**: Real stores with mocked dependencies

### 2. Regression Prevention
Each test is designed to catch specific regression patterns:

1. **Default Override Regression**: Tests ensure user selections aren't overridden by defaults
2. **Navigation Reset Regression**: Tests ensure client selection persists across navigation
3. **Store Sync Regression**: Tests ensure stores stay synchronized
4. **UI State Regression**: Tests ensure UI reflects actual client state

### 3. Edge Cases
- Invalid client IDs in localStorage
- Network failures during client switching
- Empty client lists
- Malformed localStorage data

## Integration with CI/CD

These tests should be run:
1. **Before every commit** - Unit tests catch immediate regressions
2. **In PR reviews** - Automated testing prevents merging breaking changes
3. **Before releases** - Full test suite ensures stability

## Future Enhancements

1. **E2E Tests**: Add Playwright tests for full user workflows
2. **Performance Tests**: Test switching speed with large client lists
3. **Accessibility Tests**: Ensure client switching is accessible
4. **Visual Regression Tests**: Ensure UI doesn't break during switching

## Debugging Failed Tests

### Common Issues
1. **Mock Setup**: Ensure all dependencies are properly mocked
2. **Async Operations**: Use `waitFor` for async state changes
3. **Store State**: Reset stores between tests
4. **localStorage**: Clear localStorage between tests

### Debug Mode
Run tests in debug mode to see console logs:
```bash
VITEST_DEBUG=1 pnpm test:client-switching
```

## Maintenance

1. **Update tests** when adding new client switching features
2. **Add edge cases** discovered in production
3. **Review coverage** regularly to ensure comprehensive testing
4. **Document new regression patterns** as they're discovered

This testing strategy ensures that client switching functionality remains stable and reliable, preventing the type of regressions that have occurred in the past.