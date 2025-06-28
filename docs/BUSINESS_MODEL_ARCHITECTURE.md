# Business Model Architecture - 175EUR Consumable Credit System
*Updated: 2025-06-27*

## 🎯 Executive Summary

The Flows Admin platform operates on a **consumable credit model** where clients purchase credits at **175 EUR each**. One credit is consumed when an onboarding or offboarding workflow is **initiated** (not completed), providing predictable revenue while incentivizing process efficiency.

## 💰 Credit System Architecture

### **Core Pricing Model**
```typescript
interface CreditPricing {
  basePrice: 175; // EUR per credit
  currency: 'EUR';
  consumption: {
    trigger: 'workflow_initiation'; // Key: charged when started, not completed
    processes: ['onboarding', 'offboarding'];
    refundPolicy: 'no_refunds_after_initiation';
  };
}
```

### **Business Logic Rules**
1. **Initiation Trigger**: Credit deducted when workflow moves from 'draft' to 'active'
2. **No Completion Dependency**: Credit consumed regardless of process success/failure
3. **Single Deduction**: One credit per employee per process type
4. **No Refunds**: Credits non-refundable once workflow initiated

## 📊 Pricing Tiers & Packages

### **Starter Tier**
```typescript
interface StarterTier {
  monthlyCredits: 25;
  monthlyPrice: 3938; // EUR (25 * 175 with 10% discount)
  annualPrice: 39375; // EUR (12 months with 15% annual discount)
  features: [
    'basic_onboarding_workflows',
    'standard_offboarding_workflows', 
    'document_templates',
    'email_notifications',
    'basic_reporting'
  ];
  limits: {
    maxAdmins: 3;
    maxLocations: 1;
    retentionPeriod: '12_months';
  };
}
```

### **Professional Tier**
```typescript
interface ProfessionalTier {
  monthlyCredits: 100;
  monthlyPrice: 14000; // EUR (100 * 175 with 20% discount)
  annualPrice: 126000; // EUR (15% annual discount)
  features: [
    'advanced_workflow_customization',
    'multi_location_support',
    'performance_tracking',
    'integration_apis',
    'advanced_analytics',
    'custom_document_templates',
    'slack_teams_integration'
  ];
  limits: {
    maxAdmins: 15;
    maxLocations: 'unlimited';
    retentionPeriod: '24_months';
  };
}
```

### **Enterprise Tier**
```typescript
interface EnterpriseTier {
  monthlyCredits: 'unlimited';
  monthlyPrice: 'custom_negotiated'; // Typically 40k-80k EUR/month
  features: [
    'unlimited_workflows',
    'white_label_branding',
    'dedicated_support',
    'custom_integrations',
    'advanced_security',
    'compliance_reporting',
    'multi_tenant_management',
    'sla_guarantees'
  ];
  limits: {
    maxAdmins: 'unlimited';
    maxLocations: 'unlimited';
    retentionPeriod: 'configurable';
  };
}
```

## 💳 Credit Purchase & Management

### **Purchase Options**
```typescript
interface CreditPurchasing {
  minimumPurchase: 10; // credits
  maximumPurchase: 10000; // credits (anti-fraud)
  
  bulkDiscounts: {
    '50_99_credits': 0.05,    // 5% discount
    '100_499_credits': 0.10,  // 10% discount  
    '500_999_credits': 0.15,  // 15% discount
    '1000_plus_credits': 0.20 // 20% discount
  };
  
  paymentMethods: [
    'credit_card',
    'bank_transfer', 
    'invoice_net30',
    'purchase_order'
  ];
}
```

### **Credit Balance Management**
```typescript
interface CreditBalance {
  current: number;
  reserved: number; // Credits allocated to in-progress workflows
  available: number; // current - reserved
  
  alerts: {
    lowBalance: 10; // Alert when available < 10 credits
    criticalBalance: 5; // Block new workflows when available < 5
    autoReplenish: boolean; // Automatic credit purchase
  };
  
  rollover: {
    monthlyUnused: 'rolls_over'; // Unused credits don't expire
    maximumAccumulation: 1000; // Cap on total accumulated credits
  };
}
```

## 📈 Revenue Model Analysis

### **Revenue Predictability**
```typescript
interface RevenueMetrics {
  // Average customer usage patterns
  typical_usage: {
    small_company_50_employees: {
      monthly_onboarding: 4, // 4 * 175 = 700 EUR
      monthly_offboarding: 3, // 3 * 175 = 525 EUR
      monthly_revenue: 1225 // EUR
    };
    
    medium_company_500_employees: {
      monthly_onboarding: 15, // 15 * 175 = 2625 EUR
      monthly_offboarding: 12, // 12 * 175 = 2100 EUR  
      monthly_revenue: 4725 // EUR
    };
    
    large_company_2000_employees: {
      monthly_onboarding: 45, // 45 * 175 = 7875 EUR
      monthly_offboarding: 35, // 35 * 175 = 6125 EUR
      monthly_revenue: 14000 // EUR
    };
  };
}
```

### **Market Positioning**
```typescript
interface MarketPosition {
  competition: {
    bambooHR: 'Per employee/month pricing (~6-8 EUR)';
    workday: 'Per employee/month pricing (~15-25 EUR)';
    flows: 'Per process pricing (175 EUR)';
  };
  
  advantages: [
    'predictable_per_process_cost',
    'no_ongoing_per_employee_fees',
    'scales_with_actual_usage',
    'transparent_pricing_model'
  ];
  
  value_proposition: {
    cost_efficiency: 'Only pay for active HR processes';
    budget_predictability: 'Fixed cost per employee lifecycle event';
    scale_flexibility: 'Cost scales with growth, not headcount';
  };
}
```

## 🔄 Workflow Credit Integration

### **Database Schema for Credit Tracking**
```sql
CREATE TABLE api.credit_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES api.clients(id),
  transaction_type VARCHAR(20) NOT NULL CHECK (transaction_type IN ('purchase', 'usage', 'refund', 'adjustment')),
  
  -- Credit details
  credit_amount INTEGER NOT NULL,
  price_per_credit DECIMAL(10,2) NOT NULL DEFAULT 175.00,
  total_amount DECIMAL(12,2) NOT NULL,
  currency VARCHAR(3) NOT NULL DEFAULT 'EUR',
  
  -- Usage tracking (for 'usage' transactions)
  process_type VARCHAR(20) CHECK (process_type IN ('onboarding', 'offboarding')),
  employee_id UUID REFERENCES api.employees(id),
  workflow_id UUID, -- Reference to specific workflow instance
  
  -- Purchase tracking (for 'purchase' transactions)  
  payment_method VARCHAR(20),
  payment_reference VARCHAR(255),
  invoice_number VARCHAR(100),
  
  -- Metadata
  description TEXT,
  created_by UUID, -- Admin who initiated transaction
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT valid_usage_transaction CHECK (
    (transaction_type = 'usage' AND process_type IS NOT NULL AND employee_id IS NOT NULL) OR
    (transaction_type != 'usage')
  ),
  CONSTRAINT valid_purchase_transaction CHECK (
    (transaction_type = 'purchase' AND payment_method IS NOT NULL) OR
    (transaction_type != 'purchase')
  )
);

CREATE TABLE api.client_credit_balances (
  client_id UUID PRIMARY KEY REFERENCES api.clients(id),
  total_purchased INTEGER NOT NULL DEFAULT 0,
  total_used INTEGER NOT NULL DEFAULT 0,
  current_balance INTEGER GENERATED ALWAYS AS (total_purchased - total_used) STORED,
  reserved_credits INTEGER NOT NULL DEFAULT 0, -- For in-progress workflows
  available_credits INTEGER GENERATED ALWAYS AS (total_purchased - total_used - reserved_credits) STORED,
  
  -- Alert thresholds
  low_balance_threshold INTEGER DEFAULT 10,
  critical_balance_threshold INTEGER DEFAULT 5,
  auto_replenish_enabled BOOLEAN DEFAULT FALSE,
  auto_replenish_amount INTEGER DEFAULT 50,
  
  -- Timestamps
  last_purchase_at TIMESTAMP WITH TIME ZONE,
  last_usage_at TIMESTAMP WITH TIME ZONE,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### **Workflow Integration Points**
```typescript
interface WorkflowCreditIntegration {
  // When workflow is initiated
  onWorkflowStart: {
    creditCheck: 'Verify available credits >= 1';
    creditReservation: 'Reserve 1 credit for this workflow';
    creditDeduction: 'Deduct 1 credit from available balance';
    auditLog: 'Record credit usage transaction';
  };
  
  // When workflow is completed/cancelled
  onWorkflowEnd: {
    creditRelease: 'Release any reserved credits (N/A - already deducted)';
    statusUpdate: 'Update workflow with final credit transaction ID';
    reporting: 'Include in usage analytics';
  };
  
  // Pre-workflow validation
  workflowValidation: {
    creditAvailability: 'Block workflow if insufficient credits';
    balanceAlert: 'Notify admin of low balance';
    emergencyOverride: 'Allow critical workflows to proceed (with approval)';
  };
}
```

## 📊 Financial Reporting & Analytics

### **Admin Dashboard Metrics**
```typescript
interface CreditDashboard {
  currentMonth: {
    creditsUsed: number;
    costPerCredit: number;
    totalSpent: number;
    workflowsInitiated: number;
    averageCostPerEmployee: number;
  };
  
  trends: {
    monthlyUsage: TrendData[];
    departmentBreakdown: DepartmentUsage[];
    processTypeDistribution: ProcessTypeMetrics;
    seasonalPatterns: SeasonalAnalysis;
  };
  
  predictions: {
    projectedMonthlyUsage: number;
    budgetForecast: number;
    recommendedCreditPurchase: number;
    costOptimizationSuggestions: string[];
  };
}
```

### **ROI Analysis Tools**
```typescript
interface ROIAnalysis {
  traditionalCosts: {
    hrAdminTime: number; // Hours saved per process
    paperworkReduction: number; // Document processing savings
    errorReduction: number; // Cost of manual process errors
    complianceImprovement: number; // Risk reduction value
  };
  
  flowsCosts: {
    creditCosts: number; // 175 EUR per process
    implementationCosts: number; // One-time setup
    trainingCosts: number; // Staff training investment
  };
  
  roi: {
    monthlySavings: number;
    paybackPeriod: number; // Months
    annualROI: number; // Percentage
    efficiencyGains: string[];
  };
}
```

## 🎯 Competitive Advantage Analysis

### **Pricing Model Comparison**
```typescript
interface CompetitivePricing {
  traditional_per_employee: {
    typical_cost: '6-25 EUR/employee/month';
    problems: [
      'Charges for inactive employees',
      'Cost scales with headcount, not activity',
      'Hidden fees for additional features',
      'Annual commitment requirements'
    ];
  };
  
  flows_per_process: {
    cost: '175 EUR per workflow initiated';
    advantages: [
      'Only pay for active HR processes',
      'Transparent, predictable pricing',
      'Scales with business activity',
      'No long-term commitments'
    ];
  };
  
  total_cost_examples: {
    small_company_50_employees: {
      traditional: '300-1250 EUR/month (ongoing)',
      flows: '1225 EUR/month (average usage)',
      advantage: 'Similar cost, better features'
    };
    
    large_company_2000_employees: {
      traditional: '12000-50000 EUR/month (ongoing)',
      flows: '14000 EUR/month (average usage)',
      advantage: 'Significant savings with usage-based model'
    };
  };
}
```

## 🔮 Future Pricing Evolution

### **Advanced Pricing Models**
```typescript
interface FuturePricingModels {
  tiered_process_pricing: {
    simple_onboarding: 125; // EUR
    standard_onboarding: 175; // EUR  
    executive_onboarding: 350; // EUR
    bulk_offboarding: 100; // EUR (restructuring scenarios)
  };
  
  subscription_hybrid: {
    base_subscription: 'Monthly platform fee (500-2000 EUR)';
    included_credits: 'Credits included in subscription';
    overage_pricing: 'Reduced rate for additional credits';
  };
  
  usage_based_discounts: {
    high_volume_clients: 'Progressive discounts for heavy usage';
    loyalty_discounts: 'Reduced rates for long-term clients';
    seasonal_pricing: 'Lower rates during slow hiring periods';
  };
}
```

### **Value-Added Services**
```typescript
interface ValueAddedServices {
  premium_support: {
    dedicated_csm: 2000; // EUR/month
    24_7_support: 1000; // EUR/month
    custom_training: 5000; // EUR one-time
  };
  
  professional_services: {
    implementation: 10000; // EUR one-time
    custom_workflows: 2500; // EUR per workflow
    integration_development: 15000; // EUR per integration
  };
  
  compliance_services: {
    gdpr_audit: 5000; // EUR annually
    sox_compliance: 7500; // EUR annually
    industry_certification: 3000; // EUR per certification
  };
}
```

## 📋 Implementation Roadmap

### **Phase 1: Core Credit System (Week 1)**
- [ ] Implement credit transaction database schema
- [ ] Build credit balance management functionality
- [ ] Create workflow credit deduction logic
- [ ] Add credit purchase interface

### **Phase 2: Admin Dashboard (Week 2)**
- [ ] Build credit usage analytics dashboard
- [ ] Implement balance alerts and notifications
- [ ] Create usage reporting and forecasting
- [ ] Add bulk credit purchase options

### **Phase 3: Advanced Features (Week 3)**
- [ ] Implement tiered pricing discounts
- [ ] Add automatic credit replenishment
- [ ] Build ROI analysis tools
- [ ] Create budget management features

### **Phase 4: Enterprise Features (Week 4)**
- [ ] Add multi-tier approval workflows
- [ ] Implement enterprise billing integration
- [ ] Build custom pricing model support
- [ ] Create comprehensive audit trails

This business model architecture ensures Flows provides predictable value-based pricing while maintaining healthy unit economics and clear competitive differentiation.