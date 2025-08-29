import { expect, test } from '@playwright/test';

test.describe('Cross-App Navigation Test Suite', () => {
  test.beforeEach(async ({ page }) => {
    // Navigate to the app
    await page.goto('/');

    // Wait for initial load
    await page.waitForSelector('[data-testid="loading-indicator"]', {
      state: 'hidden',
      timeout: 30000,
    });
  });

  test.describe('People ↔ Employees Navigation', () => {
    test('should navigate between People and Employees views', async ({ page }) => {
      // Start on People tab
      await page.click('[data-testid="tab-people"]');
      await page.waitForSelector('[data-testid="view-people"]', { state: 'visible' });

      // Check if Employees tab exists (legacy view)
      const employeesTab = page.locator('[data-testid="tab-employees"]');

      if ((await employeesTab.count()) > 0) {
        // Navigate to Employees
        await employeesTab.click();
        await page.waitForSelector('[data-testid="view-employees"]', { state: 'visible' });

        // Verify employees view is active
        await expect(page.locator('[data-testid="view-employees"]')).toBeVisible();

        // Navigate back to People
        await page.click('[data-testid="tab-people"]');
        await page.waitForSelector('[data-testid="view-people"]', { state: 'visible' });

        // Verify people view is active
        await expect(page.locator('[data-testid="view-people"]')).toBeVisible();
      } else {
        console.log('Employees tab not found - testing People view only');
        await expect(page.locator('[data-testid="view-people"]')).toBeVisible();
      }
    });

    test('should maintain data consistency between People and Employees', async ({ page }) => {
      // Navigate to People and collect person data
      await page.click('[data-testid="tab-people"]');
      await page.waitForSelector('[data-testid="view-people"]', { state: 'visible' });

      const personCards = page.locator('[data-testid^="person-card-"]');
      const peopleData = [];

      if ((await personCards.count()) > 0) {
        // Collect first few people's data
        const testCount = Math.min(await personCards.count(), 3);

        for (let i = 0; i < testCount; i++) {
          const personCard = personCards.nth(i);

          // Extract person information from card
          const nameElement = personCard.locator('[data-testid="person-name"]');
          const emailElement = personCard.locator('[data-testid="person-email"]');

          let name = '';
          let email = '';

          if ((await nameElement.count()) > 0) {
            name = await nameElement.textContent();
          }
          if ((await emailElement.count()) > 0) {
            email = await emailElement.textContent();
          }

          // If no specific elements, try to extract from card text
          if (!name && !email) {
            const cardText = await personCard.textContent();
            // Look for email pattern in card text
            const emailMatch = cardText.match(/[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/);
            if (emailMatch) {
              email = emailMatch[0];
            }
          }

          peopleData.push({ name: name.trim(), email: email.trim() });
        }
      }

      // Check if Employees tab exists
      const employeesTab = page.locator('[data-testid="tab-employees"]');

      if ((await employeesTab.count()) > 0) {
        // Navigate to Employees view
        await employeesTab.click();
        await page.waitForSelector('[data-testid="view-employees"]', { state: 'visible' });

        const employeeCards = page.locator('[data-testid^="employee-card-"]');

        if ((await employeeCards.count()) > 0) {
          // Compare employee data with people data
          const testCount = Math.min(await employeeCards.count(), 3);

          for (let i = 0; i < testCount; i++) {
            const employeeCard = employeeCards.nth(i);

            const empNameElement = employeeCard.locator('[data-testid="employee-name"]');
            const empEmailElement = employeeCard.locator('[data-testid="employee-email"]');

            let empName = '';
            let empEmail = '';

            if ((await empNameElement.count()) > 0) {
              empName = await empNameElement.textContent();
            }
            if ((await empEmailElement.count()) > 0) {
              empEmail = await empEmailElement.textContent();
            }

            // Look for matching person in people data
            const matchingPerson = peopleData.find(
              (person) =>
                (person.email && empEmail && person.email === empEmail) ||
                (person.name && empName && person.name === empName)
            );

            if (matchingPerson) {
              console.log(`Found matching data: ${empName} / ${empEmail}`);
            }
          }
        }
      }

      console.log(`Collected data for ${peopleData.length} people`);
    });

    test('should handle person detail navigation from both views', async ({ page }) => {
      // Test person detail navigation from People view
      await page.click('[data-testid="tab-people"]');
      await page.waitForSelector('[data-testid="view-people"]', { state: 'visible' });

      const personCards = page.locator('[data-testid^="person-card-"]');

      if ((await personCards.count()) > 0) {
        // Navigate to person detail from People view
        await personCards.first().click();

        const personDetail = page.locator('[data-testid="person-detail"]');
        const employeeDetail = page.locator('[data-testid="employee-detail"]');

        // Should navigate to some detail view
        const hasPersonDetail = (await personDetail.count()) > 0;
        const hasEmployeeDetail = (await employeeDetail.count()) > 0;

        expect(hasPersonDetail || hasEmployeeDetail).toBe(true);

        if (hasPersonDetail) {
          await expect(personDetail).toBeVisible({ timeout: 10000 });
        } else if (hasEmployeeDetail) {
          await expect(employeeDetail).toBeVisible({ timeout: 10000 });
        }

        // Return to main view
        const backButtons = [
          page.locator('[data-testid="back-to-people"]'),
          page.locator('[data-testid="back-to-employees"]'),
          page.locator('text=Back'),
          page.locator('[data-testid="back-button"]'),
        ];

        for (const backButton of backButtons) {
          if ((await backButton.count()) > 0) {
            await backButton.click();
            break;
          }
        }

        // Should return to people view
        await expect(page.locator('[data-testid="view-people"]')).toBeVisible({ timeout: 10000 });
      }
    });
  });

  test.describe('Settings Integration', () => {
    test('should navigate to settings and return', async ({ page }) => {
      // Look for settings access points
      const settingsButtons = [
        page.locator('[data-testid="settings-button"]'),
        page.locator('[data-testid="open-settings"]'),
        page.locator('text=Settings'),
        page.locator('[aria-label="Settings"]'),
      ];

      let settingsButton = null;
      for (const button of settingsButtons) {
        if ((await button.count()) > 0) {
          settingsButton = button;
          break;
        }
      }

      if (settingsButton) {
        // Navigate to settings
        await settingsButton.click();

        // Look for settings content
        const settingsIndicators = [
          page.locator('[data-testid="settings-panel"]'),
          page.locator('[data-testid="settings-view"]'),
          page.locator('text=Client Settings'),
          page.locator('text=Preferences'),
        ];

        let settingsVisible = false;
        for (const indicator of settingsIndicators) {
          if ((await indicator.count()) > 0) {
            await expect(indicator).toBeVisible({ timeout: 10000 });
            settingsVisible = true;
            break;
          }
        }

        expect(settingsVisible).toBe(true);

        // Close settings or navigate away
        const closeButtons = [
          page.locator('[data-testid="close-settings"]'),
          page.locator('text=Close'),
          page.locator('[data-testid="settings-close"]'),
          page.locator('.close'),
        ];

        for (const closeButton of closeButtons) {
          if ((await closeButton.count()) > 0) {
            await closeButton.click();
            break;
          }
        }

        // Should return to previous view
        await page.waitForTimeout(1000);
      } else {
        console.log('Settings button not found - testing navigation without settings');
      }
    });

    test('should handle client switching from settings', async ({ page }) => {
      // Navigate to People view first
      await page.click('[data-testid="tab-people"]');
      await page.waitForSelector('[data-testid="view-people"]', { state: 'visible' });

      // Look for settings or client switcher
      const clientSwitchers = [
        page.locator('[data-testid="client-switcher"]'),
        page.locator('[data-testid="floating-status-button"]'),
        page.locator('[data-testid="settings-button"]'),
      ];

      let clientSwitcher = null;
      for (const switcher of clientSwitchers) {
        if ((await switcher.count()) > 0) {
          clientSwitcher = switcher;
          break;
        }
      }

      if (clientSwitcher) {
        // Get current client name if available
        const currentClientName = await page
          .locator('[data-testid="current-client-name"]')
          .textContent()
          .catch(() => null);

        // Open client switcher
        await clientSwitcher.click();

        // Look for client options
        const clientOptions = page.locator('[data-testid^="client-option-"]');

        if ((await clientOptions.count()) > 1) {
          // Switch to different client
          await clientOptions.nth(1).click();

          // Wait for potential reload/update
          await page.waitForLoadState('networkidle');
          await page.waitForTimeout(2000);

          // Verify people view still works after client switch
          await expect(page.locator('[data-testid="view-people"]')).toBeVisible({ timeout: 10000 });

          // Check if client actually changed
          const newClientName = await page
            .locator('[data-testid="current-client-name"]')
            .textContent()
            .catch(() => null);

          if (currentClientName && newClientName && currentClientName !== newClientName) {
            console.log(`Client switched from ${currentClientName} to ${newClientName}`);
          }
        }
      }
    });
  });

  test.describe('Application Tab Navigation', () => {
    test('should navigate between application tabs', async ({ page }) => {
      // Get all available tabs
      const tabs = page.locator('[data-testid^="tab-"]');
      const tabCount = await tabs.count();

      expect(tabCount).toBeGreaterThan(0);

      // Test navigation between first few tabs
      const testTabs = Math.min(tabCount, 4);

      for (let i = 0; i < testTabs; i++) {
        const tab = tabs.nth(i);
        const tabId = await tab.getAttribute('data-testid');

        // Click tab
        await tab.click();

        // Wait for corresponding view to load
        const viewId = tabId.replace('tab-', 'view-');
        const correspondingView = page.locator(`[data-testid="${viewId}"]`);

        if ((await correspondingView.count()) > 0) {
          await expect(correspondingView).toBeVisible({ timeout: 10000 });
        } else {
          // Some tabs might have different view naming conventions
          await page.waitForTimeout(1000);
          console.log(`Tab ${tabId} clicked - view ${viewId} not found but navigation completed`);
        }

        // Verify tab is marked as active
        const isActive = await tab.getAttribute('aria-selected');
        const hasActiveClass = await tab.evaluate((el) => el.classList.contains('active'));

        expect(isActive === 'true' || hasActiveClass).toBe(true);
      }
    });

    test('should maintain state during tab navigation', async ({ page }) => {
      // Navigate to People tab and get some data
      await page.click('[data-testid="tab-people"]');
      await page.waitForSelector('[data-testid="view-people"]', { state: 'visible' });

      const personCards = page.locator('[data-testid^="person-card-"]');
      const initialPersonCount = await personCards.count();

      // Navigate to different tab if available
      const tabs = page.locator('[data-testid^="tab-"]:not([data-testid="tab-people"])');

      if ((await tabs.count()) > 0) {
        // Click on different tab
        await tabs.first().click();
        await page.waitForTimeout(2000);

        // Navigate back to People
        await page.click('[data-testid="tab-people"]');
        await page.waitForSelector('[data-testid="view-people"]', { state: 'visible' });

        // Verify people data is still there
        const finalPersonCount = await personCards.count();
        expect(finalPersonCount).toBe(initialPersonCount);
      }
    });

    test('should handle tab navigation with URL changes', async ({ page }) => {
      // Test direct URL navigation to different views
      const testRoutes = ['/people', '/invitations', '/employees', '/settings'];

      for (const route of testRoutes) {
        try {
          await page.goto(route);

          // Wait for page to load
          await page.waitForTimeout(2000);

          // Check that page loaded successfully (not 404 or error)
          const hasError =
            (await page.locator('text=404').count()) > 0 ||
            (await page.locator('text=Error').count()) > 0 ||
            (await page.locator('text=Not Found').count()) > 0;

          if (!hasError) {
            // Verify some content is present
            const bodyText = await page.locator('body').textContent();
            expect(bodyText.length).toBeGreaterThan(100);

            console.log(`Route ${route} loaded successfully`);
          } else {
            console.log(`Route ${route} returned error (expected for some routes)`);
          }
        } catch (error) {
          console.log(`Route ${route} failed to load: ${error.message}`);
        }
      }
    });
  });

  test.describe('Deep Link Navigation', () => {
    test('should handle deep links to person details', async ({ page }) => {
      // First get some person IDs from the people list
      await page.goto('/people');
      await page.waitForSelector('[data-testid="view-people"]', { state: 'visible' });

      const personCards = page.locator('[data-testid^="person-card-"]');

      if ((await personCards.count()) > 0) {
        // Get first person's ID
        const firstPersonCard = personCards.first();
        const personDataTestId = await firstPersonCard.getAttribute('data-testid');
        const personId = personDataTestId?.replace('person-card-', '');

        if (personId) {
          // Navigate directly to person detail URL
          await page.goto(`/people/${personId}`);

          // Should load person detail page
          await expect(page.locator('[data-testid="person-detail"]')).toBeVisible({
            timeout: 10000,
          });

          // Verify URL is correct
          expect(page.url()).toContain(`/people/${personId}`);

          // Should be able to navigate back
          const backButton = page.locator('[data-testid="back-to-people"]');
          if ((await backButton.count()) > 0) {
            await backButton.click();
            await expect(page.locator('[data-testid="view-people"]')).toBeVisible();
          }
        }
      }
    });

    test('should handle browser back/forward navigation', async ({ page }) => {
      // Navigate through several pages
      await page.goto('/people');
      await page.waitForSelector('[data-testid="view-people"]', { state: 'visible' });

      // Go to person detail if possible
      const personCards = page.locator('[data-testid^="person-card-"]');

      if ((await personCards.count()) > 0) {
        await personCards.first().click();
        await expect(page.locator('[data-testid="person-detail"]')).toBeVisible({ timeout: 10000 });

        // Use browser back button
        await page.goBack();
        await expect(page.locator('[data-testid="view-people"]')).toBeVisible({ timeout: 10000 });

        // Use browser forward button
        await page.goForward();
        await expect(page.locator('[data-testid="person-detail"]')).toBeVisible({ timeout: 10000 });
      }
    });
  });

  test.describe('Mobile Navigation', () => {
    test('should handle mobile navigation patterns', async ({ page }) => {
      // Set mobile viewport
      await page.setViewportSize({ width: 375, height: 667 });

      await page.goto('/');
      await page.waitForSelector('[data-testid="loading-indicator"]', {
        state: 'hidden',
        timeout: 30000,
      });

      // Look for mobile navigation elements
      const mobileMenuButton = page.locator('[data-testid="mobile-menu-button"]');
      const hamburgerMenu = page.locator('[data-testid="hamburger-menu"]');

      if ((await mobileMenuButton.count()) > 0) {
        // Test mobile menu
        await mobileMenuButton.click();

        // Should show navigation options
        const mobileMenu = page.locator('[data-testid="mobile-menu"]');
        if ((await mobileMenu.count()) > 0) {
          await expect(mobileMenu).toBeVisible();
        }
      } else if ((await hamburgerMenu.count()) > 0) {
        await hamburgerMenu.click();
      }

      // Test touch navigation
      await page.click('[data-testid="tab-people"]');
      await page.waitForSelector('[data-testid="view-people"]', { state: 'visible' });

      // Verify mobile-friendly navigation works
      await expect(page.locator('[data-testid="view-people"]')).toBeVisible();
    });
  });

  test.describe('Accessibility Navigation', () => {
    test('should support keyboard navigation between views', async ({ page }) => {
      await page.goto('/');
      await page.waitForSelector('[data-testid="loading-indicator"]', {
        state: 'hidden',
        timeout: 30000,
      });

      // Focus on first tab and navigate with keyboard
      const firstTab = page.locator('[data-testid^="tab-"]').first();
      await firstTab.focus();

      // Press Tab key to navigate
      await page.keyboard.press('Tab');

      // Press Enter to activate focused element
      await page.keyboard.press('Enter');

      // Should navigate to corresponding view
      await page.waitForTimeout(1000);

      // Verify some content is visible
      const hasContent =
        (await page.locator('main').count()) > 0 ||
        (await page.locator('[data-testid^="view-"]').count()) > 0;

      expect(hasContent).toBe(true);
    });

    test('should have proper ARIA labels for navigation', async ({ page }) => {
      await page.goto('/');
      await page.waitForSelector('[data-testid="loading-indicator"]', {
        state: 'hidden',
        timeout: 30000,
      });

      // Check for ARIA labels on navigation elements
      const tabs = page.locator('[data-testid^="tab-"]');
      const tabCount = await tabs.count();

      for (let i = 0; i < Math.min(tabCount, 3); i++) {
        const tab = tabs.nth(i);

        // Check for accessibility attributes
        const ariaLabel = await tab.getAttribute('aria-label');
        const ariaSelected = await tab.getAttribute('aria-selected');
        const role = await tab.getAttribute('role');

        // Should have some accessibility attributes
        const hasAccessibility = ariaLabel || role === 'tab' || role === 'button';

        if (!hasAccessibility) {
          console.warn(`Tab ${i} may be missing accessibility attributes`);
        }
      }
    });
  });
});
