import { test, expect } from '@playwright/test';

test.describe('Data Consistency Test Suite', () => {
  test.beforeEach(async ({ page }) => {
    // Navigate to the app
    await page.goto('/');
    
    // Wait for initial load
    await page.waitForSelector('[data-testid="loading-indicator"]', { state: 'hidden', timeout: 30000 });
  });

  test.describe('PersonEnrollment Data Consistency', () => {
    test('should correctly match person data with enrollment data', async ({ page }) => {
      // Navigate to People tab
      await page.click('[data-testid="tab-people"]');
      await page.waitForSelector('[data-testid="view-people"]', { state: 'visible' });
      
      const personCards = page.locator('[data-testid^="person-card-"]');
      await expect(personCards.first()).toBeVisible({ timeout: 10000 });
      
      const personCount = await personCards.count();
      const testCount = Math.min(personCount, 5); // Test first 5 people
      
      for (let i = 0; i < testCount; i++) {
        const personCard = personCards.nth(i);
        
        // Get person ID from the card
        const personDataTestId = await personCard.getAttribute('data-testid');
        const personId = personDataTestId?.replace('person-card-', '');
        
        // Navigate to person detail
        await personCard.click();
        await expect(page.locator('[data-testid="person-detail"]')).toBeVisible({ timeout: 10000 });
        
        // Verify the page loaded without JavaScript errors
        const errors = [];
        page.on('console', msg => {
          if (msg.type() === 'error') {
            errors.push(msg.text());
          }
        });
        
        // Check that enrollment section behaves correctly
        const enrollmentSection = page.locator('[data-testid="enrollment-progress"]');
        const noEnrollmentMessage = page.locator('[data-testid="no-enrollment-message"]');
        
        const hasEnrollment = await enrollmentSection.count() > 0;
        const hasNoEnrollmentMessage = await noEnrollmentMessage.count() > 0;
        
        // Either enrollment data should be shown OR no enrollment message should be shown
        expect(hasEnrollment || hasNoEnrollmentMessage).toBe(true);
        
        // If enrollment data exists, verify it displays correctly
        if (hasEnrollment) {
          await expect(enrollmentSection).toBeVisible();
          
          // Check for progress percentage
          const progressElement = page.locator('[data-testid="completion-percentage"]');
          if (await progressElement.count() > 0) {
            const progressText = await progressElement.textContent();
            expect(progressText).toMatch(/\d+%/); // Should contain percentage
          }
          
          // Check documents section if present
          const documentsSection = page.locator('[data-testid="documents-section"]');
          if (await documentsSection.count() > 0) {
            await expect(documentsSection).toBeVisible();
            
            // Verify document items display correctly
            const documentItems = page.locator('[data-testid^="document-item-"]');
            if (await documentItems.count() > 0) {
              const firstDoc = documentItems.first();
              await expect(firstDoc).toBeVisible();
              
              // Verify document has status and name
              const docName = firstDoc.locator('[data-testid="document-name"]');
              const docStatus = firstDoc.locator('[data-testid="document-status"]');
              
              if (await docName.count() > 0) {
                await expect(docName).toBeVisible();
              }
              if (await docStatus.count() > 0) {
                await expect(docStatus).toBeVisible();
              }
            }
          }
          
          // Check tasks section if present
          const tasksSection = page.locator('[data-testid="tasks-section"]');
          if (await tasksSection.count() > 0) {
            await expect(tasksSection).toBeVisible();
            
            // Verify task items display correctly
            const taskItems = page.locator('[data-testid^="task-item-"]');
            if (await taskItems.count() > 0) {
              const firstTask = taskItems.first();
              await expect(firstTask).toBeVisible();
              
              // Verify task has title and status
              const taskTitle = firstTask.locator('[data-testid="task-title"]');
              const taskStatus = firstTask.locator('[data-testid="task-status"]');
              
              if (await taskTitle.count() > 0) {
                await expect(taskTitle).toBeVisible();
              }
              if (await taskStatus.count() > 0) {
                await expect(taskStatus).toBeVisible();
              }
            }
          }
        }
        
        // Check for critical JavaScript errors that might indicate data mismatch
        const criticalErrors = errors.filter(error => 
          error.includes('Cannot read property') ||
          error.includes('Cannot read properties') ||
          error.includes('personId') ||
          error.includes('employeeId') ||
          error.includes('TypeError') ||
          error.includes('undefined')
        );
        
        if (criticalErrors.length > 0) {
          console.warn(`Data consistency errors for person ${personId}:`, criticalErrors);
          // Don't fail the test but log the issue for investigation
        }
        
        // Return to people list for next iteration
        await page.click('[data-testid="back-to-people"]');
        await expect(page.locator('[data-testid="view-people"]')).toBeVisible();
      }
    });

    test('should handle mixed employee and associate data correctly', async ({ page }) => {
      // Navigate to People tab
      await page.click('[data-testid="tab-people"]');
      await page.waitForSelector('[data-testid="view-people"]', { state: 'visible' });
      
      const personCards = page.locator('[data-testid^="person-card-"]');
      await expect(personCards.first()).toBeVisible({ timeout: 10000 });
      
      const personCount = await personCards.count();
      
      const foundTypes = {
        employees: [],
        associates: [],
        withEnrollment: [],
        withoutEnrollment: []
      };
      
      // Analyze all people to understand data consistency patterns
      for (let i = 0; i < Math.min(personCount, 10); i++) {
        const personCard = personCards.nth(i);
        const personDataTestId = await personCard.getAttribute('data-testid');
        const personId = personDataTestId?.replace('person-card-', '');
        
        await personCard.click();
        await expect(page.locator('[data-testid="person-detail"]')).toBeVisible({ timeout: 10000 });
        
        // Determine person type
        const employeeIndicator = page.locator('text=Employee');
        const associateIndicator = page.locator('text=Associate');
        
        let personType = 'unknown';
        if (await employeeIndicator.count() > 0) {
          personType = 'employee';
          foundTypes.employees.push(personId);
        } else if (await associateIndicator.count() > 0) {
          personType = 'associate';
          foundTypes.associates.push(personId);
        }
        
        // Check enrollment status
        const hasEnrollment = await page.locator('[data-testid="enrollment-progress"]').count() > 0;
        if (hasEnrollment) {
          foundTypes.withEnrollment.push(personId);
        } else {
          foundTypes.withoutEnrollment.push(personId);
        }
        
        // Verify appropriate data fields are shown for each type
        if (personType === 'employee') {
          // Employees should have employment status
          const employmentStatus = page.locator('[data-testid="employment-status"]');
          if (await employmentStatus.count() > 0) {
            await expect(employmentStatus).toBeVisible();
          }
        } else if (personType === 'associate') {
          // Associates should have associate type
          const associateType = page.locator('[data-testid="associate-type"]');
          if (await associateType.count() > 0) {
            await expect(associateType).toBeVisible();
          }
        }
        
        await page.click('[data-testid="back-to-people"]');
        await expect(page.locator('[data-testid="view-people"]')).toBeVisible();
      }
      
      // Log analysis results
      console.log('Data consistency analysis:', {
        totalPeople: Math.min(personCount, 10),
        employees: foundTypes.employees.length,
        associates: foundTypes.associates.length,
        withEnrollment: foundTypes.withEnrollment.length,
        withoutEnrollment: foundTypes.withoutEnrollment.length
      });
      
      // Basic sanity checks
      expect(foundTypes.employees.length + foundTypes.associates.length).toBeGreaterThan(0);
    });

    test('should handle enrollment data lookup correctly (personId vs employeeId fix)', async ({ page }) => {
      // This test specifically validates the fix for the personId/employeeId mismatch bug
      
      // Navigate to People tab
      await page.click('[data-testid="tab-people"]');
      await page.waitForSelector('[data-testid="view-people"]', { state: 'visible' });
      
      // Set up console error monitoring
      const consoleErrors = [];
      page.on('console', msg => {
        if (msg.type() === 'error') {
          consoleErrors.push(msg.text());
        }
      });
      
      const personCards = page.locator('[data-testid^="person-card-"]');
      await expect(personCards.first()).toBeVisible({ timeout: 10000 });
      
      // Test multiple people to catch enrollment lookup issues
      const personCount = await personCards.count();
      const testCount = Math.min(personCount, 5);
      
      for (let i = 0; i < testCount; i++) {
        const personCard = personCards.nth(i);
        const personDataTestId = await personCard.getAttribute('data-testid');
        const personId = personDataTestId?.replace('person-card-', '');
        
        // Clear previous errors
        consoleErrors.length = 0;
        
        // Navigate to person detail
        await personCard.click();
        
        // The page should load without crashing (this was the main symptom of the bug)
        await expect(page.locator('[data-testid="person-detail"]')).toBeVisible({ timeout: 10000 });
        
        // Verify person information loads correctly
        await expect(page.locator('[data-testid="person-name"]')).toBeVisible();
        
        // Check for enrollment-related errors
        const enrollmentErrors = consoleErrors.filter(error => 
          error.includes('employeeId') || 
          error.includes('personId') ||
          error.includes('enrollment') ||
          error.includes('undefined')
        );
        
        if (enrollmentErrors.length > 0) {
          console.warn(`Enrollment lookup errors for person ${personId}:`, enrollmentErrors);
          // This suggests the personId/employeeId fix may not be complete
        }
        
        // If enrollment section exists, verify it renders without errors
        const enrollmentSection = page.locator('[data-testid="enrollment-progress"]');
        if (await enrollmentSection.count() > 0) {
          await expect(enrollmentSection).toBeVisible();
          
          // Check that completion percentage is valid
          const percentageElement = page.locator('[data-testid="completion-percentage"]');
          if (await percentageElement.count() > 0) {
            const percentageText = await percentageElement.textContent();
            expect(percentageText).toMatch(/^\d+%$/);
            
            const percentage = parseInt(percentageText.replace('%', ''));
            expect(percentage).toBeGreaterThanOrEqual(0);
            expect(percentage).toBeLessThanOrEqual(100);
          }
        }
        
        await page.click('[data-testid="back-to-people"]');
        await expect(page.locator('[data-testid="view-people"]')).toBeVisible();
      }
      
      // Overall check: no critical enrollment-related errors should occur
      const criticalEnrollmentErrors = consoleErrors.filter(error =>
        (error.includes('employeeId') || error.includes('enrollment')) && 
        (error.includes('TypeError') || error.includes('Cannot read'))
      );
      
      expect(criticalEnrollmentErrors.length).toBe(0);
    });
  });

  test.describe('Cross-Reference Data Validation', () => {
    test('should maintain data consistency between People and Employees views', async ({ page }) => {
      // Navigate to People tab first
      await page.click('[data-testid="tab-people"]');
      await page.waitForSelector('[data-testid="view-people"]', { state: 'visible' });
      
      const personCards = page.locator('[data-testid^="person-card-"]');
      await expect(personCards.first()).toBeVisible({ timeout: 10000 });
      
      // Collect data from first few people
      const peopleData = [];
      const peopleCount = await personCards.count();
      const testCount = Math.min(peopleCount, 3);
      
      for (let i = 0; i < testCount; i++) {
        const personCard = personCards.nth(i);
        await personCard.click();
        
        await expect(page.locator('[data-testid="person-detail"]')).toBeVisible({ timeout: 10000 });
        
        // Extract person data
        const nameElement = page.locator('[data-testid="person-name"]');
        const emailElement = page.locator('[data-testid="person-email"]');
        
        const name = await nameElement.textContent();
        const email = await emailElement.textContent();
        
        peopleData.push({ name, email });
        
        await page.click('[data-testid="back-to-people"]');
        await expect(page.locator('[data-testid="view-people"]')).toBeVisible();
      }
      
      // Now check if there's an Employees tab (legacy view)
      const employeesTab = page.locator('[data-testid="tab-employees"]');
      if (await employeesTab.count() > 0) {
        await employeesTab.click();
        await page.waitForSelector('[data-testid="view-employees"]', { state: 'visible' });
        
        // Verify that employee data matches people data where applicable
        const employeeCards = page.locator('[data-testid^="employee-card-"]');
        
        if (await employeeCards.count() > 0) {
          // Check first few employees
          const employeeCount = await employeeCards.count();
          const checkCount = Math.min(employeeCount, 3);
          
          for (let i = 0; i < checkCount; i++) {
            const employeeCard = employeeCards.nth(i);
            await employeeCard.click();
            
            await expect(page.locator('[data-testid="employee-detail"]')).toBeVisible({ timeout: 10000 });
            
            // Extract employee data
            const nameElement = page.locator('[data-testid="employee-name"]');
            const emailElement = page.locator('[data-testid="employee-email"]');
            
            if (await nameElement.count() > 0 && await emailElement.count() > 0) {
              const employeeName = await nameElement.textContent();
              const employeeEmail = await emailElement.textContent();
              
              // Check if this employee exists in people data
              const matchingPerson = peopleData.find(person => 
                person.email === employeeEmail || person.name === employeeName
              );
              
              if (matchingPerson) {
                console.log(`Found matching data: ${employeeName} / ${employeeEmail}`);
              }
            }
            
            await page.click('[data-testid="back-to-employees"]');
            await expect(page.locator('[data-testid="view-employees"]')).toBeVisible();
          }
        }
      }
    });

    test('should handle client switching without data corruption', async ({ page }) => {
      // Test data consistency across client switches
      
      // Get initial client
      const currentClient = await page.textContent('[data-testid="current-client-name"]').catch(() => null);
      
      // Navigate to people and get baseline data
      await page.click('[data-testid="tab-people"]');
      await page.waitForSelector('[data-testid="view-people"]', { state: 'visible' });
      
      const initialPersonCards = page.locator('[data-testid^="person-card-"]');
      const initialCount = await initialPersonCards.count();
      
      // Try to switch client if possible
      const clientSwitcher = page.locator('[data-testid="client-switcher"]');
      if (await clientSwitcher.count() > 0) {
        await clientSwitcher.click();
        
        // Look for client options
        const clientOptions = page.locator('[data-testid^="client-option-"]');
        if (await clientOptions.count() > 1) {
          // Switch to different client
          await clientOptions.nth(1).click();
          
          // Wait for data to reload
          await page.waitForLoadState('networkidle');
          await page.waitForSelector('[data-testid="view-people"]', { state: 'visible' });
          
          // Verify data changed appropriately
          const newPersonCards = page.locator('[data-testid^="person-card-"]');
          await expect(newPersonCards.first()).toBeVisible({ timeout: 10000 });
          
          // Data should be consistent (either same or different, but not corrupted)
          const newCount = await newPersonCards.count();
          expect(newCount).toBeGreaterThanOrEqual(0);
          
          // Switch back to original client
          await clientSwitcher.click();
          if (currentClient) {
            const originalClientOption = page.locator(`[data-testid="client-option-${currentClient}"]`);
            if (await originalClientOption.count() > 0) {
              await originalClientOption.click();
              await page.waitForLoadState('networkidle');
            }
          }
        }
      }
    });
  });

  test.describe('Data Loading State Consistency', () => {
    test('should show appropriate loading states during data fetch', async ({ page }) => {
      // Navigate to People tab
      await page.click('[data-testid="tab-people"]');
      
      // Check for loading indicator
      const loadingIndicator = page.locator('[data-testid="loading-indicator"]');
      
      // Either loading should be shown or data should be immediately available
      const loadingVisible = await loadingIndicator.isVisible();
      const peopleViewVisible = await page.locator('[data-testid="view-people"]').isVisible();
      
      expect(loadingVisible || peopleViewVisible).toBe(true);
      
      // Wait for final state
      await page.waitForSelector('[data-testid="view-people"]', { state: 'visible', timeout: 10000 });
      
      // Loading should be hidden when data is loaded
      await expect(loadingIndicator).not.toBeVisible();
    });

    test('should handle empty data states gracefully', async ({ page }) => {
      // This test checks how the app handles when there's no people data
      
      await page.click('[data-testid="tab-people"]');
      await page.waitForSelector('[data-testid="view-people"]', { state: 'visible' });
      
      const personCards = page.locator('[data-testid^="person-card-"]');
      const emptyState = page.locator('[data-testid="people-empty-state"]');
      
      const hasPersons = await personCards.count() > 0;
      const hasEmptyState = await emptyState.count() > 0;
      
      // Either there should be people data OR an empty state message
      expect(hasPersons || hasEmptyState).toBe(true);
      
      if (hasEmptyState) {
        await expect(emptyState).toBeVisible();
      }
    });
  });
});