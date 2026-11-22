# TrailSync Supabase database

## Migration

Apply `migrations/20261122000100_trailsync_tracking_foundation.sql` once to the target Supabase project. It creates the profile and tracking schema, enables row-level security, applies least-privilege grants and owner policies, and installs the authenticated batch synchronization RPC. The migration is wrapped in a transaction, so a SQL error rolls back its changes.

This migration creates the tables in `public` and assumes the standard Supabase `auth.users`, `anon`, and `authenticated` objects/roles. It does not create or require a service-role credential. The project-level service role can bypass RLS by design; its secret must remain server-side and must never be included in a Flutter build. Session IDs remain client-supplied so offline-created sessions retain the same UUID when synchronized; server timestamps and the server row UUID for location records are not client-writable.

### Run it in Supabase SQL Editor

1. Open the intended Supabase project in the dashboard and confirm its project name before changing the database.
2. Open **SQL Editor** and select **New query**.
3. Open `supabase/migrations/20261122000100_trailsync_tracking_foundation.sql` in the repository and copy the entire file, including its `begin;` and `commit;` statements.
4. Paste it into the new SQL Editor query and select **Run** once.
5. Confirm the statement completes without an error. Then run the read-only checks in `supabase/validation/verify_tracking_foundation.sql`.
6. Test authorization and the RPC through a signed-in client using two different test users. The SQL Editor normally executes as a privileged database role and therefore is not a valid RLS behavior test.

Do not re-run the migration after it succeeds: the `CREATE TABLE` statements are intentionally versioned migration operations, not `IF NOT EXISTS` repairs. Keep the file in version control. If the project later adopts Supabase CLI migrations after this was applied manually, reconcile the migration history before using `db push`; do not let a CLI attempt to create these already-present tables again.

## Schema and constraint rationale

### `profiles`

- `id` is both the UUID primary key and a foreign key to `auth.users(id)`, with `ON DELETE CASCADE`; each profile is therefore tied to exactly one auth account.
- `display_name` is optional and capped at 120 characters.
- `created_at` and `updated_at` are server timestamps. A trigger maintains `updated_at` on edits.
- A profile row is created by the authenticated client on first use; there is no trigger that copies unreviewed auth metadata into a public table.

### `tracking_sessions`

- `id` is a UUID primary key with a server default. For offline creation, the client should supply its own stable UUID so the same session ID can be synchronized later.
- `user_id` references `auth.users(id)` and cascades on account deletion.
- `(id, user_id)` is also unique so `location_records` can use a composite ownership foreign key.
- `status` is limited to `recording`, `paused`, `completed`, or `cancelled`; title length is capped at 120.
- `recording` and `paused` sessions must have no `ended_at`; `completed` and `cancelled` sessions must have one. `started_at` and `ended_at` must be finite timestamps, with the end no earlier than the start. Optional distance must be finite and nonnegative.
- `created_at` and trigger-maintained `updated_at` support history and incremental pull synchronization.

### `location_records`

- `id` is a server UUID primary key. `client_record_id` is a required, globally unique client-generated UUID and is the idempotency key used by the sync RPC.
- `(session_id, user_id)` references `(tracking_sessions.id, tracking_sessions.user_id)` with `ON DELETE CASCADE`. This database constraint prevents a location row from claiming an owner different from its session owner.
- `recorded_at` must be finite. Latitude must be in `[-90, 90]`; longitude must be in `[-180, 180]`. Optional altitude, accuracy, speed and heading are checked for finite/range-safe values; accuracy and speed cannot be negative, and heading is `[0, 360)`.
- Rows are append-only through ordinary client grants: `authenticated` can select, insert and delete its own rows, but cannot update a location record.
- `created_at` is the server acceptance time. It is useful for a stable incremental-download cursor when an offline device later uploads older `recorded_at` values.

## Indexes

Primary keys and unique constraints create their own indexes. The migration adds these query indexes:

| Index | Purpose |
|---|---|
| `tracking_sessions_user_started_at_idx (user_id, started_at DESC, id)` | User-scoped session history ordered by start time. |
| `tracking_sessions_user_updated_at_idx (user_id, updated_at DESC, id)` | User-scoped incremental sync after an update watermark. |
| `location_records_user_created_at_idx (user_id, created_at, id)` | Pull newly accepted records in stable server-time order. |
| `location_records_user_recorded_at_idx (user_id, recorded_at DESC)` | User-scoped time range queries by actual capture time. |
| `location_records_session_recorded_at_idx (session_id, recorded_at, id)` | Load a session's route in capture order and support the session foreign key's cascade work. |

The `client_record_id` unique constraint also creates the index used by conflict-safe inserts. The `user_id` leading columns on user-scoped indexes avoid redundant single-column indexes.

## RLS policies and grants

RLS is enabled on all three user-specific tables. Table grants are revoked from `PUBLIC`, `anon`, and `authenticated`, then the minimum needed operations are granted to `authenticated`. Column-level insert/update grants also keep server timestamps and the location row UUID out of client writes.

- **Profiles:** select and delete are table-level grants; insert is limited to `id` and `display_name`, and update to `display_name`. Every operation is allowed only when `id = auth.uid()`; updates check ownership before and after the change.
- **Tracking sessions:** select/delete are table-level grants; insert allows the session fields but not server timestamps; update allows title/status/end time/distance but not `id`, `user_id`, `started_at`, or server timestamps. Every operation is allowed only when `user_id = auth.uid()`; updates cannot move ownership to another user.
- **Location records:** select/delete are table-level grants; insert allows the client record ID, owner/session IDs, capture time, coordinates and optional sensor values, but not the server row UUID or `created_at`. Inserts require `user_id = auth.uid()` and an existing session owned by the same user. The composite foreign key independently enforces that relationship. No update grant or update policy is provided.
- **Batch RPC:** `sync_location_records(uuid, jsonb)` is executable by `authenticated`, not by `anon` or `PUBLIC`. It is `SECURITY INVOKER`, so RLS and caller grants still apply; it is not a service-role bypass.

## Batch synchronization contract

Call `sync_location_records` as an authenticated user with a session UUID and a JSON array. Each item uses these keys:

```json
{
  "record_id": "client-generated-uuid",
  "recorded_at": "2026-11-22T12:00:00Z",
  "latitude": 37.4219,
  "longitude": -122.0840,
  "altitude_m": 12.5,
  "accuracy_m": 4.0,
  "speed_mps": 1.2,
  "heading_deg": 90.0
}
```

`record_id`, `recorded_at`, `latitude`, and `longitude` are required. Sensor values are optional. Send timestamps in ISO 8601 with a `Z` or explicit UTC offset. Submit at most 500 records. The server also caps PostgreSQL's JSONB representation at 512 KiB (`pg_column_size`); this is not an exact HTTP-body byte count, so keep request bodies comfortably below that size and split/retry if the RPC reports a payload-too-large error.

The RPC returns one row per item: `record_ordinal`, the submitted `client_record_id`, `acknowledgement`, `error_code`, and the server `location_record_id` when accepted or recognized as a duplicate.

- `accepted`: inserted for the first time.
- `duplicate`: the UUID already exists with the same session, owner and payload; no new row was created.
- `rejected`: validation/ownership failed, or a UUID was reused for a different payload/session. The error code identifies the reason without revealing another user's record.
- A batch with more than 500 items but within the 512 KiB JSONB cap returns a `batch_too_large` rejection per submitted item. A JSONB value whose PostgreSQL representation exceeds 512 KiB is rejected as a whole and must be split by the client.
- An unknown or non-owned session returns `session_not_found` for every item. The RPC explicitly checks ownership, the insert policy checks it again, and the composite foreign key enforces it in storage.

The client must persist each `client_record_id` locally and retry the same ID and unchanged payload after timeouts. It should remove/reconcile pending work only after receiving the corresponding acknowledgement. A reused ID with altered data is deliberately rejected instead of silently overwriting an accepted GPS point.

Insert the session first using its stable UUID and authenticated `user_id`, then call the location RPC in bounded chunks. If the session insert times out, query that UUID under RLS before retrying; do not blindly upsert a session, because a retry must not overwrite the existing session state. Subsequent session edits can update only the explicitly granted fields. The RPC provides per-record idempotency for its points.

## Rollback notes

Prefer a new forward migration for deployed environments. Rollback deletes all profile/session/location data from these tables. Only use the following in a disposable project before real data is stored:

```sql
begin;
drop function if exists public.sync_location_records(uuid, jsonb);
drop table if exists public.location_records;
drop table if exists public.tracking_sessions;
drop table if exists public.profiles;
drop function if exists public.set_updated_at();
commit;
```

## Validation

Run `validation/verify_tracking_foundation.sql` after migration. These checks verify object existence, RLS flags, constraints, indexes, policies, and the intended grants. Then verify behavior through the authenticated Supabase client:

1. User A creates a session and submits one record: it should receive `accepted`.
2. User A submits the identical record UUID and payload again: it should receive `duplicate`, with only one stored row.
3. User A submits the same UUID with changed coordinates: it should receive `record_id_payload_mismatch` and the stored row should remain unchanged.
4. User A calls the RPC with User B's session UUID: each item should receive `session_not_found`.
5. User A queries sessions and locations while User B has rows: User A must see only User A's rows.

The SQL Editor checks are catalog checks; because SQL Editor runs with elevated privileges, they do not replace these signed-in RLS behavior checks.
