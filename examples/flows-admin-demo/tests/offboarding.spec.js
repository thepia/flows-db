/**
 * Offboarding App Tab Tests
 * Comprehensive tests for the offboarding functionality
 */

import { test, expect } from '@playwright/test';
import { NavigationHelper, OffboardingHelper } from './helpers/navigation.js';
import { TestSetup } from './helpers/test-setup.js';

test.describe('Offboarding App Tab', () => {
  let nav, offboarding, setup;

  test.beforeEach(async ({ page }) => {
    nav = new NavigationHelper(page);
    offboarding = new OffboardingHelper(page);
    setup = new TestSetup(page);

    // Setup test environment
    await setup.setupMockApiResponses();
    await setup.navigateToApp();
    await setup.addTestingCSS();
  });

  test.describe('Navigation', () => {
    test('should navigate to offboarding tab', async ({ page }) => {
      await nav.navigateToOffboarding();
      
      // Verify we're on the offboarding tab
      await expect(page.locator('[data-testid="tab-offboarding"]')).toHaveAttribute('data-active', 'true');
      await expect(page.locator('[data-testid="view-overview"]')).toBeVisible();
    });

    test('should show overview as default view', async ({ page }) => {
      await nav.navigateToOffboarding();
      
      // Verify overview is the default active view
      await expect(page.locator('[data-testid="offboarding-view-overview"]')).toHaveAttribute('data-active', 'true');
      await expect(page.locator('[data-testid="view-overview"]')).toBeVisible();
    });

    test('should navigate between offboarding views', async ({ page }) => {
      await nav.navigateToOffboarding();
      
      // Test navigation to each view
      const views = ['templates', 'processes'];
      
      for (const view of views) {
        await nav.navigateToOffboardingView(view);
        await expect(page.locator(`[data-testid="view-${view}"]`)).toBeVisible();
        await expect(page.locator(`[data-testid="offboarding-view-${view}"]`)).toHaveAttribute('data-active', 'true');
      }
    });

    test('should show tasks view only when process selected', async ({ page }) => {
      await nav.navigateToOffboarding();
      
      // Tasks view should not be visible initially
      await expect(page.locator('[data-testid="offboarding-view-tasks"]')).not.toBeVisible();
      
      // Navigate to processes and select one
      await nav.navigateToOffboardingView('processes');
      await page.click('[data-testid="process-process-001"]');
      
      // Tasks view should now be visible and active
      await expect(page.locator('[data-testid="offboarding-view-tasks"]')).toBeVisible();
      await expect(page.locator('[data-testid="view-tasks"]')).toBeVisible();
    });

    test('should maintain navigation state on page refresh', async ({ page }) => {
      await nav.navigateToOffboarding();
      await nav.navigateToOffboardingView('templates');
      
      // Refresh page
      await page.reload();
      await page.waitForLoadState('networkidle');
      
      // Should return to default state (overview)
      await expect(page.locator('[data-testid="view-overview"]')).toBeVisible();
    });
  });

  test.describe('Overview Dashboard', () => {
    test('should display all metric cards', async ({ page }) => {
      await nav.navigateToOffboarding();
      
      await offboarding.verifyDashboardMetrics();
      
      // Verify metric values are displayed
      await expect(page.locator('[data-testid="metric-card-active"] .metric-value')).toContainText('3');
      await expect(page.locator('[data-testid="metric-card-ending-soon"] .metric-value')).toContainText('1');
      await expect(page.locator('[data-testid="metric-card-completed"] .metric-value')).toContainText('5');
      await expect(page.locator('[data-testid="metric-card-attention"] .metric-value')).toContainText('2');
    });

    test('should navigate to processes when clicking metric cards', async ({ page }) => {
      await nav.navigateToOffboarding();
      
      await offboarding.clickMetricCard('active');
      
      // Should navigate to processes view
      await expect(page.locator('[data-testid="view-processes"]')).toBeVisible();
      await expect(page.locator('[data-testid="offboarding-view-processes"]')).toHaveAttribute('data-active', 'true');
    });

    test('should display create offboarding button', async ({ page }) => {
      await nav.navigateToOffboarding();
      
      const createButton = page.locator('[data-testid="create-offboarding-button"]');
      await expect(createButton).toBeVisible();
      await expect(createButton).toBeEnabled();
    });

    test('should navigate to templates when clicking create offboarding', async ({ page }) => {
      await nav.navigateToOffboarding();
      
      await page.click('[data-testid="create-offboarding-button"]');
      
      // Should navigate to templates view
      await expect(page.locator('[data-testid="view-templates"]')).toBeVisible();
      await expect(page.locator('[data-testid="offboarding-view-templates"]')).toHaveAttribute('data-active', 'true');
    });

    test('should display processes requiring action', async ({ page }) => {
      await nav.navigateToOffboarding();
      
      // Should show action items section
      await expect(page.locator('[data-testid="processes-requiring-action"]')).toBeVisible();
      
      // Should display at least one actionable process
      await expect(page.locator('[data-testid^="actionable-process-"]')).toHaveCount(2);
    });

    test('should display performance insights', async ({ page }) => {
      await nav.navigateToOffboarding();
      
      // Verify performance insights section
      await expect(page.locator('[data-testid="performance-insights"]')).toBeVisible();
      await expect(page.locator('[data-testid="completion-rate"]')).toContainText('%');
      await expect(page.locator('[data-testid="avg-duration"]')).toContainText('days');
    });

    test('should display quick filters', async ({ page }) => {
      await nav.navigateToOffboarding();
      
      // Verify quick filter buttons
      const quickFilters = [
        'quick-filter-overdue',
        'quick-filter-pending-approval',
        'quick-filter-this-month'
      ];
      
      for (const filter of quickFilters) {
        await expect(page.locator(`[data-testid="${filter}"]`)).toBeVisible();
      }
    });
  });

  test.describe('Template Management', () => {
    test('should display template grid', async ({ page }) => {
      await nav.navigateToOffboardingView('templates');
      
      // Should display templates
      await expect(page.locator('[data-testid="templates-grid"]')).toBeVisible();
      await expect(page.locator('[data-testid^="template-"]')).toHaveCount(3);
    });

    test('should display template details', async ({ page }) => {
      await nav.navigateToOffboardingView('templates');
      
      const template = page.locator('[data-testid="template-template-001"]');
      
      // Verify template information is displayed
      await expect(template.locator('.template-name')).toContainText('Standard Employee Offboarding');
      await expect(template.locator('.template-type')).toContainText('company_wide');
      await expect(template.locator('.task-count')).toContainText('12 tasks');
      await expect(template.locator('.duration')).toContainText('14 days');
    });

    test('should filter templates by department', async ({ page }) => {
      await nav.navigateToOffboardingView('templates');
      
      // Filter by Engineering department
      await page.selectOption('[data-testid="department-filter"]', 'Engineering');
      
      // Should show only engineering templates
      await expect(page.locator('[data-testid="template-template-002"]')).toBeVisible();
      await expect(page.locator('[data-testid="template-template-001"]')).not.toBeVisible();
    });

    test('should filter templates by type', async ({ page }) => {
      await nav.navigateToOffboardingView('templates');
      
      // Filter by department-specific type
      await page.selectOption('[data-testid="type-filter"]', 'department_specific');
      
      // Should show only department-specific templates
      await expect(page.locator('[data-testid="template-template-002"]')).toBeVisible();
      await expect(page.locator('[data-testid="template-template-003"]')).toBeVisible();
      await expect(page.locator('[data-testid="template-template-001"]')).not.toBeVisible();
    });

    test('should search templates', async ({ page }) => {
      await nav.navigateToOffboardingView('templates');
      
      // Search for engineering templates
      await page.fill('[data-testid="template-search"]', 'engineering');
      
      // Should show only matching templates
      await expect(page.locator('[data-testid="template-template-002"]')).toBeVisible();
      await expect(page.locator('[data-testid="template-template-001"]')).not.toBeVisible();
    });

    test('should select template', async ({ page }) => {
      await nav.navigateToOffboardingView('templates');
      
      const template = page.locator('[data-testid="template-template-001"]');
      await template.click();
      
      // Template should show selected state
      await expect(template).toHaveClass(/selected/);
    });

    test('should show create template button', async ({ page }) => {
      await nav.navigateToOffboardingView('templates');
      
      const createButton = page.locator('[data-testid="create-template-button"]');
      await expect(createButton).toBeVisible();
      await expect(createButton).toBeEnabled();
    });
  });

  test.describe('Process Management', () => {
    test('should display process list', async ({ page }) => {
      await nav.navigateToOffboardingView('processes');
      
      // Should display processes
      await expect(page.locator('[data-testid="processes-list"]')).toBeVisible();
      await expect(page.locator('[data-testid^="process-"]')).toHaveCount(3);
    });

    test('should display process details', async ({ page }) => {
      await nav.navigateToOffboardingView('processes');
      
      const process = page.locator('[data-testid="process-process-001"]');
      
      // Verify process information
      await expect(process.locator('.process-name')).toContainText('John Smith Offboarding');
      await expect(process.locator('.employee-department')).toContainText('Engineering');
      await expect(process.locator('.process-status')).toContainText('active');
      await expect(process.locator('.completion-percentage')).toContainText('45%');
    });

    test('should show process progress bar', async ({ page }) => {
      await nav.navigateToOffboardingView('processes');
      
      const process = page.locator('[data-testid="process-process-001"]');
      const progressBar = process.locator('[data-testid="progress-bar"]');
      
      await expect(progressBar).toBeVisible();
      await expect(progressBar).toHaveAttribute('value', '45');
    });

    test('should display process priority indicators', async ({ page }) => {
      await nav.navigateToOffboardingView('processes');
      
      // Check urgent priority process
      const urgentProcess = page.locator('[data-testid="process-process-002"]');
      await expect(urgentProcess.locator('.priority-badge')).toContainText('urgent');
      await expect(urgentProcess.locator('.priority-badge')).toHaveClass(/priority-urgent/);
    });

    test('should filter processes by status', async ({ page }) => {
      await nav.navigateToOffboardingView('processes');
      
      // Filter by active status
      await page.selectOption('[data-testid="status-filter"]', 'active');
      
      // Should show only active processes
      await expect(page.locator('[data-testid="process-process-001"]')).toBeVisible();
      await expect(page.locator('[data-testid="process-process-003"]')).not.toBeVisible();
    });

    test('should select process and navigate to tasks', async ({ page }) => {
      await nav.navigateToOffboardingView('processes');
      
      await page.click('[data-testid="process-process-001"]');
      
      // Should navigate to tasks view
      await expect(page.locator('[data-testid="view-tasks"]')).toBeVisible();
      await expect(page.locator('[data-testid="offboarding-view-tasks"]')).toHaveAttribute('data-active', 'true');
    });

    test('should show create process button', async ({ page }) => {
      await nav.navigateToOffboardingView('processes');
      
      const createButton = page.locator('[data-testid="create-process-button"]');
      await expect(createButton).toBeVisible();
      
      // Should navigate to templates when clicked
      await createButton.click();
      await expect(page.locator('[data-testid="view-templates"]')).toBeVisible();
    });
  });

  test.describe('Task Management', () => {
    test.beforeEach(async ({ page }) => {
      // Navigate to tasks view via process selection
      await nav.navigateToOffboardingView('processes');
      await page.click('[data-testid="process-process-001"]');
    });

    test('should display kanban board', async ({ page }) => {
      // Verify kanban columns
      const columns = ['pending', 'in_progress', 'completed', 'blocked'];
      
      for (const column of columns) {
        await expect(page.locator(`[data-testid="task-column-${column}"]`)).toBeVisible();
      }
    });

    test('should display tasks in correct columns', async ({ page }) => {
      // Check tasks are in correct columns based on status
      await expect(page.locator('[data-testid="task-column-completed"] [data-testid="task-task-001"]')).toBeVisible();
      await expect(page.locator('[data-testid="task-column-in_progress"] [data-testid="task-task-002"]')).toBeVisible();
      await expect(page.locator('[data-testid="task-column-pending"] [data-testid="task-task-003"]')).toBeVisible();
      await expect(page.locator('[data-testid="task-column-blocked"] [data-testid="task-task-004"]')).toBeVisible();
    });

    test('should display task details', async ({ page }) => {
      const task = page.locator('[data-testid="task-task-002"]');
      
      // Verify task information
      await expect(task.locator('.task-name')).toContainText('Knowledge transfer session');
      await expect(task.locator('.task-priority')).toContainText('critical');
      await expect(task.locator('.task-assignee')).toContainText('John Smith');
    });

    test('should show task due dates', async ({ page }) => {
      const task = page.locator('[data-testid="task-task-002"]');
      await expect(task.locator('.task-due-date')).toBeVisible();
    });

    test('should display blocked task reason', async ({ page }) => {
      const blockedTask = page.locator('[data-testid="task-task-004"]');
      await expect(blockedTask.locator('.blocked-reason')).toContainText('Waiting for employee availability');
    });

    test('should show task dependencies', async ({ page }) => {
      const task = page.locator('[data-testid="task-task-003"]');
      await expect(task.locator('.task-dependencies')).toContainText('Depends on: task-002');
    });

    test('should display progress for in-progress tasks', async ({ page }) => {
      const task = page.locator('[data-testid="task-task-002"]');
      await expect(task.locator('.task-progress')).toContainText('2 / 4 hours');
    });
  });

  test.describe('Responsive Design', () => {
    test('should work on mobile viewport', async ({ page }) => {
      await setup.setViewport('mobile');
      await nav.navigateToOffboarding();
      
      // Should display mobile-friendly layout
      await expect(page.locator('[data-testid="view-overview"]')).toBeVisible();
      
      // Navigation should be accessible
      const mobileMenu = page.locator('[data-testid="mobile-menu-button"]');
      if (await mobileMenu.isVisible()) {
        await mobileMenu.click();
        await expect(page.locator('[data-testid="mobile-menu"]')).toBeVisible();
      }
    });

    test('should work on tablet viewport', async ({ page }) => {
      await setup.setViewport('tablet');
      await nav.navigateToOffboarding();
      
      // Should maintain functionality on tablet
      await expect(page.locator('[data-testid="view-overview"]')).toBeVisible();
      await nav.navigateToOffboardingView('templates');
      await expect(page.locator('[data-testid="view-templates"]')).toBeVisible();
    });
  });

  test.describe('Error Handling', () => {
    test('should handle API errors gracefully', async ({ page }) => {
      await setup.resetMocks();
      await setup.setupErrorResponses();
      
      await nav.navigateToOffboarding();
      
      // Should display error message
      await expect(page.locator('[data-testid="error-message"]')).toBeVisible();
      await expect(page.locator('[data-testid="retry-button"]')).toBeEnabled();
    });

    test('should recover from errors after retry', async ({ page }) => {
      await setup.resetMocks();
      await setup.setupErrorResponses();
      
      await nav.navigateToOffboarding();
      await expect(page.locator('[data-testid="error-message"]')).toBeVisible();
      
      // Fix the error and retry
      await setup.resetMocks();
      await setup.setupMockApiResponses();
      await page.click('[data-testid="retry-button"]');
      
      // Should recover and show content
      await expect(page.locator('[data-testid="view-overview"]')).toBeVisible();
      await expect(page.locator('[data-testid="error-message"]')).not.toBeVisible();
    });

    test('should show loading states', async ({ page }) => {
      await setup.resetMocks();
      await setup.setupSlowResponses(1000);
      
      await nav.navigateToOffboarding();
      
      // Should show loading indicator
      await expect(page.locator('[data-testid="loading-indicator"]')).toBeVisible();
      
      // Loading should disappear after response
      await expect(page.locator('[data-testid="loading-indicator"]')).not.toBeVisible({ timeout: 10000 });
    });
  });

  test.describe('Performance', () => {
    test('should navigate quickly between views', async ({ page }) => {
      await setup.setupPerformanceMonitoring();
      
      // Measure navigation timing
      const navigationTime = await nav.measureNavigationTime(async () => {
        await nav.navigateToOffboarding();
      });
      
      expect(navigationTime).toBeLessThan(1000); // Should navigate in less than 1 second
    });

    test('should handle large datasets efficiently', async ({ page }) => {
      // This would be more relevant with real data
      await nav.navigateToOffboardingView('templates');
      
      // Verify all templates load quickly
      await expect(page.locator('[data-testid^="template-"]')).toHaveCount(3);
      
      const metrics = await setup.getPerformanceMetrics();
      expect(metrics.loadTime).toBeLessThan(3000);
    });
  });

  test.describe('Accessibility', () => {
    test('should support keyboard navigation', async ({ page }) => {
      await setup.setupKeyboardTesting();
      await nav.navigateToOffboarding();
      
      // Tab through navigation elements
      await page.keyboard.press('Tab');
      await expect(page.locator(':focus')).toHaveAttribute('data-testid', 'offboarding-view-overview');
      
      await page.keyboard.press('Tab');
      await expect(page.locator(':focus')).toHaveAttribute('data-testid', 'offboarding-view-templates');
      
      // Activate with Enter
      await page.keyboard.press('Enter');
      await expect(page.locator('[data-testid="view-templates"]')).toBeVisible();
    });

    test('should have proper ARIA labels', async ({ page }) => {
      await nav.navigateToOffboarding();
      
      // Check button labels
      await expect(page.locator('[data-testid="create-offboarding-button"]')).toHaveAttribute('aria-label');
      
      // Check navigation
      await expect(page.locator('[data-testid="offboarding-view-overview"]')).toHaveAttribute('role', 'tab');
    });

    test('should have proper focus management', async ({ page }) => {
      await nav.navigateToOffboarding();
      await nav.navigateToOffboardingView('templates');
      
      // Focus should be managed properly after navigation
      const focusedElement = page.locator(':focus');
      await expect(focusedElement).toBeVisible();
    });
  });
});