# Architecture Migration Guide

## ⚠️ Important SvelteKit Naming Conventions

**NEVER** use `+` prefix for regular files! Files with `+` are reserved for SvelteKit:
- `+page.svelte` - Route pages
- `+layout.svelte` - Layout components  
- `+page.ts` - Page load functions
- `+error.svelte` - Error pages

## 🗂️ Proper File Organization

### Current Structure (Before Cleanup)
```
src/routes/
└── +page.svelte (1,462 lines) ❌ TOO LARGE
```

### Target Structure (After Cleanup)
```
src/
├── routes/
│   └── +page.svelte (100 lines) ✅ CLEAN
├── lib/
│   ├── components/
│   │   ├── navigation/
│   │   │   ├── AppNavigation.svelte
│   │   │   └── TabButton.svelte
│   │   ├── tabs/
│   │   │   ├── PeopleTab.svelte
│   │   │   ├── ApplicationTab.svelte
│   │   │   └── ProcessesTab.svelte
│   │   └── TabContentRouter.svelte
│   ├── services/
│   │   ├── ApplicationsService.ts
│   │   ├── PeopleService.ts
│   │   └── BaseService.ts
│   ├── stores/
│   │   ├── applications.store.ts
│   │   ├── people.store.ts
│   │   └── navigation.store.ts
│   └── composables/
│       ├── useTabNavigation.ts
│       └── useDataLoader.ts
└── docs/
    ├── examples/
    │   └── page-after-cleanup.svelte ✅ EXAMPLE ONLY
    └── MIGRATION_GUIDE.md
```

## 🔄 Migration Steps

### Step 1: Create Component Structure
```bash
# Create directory structure
mkdir -p src/lib/components/navigation
mkdir -p src/lib/components/tabs
mkdir -p src/lib/services
mkdir -p src/lib/stores/domains
mkdir -p src/lib/composables
```

### Step 2: Extract Navigation Component
1. Copy navigation logic from `+page.svelte` 
2. Create `src/lib/components/navigation/AppNavigation.svelte`
3. Test navigation independently

### Step 3: Extract Tab Components
1. Extract each tab's content into separate components
2. Create `TabContentRouter.svelte` for routing logic
3. Update `+page.svelte` to use new components

### Step 4: Create Service Layer
1. Extract data operations from stores
2. Create focused service classes
3. Update stores to use services

## ⚡ Quick Start Migration

### Before (Current +page.svelte)
```svelte
<script>
  // 100+ lines of reactive logic
  // Mixed navigation, data loading, UI logic
  // Hard to debug and maintain
</script>

<!-- 1,300+ lines of template -->
```

### After (New +page.svelte) 
```svelte
<script>
  // Clean, focused logic (~50 lines)
  import AppNavigation from '$lib/components/navigation/AppNavigation.svelte';
  import TabContentRouter from '$lib/components/TabContentRouter.svelte';
  
  // Simple navigation composable
  const { activeTab, selectedApp } = useTabNavigation(applications);
</script>

<!-- Clean, minimal template (~50 lines) -->
<AppNavigation bind:activeTab />
<TabContentRouter {activeTab} {selectedApp} />
```

## 🧪 Testing Strategy

### Current Testing Issues
- Complex E2E tests navigating massive component
- Hard to isolate specific functionality
- Slow test execution

### Improved Testing Approach
```typescript
// Unit tests for individual components
test('AppNavigation - should highlight active tab', () => {
  // Test navigation component in isolation
});

// Unit tests for services
test('ApplicationsService - should load applications', () => {
  // Test service logic independently
});

// Focused integration tests
test('TabContentRouter - should show correct content', () => {
  // Test routing logic specifically
});
```

## 📊 Success Metrics

| Metric | Before | Target | Status |
|--------|--------|---------|---------|
| Main file size | 1,462 lines | <100 lines | 🔄 In Progress |
| Component count | 1 massive | 8+ focused | ✅ Started |
| Test isolation | ❌ Complex | ✅ Simple | 🔄 Planning |
| Debug time | Hours | Minutes | 🔄 In Progress |
| Hot reload speed | >3s | <1s | 🔄 To Test |

## 🚀 Benefits Realized

### For Development
- ✅ **Faster debugging** - Clear component boundaries
- ✅ **Better hot reload** - Smaller components update faster
- ✅ **Easier testing** - Unit test individual components
- ✅ **Code reusability** - Components can be reused

### For Maintenance  
- ✅ **Easier changes** - Modify one component without affecting others
- ✅ **Better error isolation** - Errors contained to specific components
- ✅ **Clear responsibilities** - Each component has single purpose
- ✅ **Documentation** - Smaller components easier to document

## ⚠️ Migration Risks & Mitigation

### Low Risk
- ✅ **Component extraction** - Existing functionality preserved
- ✅ **Service creation** - Additive changes

### Medium Risk  
- ⚠️ **Store refactoring** - Careful migration needed
- ⚠️ **Reactive logic changes** - Thorough testing required

### Mitigation Strategy
1. **Incremental migration** - One component at a time
2. **Parallel development** - Keep existing code until tested
3. **Comprehensive testing** - E2E tests ensure no regressions
4. **Feature flags** - Conditional rendering during transition