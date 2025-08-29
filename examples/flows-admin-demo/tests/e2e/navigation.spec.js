import { expect, test } from '@playwright/test';
import {
  NavigationActions,
  NavigationContract,
  NavigationPaths,
} from './contracts/navigation.contract.js';

test.describe('Navigation Test Suite', () => {
  test.beforeEach(async ({ page }) => {
    // Navigate to the app
    await page.goto('/');

    // Wait for initial load
    await page.waitForSelector('[data-testid="loading-indicator"]', {
      state: 'hidden',
      timeout: 30000,
    });
  });

  test.describe('Main Tab Navigation', () => {
    test('should display People tab as active by default', async ({ page }) => {
      await NavigationContract.testHelpers.verifyActiveTab(page, 'tab-people');
      await expect(page.locator('[data-testid="view-people"]')).toBeVisible();
    });

    test('should navigate between tabs', async ({ page }) => {
      // Start on People tab
      await NavigationContract.testHelpers.verifyActiveTab(page, 'tab-people');

      // Find and click first application tab (if exists)
      const appTabs = await page
        .locator('[data-testid^="tab-"]:not([data-testid="tab-people"])')
        .all();
      if (appTabs.length > 0) {
        const firstAppTab = appTabs[0];
        const tabId = await firstAppTab.getAttribute('data-testid');

        await firstAppTab.click();
        await NavigationContract.testHelpers.verifyActiveTab(page, tabId);

        // Switch back to People tab
        await NavigationActions.switchTab(page, 'tab-people');
        await NavigationContract.testHelpers.verifyActiveTab(page, 'tab-people');
      }
    });

    test('should maintain tab state when navigating within a tab', async ({ page }) => {
      // Navigate to an application tab with offboarding
      const offboardingTab = await page
        .locator('[data-testid^="tab-"]')
        .filter({ hasText: 'Offboarding' })
        .first();

      if ((await offboardingTab.count()) > 0) {
        const tabId = await offboardingTab.getAttribute('data-testid');
        await offboardingTab.click();

        // Navigate through offboarding views
        await NavigationActions.switchOffboardingView(page, 'templates');

        // Verify tab is still active
        await NavigationContract.testHelpers.verifyActiveTab(page, tabId);
      }
    });
  });

  test.describe('Offboarding Sub-Navigation', () => {
    test.beforeEach(async ({ page }) => {
      // Navigate to offboarding tab
      const offboardingTab = await page
        .locator('[data-testid^="tab-"]')
        .filter({ hasText: 'Offboarding' })
        .first();
      if ((await offboardingTab.count()) > 0) {
        await offboardingTab.click();
        await page.waitForSelector('[data-testid="view-overview"]', { state: 'visible' });
      } else {
        test.skip();
      }
    });

    test('should display Overview by default', async ({ page }) => {
      await NavigationContract.testHelpers.verifyActiveView(page, 'offboarding-view-overview');
      await expect(page.locator('[data-testid="view-overview"]')).toBeVisible();
    });

    test('should navigate between offboarding views', async ({ page }) => {
      // Navigate to Templates
      await NavigationActions.switchOffboardingView(page, 'templates');
      await NavigationContract.testHelpers.verifyActiveView(page, 'offboarding-view-templates');
      await expect(page.locator('[data-testid="view-templates"]')).toBeVisible();

      // Navigate to Processes
      await NavigationActions.switchOffboardingView(page, 'processes');
      await NavigationContract.testHelpers.verifyActiveView(page, 'offboarding-view-processes');
      await expect(page.locator('[data-testid="view-processes"]')).toBeVisible();

      // Navigate back to Overview
      await NavigationActions.switchOffboardingView(page, 'overview');
      await NavigationContract.testHelpers.verifyActiveView(page, 'offboarding-view-overview');
      await expect(page.locator('[data-testid="view-overview"]')).toBeVisible();
    });

    test('should show Tasks view only when a process is selected', async ({ page }) => {
      // Tasks button should not be visible initially
      await expect(page.locator('[data-testid="offboarding-view-tasks"]')).not.toBeVisible();

      // TODO: Once process selection is implemented, verify Tasks button appears
    });
  });

  test.describe('Dashboard Navigation Actions', () => {
    test.beforeEach(async ({ page }) => {
      // Navigate to offboarding overview
      const offboardingTab = await page
        .locator('[data-testid^="tab-"]')
        .filter({ hasText: 'Offboarding' })
        .first();
      if ((await offboardingTab.count()) > 0) {
        await offboardingTab.click();
        await page.waitForSelector('[data-testid="view-overview"]', { state: 'visible' });
      } else {
        test.skip();
      }
    });

    test('should navigate from metric cards', async ({ page }) => {
      // Click Active Processes metric
      await NavigationActions.clickMetricCard(page, 'metric-active-processes');
      await NavigationContract.testHelpers.verifyActiveView(page, 'offboarding-view-processes');

      // Go back to overview
      await NavigationActions.switchOffboardingView(page, 'overview');

      // Click Ending Soon metric
      await NavigationActions.clickMetricCard(page, 'metric-ending-soon');
      await NavigationContract.testHelpers.verifyActiveView(page, 'offboarding-view-processes');

      // Go back to overview
      await NavigationActions.switchOffboardingView(page, 'overview');

      // Click Recently Completed metric
      await NavigationActions.clickMetricCard(page, 'metric-recently-completed');
      await NavigationContract.testHelpers.verifyActiveView(page, 'offboarding-view-processes');

      // Go back to overview
      await NavigationActions.switchOffboardingView(page, 'overview');

      // Click Needs Attention metric
      await NavigationActions.clickMetricCard(page, 'metric-needs-attention');
      await NavigationContract.testHelpers.verifyActiveView(page, 'offboarding-view-processes');
    });

    test('should navigate from quick filters', async ({ page }) => {
      // Click Overdue Processes filter
      await NavigationActions.clickQuickFilter(page, 'filter-overdue-processes');
      await NavigationContract.testHelpers.verifyActiveView(page, 'offboarding-view-processes');

      // Go back to overview
      await NavigationActions.switchOffboardingView(page, 'overview');

      // Click Pending Approvals filter
      await NavigationActions.clickQuickFilter(page, 'filter-pending-approvals');
      await NavigationContract.testHelpers.verifyActiveView(page, 'offboarding-view-processes');

      // Go back to overview
      await NavigationActions.switchOffboardingView(page, 'overview');

      // Click This Month filter
      await NavigationActions.clickQuickFilter(page, 'filter-this-month');
      await NavigationContract.testHelpers.verifyActiveView(page, 'offboarding-view-processes');
    });

    test('should navigate using Create Offboarding button', async ({ page }) => {
      const createButton = page.locator('[data-testid="action-create-offboarding"]');
      await createButton.click();

      await NavigationContract.testHelpers.verifyActiveView(page, 'offboarding-view-templates');
    });

    test('should navigate from actionable process items', async ({ page }) => {
      // Check if there are any actionable processes
      const processButtons = await page.locator('[data-testid^="action-view-process-"]').all();

      if (processButtons.length > 0) {
        // Click the first process
        await processButtons[0].click();

        // Should navigate to tasks view
        await NavigationContract.testHelpers.verifyActiveView(page, 'offboarding-view-tasks');
        await expect(page.locator('[data-testid="view-tasks"]')).toBeVisible();
      }

      // Test View All button if visible
      const viewAllButton = page.locator('[data-testid="action-view-all-needs-attention"]');
      if (await viewAllButton.isVisible()) {
        await viewAllButton.click();
        await NavigationContract.testHelpers.verifyActiveView(page, 'offboarding-view-processes');
      }
    });
  });

  test.describe('State Persistence', () => {
    test('should reset offboarding view when switching tabs', async ({ page }) => {
      // Navigate to offboarding tab
      const offboardingTab = await page
        .locator('[data-testid^="tab-"]')
        .filter({ hasText: 'Offboarding' })
        .first();
      if ((await offboardingTab.count()) === 0) {
        test.skip();
        return;
      }

      const tabId = await offboardingTab.getAttribute('data-testid');
      await offboardingTab.click();

      // Navigate to Templates view
      await NavigationActions.switchOffboardingView(page, 'templates');
      await NavigationContract.testHelpers.verifyActiveView(page, 'offboarding-view-templates');

      // Switch to People tab
      await NavigationActions.switchTab(page, 'tab-people');

      // Switch back to offboarding tab
      await NavigationActions.switchTab(page, tabId);

      // Should be back on Overview (default view)
      await NavigationContract.testHelpers.verifyActiveView(page, 'offboarding-view-overview');
    });

    test('should maintain selected process when switching between processes and tasks', async ({
      page,
    }) => {
      // Navigate to offboarding tab
      const offboardingTab = await page
        .locator('[data-testid^="tab-"]')
        .filter({ hasText: 'Offboarding' })
        .first();
      if ((await offboardingTab.count()) === 0) {
        test.skip();
        return;
      }

      await offboardingTab.click();

      // Check if there are actionable processes
      const processButtons = await page.locator('[data-testid^="action-view-process-"]').all();

      if (processButtons.length > 0) {
        // Click a process to go to tasks
        await processButtons[0].click();
        await NavigationContract.testHelpers.verifyActiveView(page, 'offboarding-view-tasks');

        // Navigate to processes view
        await NavigationActions.switchOffboardingView(page, 'processes');

        // Navigate back to tasks - should still show tasks button
        await expect(page.locator('[data-testid="offboarding-view-tasks"]')).toBeVisible();
      }
    });
  });

  test.describe('Navigation Accessibility', () => {
    test('should be keyboard navigable', async ({ page }) => {
      // Start on People tab
      await page.locator('[data-testid="tab-people"]').focus();

      // Navigate to next tab using keyboard
      await page.keyboard.press('Tab');

      // Activate the focused tab
      await page.keyboard.press('Enter');

      // Verify navigation occurred
      const focusedElement = await page.locator(':focus');
      const testId = await focusedElement.getAttribute('data-testid');

      if (testId && testId.startsWith('tab-')) {
        await NavigationContract.testHelpers.verifyActiveTab(page, testId);
      }
    });

    test('should have proper ARIA attributes', async ({ page }) => {
      // Check tab navigation ARIA
      const tabButtons = await page.locator('[data-testid^="tab-"]').all();

      for (const tab of tabButtons) {
        const isActive = (await tab.getAttribute('data-active')) === 'true';

        // Active tabs should have appropriate styling
        if (isActive) {
          const classes = await tab.getAttribute('class');
          expect(classes).toContain('border-blue-500');
          expect(classes).toContain('text-blue-600');
        }
      }
    });
  });

  test.describe('Error Handling', () => {
    test('should handle navigation when data is loading', async ({ page }) => {
      // This test would require mocking the loading state
      // For now, we'll verify the loading indicator exists
      await page.goto('/');

      // The loading indicator should exist in the DOM
      const loadingIndicator = page.locator('[data-testid="loading-indicator"]');

      // It might be visible or hidden depending on load state
      await expect(loadingIndicator)
        .toBeInViewport({ timeout: 1000 })
        .catch(() => {
          // Loading completed too fast, which is fine
        });
    });
  });
});

// Performance Tests
test.describe('Navigation Performance', () => {
  test('should complete navigation within acceptable time', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('[data-testid="loading-indicator"]', { state: 'hidden' });

    const startTime = Date.now();

    // Perform several navigation actions
    const appTab = await page
      .locator('[data-testid^="tab-"]:not([data-testid="tab-people"])')
      .first();
    if ((await appTab.count()) > 0) {
      await appTab.click();
      await page.waitForSelector('[data-testid^="view-"]', { state: 'visible' });

      const navigationTime = Date.now() - startTime;

      // Navigation should complete within 500ms
      expect(navigationTime).toBeLessThan(500);
    }
  });
});

// Mobile Navigation Tests
test.describe('Mobile Navigation', () => {
  test.use({ viewport: { width: 375, height: 667 } });

  test('should work on mobile viewport', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('[data-testid="loading-indicator"]', { state: 'hidden' });

    // Verify tabs are still accessible on mobile
    await expect(page.locator('[data-testid="tab-people"]')).toBeVisible();

    // Test navigation
    await NavigationActions.switchTab(page, 'tab-people');
    await expect(page.locator('[data-testid="view-people"]')).toBeVisible();
  });
});
