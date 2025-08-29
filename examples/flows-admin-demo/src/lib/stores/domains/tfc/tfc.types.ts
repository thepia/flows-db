export interface TFCBalance {
  client_id: string;
  current_balance: number;
  total_purchased: number;
  total_used: number;
  auto_replenish_enabled: boolean;
  auto_replenish_threshold: number;
  auto_replenish_amount: number;
  low_balance_threshold: number;
  critical_balance_threshold: number;
  last_updated: string;
}

export interface TFCTransaction {
  transaction_id: string;
  client_id: string;
  transaction_type: 'purchase' | 'usage';
  credit_amount: number;
  total_amount: number;
  currency: 'EUR' | 'CHF' | 'USD';
  bulk_discount_tier?: 'individual' | 'bulk_tier_1' | 'bulk_tier_2';
  discount_percentage?: number;
  description?: string;
  created_at: string;
}

export interface TFCUsageAnalytics {
  workflow_type: 'onboarding' | 'offboarding';
  department_category: string;
  count: number;
  credits_consumed: number;
  hours_saved: number;
}

export interface TFCState {
  balance: TFCBalance | null;
  transactions: TFCTransaction[];
  usageAnalytics: TFCUsageAnalytics[];
  loading: boolean;
  error: string | null;
}

export interface TFCPricingTier {
  tier: 'individual' | 'bulk_tier_1' | 'bulk_tier_2';
  minAmount: number;
  maxAmount?: number;
  discountPercentage: number;
  pricePerCredit: number;
}

export interface TimeSavingsCalculation {
  totalHoursSaved: number;
  workingDaysSaved: number;
  hoursByDepartment: Record<string, number>;
  hoursByWorkflowType: Record<string, number>;
}
