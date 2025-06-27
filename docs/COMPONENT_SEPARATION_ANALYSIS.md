# Component Separation Analysis & Refactoring Plan

## Current State Analysis

### Main Dashboard (`+page.svelte`) - 400+ lines
**Issues Identified:**
- **Monolithic structure** - All logic in single file
- **Mixed concerns** - Data loading, UI state, business logic combined
- **Repeated patterns** - Similar card structures throughout
- **Hard to test** - Components tightly coupled
- **Poor reusability** - Invitation management logic duplicated
- **Complex state management** - Multiple UI states in one component

### Current Structure Breakdown

```
+page.svelte (418 lines)
├── Data Loading Logic (50 lines)
├── Metrics Loading (30 lines)
├── Invitation Management Functions (40 lines)
├── Status/Color Helper Functions (20 lines)
├── Dashboard Header (20 lines)
├── Metrics Cards Grid (80 lines)
├── Employee Directory (100 lines)
├── Recent Invitations Sidebar (120 lines)
└── Utility Components (click handlers, etc.)
```

## Proposed Component Architecture

### 1. Dashboard Container Components

#### `DashboardHeader.svelte`
```typescript
// Purpose: Top header with title and action buttons
interface Props {
  clientName?: string;
  loading?: boolean;
}
```

#### `DashboardMetrics.svelte`
```typescript
// Purpose: KPI metrics grid (4 stat cards)
interface Props {
  totalEmployees: number;
  onboardingCount: number;
  offboardingCount: number;
  pendingInvitations: number;
  loading?: boolean;
}
```

#### `DashboardContent.svelte`
```typescript
// Purpose: Main grid layout (Employee List + Sidebar)
interface Props {
  employees: Employee[];
  invitations: Invitation[];
  loading?: boolean;
}
```

### 2. Employee Management Components

#### `EmployeeDirectory.svelte`
```typescript
// Purpose: Employee list container with search/filter
interface Props {
  employees: Employee[];
  loading?: boolean;
  onEmployeeSelect?: (employee: Employee) => void;
}
```

#### `EmployeeCard.svelte`
```typescript
// Purpose: Individual employee list item
interface Props {
  employee: Employee;
  enrollment?: EmployeeEnrollment;
  onSelect?: (employee: Employee) => void;
  onEdit?: (employee: Employee) => void;
}
```

#### `EmployeeStatusBadge.svelte`
```typescript
// Purpose: Reusable status indicator
interface Props {
  status: Employee['status'];
  size?: 'sm' | 'md' | 'lg';
}
```

### 3. Invitation Management Components

#### `InvitationsSidebar.svelte`
```typescript
// Purpose: Recent invitations sidebar container
interface Props {
  invitations: Invitation[];
  maxItems?: number;
  loading?: boolean;
  onManageInvitation?: (action: string, invitation: Invitation) => void;
}
```

#### `InvitationCard.svelte`
```typescript
// Purpose: Individual invitation display
interface Props {
  invitation: Invitation;
  compact?: boolean;
  showActions?: boolean;
  onAction?: (action: string, invitation: Invitation) => void;
}
```

#### `InvitationActionsDropdown.svelte`
```typescript
// Purpose: Reusable invitation management menu
interface Props {
  invitation: Invitation;
  isOpen: boolean;
  onToggle: () => void;
  onAction: (action: string) => void;
  compact?: boolean;
}
```

#### `InvitationStatusBadge.svelte`
```typescript
// Purpose: Reusable invitation status indicator
interface Props {
  status: Invitation['status'];
  size?: 'sm' | 'md' | 'lg';
}
```

### 4. Shared UI Components

#### `MetricCard.svelte`
```typescript
// Purpose: Reusable KPI card component
interface Props {
  title: string;
  value: number | string;
  description?: string;
  icon?: any;
  color?: 'primary' | 'success' | 'warning' | 'danger';
  loading?: boolean;
  trend?: {
    value: number;
    direction: 'up' | 'down';
    period: string;
  };
}
```

#### `LoadingState.svelte`
```typescript
// Purpose: Consistent loading indicators
interface Props {
  type?: 'spinner' | 'skeleton' | 'pulse';
  message?: string;
}
```

#### `EmptyState.svelte`
```typescript
// Purpose: Consistent empty state displays
interface Props {
  icon?: any;
  title: string;
  description?: string;
  actionLabel?: string;
  actionHref?: string;
  onAction?: () => void;
}
```

### 5. Business Logic Components (Composables)

#### `useInvitationActions.ts`
```typescript
// Purpose: Reusable invitation management logic
export function useInvitationActions() {
  const shareInvitationCode = (code: string) => { /* */ };
  const revokeInvitation = (invitation: Invitation) => { /* */ };
  const resendInvitation = (invitation: Invitation) => { /* */ };
  const viewInvitationDetails = (invitation: Invitation) => { /* */ };
  
  return {
    shareInvitationCode,
    revokeInvitation,
    resendInvitation,
    viewInvitationDetails
  };
}
```

#### `useMetrics.ts`
```typescript
// Purpose: Reusable metrics loading and management
export function useMetrics() {
  const metricsStore = writable({ loading: false, data: null });
  
  const loadMetrics = async () => { /* */ };
  const refreshMetrics = () => { /* */ };
  
  return {
    metrics: metricsStore,
    loadMetrics,
    refreshMetrics
  };
}
```

## Refactoring Implementation Plan

### Phase 1: Extract Leaf Components (Week 1)
1. **Status Badges** - `EmployeeStatusBadge` + `InvitationStatusBadge`
2. **Action Dropdown** - `InvitationActionsDropdown`
3. **Metric Card** - `MetricCard`
4. **Utility Components** - `LoadingState`, `EmptyState`

### Phase 2: Extract Feature Components (Week 2)
1. **Individual Cards** - `EmployeeCard`, `InvitationCard`
2. **Business Logic** - `useInvitationActions`, `useMetrics`
3. **Update existing usage** - Test individual components

### Phase 3: Extract Container Components (Week 3)
1. **Directory Components** - `EmployeeDirectory`, `InvitationsSidebar`
2. **Dashboard Sections** - `DashboardHeader`, `DashboardMetrics`
3. **Main Layout** - `DashboardContent`

### Phase 4: Refactor Main Dashboard (Week 4)
1. **Update `+page.svelte`** - Use new components
2. **Extract remaining logic** - Move to composables
3. **Add prop validation** - TypeScript interfaces
4. **Update tests** - Component-level testing

## File Structure After Refactoring

```
src/lib/components/
├── ui/                          # Existing shadcn components
├── dashboard/
│   ├── DashboardHeader.svelte
│   ├── DashboardMetrics.svelte
│   ├── DashboardContent.svelte
│   └── MetricCard.svelte
├── employee/
│   ├── EmployeeDirectory.svelte
│   ├── EmployeeCard.svelte
│   └── EmployeeStatusBadge.svelte
├── invitation/
│   ├── InvitationsSidebar.svelte
│   ├── InvitationCard.svelte
│   ├── InvitationActionsDropdown.svelte
│   └── InvitationStatusBadge.svelte
├── shared/
│   ├── LoadingState.svelte
│   ├── EmptyState.svelte
│   └── FloatingStatusButton.svelte  # Already extracted
└── composables/
    ├── useInvitationActions.ts
    ├── useMetrics.ts
    └── useEmployeeManagement.ts

src/routes/
├── +page.svelte                 # Simplified to ~100 lines
├── employees/
│   ├── +page.svelte            # Uses EmployeeDirectory
│   └── new/+page.svelte        # Uses EmployeeCard components
└── invitations/
    ├── +page.svelte            # Uses InvitationCard components
    └── new/+page.svelte
```

## Benefits of Refactoring

### 1. **Maintainability**
- **Single Responsibility** - Each component has one clear purpose
- **Easier Debugging** - Issues isolated to specific components
- **Simpler Updates** - Changes affect fewer files

### 2. **Reusability**
- **Cross-Page Usage** - Components used in multiple routes
- **Consistent UX** - Same invitation cards everywhere
- **Reduced Duplication** - Shared logic in composables

### 3. **Testability**
- **Unit Testing** - Test individual components in isolation
- **Mock Props** - Easy to test different states
- **Component Stories** - Storybook documentation

### 4. **Performance**
- **Smaller Bundles** - Components loaded on demand
- **Better Caching** - Unchanged components don't re-render
- **Code Splitting** - Automatic with component separation

### 5. **Developer Experience**
- **IntelliSense** - Better TypeScript support
- **Hot Reload** - Faster development cycles
- **Component Library** - Reusable design system

## TypeScript Interface Definitions

```typescript
// src/lib/types/dashboard.ts
export interface DashboardMetrics {
  totalEmployees: number;
  onboardingCount: number;
  offboardingCount: number;
  pendingInvitations: number;
  loading?: boolean;
}

export interface MetricCardProps {
  title: string;
  value: number | string;
  description?: string;
  icon?: ComponentType;
  color?: 'primary' | 'success' | 'warning' | 'danger';
  loading?: boolean;
  trend?: MetricTrend;
}

export interface MetricTrend {
  value: number;
  direction: 'up' | 'down';
  period: string;
}

// src/lib/types/invitation.ts
export interface InvitationAction {
  type: 'view' | 'share' | 'resend' | 'revoke' | 'recreate';
  label: string;
  icon: ComponentType;
  handler: (invitation: Invitation) => void;
  visible: (invitation: Invitation) => boolean;
  destructive?: boolean;
}

export interface InvitationCardProps {
  invitation: Invitation;
  compact?: boolean;
  showActions?: boolean;
  onAction?: (action: string, invitation: Invitation) => void;
}
```

## Testing Strategy

### Component Testing
```typescript
// tests/components/MetricCard.test.ts
import { render } from '@testing-library/svelte';
import MetricCard from '$lib/components/dashboard/MetricCard.svelte';

test('displays metric value and title', () => {
  const { getByText } = render(MetricCard, {
    title: 'Total Employees',
    value: 42,
    description: 'All registered employees'
  });
  
  expect(getByText('Total Employees')).toBeInTheDocument();
  expect(getByText('42')).toBeInTheDocument();
});
```

### Integration Testing
```typescript
// tests/pages/Dashboard.test.ts
import { render } from '@testing-library/svelte';
import Dashboard from '$routes/+page.svelte';

test('dashboard loads with metrics and employee list', async () => {
  // Mock stores
  const { getByRole } = render(Dashboard);
  
  expect(getByRole('heading', { name: /employee directory/i })).toBeInTheDocument();
  expect(getByRole('heading', { name: /recent invitations/i })).toBeInTheDocument();
});
```

## Migration Checklist

- [ ] **Phase 1: Leaf Components**
  - [ ] Create `MetricCard.svelte`
  - [ ] Create `EmployeeStatusBadge.svelte`
  - [ ] Create `InvitationStatusBadge.svelte`
  - [ ] Create `LoadingState.svelte`
  - [ ] Create `EmptyState.svelte`

- [ ] **Phase 2: Feature Components**
  - [ ] Create `EmployeeCard.svelte`
  - [ ] Create `InvitationCard.svelte`
  - [ ] Create `InvitationActionsDropdown.svelte`
  - [ ] Create `useInvitationActions.ts`
  - [ ] Create `useMetrics.ts`

- [ ] **Phase 3: Container Components**
  - [ ] Create `DashboardHeader.svelte`
  - [ ] Create `DashboardMetrics.svelte`
  - [ ] Create `EmployeeDirectory.svelte`
  - [ ] Create `InvitationsSidebar.svelte`
  - [ ] Create `DashboardContent.svelte`

- [ ] **Phase 4: Integration**
  - [ ] Refactor `+page.svelte` to use components
  - [ ] Update other pages to use shared components
  - [ ] Add TypeScript interfaces
  - [ ] Write component tests
  - [ ] Update documentation

## Success Metrics

**Before Refactoring:**
- Main dashboard: 418 lines
- Components: 3 files
- Reusability: Low
- Test coverage: 0%

**After Refactoring (Target):**
- Main dashboard: <100 lines
- Components: 15+ modular files
- Reusability: High (4+ pages use shared components)
- Test coverage: >80%
- Bundle size: Reduced by ~15% due to code splitting
- Development speed: 30% faster feature development

This refactoring will transform the codebase from a monolithic structure into a maintainable, testable, and reusable component library while preserving all existing functionality.