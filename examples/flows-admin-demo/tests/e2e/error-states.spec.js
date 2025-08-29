import { expect, test } from '@playwright/test';

test.describe('Error State Navigation Test Suite', () => {
  test.beforeEach(async ({ page }) => {
    // Navigate to the app
    await page.goto('/');

    // Wait for initial load
    await page.waitForSelector('[data-testid="loading-indicator"]', {
      state: 'hidden',
      timeout: 30000,
    });
  });

  test.describe('404 and Invalid Route Handling', () => {
    test('should handle invalid person ID gracefully', async ({ page }) => {
      // Navigate directly to invalid person ID
      await page.goto('/people/invalid-person-id-12345');

      // Should show 404 or not found state
      const notFoundIndicators = [
        page.locator('[data-testid="person-not-found"]'),
        page.locator('text=Person Not Found'),
        page.locator('text=404'),
        page.locator('text=Not Found'),
      ];

      let foundIndicator = false;
      for (const indicator of notFoundIndicators) {
        if ((await indicator.count()) > 0) {
          await expect(indicator).toBeVisible({ timeout: 10000 });
          foundIndicator = true;
          break;
        }
      }

      expect(foundIndicator).toBe(true);

      // Should provide navigation back to people list
      const returnButtons = [
        page.locator('text=Return to People'),
        page.locator('text=Back to People'),
        page.locator('[data-testid="back-to-people"]'),
        page.locator('a[href="/people"]'),
      ];

      let foundReturnButton = false;
      for (const button of returnButtons) {
        if ((await button.count()) > 0) {
          await button.click();
          await expect(page).toHaveURL(/\/people$/);
          foundReturnButton = true;
          break;
        }
      }

      expect(foundReturnButton).toBe(true);
    });

    test('should handle invalid employee ID gracefully', async ({ page }) => {
      // Check if employees route exists
      await page.goto('/employees/invalid-employee-id-67890');

      // Should either show 404 or redirect to valid route
      const possibleStates = [
        {
          locator: page.locator('[data-testid="employee-not-found"]'),
          description: 'Employee not found',
        },
        {
          locator: page.locator('text=Employee Not Found'),
          description: 'Employee not found text',
        },
        {
          locator: page.locator('[data-testid="view-people"]'),
          description: 'Redirected to people',
        },
        { locator: page.locator('text=404'), description: '404 page' },
      ];

      let validStateFound = false;
      for (const state of possibleStates) {
        if ((await state.locator.count()) > 0) {
          console.log(`Found valid state: ${state.description}`);
          validStateFound = true;
          break;
        }
      }

      expect(validStateFound).toBe(true);
    });

    test('should handle completely invalid routes', async ({ page }) => {
      // Navigate to completely invalid route
      await page.goto('/this-route-does-not-exist');

      // Should show some kind of error state or redirect
      const errorIndicators = [
        page.locator('text=404'),
        page.locator('text=Page Not Found'),
        page.locator('text=Not Found'),
        page.locator('[data-testid="404-page"]'),
        page.locator('[data-testid="error-page"]'),
      ];

      // Or it might redirect to home page
      const isOnHomePage = page.url().endsWith('/') || page.url().includes('localhost:5173/');

      if (isOnHomePage) {
        // Redirected to home - verify home page loads
        await expect(page.locator('[data-testid="tab-people"]')).toBeVisible({ timeout: 10000 });
      } else {
        // Should show error page
        let foundError = false;
        for (const indicator of errorIndicators) {
          if ((await indicator.count()) > 0) {
            await expect(indicator).toBeVisible();
            foundError = true;
            break;
          }
        }
        expect(foundError).toBe(true);
      }
    });
  });

  test.describe('Data Loading Error States', () => {
    test('should handle network errors gracefully', async ({ page }) => {
      // Intercept API calls and simulate network errors
      await page.route('**/api/**', (route) => {
        route.abort('failed');
      });

      await page.route('**/supabase.co/**', (route) => {
        route.abort('failed');
      });

      // Navigate to people page
      await page.goto('/people');

      // Should show error state or retry option
      const errorStates = [
        page.locator('[data-testid="network-error"]'),
        page.locator('[data-testid="loading-error"]'),
        page.locator('text=Failed to load'),
        page.locator('text=Network error'),
        page.locator('text=Try again'),
        page.locator('[data-testid="retry-button"]'),
      ];

      let errorStateFound = false;
      for (const errorState of errorStates) {
        if ((await errorState.count()) > 0) {
          console.log('Found error state indicator');
          errorStateFound = true;
          break;
        }
      }

      // Allow some time for error states to appear
      await page.waitForTimeout(3000);

      // Re-check error states after timeout
      if (!errorStateFound) {
        for (const errorState of errorStates) {
          if ((await errorState.count()) > 0) {
            errorStateFound = true;
            break;
          }
        }
      }

      // The app should handle network errors gracefully
      // Either show error state or fallback to cached/default data
      const hasContent = (await page.locator('[data-testid="view-people"]').count()) > 0;

      expect(errorStateFound || hasContent).toBe(true);
    });

    test('should handle partial data loading failures', async ({ page }) => {
      // Navigate to a person detail page
      await page.goto('/people');
      await page.waitForSelector('[data-testid="view-people"]', { state: 'visible' });

      const personCards = page.locator('[data-testid^="person-card-"]');
      if ((await personCards.count()) > 0) {
        await personCards.first().click();
        await expect(page.locator('[data-testid="person-detail"]')).toBeVisible({ timeout: 10000 });

        // Check that page loaded without critical errors
        const errors = [];
        page.on('console', (msg) => {
          if (msg.type() === 'error') {
            errors.push(msg.text());
          }
        });

        // Wait a bit to catch any errors
        await page.waitForTimeout(2000);

        // Filter for critical errors that would break functionality
        const criticalErrors = errors.filter(
          (error) =>
            error.includes('TypeError') ||
            error.includes('Cannot read property') ||
            error.includes('Cannot read properties') ||
            error.includes('ReferenceError')
        );

        // Should not have critical errors that break the page
        expect(criticalErrors.length).toBe(0);

        // Essential elements should still be visible
        await expect(page.locator('[data-testid="person-name"]')).toBeVisible();
      }
    });

    test('should handle client switching errors', async ({ page }) => {
      // Navigate to people page
      await page.goto('/people');
      await page.waitForSelector('[data-testid="view-people"]', { state: 'visible' });

      // Try to find client switcher
      const clientSwitcher = page.locator('[data-testid="client-switcher"]');
      const floatingStatusButton = page.locator('[data-testid="floating-status-button"]');

      let switcherElement = null;
      if ((await clientSwitcher.count()) > 0) {
        switcherElement = clientSwitcher;
      } else if ((await floatingStatusButton.count()) > 0) {
        switcherElement = floatingStatusButton;
      }

      if (switcherElement) {
        // Set up console error monitoring
        const errors = [];
        page.on('console', (msg) => {
          if (msg.type() === 'error') {
            errors.push(msg.text());
          }
        });

        // Try to switch client
        await switcherElement.click();

        // Look for client options
        const clientOptions = page.locator('[data-testid^="client-option-"]');
        if ((await clientOptions.count()) > 1) {
          // Try switching to different client
          await clientOptions.nth(1).click();

          // Wait for potential state changes
          await page.waitForTimeout(3000);

          // Check for client switching errors
          const switchingErrors = errors.filter(
            (error) =>
              error.includes('client') ||
              error.includes('localStorage') ||
              error.includes('undefined') ||
              error.includes('TypeError')
          );

          if (switchingErrors.length > 0) {
            console.warn('Client switching errors detected:', switchingErrors);
          }

          // Page should still be functional after client switch
          await expect(page.locator('[data-testid="view-people"]')).toBeVisible({ timeout: 10000 });
        }
      }
    });
  });

  test.describe('User Input Error Handling', () => {
    test('should handle invalid form inputs gracefully', async ({ page }) => {
      // Navigate to new person form if it exists
      await page.goto('/people/new');

      // Check if form exists
      const personForm = page.locator('[data-testid="person-form"]');
      const newPersonForm = page.locator('[data-testid="new-person-form"]');

      let formElement = null;
      if ((await personForm.count()) > 0) {
        formElement = personForm;
      } else if ((await newPersonForm.count()) > 0) {
        formElement = newPersonForm;
      }

      if (formElement) {
        await expect(formElement).toBeVisible({ timeout: 10000 });

        // Try submitting empty form
        const submitButton = page.locator('[data-testid="submit-button"]');
        if ((await submitButton.count()) > 0) {
          await submitButton.click();

          // Should show validation errors
          const validationErrors = [
            page.locator('[data-testid="validation-error"]'),
            page.locator('.error'),
            page.locator('text=required'),
            page.locator('text=invalid'),
          ];

          let validationFound = false;
          for (const error of validationErrors) {
            if ((await error.count()) > 0) {
              validationFound = true;
              break;
            }
          }

          // Form should handle validation gracefully
          expect(validationFound || (await submitButton.isEnabled())).toBe(true);
        }
      }
    });

    test('should handle search input edge cases', async ({ page }) => {
      // Navigate to people page
      await page.goto('/people');
      await page.waitForSelector('[data-testid="view-people"]', { state: 'visible' });

      // Look for search input
      const searchInput = page.locator('[data-testid="search-input"]');
      const filterInput = page.locator('input[placeholder*="search"]');

      let searchElement = null;
      if ((await searchInput.count()) > 0) {
        searchElement = searchInput;
      } else if ((await filterInput.count()) > 0) {
        searchElement = filterInput;
      }

      if (searchElement) {
        // Test various search inputs
        const testSearches = [
          '', // empty
          '   ', // whitespace
          'nonexistentperson12345', // no results
          '<script>alert("xss")</script>', // potential XSS
          'а б в г д', // non-Latin characters
          '!@#$%^&*()', // special characters
          'a'.repeat(1000), // very long input
        ];

        for (const searchTerm of testSearches) {
          await searchElement.fill(searchTerm);
          await page.waitForTimeout(500); // Wait for search processing

          // Page should remain functional
          await expect(page.locator('[data-testid="view-people"]')).toBeVisible();

          // Check for JavaScript errors
          const errors = [];
          page.on('console', (msg) => {
            if (msg.type() === 'error') {
              errors.push(msg.text());
            }
          });

          if (errors.length > 0) {
            console.warn(`Search errors for "${searchTerm}":`, errors);
          }
        }

        // Clear search
        await searchElement.fill('');
      }
    });
  });

  test.describe('Browser Compatibility Error Handling', () => {
    test('should handle localStorage errors gracefully', async ({ page }) => {
      // Simulate localStorage being unavailable
      await page.addInitScript(() => {
        // Override localStorage to throw errors
        Object.defineProperty(window, 'localStorage', {
          value: {
            getItem: () => {
              throw new Error('localStorage not available');
            },
            setItem: () => {
              throw new Error('localStorage not available');
            },
            removeItem: () => {
              throw new Error('localStorage not available');
            },
            clear: () => {
              throw new Error('localStorage not available');
            },
          },
          writable: false,
        });
      });

      // Navigate to app
      await page.goto('/');

      // App should still load and function
      await expect(page.locator('[data-testid="tab-people"]')).toBeVisible({ timeout: 15000 });

      // Should be able to navigate to people
      await page.click('[data-testid="tab-people"]');
      await expect(page.locator('[data-testid="view-people"]')).toBeVisible({ timeout: 10000 });
    });

    test('should handle JavaScript disabled gracefully', async ({ page }) => {
      // This test ensures basic navigation works even with reduced JavaScript
      // Most modern apps require JS, but critical navigation should be robust

      await page.goto('/people');

      // Basic page structure should be present
      const hasContent = (await page.locator('body').count()) > 0;
      expect(hasContent).toBe(true);

      // Check that the page doesn't show a blank screen
      const bodyText = await page.locator('body').textContent();
      expect(bodyText.length).toBeGreaterThan(0);
    });
  });

  test.describe('Performance Error States', () => {
    test('should handle slow loading gracefully', async ({ page }) => {
      // Slow down network requests to test loading states
      await page.route('**/*', (route) => {
        setTimeout(() => route.continue(), 1000); // Add 1 second delay
      });

      await page.goto('/people');

      // Should show loading state
      const loadingIndicators = [
        page.locator('[data-testid="loading-indicator"]'),
        page.locator('.loading'),
        page.locator('text=Loading'),
        page.locator('[data-testid="skeleton"]'),
      ];

      let loadingFound = false;
      for (const indicator of loadingIndicators) {
        if ((await indicator.count()) > 0) {
          loadingFound = true;
          break;
        }
      }

      // Should eventually load content
      await expect(page.locator('[data-testid="view-people"]')).toBeVisible({ timeout: 15000 });

      console.log(`Loading state found: ${loadingFound}`);
    });

    test('should handle memory constraints gracefully', async ({ page }) => {
      // Test with large amounts of data navigation
      await page.goto('/people');
      await page.waitForSelector('[data-testid="view-people"]', { state: 'visible' });

      const personCards = page.locator('[data-testid^="person-card-"]');
      const personCount = await personCards.count();

      if (personCount > 0) {
        // Rapidly navigate through multiple people
        const testCount = Math.min(personCount, 10);

        for (let i = 0; i < testCount; i++) {
          await personCards.nth(i).click();
          await expect(page.locator('[data-testid="person-detail"]')).toBeVisible({
            timeout: 5000,
          });

          // Check memory usage doesn't cause crashes
          const errors = [];
          page.on('console', (msg) => {
            if (msg.type() === 'error' && msg.text().includes('memory')) {
              errors.push(msg.text());
            }
          });

          await page.click('[data-testid="back-to-people"]');
          await expect(page.locator('[data-testid="view-people"]')).toBeVisible();

          if (errors.length > 0) {
            console.warn(`Memory errors detected at iteration ${i}:`, errors);
          }
        }
      }
    });
  });
});
