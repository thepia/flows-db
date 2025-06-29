/**
 * Test setup helpers
 * Provides consistent test environment setup
 */

import { mockApiResponses } from '../fixtures/offboarding.fixtures.js';

export class TestSetup {
  constructor(page) {
    this.page = page;
  }

  /**
   * Setup mock API responses for offboarding tests
   */
  async setupMockApiResponses() {
    // Mock all offboarding API endpoints
    for (const [endpoint, response] of Object.entries(mockApiResponses)) {
      await this.page.route(`**${endpoint}*`, route => {
        route.fulfill({
          status: 200,
          contentType: 'application/json',
          body: JSON.stringify(response)
        });
      });
    }
  }

  /**
   * Setup error responses for testing error handling
   */
  async setupErrorResponses() {
    await this.page.route('**/api/offboarding/**', route => {
      route.fulfill({
        status: 500,
        contentType: 'application/json',
        body: JSON.stringify({
          error: 'Internal Server Error',
          message: 'Database connection failed'
        })
      });
    });
  }

  /**
   * Setup slow responses for testing loading states
   */
  async setupSlowResponses(delay = 2000) {
    await this.page.route('**/api/offboarding/**', async route => {
      await new Promise(resolve => setTimeout(resolve, delay));
      route.continue();
    });
  }

  /**
   * Navigate to app and wait for initial load
   */
  async navigateToApp() {
    await this.page.goto('/');
    await this.page.waitForSelector('[data-testid="app-loaded"]', { state: 'visible' });
    await this.page.waitForLoadState('networkidle');
    // Wait for loading indicator to be hidden to ensure demo data has loaded
    await this.page.waitForSelector('[data-testid="loading-indicator"]', { state: 'hidden' }).catch(() => {
      // Loading indicator might not exist, which is fine
    });
  }

  /**
   * Reset all route mocks
   */
  async resetMocks() {
    await this.page.unrouteAll();
  }

  /**
   * Set viewport for consistent testing
   * @param {string} device - Device type (desktop, tablet, mobile)
   */
  async setViewport(device = 'desktop') {
    const viewports = {
      desktop: { width: 1280, height: 720 },
      tablet: { width: 768, height: 1024 },
      mobile: { width: 375, height: 667 }
    };

    await this.page.setViewportSize(viewports[device]);
  }

  /**
   * Setup accessibility testing
   */
  async setupAccessibilityTesting() {
    // Inject axe-core for accessibility testing
    await this.page.addScriptTag({
      url: 'https://unpkg.com/axe-core@4.7.0/axe.min.js'
    });
  }

  /**
   * Take screenshot for visual regression testing
   * @param {string} name - Screenshot name
   * @param {Object} options - Screenshot options
   */
  async takeScreenshot(name, options = {}) {
    const defaultOptions = {
      fullPage: false,
      animations: 'disabled',
      path: `test-results/screenshots/${name}.png`
    };

    return await this.page.screenshot({ ...defaultOptions, ...options });
  }

  /**
   * Wait for all animations to complete
   */
  async waitForAnimations() {
    await this.page.waitForFunction(() => {
      return Promise.all(
        document.getAnimations().map(animation => animation.finished)
      );
    });
  }

  /**
   * Clear local storage and session storage
   */
  async clearStorage() {
    await this.page.evaluate(() => {
      localStorage.clear();
      sessionStorage.clear();
    });
  }

  /**
   * Set up keyboard navigation testing
   */
  async setupKeyboardTesting() {
    // Focus first element
    await this.page.keyboard.press('Tab');
  }

  /**
   * Add custom CSS for testing
   */
  async addTestingCSS() {
    await this.page.addStyleTag({
      content: `
        /* Highlight focused elements for testing */
        *:focus {
          outline: 3px solid #ff6b6b !important;
          outline-offset: 2px !important;
        }
        
        /* Disable animations for consistent testing */
        *, *::before, *::after {
          animation-duration: 0s !important;
          animation-delay: 0s !important;
          transition-duration: 0s !important;
          transition-delay: 0s !important;
        }
      `
    });
  }

  /**
   * Log test information
   */
  async logTestInfo(testName) {
    console.log(`🧪 Running test: ${testName}`);
    console.log(`📍 URL: ${this.page.url()}`);
    console.log(`📱 Viewport: ${await this.page.viewportSize()}`);
  }

  /**
   * Setup performance monitoring
   */
  async setupPerformanceMonitoring() {
    await this.page.addInitScript(() => {
      window.performanceMetrics = {
        navigationStart: performance.now(),
        metrics: []
      };
      
      // Monitor navigation timing
      window.addEventListener('load', () => {
        window.performanceMetrics.loadTime = performance.now() - window.performanceMetrics.navigationStart;
      });
      
      // Monitor user interactions
      ['click', 'keydown', 'input'].forEach(eventType => {
        document.addEventListener(eventType, (e) => {
          window.performanceMetrics.metrics.push({
            type: eventType,
            timestamp: performance.now(),
            target: e.target.tagName
          });
        });
      });
    });
  }

  /**
   * Get performance metrics
   */
  async getPerformanceMetrics() {
    return await this.page.evaluate(() => window.performanceMetrics);
  }

  /**
   * Setup custom test data attributes
   */
  async setupTestDataAttributes() {
    await this.page.addInitScript(() => {
      // Add test indicators
      document.documentElement.setAttribute('data-test-environment', 'true');
      document.documentElement.setAttribute('data-test-timestamp', Date.now());
    });
  }
}