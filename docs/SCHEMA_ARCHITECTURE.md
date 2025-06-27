# Schema Architecture Decision: Dedicated API Schema

## 🎯 Decision: Use Dedicated API Schema

After careful consideration, we've implemented a **dedicated API schema** architecture instead of using Supabase's default public schema. This document explains the reasoning and implementation details.

## 🏗️ Schema Structure

```sql
┌─────────────────────────────────────────────────┐
│                PostgreSQL Database               │
├─────────────────┬────────────────┬──────────────┤
│   API Schema    │ Internal Schema│ Audit Schema │
│   (Exposed)     │   (Hidden)     │  (Hidden)    │
├─────────────────┼────────────────┼──────────────┤
│ • clients       │ • staff_users  │ • access_logs│
│ • applications  │ • system_config│ • changes    │
│ • invitations   │ • jwt_keys     │ • events     │
│ • user_profiles │ • migrations   │ • security   │
└─────────────────┴────────────────┴──────────────┘
                          ↓
                   PostgREST API
                  (Only sees 'api')
```

## 🔐 Key Benefits

### 1. **Security Through Isolation**
```sql
-- Only expose what's necessary
CREATE SCHEMA api;      -- Client-facing tables
CREATE SCHEMA internal; -- Never exposed via API
CREATE SCHEMA audit;    -- Compliance logging

-- PostgREST configuration
COMMENT ON SCHEMA api IS 'exposed';
COMMENT ON SCHEMA internal IS 'hidden';
COMMENT ON SCHEMA audit IS 'hidden';
```

### 2. **Clear API Boundaries**
- **api schema**: Everything clients can access
- **internal schema**: System operations, config, secrets
- **audit schema**: Compliance, logging, security events

### 3. **Easier Security Audits**
```sql
-- Quick security audit: What's exposed?
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'api';

-- Versus checking every table in public schema
-- and remembering which have RLS policies
```

### 4. **Prevent Accidental Exposure**
```sql
-- New developer creates a table
CREATE TABLE internal.encryption_keys (...);
-- ✅ Automatically hidden from API

-- Versus public schema where it would be exposed
-- unless RLS is explicitly configured
```

### 5. **API Versioning Support**
```sql
-- Future API versions
CREATE SCHEMA api_v2;

-- Gradual migration
CREATE VIEW api_v2.clients AS 
  SELECT * FROM api.clients 
  WITH additional_columns;
```

## 📊 Comparison: API Schema vs Public Schema

| Aspect | Dedicated API Schema | Public Schema |
|--------|---------------------|---------------|
| **Security** | ✅ Explicit exposure control | ⚠️ Everything exposed by default |
| **Clarity** | ✅ Clear API boundaries | ❌ Mixed concerns |
| **Maintenance** | ✅ Easy to audit what's exposed | ❌ Must check each table's RLS |
| **Flexibility** | ✅ Multiple schemas for different needs | ❌ Everything in one schema |
| **PostgREST Config** | ✅ Simple: expose one schema | ⚠️ Complex RLS for each table |
| **Team Safety** | ✅ New tables hidden by default | ❌ New tables exposed by default |

## 🛠️ Implementation Details

### PostgREST Configuration
```javascript
// In Supabase, configure PostgREST to expose only 'api' schema
{
  "db_schema": "api",  // Instead of default "public"
  "db_anon_role": "anon",
  "db_authenticated_role": "authenticated"
}
```

### Migration from Public Schema
```sql
-- Move existing tables to api schema
ALTER TABLE public.clients SET SCHEMA api;
ALTER TABLE public.applications SET SCHEMA api;
ALTER TABLE public.invitations SET SCHEMA api;

-- Or use our helper function
SELECT internal.move_table_to_schema('clients', 'public', 'api');
```

### RLS Policies Work the Same
```sql
-- RLS policies work identically in api schema
ALTER TABLE api.clients ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Staff can access all clients" ON api.clients
  FOR ALL USING (auth.jwt()->>'role' = 'thepia_staff');
```

## 🔍 Common Patterns

### Pattern 1: Client-Facing Tables
```sql
-- Goes in api schema
CREATE TABLE api.user_profiles (
  id UUID PRIMARY KEY,
  client_id UUID REFERENCES api.clients(id),
  -- ... user data
);
```

### Pattern 2: System Configuration
```sql
-- Goes in internal schema
CREATE TABLE internal.feature_flags (
  id UUID PRIMARY KEY,
  feature_name TEXT,
  enabled BOOLEAN,
  -- Never exposed to clients
);
```

### Pattern 3: Audit Logging
```sql
-- Goes in audit schema
CREATE TABLE audit.data_access_log (
  id UUID PRIMARY KEY,
  accessed_at TIMESTAMP,
  user_id UUID,
  table_name TEXT,
  operation TEXT,
  -- Read-only for compliance
);
```

## 🚨 Important Considerations

### 1. **Fully Qualified Names**
```sql
-- Always use schema prefix in production code
INSERT INTO api.clients (...) VALUES (...);

-- Not just:
INSERT INTO clients (...) VALUES (...);
```

### 2. **Search Path Settings**
```sql
-- Set search path for convenience during development
SET search_path TO api, public;

-- But use fully qualified names in application code
```

### 3. **Permissions Management**
```sql
-- Grant permissions on schema level
GRANT USAGE ON SCHEMA api TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA api TO authenticated;

-- Internal schema - no access for regular users
-- (No GRANT statements for anon/authenticated)
```

### 4. **Supabase Dashboard**
- The Supabase dashboard shows all schemas
- Configure table editor to show 'api' schema by default
- Train team to use correct schema for new tables

## 📋 Migration Checklist

If migrating from public schema:

- [ ] Run `00_schema_setup.sql` to create schemas
- [ ] Move tables to appropriate schemas
- [ ] Update all SQL to use schema prefixes
- [ ] Update PostgREST configuration
- [ ] Test API access with new schema
- [ ] Update application connection strings
- [ ] Verify RLS policies still work
- [ ] Update documentation

## 🎯 Decision Summary

**We use a dedicated API schema because:**

1. **Security by default** - New tables are hidden unless explicitly exposed
2. **Clear boundaries** - Obvious what's API vs internal
3. **Easier auditing** - Simple to see what's exposed
4. **Future flexibility** - Easy to version APIs
5. **Team safety** - Reduces accidental data exposure

This architecture provides defense-in-depth security while maintaining all the benefits of Supabase's Row Level Security and real-time features.

## 🔗 Related Documentation

- [Database Schema Files](../schemas/)
- [Security Guide](SECURITY.md)
- [RLS Policy Guide](RLS_POLICIES.md)
- [Supabase PostgREST Docs](https://supabase.com/docs/guides/api)