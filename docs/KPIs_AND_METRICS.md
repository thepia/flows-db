# KPIs and Metrics for Onboarding and Offboarding

## Overview

The Flows system tracks meaningful business metrics for employee lifecycle management through two separate applications: **Onboarding** and **Offboarding**. These applications operate independently, and clients may have access to one or both depending on their subscription.

## Application Separation

### Key Principle: Independent Applications
- **Onboarding App**: Manages new employee integration
- **Offboarding App**: Manages employee departure processes
- **Client Access**: Clients may subscribe to one or both applications
- **Data Isolation**: Each application maintains its own task sets, workflows, and metrics

## KPI Definitions

### Onboarding KPIs

#### **Active Onboarding Count**
**Definition**: Number of employees-to-be currently in active onboarding process

**Criteria**:
- ✅ Have received their onboarding invitation
- ✅ Been properly set up in the system (employee record created)
- ✅ Have onboarding tasks assigned to them
- ✅ Have at least one onboarding task still open/incomplete
- ✅ Have not completed all onboarding tasks

**Business Value**: Shows current workload and employees needing attention

#### **Onboarding Completion Rate**
**Definition**: Percentage of employees who completed onboarding within target timeframe

**Calculation**: `(Completed Onboarding / Total Started) * 100`

#### **Average Onboarding Duration**
**Definition**: Mean time from invitation acceptance to onboarding completion

**Measurement**: Days between first task assignment and final task completion

### Offboarding KPIs

#### **Active Offboarding Count**  
**Definition**: Number of employees currently in active offboarding process

**Criteria**:
- ✅ Have received their offboarding invitation
- ✅ Been properly set up in the system 
- ✅ Have offboarding tasks assigned to them
- ✅ Have at least one offboarding task still open/incomplete
- ✅ Their association end date has NOT been reached yet
- ✅ Have not completed all offboarding tasks

**Business Value**: Shows departing employees requiring action before their end date

#### **Offboarding Completion Rate**
**Definition**: Percentage of employees who completed offboarding before their end date

**Calculation**: `(Completed Before End Date / Total Offboarding) * 100`

#### **Days Until Association End**
**Definition**: Time remaining for active offboarding employees

**Measurement**: Days between current date and association end date

## Data Model Requirements

### Task-Application Association

Tasks must be associated with specific applications to enable proper metrics:

```sql
-- Tasks table enhancement
ALTER TABLE api.tasks 
ADD COLUMN app_id UUID REFERENCES api.client_applications(id);

-- Index for performance
CREATE INDEX idx_tasks_app_id ON api.tasks(app_id);
```

### Employee-Application Enrollment

Track which application processes an employee is enrolled in:

```sql
-- Employee enrollments by application
CREATE TABLE api.employee_app_enrollments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES api.employees(id),
  app_id UUID NOT NULL REFERENCES api.client_applications(id),
  
  -- Process tracking
  invitation_sent_at TIMESTAMP WITH TIME ZONE,
  invitation_accepted_at TIMESTAMP WITH TIME ZONE,
  process_started_at TIMESTAMP WITH TIME ZONE,
  process_completed_at TIMESTAMP WITH TIME ZONE,
  
  -- Status
  status VARCHAR(50) DEFAULT 'invited' CHECK (status IN (
    'invited', 'accepted', 'in_progress', 'completed', 'cancelled'
  )),
  
  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(employee_id, app_id)
);
```

## Dashboard Metrics Implementation

### Onboarding Count Query
```sql
SELECT COUNT(DISTINCT e.id) as active_onboarding
FROM api.employees e
JOIN api.employee_app_enrollments eae ON e.id = eae.employee_id
JOIN api.client_applications ca ON eae.app_id = ca.id
JOIN api.tasks t ON e.id = t.employee_id AND t.app_id = ca.id
WHERE ca.app_code = 'onboarding'
  AND eae.status = 'in_progress'
  AND t.status IN ('not_started', 'in_progress')
GROUP BY e.id
HAVING COUNT(t.id) > 0;
```

### Offboarding Count Query
```sql
SELECT COUNT(DISTINCT e.id) as active_offboarding
FROM api.employees e
JOIN api.employee_app_enrollments eae ON e.id = eae.employee_id
JOIN api.client_applications ca ON eae.app_id = ca.id
JOIN api.tasks t ON e.id = t.employee_id AND t.app_id = ca.id
JOIN api.invitations i ON eae.employee_id = i.client_data->>'employee_id'::text
WHERE ca.app_code = 'offboarding'
  AND eae.status = 'in_progress'
  AND t.status IN ('not_started', 'in_progress')
  AND (i.invitation->>'association'->>'endDate')::date > CURRENT_DATE
GROUP BY e.id
HAVING COUNT(t.id) > 0;
```

## Business Rules

### Onboarding Process Flow
1. **Invitation Sent** → Employee receives onboarding invitation
2. **Invitation Accepted** → Employee clicks invitation link
3. **Setup Complete** → Employee record created, tasks assigned
4. **In Progress** → Employee working on onboarding tasks
5. **Completed** → All onboarding tasks completed

### Offboarding Process Flow
1. **Invitation Sent** → Employee receives offboarding invitation
2. **Invitation Accepted** → Employee clicks invitation link  
3. **Setup Complete** → Offboarding tasks assigned
4. **In Progress** → Employee working on offboarding tasks
5. **Association End** → Association end date reached
6. **Completed** → All offboarding tasks completed

## Alerts and Notifications

### Onboarding Alerts
- **Overdue Tasks**: Onboarding tasks past due date
- **Stalled Process**: No task activity for X days
- **Approaching Start Date**: Employee start date in next 7 days

### Offboarding Alerts  
- **Approaching End Date**: Association end date in next 14 days
- **Overdue Tasks**: Critical offboarding tasks not completed
- **Missing Setup**: Offboarding invitation sent but no tasks assigned

## Implementation Notes

### Multi-Tenant Considerations
- All metrics are client-specific
- Each client may have different onboarding/offboarding workflows
- Task templates vary by client configuration

### Performance Optimization
- Metrics should be cached/materialized for large clients
- Use appropriate database indexes for metric queries
- Consider pre-aggregated metric tables for historical reporting

### Data Privacy
- Employee PII stored in encrypted JWT tokens
- Metrics only reference employee IDs and task counts
- Association dates stored in invitation JWT for security

## Future Enhancements

### Advanced Metrics
- **Time to Productivity**: Days from start to first meaningful contribution
- **Retention Rate**: Percentage of onboarded employees retained after 6/12 months
- **Exit Interview Completion**: Percentage completing exit process fully
- **Knowledge Transfer Effectiveness**: Measured completion of handover tasks

### Predictive Analytics
- **Risk Scoring**: Employees likely to need additional onboarding support
- **Completion Forecasting**: Predicted onboarding/offboarding completion dates
- **Resource Planning**: Anticipated HR workload based on pipeline