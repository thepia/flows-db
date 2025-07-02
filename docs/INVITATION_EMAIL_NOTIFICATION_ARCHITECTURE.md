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
    const response = await fetch(`${N8N_WEBHOOK_URL}/resend-invitation`, {
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
    const response = await fetch(`${N8N_WEBHOOK_URL}/send-followup`, {
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