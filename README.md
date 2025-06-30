# @thepia/flows-db

Multi-client database management for Thepia Flows applications. This repository contains database schemas, migrations, client management scripts, and infrastructure templates for managing Supabase-based multi-tenant architecture.

## 🎯 Overview

**flows-db** provides the complete database infrastructure for managing multiple client installations of Thepia Flows applications with:

- **Multi-client data isolation** via Row-Level Security (RLS)
- **JWT-based invitation system** with encrypted PII storage
- **Client provisioning automation** and management scripts
- **Supabase schema management** and migration tools
- **GDPR-compliant architecture** with minimal PII storage

## 🚀 Quick Start

### Prerequisites

1. **GitHub Package Access**: This repository uses GitHub packages. Set up your token:
   ```bash
   export NODE_AUTH_TOKEN=your_github_token_here
   ```
   Or add it to your shell profile (.bashrc, .zshrc, etc.)

2. **Environment Variables**: Copy and configure:
   ```bash
   cp .env.example .env  # Configure your Supabase credentials
   ```

## 🏗️ Architecture

### Multi-Client Strategy
- **Single Supabase project** with RLS-based client isolation
- **Client-specific storage buckets** for asset segregation
- **Encrypted JWT invitations** to minimize database PII storage
- **Automated client provisioning** with email-based setup

### Security Model
- All client data isolated via `client_id` column and RLS policies
- Personal information encrypted in JWT tokens, not stored in database
- Only Thepia staff have direct Supabase access
- Comprehensive audit trails for all operations

## 📁 Repository Structure

```
flows-db/
├── README.md                    # This file
├── package.json                 # Node.js tooling and scripts
├── 
├── schemas/                     # Database schema definitions
│   ├── 01_clients.sql          # Client registry table
│   ├── 02_applications.sql     # Client application configurations  
│   ├── 03_invitations.sql      # Invitation metadata (no PII)
│   ├── 04_audit_events.sql     # Audit trail tables
│   └── 05_rls_policies.sql     # Row-Level Security policies
│
├── migrations/                  # Database migration scripts
│   ├── 001_initial_setup.sql   # Initial schema creation
│   ├── 002_add_client_tiers.sql
│   └── migration-template.sql
│
├── scripts/                     # Management and automation scripts
│   ├── setup-client.js         # New client provisioning
│   ├── manage-invitations.js   # Invitation management
│   ├── health-check.js         # Database health monitoring
│   ├── backup-restore.js       # Backup and restore utilities
│   └── analytics.js            # Usage analytics and reporting
│
├── templates/                   # Client setup templates
│   ├── client-config.json      # Client configuration template
│   ├── app-config.json         # Application configuration template
│   ├── rls-policies.sql        # RLS policy templates
│   └── storage-buckets.sql     # Storage bucket setup templates
│
├── docs/                        # Documentation
│   ├── SETUP_GUIDE.md          # Complete setup instructions
│   ├── CLIENT_ONBOARDING.md    # Client onboarding process
│   ├── API_REFERENCE.md        # Database API documentation
│   ├── SECURITY.md             # Security implementation details
│   └── TROUBLESHOOTING.md      # Common issues and solutions
│
├── tests/                       # Test suites
│   ├── schema.test.js          # Schema validation tests
│   ├── rls.test.js             # RLS policy tests  
│   ├── client-setup.test.js    # Client provisioning tests
│   └── integration.test.js     # End-to-end integration tests
│
└── config/                      # Configuration files
    ├── supabase.example.env     # Environment variables template
    ├── database.config.js       # Database connection config
    └── client-tiers.json        # Client tier definitions
```

## 🚀 Quick Start

### Prerequisites
- Node.js 18+ and pnpm
- Supabase account and project
- Access to thepia.net DNS management

### Setup
```bash
# Clone the repository
git clone https://github.com/thepia/flows-db.git
cd flows-db

# Install dependencies
pnpm install

# Copy environment template
cp config/supabase.example.env .env

# Edit environment variables
# SUPABASE_URL=your-project-url
# SUPABASE_ANON_KEY=your-anon-key
# SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
# JWT_SECRET=your-jwt-secret

# Initialize database schema
pnpm run db:init

# Run health check
pnpm run health-check
```

### Add Your First Client
```bash
# Provision new client
pnpm run client:create \
  --client-code="acme" \
  --legal-name="Acme Corporation" \
  --domain="acme-corp.thepia.net" \
  --region="EU"

# Verify client setup
pnpm run client:status acme
```

## 📊 Database Schema

### Core Tables

#### `clients` - Master Client Registry
- **Purpose**: Central registry of all client installations
- **Key Fields**: `client_code`, `legal_name`, `domain`, `tier`, `region`
- **Security**: RLS enabled, staff-only access

#### `client_applications` - App Configurations
- **Purpose**: Application configurations per client
- **Key Fields**: `client_id`, `app_code`, `configuration`, `features`
- **Security**: Client-isolated via RLS policies

#### `invitations` - Invitation Metadata
- **Purpose**: Invitation tracking without PII storage
- **Key Fields**: `invitation_code`, `jwt_token_hash`, `status`
- **Security**: No PII stored - all personal data encrypted in JWT

### Security Features
- **Row-Level Security (RLS)** on all client tables
- **Encrypted JWT tokens** containing invitation PII
- **Client-specific storage buckets** for file isolation
- **Comprehensive audit trails** for all operations

## 🔐 Invitation System

### JWT-Based Architecture
```typescript
// Invitation JWT contains encrypted PII
interface InvitationJWT {
  // Standard claims
  iss: 'api.thepia.com';
  aud: 'flows.thepia.net';
  sub: string; // invitation_id
  
  // Encrypted invitation data
  invitation: {
    invitee: {
      fullName: string;    // ENCRYPTED
      companyEmail: string; // ENCRYPTED  
      privateEmail: string; // ENCRYPTED
    };
    permissions: string[];
    restrictions: object;
  };
}
```

### Benefits
- **Zero PII in database** - all personal data in encrypted JWT
- **Stateless validation** - no database lookup for basic checks
- **Tamper-proof** - JWT signature prevents modification
- **Automatic expiration** - data expires with token

## 🛠️ Management Scripts

### Client Management
```bash
# Create new client
pnpm run client:create --config client-config.json

# Update client configuration  
pnpm run client:update acme --tier pro

# Deactivate client
pnpm run client:deactivate acme

# Generate client analytics
pnpm run client:analytics acme --month 2025-01
```

### Invitation Management
```bash
# Create invitation
pnpm run invitation:create \
  --client acme \
  --app offboarding \
  --invitee "john.doe@acme.com" \
  --expires-in 7d

# Validate invitation
pnpm run invitation:validate <jwt-token>

# List active invitations
pnpm run invitation:list --client acme --status pending

# Cleanup expired invitations
pnpm run invitation:cleanup
```

### Database Maintenance
```bash
# Health check
pnpm run health-check

# Create backup
pnpm run backup:create --client acme

# Restore from backup
pnpm run backup:restore backup-2025-01-15.sql

# Run schema migrations
pnpm run migrate:up

# Generate usage report
pnpm run analytics:usage --month 2025-01
```

## 📈 Monitoring & Analytics

### Key Metrics
- Client storage usage per bucket
- Invitation creation and redemption rates  
- API usage per client and application
- Error rates and performance metrics
- Database query performance

### Alerting
- Invitation expiration notifications
- Storage quota warnings
- Failed authentication attempts
- Database performance degradation

## 🔧 Configuration

### Client Tiers
```json
{
  "free": {
    "maxUsers": 100,
    "storageGB": 1,
    "features": ["basic-auth", "invitations"]
  },
  "pro": {
    "maxUsers": 1000, 
    "storageGB": 10,
    "features": ["basic-auth", "invitations", "analytics", "sso"]
  }
}
```

### Environment Variables
```env
# Supabase Configuration
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# JWT Configuration  
JWT_SECRET=your-jwt-secret-key
JWT_ISSUER=api.thepia.com
JWT_AUDIENCE=flows.thepia.net

# Email Configuration
SETUP_EMAIL_DOMAIN=thepia.net
SETUP_EMAIL_PREFIX=installation

# Storage Configuration
STORAGE_BUCKET_PREFIX=client-assets
```

## 🧪 Testing

### Test Suites
```bash
# Run all tests
pnpm test

# Test schema validation
pnpm test:schema

# Test RLS policies
pnpm test:rls

# Test client provisioning
pnpm test:client-setup

# Test invitation system
pnpm test:invitations

# Integration tests
pnpm test:integration
```

### Test Client Setup
```bash
# Create test client for development
pnpm run test:setup-client

# Cleanup test data
pnpm run test:cleanup

# Reset test database
pnpm run test:reset
```

## 📚 Documentation

- **[Setup Guide](docs/SETUP_GUIDE.md)** - Complete installation and configuration
- **[Client Onboarding](docs/CLIENT_ONBOARDING.md)** - Step-by-step client setup process  
- **[API Reference](docs/API_REFERENCE.md)** - Database schema and API documentation
- **[Security Guide](docs/SECURITY.md)** - Security implementation and best practices
- **[Troubleshooting](docs/TROUBLESHOOTING.md)** - Common issues and solutions

### Architecture Documentation

- **[Notifications System Architecture](https://github.com/thepia/thepia.com/blob/main/docs/flows/notifications-architecture.md)** - Comprehensive notification system recommendations for Flows platform applications

## 🤝 Contributing

### Development Setup
```bash
# Clone and setup
git clone https://github.com/thepia/flows-db.git
cd flows-db
pnpm install

# Setup development database
cp config/supabase.example.env .env.local
pnpm run db:init:dev

# Run tests
pnpm test

# Setup pre-commit hooks
pnpm run setup:hooks
```

### Pull Request Process
1. Create feature branch from `main`
2. Add tests for new functionality
3. Ensure all tests pass
4. Update documentation
5. Submit pull request

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Issues**: [GitHub Issues](https://github.com/thepia/flows-db/issues)
- **Documentation**: [docs/](docs/)
- **Security**: security@thepia.com
- **General**: support@thepia.com

---

**flows-db** - Secure, scalable, multi-client database infrastructure for Thepia Flows applications.