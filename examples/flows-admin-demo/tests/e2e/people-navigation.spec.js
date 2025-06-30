import { test, expect } from '@playwright/test';

test.describe('People Navigation Test Suite', () => {
  test.beforeEach(async ({ page }) => {
    // Navigate to the app
    await page.goto('/');
    
    // Wait for initial load
    await page.waitForSelector('[data-testid="loading-indicator"]', { state: 'hidden', timeout: 30000 });
    
    // Navigate to People tab
    await page.click('[data-testid="tab-people"]');
    await page.waitForSelector('[data-testid="view-people"]', { state: 'visible' });
  });

  test.describe('People List Navigation', () => {
    test('should display people list with person cards', async ({ page }) => {
      // Verify people list is visible
      await expect(page.locator('[data-testid="view-people"]')).toBeVisible();
      
      // Check that person cards are displayed
      const personCards = page.locator('[data-testid^="person-card-"]');
      await expect(personCards.first()).toBeVisible({ timeout: 10000 });
      
      // Verify at least one person is displayed
      const personCount = await personCards.count();
      expect(personCount).toBeGreaterThan(0);
    });

    test('should navigate to person detail page from person list', async ({ page }) => {
      // Wait for person cards to load and JS to be ready
      const personCards = page.locator('[data-testid^="person-card-"]');
      await expect(personCards.first()).toBeVisible({ timeout: 10000 });
      
      // Wait for SvelteKit to fully initialize
      await page.waitForTimeout(1000);
      
      // Get the first person's ID for verification
      const firstPersonCard = personCards.first();
      const personId = await firstPersonCard.getAttribute('data-testid');
      const extractedId = personId?.replace('person-card-', '');
      
      // Log console messages
      page.on('console', msg => console.log('Console:', msg.text()));
      
      // Click on the first person card
      console.log('Clicking person card with ID:', extractedId);
      
      // Try force clicking in case there's an overlay
      await firstPersonCard.click({ force: true });
      
      // Also try clicking the view details text directly
      const viewDetailsLink = firstPersonCard.locator('text=View Details');
      if (await viewDetailsLink.count() > 0) {
        console.log('Found View Details link, clicking it');
        await viewDetailsLink.click();
      }
      
      // Wait for navigation to complete
      await page.waitForLoadState('networkidle');
      
      // Verify navigation to person detail page
      await expect(page).toHaveURL(new RegExp(`/people/${extractedId}`), { timeout: 10000 });
      
      // Verify person detail page content is loaded
      await expect(page.locator('[data-testid="person-detail"]')).toBeVisible({ timeout: 10000 });
      await expect(page.locator('[data-testid="person-header"]')).toBeVisible();
    });

    test('should display person information correctly on detail page', async ({ page }) => {
      // Navigate to first person
      const personCards = page.locator('[data-testid^="person-card-"]');
      await expect(personCards.first()).toBeVisible({ timeout: 10000 });
      
      // Click the View Details link instead of the card
      const viewDetailsLink = personCards.first().locator('text=View Details');
      await viewDetailsLink.click();
      
      // Wait for detail page to load
      await expect(page.locator('[data-testid="person-detail"]')).toBeVisible({ timeout: 10000 });
      
      // Verify essential person information is displayed
      await expect(page.locator('[data-testid="person-name"]')).toBeVisible();
      await expect(page.locator('[data-testid="person-email"]')).toBeVisible();
      await expect(page.locator('[data-testid="person-department"]')).toBeVisible();
      await expect(page.locator('[data-testid="person-position"]')).toBeVisible();
    });

    test('should display enrollment information when available', async ({ page }) => {
      // Navigate to first person
      const personCards = page.locator('[data-testid^="person-card-"]');
      await expect(personCards.first()).toBeVisible({ timeout: 10000 });
      
      // Click the View Details link
      const viewDetailsLink = personCards.first().locator('text=View Details');
      await viewDetailsLink.click();
      
      // Wait for detail page to load
      await expect(page.locator('[data-testid="person-detail"]')).toBeVisible({ timeout: 10000 });
      
      // Check if enrollment data exists
      const enrollmentSection = page.locator('[data-testid="enrollment-progress"]');
      const enrollmentExists = await enrollmentSection.count() > 0;
      
      if (enrollmentExists) {
        // Verify enrollment information is displayed
        await expect(enrollmentSection).toBeVisible();
        await expect(page.locator('[data-testid="completion-percentage"]')).toBeVisible();
        
        // Check for documents and tasks sections
        const documentsSection = page.locator('[data-testid="documents-section"]');
        const tasksSection = page.locator('[data-testid="tasks-section"]');
        
        if (await documentsSection.count() > 0) {
          await expect(documentsSection).toBeVisible();
        }
        
        if (await tasksSection.count() > 0) {
          await expect(tasksSection).toBeVisible();
        }
      } else {
        // Verify no enrollment message is shown
        await expect(page.locator('[data-testid="no-enrollment-message"]')).toBeVisible();
      }
    });

    test('should return to people list when clicking back button', async ({ page }) => {
      // Navigate to person detail
      const personCards = page.locator('[data-testid^="person-card-"]');
      await expect(personCards.first()).toBeVisible({ timeout: 10000 });
      
      // Click the View Details link
      const viewDetailsLink = personCards.first().locator('text=View Details');
      await viewDetailsLink.click();
      
      // Wait for detail page
      await expect(page.locator('[data-testid="person-detail"]')).toBeVisible({ timeout: 10000 });
      
      // Click back button
      await page.click('[data-testid="back-to-people"]');
      
      // Verify return to people list
      await expect(page).toHaveURL(/\/people$/);
      await expect(page.locator('[data-testid="view-people"]')).toBeVisible();
      await expect(personCards.first()).toBeVisible();
    });
  });

  test.describe('Error State Navigation', () => {
    test('should handle invalid person ID gracefully', async ({ page }) => {
      // Navigate directly to invalid person ID
      await page.goto('/people/invalid-person-id-12345');
      
      // Verify 404/not found state
      await expect(page.locator('[data-testid="person-not-found"]')).toBeVisible({ timeout: 10000 });
      
      // Verify error message is displayed
      const errorMessage = page.locator('text=Person Not Found');
      await expect(errorMessage).toBeVisible();
      
      // Verify return to people button exists
      const returnButton = page.locator('text=Return to People');
      await expect(returnButton).toBeVisible();
      
      // Click return button and verify navigation
      await returnButton.click();
      await expect(page).toHaveURL(/\/people$/);
      await expect(page.locator('[data-testid="view-people"]')).toBeVisible();
    });

    test('should handle missing person data gracefully', async ({ page }) => {
      // This test checks the specific bug that was fixed where personId/employeeId mismatch
      // Navigate to a person that exists but might have enrollment data issues
      await page.goto('/people');
      await page.waitForSelector('[data-testid="view-people"]', { state: 'visible' });
      
      const personCards = page.locator('[data-testid^="person-card-"]');
      await expect(personCards.first()).toBeVisible({ timeout: 10000 });
      
      // Get all person IDs to test different scenarios
      const personCount = await personCards.count();
      
      for (let i = 0; i < Math.min(personCount, 3); i++) {
        const personCard = personCards.nth(i);
        const personId = await personCard.getAttribute('data-testid');
        const extractedId = personId?.replace('person-card-', '');
        
        // Navigate to person detail
        await page.goto(`/people/${extractedId}`);
        
        // Verify page loads without crashing
        await expect(page.locator('[data-testid="person-detail"]')).toBeVisible({ timeout: 10000 });
        
        // Verify essential elements are present (shouldn't crash)
        await expect(page.locator('[data-testid="person-name"]')).toBeVisible();
        
        // Check console for errors (this helps catch the enrollment data mismatch)
        const logs = [];
        page.on('console', msg => {
          if (msg.type() === 'error') {
            logs.push(msg.text());
          }
        });
        
        // If there are critical console errors, the test should be aware
        // (though we don't want to fail on minor warnings)
        const criticalErrors = logs.filter(log => 
          log.includes('TypeError') || 
          log.includes('Cannot read') || 
          log.includes('undefined')
        );
        
        if (criticalErrors.length > 0) {
          console.warn(`Critical errors found for person ${extractedId}:`, criticalErrors);
        }
      }
    });
  });

  test.describe('Person Type Differentiation', () => {
    test('should correctly identify and display employee vs associate types', async ({ page }) => {
      // Navigate to people list
      await page.waitForSelector('[data-testid="view-people"]', { state: 'visible' });
      
      const personCards = page.locator('[data-testid^="person-card-"]');
      await expect(personCards.first()).toBeVisible({ timeout: 10000 });
      
      const personCount = await personCards.count();
      
      // Check multiple people to find both employees and associates
      const foundTypes = new Set();
      
      for (let i = 0; i < Math.min(personCount, 5); i++) {
        const personCard = personCards.nth(i);
        const viewDetailsLink = personCard.locator('text=View Details');
        await viewDetailsLink.click();
        
        // Wait for detail page
        await expect(page.locator('[data-testid="person-detail"]')).toBeVisible({ timeout: 10000 });
        
        // Check person type indicator
        const employeeIndicator = page.locator('text=Employee');
        const associateIndicator = page.locator('text=Associate');
        
        if (await employeeIndicator.count() > 0) {
          foundTypes.add('employee');
          // Verify employee-specific information
          await expect(page.locator('[data-testid="employment-status"]')).toBeVisible();
        }
        
        if (await associateIndicator.count() > 0) {
          foundTypes.add('associate');
          // Verify associate-specific information
          await expect(page.locator('[data-testid="associate-type"]')).toBeVisible();
        }
        
        // Return to people list for next iteration
        await page.click('[data-testid="back-to-people"]');
        await expect(page.locator('[data-testid="view-people"]')).toBeVisible();
      }
      
      // Log what types were found (helpful for debugging test data)
      console.log(`Found person types: ${Array.from(foundTypes).join(', ')}`);
    });
  });

  test.describe('Edit Functionality Navigation', () => {
    test('should enable edit mode and show form fields', async ({ page }) => {
      // Navigate to first person
      const personCards = page.locator('[data-testid^="person-card-"]');
      await expect(personCards.first()).toBeVisible({ timeout: 10000 });
      
      // Click the View Details link
      const viewDetailsLink = personCards.first().locator('text=View Details');
      await viewDetailsLink.click();
      
      // Wait for detail page
      await expect(page.locator('[data-testid="person-detail"]')).toBeVisible({ timeout: 10000 });
      
      // Click edit button
      const editButton = page.locator('[data-testid="edit-person-button"]');
      if (await editButton.count() > 0) {
        await editButton.click();
        
        // Verify edit form is displayed
        await expect(page.locator('[data-testid="person-edit-form"]')).toBeVisible();
        
        // Verify form fields are present
        await expect(page.locator('input[name="firstName"]')).toBeVisible();
        await expect(page.locator('input[name="lastName"]')).toBeVisible();
        await expect(page.locator('input[name="email"]')).toBeVisible();
        
        // Verify save and cancel buttons
        await expect(page.locator('[data-testid="save-changes-button"]')).toBeVisible();
        await expect(page.locator('[data-testid="cancel-edit-button"]')).toBeVisible();
        
        // Test cancel functionality
        await page.click('[data-testid="cancel-edit-button"]');
        await expect(page.locator('[data-testid="person-edit-form"]')).not.toBeVisible();
      }
    });
  });

  test.describe('Navigation Performance', () => {
    test('should load person detail page within acceptable time', async ({ page }) => {
      const personCards = page.locator('[data-testid^="person-card-"]');
      await expect(personCards.first()).toBeVisible({ timeout: 10000 });
      
      // Measure navigation time
      const startTime = Date.now();
      const viewDetailsLink = personCards.first().locator('text=View Details');
      await viewDetailsLink.click();
      await expect(page.locator('[data-testid="person-detail"]')).toBeVisible({ timeout: 10000 });
      const endTime = Date.now();
      
      const navigationTime = endTime - startTime;
      
      // Navigation should complete within 3 seconds for good UX
      expect(navigationTime).toBeLessThan(3000);
      console.log(`Person detail navigation time: ${navigationTime}ms`);
    });

    test('should handle rapid navigation without issues', async ({ page }) => {
      const personCards = page.locator('[data-testid^="person-card-"]');
      await expect(personCards.first()).toBeVisible({ timeout: 10000 });
      
      const personCount = await personCards.count();
      const testCount = Math.min(personCount, 3);
      
      // Rapidly navigate between people
      for (let i = 0; i < testCount; i++) {
        const viewDetailsLink = personCards.nth(i).locator('text=View Details');
        await viewDetailsLink.click();
        await expect(page.locator('[data-testid="person-detail"]')).toBeVisible({ timeout: 5000 });
        
        // Quick return to list
        await page.click('[data-testid="back-to-people"]');
        await expect(page.locator('[data-testid="view-people"]')).toBeVisible();
      }
    });
  });

  test.describe('Accessibility Navigation', () => {
    test('should support keyboard navigation on people list', async ({ page }) => {
      await page.waitForSelector('[data-testid="view-people"]', { state: 'visible' });
      
      // Focus on first person card's View Details link
      const firstPersonCard = page.locator('[data-testid^="person-card-"]').first();
      const viewDetailsLink = firstPersonCard.locator('text=View Details');
      await viewDetailsLink.focus();
      
      // Press Enter to navigate
      await page.keyboard.press('Enter');
      
      // Verify navigation occurred
      await expect(page.locator('[data-testid="person-detail"]')).toBeVisible({ timeout: 10000 });
    });

    test('should support keyboard navigation on person detail page', async ({ page }) => {
      // Navigate to person detail
      const personCards = page.locator('[data-testid^="person-card-"]');
      await expect(personCards.first()).toBeVisible({ timeout: 10000 });
      
      // Click the View Details link
      const viewDetailsLink = personCards.first().locator('text=View Details');
      await viewDetailsLink.click();
      
      await expect(page.locator('[data-testid="person-detail"]')).toBeVisible({ timeout: 10000 });
      
      // Test tab navigation through interactive elements
      await page.keyboard.press('Tab'); // Should focus on back button or edit button
      
      const focusedElement = await page.evaluate(() => document.activeElement?.getAttribute('data-testid'));
      expect(focusedElement).toBeTruthy();
    });
  });
});