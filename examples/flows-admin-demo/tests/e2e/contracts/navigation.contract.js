/**
 * Navigation Contract
 * 
 * This contract defines the expected navigation behaviors for the flows-admin-demo app.
 * It serves as a single source of truth for navigation expectations and ensures
 * tests remain stable even when demo content changes.
 */

export const NavigationContract = {
  // Main tab navigation
  tabs: {
    people: {
      id: 'tab-people',
      label: 'People',
      icon: 'Users',
      defaultActive: true,
      content: {
        sections: ['dashboard-metrics', 'employee-directory', 'invitations-sidebar'],
        actions: ['new-invitation']
      }
    },
    processes: {
      id: 'tab-processes',
      label: 'Processes',
      icon: 'Settings',
      defaultActive: false,
      content: {
        sections: ['processes-header', 'process-list'],
        actions: ['new-process']
      }
    },
    // Dynamic tabs based on applications
    applications: {
      // These will be dynamically populated based on actual data
      // But we define the expected structure
      structure: {
        id: 'tab-{app.code}',
        label: '{app.name}',
        icon: 'Briefcase',
        content: {
          offboarding: {
            views: ['overview', 'templates', 'processes', 'tasks'],
            defaultView: 'overview'
          },
          generic: {
            sections: ['app-header', 'app-metrics', 'app-features', 'app-config', 'app-invitations']
          }
        }
      }
    }
  },

  // Offboarding sub-navigation
  offboarding: {
    views: {
      overview: {
        id: 'offboarding-view-overview',
        label: 'Overview',
        sections: [
          'metrics-cards',
          'additional-stats',
          'action-required',
          'quick-filters',
          'performance-insights'
        ],
        actions: {
          createOffboarding: {
            id: 'action-create-offboarding',
            label: 'Create Offboarding',
            navigatesToView: 'templates'
          },
          filterByStatus: {
            id: 'action-filter-status-{status}',
            navigatesToView: 'processes',
            statuses: ['active', 'ending_soon', 'recent_completed', 'needs_attention', 'overdue', 'pending_approval']
          },
          filterByTimeframe: {
            id: 'action-filter-timeframe-{timeframe}',
            navigatesToView: 'processes',
            timeframes: ['ending_soon', 'recent_completed', 'this_month']
          },
          viewProcess: {
            id: 'action-view-process',
            navigatesToView: 'tasks'
          }
        }
      },
      templates: {
        id: 'offboarding-view-templates',
        label: 'Templates',
        actions: {
          selectTemplate: 'action-select-template',
          createTemplate: 'action-create-template',
          editTemplate: 'action-edit-template'
        }
      },
      processes: {
        id: 'offboarding-view-processes',
        label: 'Processes',
        actions: {
          selectProcess: {
            id: 'action-select-process',
            navigatesToView: 'tasks'
          },
          createProcess: {
            id: 'action-create-process',
            navigatesToView: 'templates'
          },
          updateProcessStatus: 'action-update-process-status'
        }
      },
      tasks: {
        id: 'offboarding-view-tasks',
        label: 'Tasks',
        requiresContext: 'selectedProcess',
        actions: {
          updateTask: 'action-update-task',
          completeTask: 'action-complete-task',
          startTask: 'action-start-task',
          addNote: 'action-add-note',
          uploadDocument: 'action-upload-document'
        }
      }
    }
  },

  // Dashboard navigation actions
  dashboard: {
    metrics: {
      activeProcesses: {
        id: 'metric-active-processes',
        clickAction: 'filterByStatus',
        param: 'active'
      },
      endingSoon: {
        id: 'metric-ending-soon',
        clickAction: 'filterByTimeframe',
        param: 'ending_soon'
      },
      recentlyCompleted: {
        id: 'metric-recently-completed',
        clickAction: 'filterByTimeframe',
        param: 'recent_completed'
      },
      needsAttention: {
        id: 'metric-needs-attention',
        clickAction: 'filterByStatus',
        param: 'needs_attention'
      }
    },
    quickFilters: {
      overdueProcesses: {
        id: 'filter-overdue-processes',
        clickAction: 'filterByStatus',
        param: 'overdue'
      },
      pendingApprovals: {
        id: 'filter-pending-approvals',
        clickAction: 'filterByStatus',
        param: 'pending_approval'
      },
      thisMonthActivity: {
        id: 'filter-this-month',
        clickAction: 'filterByTimeframe',
        param: 'this_month'
      }
    },
    actionableProcesses: {
      viewProcessButton: {
        id: 'action-view-process-{processId}',
        clickAction: 'viewProcess'
      },
      viewAllButton: {
        id: 'action-view-all-needs-attention',
        clickAction: 'filterByStatus',
        param: 'needs_attention'
      }
    }
  },

  // State expectations
  stateExpectations: {
    tabSwitch: {
      preserves: ['selectedClient'],
      resets: ['offboardingView', 'selectedTemplate', 'selectedProcess']
    },
    offboardingViewSwitch: {
      preserves: ['activeTab', 'selectedClient'],
      conditionallyPreserves: {
        selectedProcess: ['when switching between processes and tasks']
      }
    },
    navigation: {
      urlPatterns: {
        root: '/',
        withTab: '/?tab={tabId}',
        withOffboardingView: '/?tab={tabId}&view={viewId}',
        withProcess: '/?tab={tabId}&view=tasks&processId={processId}'
      }
    }
  },

  // Test helpers
  testHelpers: {
    getTabSelector: (tabId) => `[data-testid="${tabId}"]`,
    getViewButtonSelector: (viewId) => `[data-testid="${viewId}"]`,
    getActionSelector: (actionId) => `[data-testid="${actionId}"]`,
    getMetricCardSelector: (metricId) => `[data-testid="${metricId}"]`,
    
    // Wait conditions
    waitForNavigation: async (page, expectedView) => {
      // Wait for view content to be visible
      await page.waitForSelector(`[data-testid="view-${expectedView}"]`, { state: 'visible' });
      // Wait for any loading states to complete
      await page.waitForSelector('[data-testid="loading-indicator"]', { state: 'hidden' }).catch(() => {});
    },
    
    // State verification
    verifyActiveTab: async (page, tabId) => {
      const activeTab = await page.locator(`[data-testid="${tabId}"][data-active="true"]`);
      await expect(activeTab).toBeVisible();
    },
    
    verifyActiveView: async (page, viewId) => {
      const activeView = await page.locator(`[data-testid="${viewId}"][data-active="true"]`);
      await expect(activeView).toBeVisible();
    }
  }
};

// Export navigation paths for easy access in tests
export const NavigationPaths = {
  dashboard: () => '/',
  peopleTab: () => '/?tab=people',
  processesTab: () => '/?tab=processes',
  applicationTab: (appCode) => `/?tab=${appCode}`,
  offboardingView: (appCode, view) => `/?tab=${appCode}&view=${view}`,
  offboardingProcess: (appCode, processId) => `/?tab=${appCode}&view=tasks&processId=${processId}`
};

// Export navigation actions
export const NavigationActions = {
  switchTab: async (page, tabId) => {
    await page.click(`[data-testid="${tabId}"]`);
    await NavigationContract.testHelpers.waitForNavigation(page, tabId);
  },
  
  switchToProcesses: async (page) => {
    await page.click(`[data-testid="tab-processes"]`);
    await NavigationContract.testHelpers.waitForNavigation(page, 'processes');
  },
  
  switchOffboardingView: async (page, viewId) => {
    await page.click(`[data-testid="offboarding-view-${viewId}"]`);
    await NavigationContract.testHelpers.waitForNavigation(page, viewId);
  },
  
  clickMetricCard: async (page, metricId) => {
    await page.click(`[data-testid="${metricId}"]`);
  },
  
  clickQuickFilter: async (page, filterId) => {
    await page.click(`[data-testid="${filterId}"]`);
  }
};