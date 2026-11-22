-- Read-only catalog checks for the TrailSync database foundation.
-- Run in Supabase SQL Editor after the migration. These checks do not exercise
-- RLS behavior because SQL Editor runs with elevated database privileges.

-- 1. Confirm all required tables exist and RLS is enabled.
select
  p.schemaname,
  p.tablename,
  p.rowsecurity as rls_enabled
from pg_catalog.pg_tables as p
where p.schemaname = 'public'
  and p.tablename in ('profiles', 'tracking_sessions', 'location_records')
order by p.tablename;

-- 2. Inspect primary keys, foreign keys, unique constraints and checks.
select
  c.conrelid::regclass as table_name,
  c.conname as constraint_name,
  c.contype as constraint_type,
  pg_catalog.pg_get_constraintdef(c.oid) as definition
from pg_catalog.pg_constraint as c
where c.conrelid in (
  'public.profiles'::regclass,
  'public.tracking_sessions'::regclass,
  'public.location_records'::regclass
)
order by table_name::text, constraint_name;

-- 3. Confirm primary-key, unique and query indexes.
select
  schemaname,
  tablename,
  indexname,
  indexdef
from pg_catalog.pg_indexes
where schemaname = 'public'
  and tablename in ('profiles', 'tracking_sessions', 'location_records')
order by tablename, indexname;

-- 4. Inspect row-level policies and their ownership predicates.
select
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual as using_expression,
  with_check
from pg_catalog.pg_policies
where schemaname = 'public'
  and tablename in ('profiles', 'tracking_sessions', 'location_records')
order by tablename, policyname;

-- 5. Confirm minimum table grants and the RPC's execute grants.
select
  has_table_privilege('authenticated', 'public.profiles', 'SELECT') as authenticated_can_read_profiles,
  has_table_privilege('anon', 'public.profiles', 'SELECT') as anon_can_read_profiles,
  has_column_privilege('authenticated', 'public.location_records', 'client_record_id', 'INSERT') as authenticated_can_insert_location_ids,
  has_column_privilege('authenticated', 'public.location_records', 'created_at', 'INSERT') as authenticated_can_set_server_created_at,
  has_table_privilege('authenticated', 'public.location_records', 'UPDATE') as authenticated_can_update_locations,
  has_function_privilege('authenticated', 'public.sync_location_records(uuid,jsonb)', 'EXECUTE') as authenticated_can_sync,
  has_function_privilege('anon', 'public.sync_location_records(uuid,jsonb)', 'EXECUTE') as anon_can_sync;

-- Expected results:
-- * Query 1 returns exactly three rows and `rls_enabled` is true for each.
-- * Query 2 includes the auth-user FKs, session-owner composite FK, UUID unique
--   constraints, coordinate/range checks and session state/timestamp checks.
-- * Query 3 includes all named indexes documented in ../README.md.
-- * Query 4 shows only `authenticated` owner-scoped policies.
-- * Query 5 returns true, false, true, false, false, true, false in that order.
