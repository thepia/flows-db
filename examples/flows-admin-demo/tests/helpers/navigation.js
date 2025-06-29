/**
 * Navigation helper functions for Playwright tests
 * Provides reusable navigation patterns
 */

import { expect } from '@playwright/test';

export class NavigationHelper {
  constructor(page) {
    this.page = page;
  }

  /**
   * Navigate to the main offboarding tab
   */
  async navigateToOffboarding() {
    // Wait for applications to load and offboarding tab to be available
    await this.page.waitForSelector('[data-testid="tab-offboarding"]', { state: 'visible' });
    await this.page.click('[data-testid="tab-offboarding"]');
    await this.page.waitForSelector('[data-testid="view-overview"]', { state: 'visible' });
    await this.verifyOffboardingTabActive();
  }

  /**
   * Navigate to a specific offboarding view
   * @param {string} view - The view to navigate to (overview, templates, processes, tasks)
   */
  async navigateToOffboardingView(view) {
    await this.page.click(`[data-testid="offboarding-view-${view}"]`);
    await this.page.waitForSelector(`[data-testid="view-${view}"]`, { state: 'visible' });
    await this.verifyOffboardingViewActive(view);
  }

  /**
   * Navigate to People tab
   */
  async navigateToPeople() {
    await this.page.click('[data-testid="tab-people"]');
    await this.page.waitForSelector('[data-testid="view-people"]', { state: 'visible' });
    await this.verifyPeopleTabActive();
  }

  /**
   * Verify offboarding tab is active
   */
  async verifyOffboardingTabActive() {
    const tab = this.page.locator('[data-testid="tab-offboarding"]');
    await expect(tab).toHaveAttribute('data-active', 'true');
  }

  /**
   * Verify specific offboarding view is active
   * @param {string} view - The view to verify
   */
  async verifyOffboardingViewActive(view) {
    const viewButton = this.page.locator(`[data-testid="offboarding-view-${view}"]`);
    const viewContent = this.page.locator(`[data-testid="view-${view}"]`);
    
    // Check button is active
    await expect(viewButton).toHaveAttribute('data-active', 'true');
    
    // Check view content is visible
    await expect(viewContent).toBeVisible();
  }

  /**
   * Verify people tab is active
   */
  async verifyPeopleTabActive() {
    const tab = this.page.locator('[data-testid="tab-people"]');
    await expect(tab).toHaveAttribute('data-active', 'true');
  }

  /**
   * Get all available navigation tabs
   */
  async getAvailableTabs() {
    const tabs = await this.page.locator('[data-testid^="tab-"]').all();
    const tabIds = [];
    
    for (const tab of tabs) {
      const testId = await tab.getAttribute('data-testid');
      tabIds.push(testId.replace('tab-', ''));
    }
    
    return tabIds;
  }

  /**
   * Get all available offboarding views
   */
  async getAvailableOffboardingViews() {
    const views = await this.page.locator('[data-testid^="offboarding-view-"]').all();
    const viewIds = [];
    
    for (const view of views) {
      const testId = await view.getAttribute('data-testid');
      viewIds.push(testId.replace('offboarding-view-', ''));
    }
    
    return viewIds;
  }

  /**
   * Wait for navigation to complete
   */
  async waitForNavigationComplete() {
    await this.page.waitForLoadState('networkidle');
    await this.page.waitForSelector('[data-testid="loading-indicator"]', { state: 'hidden' });
  }

  /**
   * Measure navigation timing
   * @param {Function} navigationAction - The navigation action to measure
   */
  async measureNavigationTime(navigationAction) {
    const startTime = performance.now();
    await navigationAction();
    await this.waitForNavigationComplete();
    return performance.now() - startTime;
  }
}

export class OffboardingHelper {
  constructor(page) {
    this.page = page;
    this.nav = new NavigationHelper(page);
  }

  /**
   * Create a new offboarding process
   * @param {string} templateId - The template to use
   */
  async createOffboardingProcess(templateId = 'template-001') {
    await this.nav.navigateToOffboardingView('templates');
    
    // Select template
    await this.page.click(`[data-testid="template-${templateId}"]`);
    
    // Fill out process details (mock for now)
    await this.page.click('[data-testid="create-process-button"]');
    
    // Wait for process creation
    await this.page.waitForSelector('[data-testid="process-created"]', { state: 'visible' });
  }

  /**
   * Select a process and navigate to tasks
   * @param {string} processId - The process to select
   */
  async selectProcess(processId) {
    await this.nav.navigateToOffboardingView('processes');
    await this.page.click(`[data-testid="process-${processId}"]`);
    await this.nav.verifyOffboardingViewActive('tasks');
  }

  /**
   * Update task status
   * @param {string} taskId - The task to update
   * @param {string} status - New status (pending, in_progress, completed, blocked)
   */
  async updateTaskStatus(taskId, status) {
    const task = this.page.locator(`[data-testid="task-${taskId}"]`);
    const statusColumn = this.page.locator(`[data-testid="task-column-${status}"]`);
    
    // Drag and drop task to new status column
    await task.dragTo(statusColumn);
    
    // Wait for update confirmation
    await this.page.waitForSelector(`[data-testid="task-${taskId}"][data-status="${status}"]`);
  }

  /**
   * Verify dashboard metrics are displayed
   */
  async verifyDashboardMetrics() {
    const requiredMetrics = [
      'metric-card-active',
      'metric-card-ending-soon',
      'metric-card-completed',
      'metric-card-attention'
    ];

    for (const metric of requiredMetrics) {
      await expect(this.page.locator(`[data-testid="${metric}"]`)).toBeVisible();
    }
  }

  /**
   * Click a dashboard metric card and verify navigation
   * @param {string} metricType - The type of metric to click
   */
  async clickMetricCard(metricType) {
    await this.page.click(`[data-testid="metric-card-${metricType}"]`);
    await this.nav.verifyOffboardingViewActive('processes');
  }

  /**
   * Filter templates by department
   * @param {string} department - Department to filter by
   */
  async filterTemplatesByDepartment(department) {
    await this.nav.navigateToOffboardingView('templates');
    await this.page.selectOption('[data-testid="department-filter"]', department);
    await this.page.waitForSelector('[data-testid="templates-filtered"]');
  }

  /**
   * Search templates
   * @param {string} searchTerm - Term to search for
   */
  async searchTemplates(searchTerm) {
    await this.nav.navigateToOffboardingView('templates');
    await this.page.fill('[data-testid="template-search"]', searchTerm);
    await this.page.waitForSelector('[data-testid="search-results"]');
  }
}