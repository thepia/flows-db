# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Flows Repositories

This section must be replicated across the directories of the Thepia Flows product to ensure consistency. Capture lessons learned.

### Repository Standards and Consensus

**📋 COMPLETE STANDARDS**: See [thepia.com/docs/flows/repository-standards.md](https://github.com/thepia/thepia.com/blob/main/docs/flows/repository-standards.md) for comprehensive development standards that must be applied across all Flows repositories.

#### Repository Ecosystem
The Thepia Flows product consists of interconnected repositories:
- **`thepia.com`**: Main website and API server with authentication backend
- **`flows-auth`**: Frontend sign-in UI library (Svelte) with WebAuthn support
- **`flows-db`**: Database schema and functionality with admin demo application  
- **`flows.thepia.net`**: Public demo website (upcoming) with production database integration

#### Critical Development Standards
- **PNPM only** - Package manager across all repositories
- **Biome configuration** - Exact biome.json required (see standards doc)
- **`NODE_AUTH_TOKEN`** - Local .env file for GitHub package installation
- **Error reporting system** - Mandatory implementation in all demos
- **@thepia/branding integration** - Required for client-specific theming
- **Component breakdown** - Regular refactoring to avoid module bloat
- **automation** - Run automated checks to ensure quality. Build out GitHub Actions.
- **Document First** - Document before implementing new features. Write in /docs/ and reference in README.md

#### Demo Patterns (Mandatory)
```bash
# Required scripts in all demo repositories
pnpm demo:setup     # Initialize demo environment
pnpm demo:*         # Various demo operations  
pnpm build         # Ensure correctness before commits
pnpm lint          # Biome linting (must pass)
```

#### Quality Requirements
- **Strict code standards** for maintaining development velocity
- **Build must pass** before any commit (`pnpm build`)
- **Error reporting to demo server console** for AI debugging
- **File logging** for AI assistant error tracking
- **Consistent patterns** across repositories for generated code quality

#### Cross-Repository Integration
- **GitHub packages** for shared functionality
- **GitHub Actions** for automated workflows
- **Mature demo components** migrate to shared libraries
- **Synchronized standards** across all CLAUDE.md files

## Project Overview

This is `@thepia/flows-db` - a multi-client database management system for Thepia Flows applications. It provides:
- Multi-tenant PostgreSQL database with Row-Level Security (RLS)
- JWT-based invitation system with encrypted PII storage
- Client provisioning and management automation
- Supabase integration for real-time database operations

## Architecture

### Database Schema Architecture
The system uses a **dedicated API schema** approach instead of the default public schema:
- `api` schema: Client-facing tables exposed via PostgREST
- `internal` schema: System operations, config, secrets (never exposed)
- `audit` schema: Compliance logging and security events

### Core Tables
- `api.clients`: Master client registry with RLS-based isolation
- `api.client_applications`: Application configurations per client
- `api.invitations`: JWT-based invitation metadata (no PII stored)

### Security Model
- All client data isolated via `client_id` column with RLS policies
- Personal information encrypted in JWT tokens, not database
- Only Thepia staff have direct Supabase access
- Comprehensive audit trails for all operations

## Development Commands

### Database Operations
```bash
# Initialize database schema
pnpm run db:init

# Run migrations
pnpm run db:migrate

# Health check
pnpm run health-check

# Reset database (dev only)
pnpm run db:reset
```

### Client Management
```bash
# Interactive client setup
pnpm run client:create

# Create client with parameters
pnpm run client:create -- create --client-code="acme" --legal-name="Acme Corp" --domain="acme.thepia.net"

# Check client status
pnpm run client:status <client-code>

# Update client configuration
pnpm run client:update <client-code> --tier pro

# Deactivate client
pnpm run client:deactivate <client-code>
```

### Invitation Management
```bash
# Create invitation
pnpm run invitation:create --client acme --app offboarding --invitee "user@example.com"

# Validate invitation
pnpm run invitation:validate <jwt-token>

# List invitations
pnpm run invitation:list --client acme --status pending

# Cleanup expired invitations
pnpm run invitation:cleanup
```

### Development
```bash
# Start development server
pnpm run dev

# Run tests
pnpm run test
pnpm run test:watch
pnpm run test:coverage

# Linting and formatting
pnpm run lint
pnpm run lint:fix
pnpm run format
pnpm run format:check

# Type checking
pnpm run typecheck

# Build
pnpm run build
```

### Demo Application
```bash
# Run admin demo (Svelte app)
pnpm run demo:admin

# Build demo
pnpm run demo:admin:build

# Install demo dependencies
pnpm run demo:admin:install
```

## Key Implementation Details

### Schema Prefixes
Always use fully qualified table names in production code:
```sql
-- Correct
INSERT INTO api.clients (...) VALUES (...);

-- Avoid
INSERT INTO clients (...) VALUES (...);
```

### Environment Variables
Required environment variables:
- `SUPABASE_URL`: Supabase project URL
- `SUPABASE_SERVICE_ROLE_KEY`: Service role key for admin operations
- `SUPABASE_ANON_KEY`: Anonymous key for client access
- `JWT_SECRET`: Secret for JWT token signing

### Client Setup Process
1. Validate client code and domain uniqueness
2. Create client record in `api.clients`
3. Create storage buckets for client assets
4. Set up applications in `api.client_applications`
5. Configure RLS policies for data isolation

### Testing Strategy
- Schema validation tests
- RLS policy verification
- Client provisioning integration tests
- No mocking policy - integration tests against real database

### Common Patterns
- Use `scripts/setup-client.js` for client provisioning
- JWT tokens contain all PII - database stores only hashes
- Direct fetch API calls as workaround for schema configuration
- Comprehensive error handling with chalk/ora for CLI feedback

## File Structure
- `/schemas/`: SQL schema definitions
- `/scripts/`: Management and automation scripts
- `/examples/flows-admin-demo/`: Svelte demo application
- `/docs/`: Additional documentation
- `/config/`: Configuration templates

## Current Development Progress
- Flows Invitations Implementation
  - Working on end-to-end invitation system
  - Supabase table confirmed to be correct
  - Frontend encryption planned for PII protection
  - Using demo as the frontend for implementation