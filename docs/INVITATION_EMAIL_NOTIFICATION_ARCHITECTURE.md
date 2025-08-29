# Invitation Email Notification Architecture

## Overview

This document outlines the comprehensive email notification system for invitation management, including demo requests, automatic cadence, manual resending, and failure handling. The system uses N8N for workflow automation with persistence in the `api.invitations` table.

## Architecture Components

### 1. Database Layer (`api.invitations` table)

**Email Tracking Fields:**
```sql
-- Email status tracking
email_sent BOOLEAN DEFAULT FALSE
email_sent_at TIMESTAMP WITH TIME ZONE
email_id VARCHAR(100)  -- Email service tracking ID
follow_up_sent BOOLEAN DEFAULT FALSE
follow_up_sent_at TIMESTAMP WITH TIME ZONE
email_attempts INTEGER DEFAULT 0
last_email_error TEXT
```

**Key Database Functions:**
- `mark_invitation_email_sent(invitation_id, email_id)` - Record successful email delivery
- `mark_invitation_email_failed(invitation_id, error_message)` - Record email failure
- `mark_invitation_followup_sent(invitation_id, email_id)` - Record follow-up email
- `get_invitations_needing_email()` - Get pending invitations requiring email
- `get_invitations_needing_followup()` - Get invitations requiring follow-up

### 2. N8N Workflow Layer

**Primary Workflows:**
1. **Invitation Email Sender** - Sends initial invitation emails
2. **Email Failure Handler** - Handles retry logic and error logging
3. **Follow-up Cadence** - Automated reminder emails
4. **Manual Resend Trigger** - Admin-initiated resend functionality

## Complete Email Workflow

### 1. Initial Invitation Email Flow

```
Demo Request Approval → N8N Webhook → Email Generation → Email Delivery → Status Update
```

**N8N Workflow: "Send Invitation Email"**

1. **Trigger**: Database trigger or webhook when invitation status changes to 'pending'
2. **Get Invitation Data**: Query invitation details including JWT token
3. **Decrypt JWT**: Extract personal information (name, email, company)
4. **Generate Email**: Create personalized invitation email with:
   - Invitation link with JWT token
   - Demo environment details
   - Access duration and expiration
   - Branded email template
5. **Send Email**: Use email service (SendGrid, AWS SES, etc.)
6. **Update Database**: Call `mark_invitation_email_sent()` or `mark_invitation_email_failed()`

### 2. Email Delivery Monitoring

**Success Path:**
```sql
-- Mark email as sent successfully
SELECT api.mark_invitation_email_sent(
  '123e4567-e89b-12d3-a456-426614174000',
  'sendgrid_message_id_abc123'
);
```

**Failure Path:**
```sql
-- Log email delivery failure
SELECT api.mark_invitation_email_failed(
  '123e4567-e89b-12d3-a456-426614174000',
  'SMTP delivery failed: recipient mailbox full'
);
```

### 3. Automatic Follow-up Cadence

**N8N Workflow: "Invitation Follow-up Cadence"**

**Schedule**: Runs every 6 hours

**Logic:**
1. **Query Pending Follow-ups**: Call `get_invitations_needing_followup()`
2. **Filter by Days**: Different follow-up messages based on time elapsed
3. **Send Follow-up Email**: Personalized reminder with updated call-to-action
4. **Update Database**: Mark follow-up as sent

**Follow-up Schedule:**
- **Day 3**: Gentle reminder with additional value proposition
- **Day 7**: Urgency-based reminder with limited-time offer
- **Day 12**: Final reminder before expiration
- **Day 14**: Invitation expires (status changes to 'expired')

### 4. Manual Resend Functionality

**Admin Interface Integration:**

```typescript
// In flows-admin-demo
class InvitationEmailService {
  async resendInvitation(invitationId: string, reason: string): Promise<void> {
    // Trigger N8N webhook for manual resend
    const response = await fetch(`${N8N_BASE_URL}/resend-invitation`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        invitationId,
        reason,
        triggeredBy: 'admin_manual',
        timestamp: new Date().toISOString()
      })
    });
    
    if (!response.ok) {
      throw new Error('Failed to trigger email resend');
    }
  }
  
  async sendFollowup(invitationId: string, customMessage?: string): Promise<void> {
    // Trigger immediate follow-up email
    const response = await fetch(`${N8N_BASE_URL}/send-followup`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        invitationId,
        customMessage,
        triggeredBy: 'admin_manual',
        timestamp: new Date().toISOString()
      })
    });
    
    if (!response.ok) {
      throw new Error('Failed to send follow-up email');
    }
  }
}
```

## N8N Workflow Implementations

### 1. Primary Email Sender Workflow

```json
{
  "name": "Send Invitation Email",
  "nodes": [
    {
      "name": "Webhook Trigger",
      "type": "n8n-nodes-base.webhook",
      "parameters": {
        "path": "send-invitation",
        "httpMethod": "POST"
      }
    },
    {
      "name": "Get Invitation",
      "type": "n8n-nodes-base.supabase",
      "parameters": {
        "operation": "select",
        "table": "invitations",
        "filterBy": "id",
        "filterValue": "={{ $json.invitationId }}"
      }
    },
    {
      "name": "Decrypt JWT",
      "type": "n8n-nodes-base.function",
      "parameters": {
        "functionCode": "// Decrypt JWT token to extract PII..."
      }
    },
    {
      "name": "Generate Email Template",
      "type": "n8n-nodes-base.function",
      "parameters": {
        "functionCode": "// Generate personalized email content..."
      }
    },
    {
      "name": "Send Email",
      "type": "n8n-nodes-base.sendGrid",
      "parameters": {
        "to": "={{ $json.email }}",
        "subject": "Your Demo Access is Ready",
        "html": "={{ $json.emailContent }}"
      }
    },
    {
      "name": "Mark Email Sent",
      "type": "n8n-nodes-base.supabase",
      "parameters": {
        "operation": "rpc",
        "function": "mark_invitation_email_sent",
        "parameters": {
          "p_invitation_id": "={{ $json.invitationId }}",
          "p_email_id": "={{ $json.emailId }}"
        }
      }
    }
  ]
}
```

### 2. Follow-up Cadence Workflow

```json
{
  "name": "Invitation Follow-up Cadence",
  "nodes": [
    {
      "name": "Schedule Trigger",
      "type": "n8n-nodes-base.cron",
      "parameters": {
        "rule": "0 */6 * * *"
      }
    },
    {
      "name": "Get Follow-up Needed",
      "type": "n8n-nodes-base.supabase",
      "parameters": {
        "operation": "rpc",
        "function": "get_invitations_needing_followup"
      }
    },
    {
      "name": "Process Each Invitation",
      "type": "n8n-nodes-base.function",
      "parameters": {
        "functionCode": "// Process each invitation requiring follow-up..."
      }
    },
    {
      "name": "Send Follow-up Email",
      "type": "n8n-nodes-base.sendGrid",
      "parameters": {
        "to": "={{ $json.email }}",
        "subject": "Reminder: Your Demo Access Expires Soon",
        "html": "={{ $json.followupContent }}"
      }
    },
    {
      "name": "Mark Follow-up Sent",
      "type": "n8n-nodes-base.supabase",
      "parameters": {
        "operation": "rpc",
        "function": "mark_invitation_followup_sent",
        "parameters": {
          "p_invitation_id": "={{ $json.invitationId }}",
          "p_email_id": "={{ $json.emailId }}"
        }
      }
    }
  ]
}
```

## Email Templates

### 1. Initial Invitation Email

```html
<!DOCTYPE html>
<html>
<head>
  <title>Your Thepia Flows Demo Access</title>
</head>
<body>
  <h1>Welcome to Your Thepia Flows Demo!</h1>
  
  <p>Hi {{ name }},</p>
  
  <p>Great news! Your demo request for {{ workflow_type }} has been approved.</p>
  
  <p><strong>Your Demo Details:</strong></p>
  <ul>
    <li>Duration: {{ demo_duration }}</li>
    <li>Expires: {{ expires_at }}</li>
    <li>Environment: {{ demo_environment }}</li>
  </ul>
  
  <p>
    <a href="{{ invitation_link }}" style="background: #007bff; color: white; padding: 12px 24px; text-decoration: none; border-radius: 4px;">
      Access Your Demo
    </a>
  </p>
  
  <p>Questions? Reply to this email for support.</p>
  
  <p>Best regards,<br>The Thepia Team</p>
</body>
</html>
```

### 2. Follow-up Email Templates

**Day 3 Follow-up:**
```html
<h1>Don't Miss Your Demo Opportunity</h1>
<p>Hi {{ name }},</p>
<p>We noticed you haven't accessed your {{ workflow_type }} demo yet. Here's what you'll discover...</p>
```

**Day 7 Follow-up:**
```html
<h1>Your Demo Expires in 7 Days</h1>
<p>Hi {{ name }},</p>
<p>Time is running out! Your exclusive demo access expires on {{ expires_at }}.</p>
```

**Day 12 Final Reminder:**
```html
<h1>Final Reminder: Demo Expires Tomorrow</h1>
<p>Hi {{ name }},</p>
<p>This is your final reminder - your demo access expires in 24 hours.</p>
```

## Admin Interface Integration

### 1. Email Status Dashboard

```typescript
interface EmailStatusDashboard {
  // Email delivery stats
  totalEmailsSent: number;
  deliverySuccessRate: number;
  failedDeliveries: number;
  bounceRate: number;
  
  // Follow-up stats
  followUpsSent: number;
  followUpOpenRate: number;
  followUpClickRate: number;
  
  // Resend requests
  manualResends: number;
  resendSuccessRate: number;
}
```

### 2. Manual Email Controls

**Component: InvitationEmailActions**
```svelte
<script>
  import { InvitationEmailService } from '$lib/services/invitation-email-service';
  
  export let invitation;
  
  const emailService = new InvitationEmailService();
  
  async function resendEmail() {
    await emailService.resendInvitation(invitation.id, 'Admin manual resend');
    // Show success notification
  }
  
  async function sendFollowup() {
    await emailService.sendFollowup(invitation.id);
    // Show success notification
  }
</script>

<div class="email-actions">
  <button on:click={resendEmail} disabled={invitation.email_attempts >= 3}>
    Resend Email ({invitation.email_attempts}/3)
  </button>
  
  <button on:click={sendFollowup} disabled={invitation.follow_up_sent}>
    Send Follow-up
  </button>
  
  {#if invitation.last_email_error}
    <div class="error">
      Last Error: {invitation.last_email_error}
    </div>
  {/if}
</div>
```

## Error Handling & Monitoring

### 1. Email Delivery Failures

**Common Failure Scenarios:**
- Invalid email addresses
- Mailbox full
- SMTP server issues
- Rate limiting
- Spam filters

**Retry Logic:**
- Max 3 delivery attempts
- Exponential backoff (1h, 4h, 12h)
- Admin notification after 3 failures

### 2. Monitoring & Alerts

**N8N Workflow: "Email Monitoring"**
- Runs every hour
- Checks for failed deliveries
- Sends admin alerts for high failure rates
- Generates daily email delivery reports

## Security Considerations

### 1. JWT Token Handling

- JWT tokens contain encrypted PII
- Never log JWT tokens in email service
- Use secure token transmission
- Implement token expiration

### 2. Email Service Security

- Use authenticated SMTP connections
- Implement rate limiting
- Monitor for spam complaints
- Maintain email reputation

## Implementation Priority

### Phase 1: Core Email Functionality
1. ✅ Database schema with email tracking fields
2. ✅ Database functions for email status management
3. 🔄 N8N workflow for initial invitation emails
4. 🔄 Basic email template with JWT token integration

### Phase 2: Follow-up Cadence
1. 🔄 Automated follow-up workflow
2. 🔄 Multiple email templates for different stages
3. 🔄 Admin interface for email status monitoring

### Phase 3: Advanced Features
1. 🔄 Manual resend functionality
2. 🔄 Email delivery analytics
3. 🔄 A/B testing for email templates
4. 🔄 Advanced personalization

This architecture provides a robust, scalable email notification system that handles both automatic cadence and manual interventions while maintaining complete audit trails in the database.

---

## 🚀 RECOMMENDED ARCHITECTURE EVOLUTION

> **Note**: The above architecture documents the initial email-specific approach. For production implementation, we recommend evolving to a **Unified Notification Queue Architecture** that handles all notification types (email, SMS, push, Discord) through a single N8N workflow to optimize N8N Cloud pricing and workflow limits.

### **Queue-Based Notification Architecture**

**Core Concept**: Replace multiple notification workflows with a single database-driven notification queue processor that handles all delivery methods through one N8N workflow.

**Key Benefits**:
- ✅ **N8N Optimization**: Single workflow for all notifications (fits within 5-workflow Starter plan limit)
- ✅ **Unified Status Management**: All retry logic, timing, and error handling in database
- ✅ **Admin Simplification**: Approval becomes simple status change + notification record creation
- ✅ **Scalable**: Add new notification types by inserting database records
- ✅ **Cost Effective**: Minimize active N8N workflows while maximizing functionality

### **Implementation Approach**

**Database Schema Extension**:
```sql
-- Option A: Extend existing invitations table
ALTER TABLE api.invitations ADD COLUMN IF NOT EXISTS 
  notification_status VARCHAR(50) DEFAULT 'email_pending',
  email_attempts INTEGER DEFAULT 0,
  email_next_attempt TIMESTAMP WITH TIME ZONE,
  last_email_error TEXT;

-- Option B: Central notifications table (future evolution)
CREATE TABLE api.notifications (
  notification_type VARCHAR(50), -- 'invitation_email', 'approval_sms', etc.
  reference_id UUID, -- Points to invitations.id or other source
  delivery_method VARCHAR(20), -- 'email', 'sms', 'push', 'discord'
  status VARCHAR(50) DEFAULT 'pending',
  attempt_count INTEGER DEFAULT 0,
  send_after TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**N8N Workflow Evolution**:
- **Single "Notification Processor"** workflow with timer trigger (every 5 minutes)
- **Manual trigger** for immediate processing from admin interface  
- **Database queries** to fetch pending notifications across all types
- **Routing logic** to handle email, SMS, push, Discord delivery methods
- **Status updates** back to database after delivery attempts

**Admin Interface Changes**:
- **Approval flow**: Simple status change + notification record creation
- **Manual notification trigger**: Button to immediately process notification queue
- **Notification monitoring**: View pending/failed notifications across all types

### **Migration Path**

1. **Phase 1**: Extend invitations table with notification status fields
2. **Phase 2**: Build unified N8N Notification Processor workflow  
3. **Phase 3**: Modify admin approval flow to use queue pattern
4. **Phase 4**: Add SMS, push, Discord notification types
5. **Phase 5**: Optional migration to central notifications table

This evolution maintains all the robust features documented above while optimizing for N8N Cloud constraints and providing a foundation for multi-channel notifications.