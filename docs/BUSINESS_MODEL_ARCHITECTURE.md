# Business Model Architecture - Thepia Flow Credits (TFC) System
*Updated: 2025-06-29*

## 🎯 Executive Summary

The Flows Admin platform operates on a **Thepia Flow Credits (TFC)** model where clients purchase credits at **150 EUR/CHF each**. One credit is consumed when an onboarding or offboarding workflow is **initiated** (not completed), providing predictable revenue while incentivizing process efficiency. Bulk purchase discounts encourage annual commitments and larger volume purchases.

## 💰 Credit System Architecture

### **Thepia Flow Credits (TFC) Pricing Model**
```typescript
interface TFCPricing {
  creditName: 'Thepia Flow Credits';
  abbreviation: 'TFC';
  basePrice: 150; // EUR/CHF per credit
  supportedCurrencies: ['EUR', 'CHF'];
  consumption: {
    trigger: 'workflow_initiation'; // Key: charged when started, not completed
    processes: ['onboarding', 'offboarding'];
    refundPolicy: 'no_refunds_after_initiation';
  };
  
  bulkDiscounts: {
    individual: { quantity: [1, 499], discount: 0 }, // 150 EUR/CHF each
    bulk_tier_1: { quantity: [500, 1000], discount: 0.25 }, // 25% off = 112.50 EUR/CHF each
    bulk_tier_2: { quantity: [2500, Infinity], discount: 0.30 } // 30% off = 105 EUR/CHF each
  };
}
```

### **Business Logic Rules**
1. **Per-Process Payment**: One TFC is charged when each onboarding/offboarding process is **initiated** (not monthly/annually)
2. **Initiation Trigger**: Credit deducted when workflow moves from 'draft' to 'active'
3. **No Completion Dependency**: Credit consumed regardless of process success/failure
4. **Single Deduction**: One credit per employee per process type
5. **No Refunds**: Credits non-refundable once workflow initiated
6. **No Subscriptions**: No recurring monthly or annual fees - only pay when processes are started

## 📊 Pricing Tiers & Packages

### **Starter Package**
```typescript
interface StarterPackage {
  // Pay-per-process model - charged when process is initiated
  pricePerProcess: 150; // EUR/CHF per onboarding/offboarding initiated
  
  // Typical usage estimates (for planning purposes only)
  estimatedMonthlyProcesses: 25;
  estimatedMonthlyCost: 3750; // EUR/CHF (25 processes * 150)
  
  // Bulk purchase option
  bulkPurchaseOption: {
    minimumCredits: 100,
    discount: 0, // No bulk discount for starter tier
    pricePerCredit: 150 // EUR/CHF
  };
  
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

### **Professional Package**
```typescript
interface ProfessionalPackage {
  // Pay-per-process model - charged when process is initiated
  pricePerProcess: 112.50; // EUR/CHF per onboarding/offboarding (with bulk discount)
  
  // Bulk purchase requirement for discount
  bulkPurchaseRequirement: {
    minimumCredits: 500, // Qualifies for bulk_tier_1 discount (25% off)
    maximumCredits: 1000,
    discount: 0.25, // 25% bulk discount
    basePrice: 150, // EUR/CHF
    discountedPrice: 112.50 // EUR/CHF per process initiated
  };
  
  // Typical usage estimates (for planning purposes only)
  estimatedMonthlyProcesses: 100;
  estimatedMonthlyCost: 11250; // EUR/CHF (100 processes * 112.50)
  
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

### **Enterprise Package**
```typescript
interface EnterprisePackage {
  // Pay-per-process model - charged when process is initiated
  pricePerProcess: 105; // EUR/CHF per onboarding/offboarding (with bulk discount)
  
  // Bulk purchase requirement for maximum discount
  bulkPurchaseRequirement: {
    minimumCredits: 2500, // Qualifies for bulk_tier_2 discount (30% off)
    discount: 0.30, // 30% bulk discount
    basePrice: 150, // EUR/CHF
    discountedPrice: 105 // EUR/CHF per process initiated
  };
  
  // Custom enterprise pricing available for large volume commitments
  customPricing: {
    available: true,
    minimumCommitment: 10000, // processes annually
    negotiatedRates: 'Available for 10,000+ processes/year'
  };
  
  // Typical usage estimates (for planning purposes only)
  estimatedMonthlyProcesses: 'varies_widely';
  estimatedMonthlyCost: 'custom_based_on_usage';
  
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

### **Thepia Flow Credits Purchase Options**
```typescript
interface TFCPurchasing {
  creditName: 'Thepia Flow Credits (TFC)';
  basePriceEUR: 150;
  basePriceCHF: 150;
  minimumPurchase: 10; // credits
  maximumPurchase: 10000; // credits (anti-fraud)
  
  bulkDiscounts: {
    'individual': {
      range: [1, 499],
      discount: 0,
      priceEUR: 150,
      priceCHF: 150,
      description: 'Standard individual pricing'
    },
    'bulk_tier_1': {
      range: [500, 1000], 
      discount: 0.25, // 25% discount
      priceEUR: 112.50,
      priceCHF: 112.50,
      description: 'Bulk Tier 1: 500-1000 credits'
    },
    'bulk_tier_2': {
      range: [2500, Infinity],
      discount: 0.30, // 30% discount  
      priceEUR: 105,
      priceCHF: 105,
      description: 'Bulk Tier 2: 2500+ credits'
    }
  };
  
  paymentMethods: [
    'credit_card',
    'bank_transfer', 
    'invoice_net30',
    'purchase_order'
  ];
  
  annualCommitmentBonus: {
    additionalDiscount: 0.15, // 15% off annual purchases
    description: 'Additional discount for 12-month commitments'
  };
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

### **TFC Revenue Predictability**
```typescript
interface TFCRevenueMetrics {
  // Usage-based revenue patterns (pay-per-process initiated)
  typical_usage: {
    small_company_50_employees: {
      processes_initiated_monthly: 7, // 4 onboarding + 3 offboarding
      cost_per_process: 150, // EUR/CHF (individual pricing)
      monthly_spend_estimate: 1050, // EUR/CHF (7 * 150)
      annual_spend_estimate: 12600, // EUR/CHF
      payment_model: 'pay_per_process_initiated',
      tfc_tier: 'individual'
    };
    
    medium_company_500_employees: {
      processes_initiated_monthly: 27, // 15 onboarding + 12 offboarding
      cost_per_process: 112.50, // EUR/CHF (25% bulk discount applied)
      monthly_spend_estimate: 3037.50, // EUR/CHF (27 * 112.50)
      annual_spend_estimate: 36450, // EUR/CHF
      payment_model: 'pay_per_process_initiated',
      tfc_tier: 'bulk_tier_1'
    };
    
    large_company_2000_employees: {
      processes_initiated_monthly: 80, // 45 onboarding + 35 offboarding
      cost_per_process: 105, // EUR/CHF (30% bulk discount applied)
      monthly_spend_estimate: 8400, // EUR/CHF (80 * 105)
      annual_spend_estimate: 100800, // EUR/CHF
      payment_model: 'pay_per_process_initiated',
      tfc_tier: 'bulk_tier_2'
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
    flows: 'Per process TFC pricing (150 EUR/CHF, bulk discounts available)';
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
  
  -- TFC Credit details
  credit_amount INTEGER NOT NULL,
  price_per_credit DECIMAL(10,2) NOT NULL DEFAULT 150.00, -- Base TFC price (before bulk discounts)
  total_amount DECIMAL(12,2) NOT NULL,
  currency VARCHAR(3) NOT NULL DEFAULT 'EUR' CHECK (currency IN ('EUR', 'CHF')),
  
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