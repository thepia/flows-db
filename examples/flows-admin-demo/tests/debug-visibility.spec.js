import { expect, test } from '@playwright/test';

test('debug application tabs visibility issue', async ({ page }) => {
  await page.goto('/');

  // Wait for loading
  await page.waitForSelector('[data-testid="loading-indicator"]', {
    state: 'hidden',
    timeout: 10000,
  });

  // Wait for applications to actually load
  await page.waitForFunction(
    () => {
      const debugSpan = document.querySelector('span.text-blue-500.text-xs');
      return debugSpan && debugSpan.textContent && debugSpan.textContent.includes('Loaded=true');
    },
    { timeout: 10000 }
  );

  // Get debug info
  const debugText = await page.locator('span.text-blue-500.text-xs').textContent();
  console.log('Debug text:', debugText);

  // Check if the conditional block is in the DOM
  const appButtons = await page.locator('[data-testid^="tab-"][data-testid*="-"]').all();
  console.log(`Found ${appButtons.length} application buttons in DOM`);

  // Check each button's visibility
  for (let i = 0; i < appButtons.length; i++) {
    const button = appButtons[i];
    const testId = await button.getAttribute('data-testid');
    const isVisible = await button.isVisible();
    // isAttached() not available on ElementHandle, skip it
    const boundingBox = await button.boundingBox();

    console.log(`Button ${i}: ${testId}`);
    console.log(`  - Visible: ${isVisible}`);
    console.log(`  - BoundingBox:`, boundingBox);

    if (!isVisible) {
      // Try to find why it's not visible
      const computedStyle = await button.evaluate((el) => {
        const style = window.getComputedStyle(el);
        return {
          display: style.display,
          visibility: style.visibility,
          opacity: style.opacity,
          position: style.position,
          zIndex: style.zIndex,
          width: style.width,
          height: style.height,
        };
      });
      console.log('  - Computed style:', computedStyle);

      // Check parent visibility
      const parent = await button.evaluateHandle((el) => el.parentElement);
      const parentVisible = await parent.evaluate((el) => {
        const style = window.getComputedStyle(el);
        return {
          display: style.display,
          visibility: style.visibility,
          tagName: el.tagName,
          className: el.className,
        };
      });
      console.log('  - Parent:', parentVisible);
    }
  }

  // Take a screenshot for manual inspection
  await page.screenshot({ path: 'debug-tabs-visibility.png', fullPage: true });

  // Also check the HTML structure
  const navHTML = await page.locator('nav').innerHTML();
  console.log('Navigation HTML:', navHTML.substring(0, 500) + '...');
});
