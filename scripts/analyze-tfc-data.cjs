#!/usr/bin/env node

const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY, {
  db: { schema: 'api' },
});

async function analyzeAvailableTFCData() {
  console.log('📊 Analyzing available TFC data...\n');

  const { data: client } = await supabase
    .from('clients')
    .select('*')
    .eq('client_code', 'hygge-hvidlog')
    .single();

  if (!client) {
    console.log('No client found');
    return;
  }

  console.log('✅ Available TFC Tables & Data:\n');

  // 1. TFC Client Balances
  const { data: balance } = await supabase
    .from('tfc_client_balances')
    .select('*')
    .eq('client_id', client.id)
    .single();

  console.log('🏦 TFC Client Balances:');
  if (balance) {
    console.log(`  ✓ Current Balance: ${balance.current_balance} TFC`);
    console.log(`  ✓ Total Purchased: ${balance.total_purchased} TFC`);
    console.log(`  ✓ Total Used: ${balance.total_used} TFC`);
    console.log(`  ✓ Total Spent: €${balance.total_spent}`);
    console.log(`  ✓ Average Price: €${balance.average_credit_price}/TFC`);
    console.log(`  ✓ Auto-replenish: ${balance.auto_replenish_enabled ? 'Enabled' : 'Disabled'}`);
    console.log(
      `  ✓ Thresholds: Low ${balance.low_balance_threshold}, Critical ${balance.critical_balance_threshold}`
    );
  }

  // 2. TFC Payments
  const { data: payments } = await supabase
    .from('tfc_payments')
    .select('*')
    .eq('client_id', client.id)
    .order('completed_at', { ascending: false })
    .limit(3);

  console.log(`\n💳 TFC Payments (${payments?.length || 0} recent):`);
  if (payments) {
    payments.forEach((p) => {
      console.log(
        `  ✓ ${p.payment_amount} ${p.currency} - ${p.payment_method} (${p.payment_status})`
      );
    });
  }

  // 3. TFC Credit Transactions
  const { data: transactions } = await supabase
    .from('tfc_credit_transactions')
    .select('*')
    .eq('client_id', client.id)
    .order('created_at', { ascending: false })
    .limit(5);

  console.log(`\n📈 TFC Transactions (${transactions?.length || 0} recent):`);
  if (transactions) {
    transactions.forEach((t) => {
      console.log(`  ✓ ${t.transaction_type}: ${t.credit_amount} TFC @ €${t.price_per_credit}`);
    });
  }

  // 4. TFC Workflow Usage
  const { data: usage } = await supabase
    .from('tfc_workflow_usage')
    .select('*')
    .eq('client_id', client.id)
    .order('consumed_at', { ascending: false })
    .limit(3);

  console.log(`\n🔄 TFC Workflow Usage (${usage?.length || 0} recent):`);
  if (usage) {
    usage.forEach((u) => {
      console.log(`  ✓ ${u.workflow_type}: ${u.credits_consumed} TFC - ${u.department_category}`);
    });
  }

  // 5. TFC Invoices
  const { data: invoices } = await supabase
    .from('tfc_invoices')
    .select('*')
    .eq('client_id', client.id)
    .order('invoice_date', { ascending: false })
    .limit(3);

  console.log(`\n🧾 TFC Invoices (${invoices?.length || 0} recent):`);
  if (invoices) {
    invoices.forEach((inv) => {
      console.log(`  ✓ ${inv.invoice_number}: ${inv.currency} ${inv.total_amount} (${inv.status})`);
    });
  }

  console.log('\n📋 TFC Panel Components Available:');
  console.log('  ✓ Real-time balance and usage statistics');
  console.log('  ✓ Purchase history with bulk discount tracking');
  console.log('  ✓ Usage analytics by workflow type and department');
  console.log('  ✓ Invoice history with payment status');
  console.log('  ✓ Auto-replenish configuration');
  console.log('  ✓ Credit pricing tiers and discount calculations');
  console.log('  ✓ Utilization trends and forecasting data');
}

analyzeAvailableTFCData();
