## Development Memories

- When updating client demo data follow docs/DEMO_DATA_MEMORY.md
- We save SQL scripts to be run in Supabase Dashboard under /schemas
- You cant check in secrets and tokens
- We use vite-plugin-restart. You can trigger a restart by changing schemas, scripts or the vite configuration.

## Root Cause of My schema Mistakes

  I keep defaulting to "standard Supabase patterns" instead of remembering this project's specific
   architecture:

  - Standard Supabase: Uses public schema by default
  - This project: Uses api schema exclusively with PostgREST restrictions

  What I Should Remember

  Every time I write Supabase code, check:
  1. ✅ Does the client have { db: { schema: 'api' } }?
  2. ✅ Am I assuming default schema behavior?
  3. ✅ Have I seen this exact error before in this project?

  The Pattern I Keep Missing

  I solve the schema issue once, then immediately forget it in the next script/file and repeat the
   same mistake. I need to:

  1. Always start with the schema config when writing any Supabase client code
  2. Reference the working examples (like populate-process-data.cjs) instead of writing from
  scratch
  3. Remember this is NOT a standard Supabase setup