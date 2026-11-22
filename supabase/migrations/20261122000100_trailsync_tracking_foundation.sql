-- TrailSync tracking database foundation.
-- Apply once to a Supabase project. See ../README.md for rollout and validation notes.

begin;

-- Keep updated_at server-managed for profile and session edits.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $function$
begin
  new.updated_at := pg_catalog.now();
  return new;
end;
$function$;

revoke all on function public.set_updated_at() from public, anon, authenticated;

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text,
  created_at timestamp with time zone not null default pg_catalog.now(),
  updated_at timestamp with time zone not null default pg_catalog.now(),
  constraint profiles_display_name_length_check
    check (display_name is null or pg_catalog.char_length(display_name) <= 120)
);

comment on table public.profiles is
  'User-editable profile data. id is the matching Supabase Auth user UUID.';

create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

create table public.tracking_sessions (
  id uuid primary key default pg_catalog.gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  title text,
  status text not null default 'recording',
  started_at timestamp with time zone not null,
  ended_at timestamp with time zone,
  distance_meters double precision,
  created_at timestamp with time zone not null default pg_catalog.now(),
  updated_at timestamp with time zone not null default pg_catalog.now(),

  -- Required as the target of the composite ownership foreign key below.
  constraint tracking_sessions_id_user_id_key unique (id, user_id),
  constraint tracking_sessions_status_check
    check (status in ('recording', 'paused', 'completed', 'cancelled')),
  constraint tracking_sessions_status_end_time_check
    check (
      (status in ('recording', 'paused') and ended_at is null)
      or (status in ('completed', 'cancelled') and ended_at is not null)
    ),
  constraint tracking_sessions_title_length_check
    check (title is null or pg_catalog.char_length(title) <= 120),
  constraint tracking_sessions_started_at_finite_check
    check (started_at > '-infinity'::timestamp with time zone
       and started_at < 'infinity'::timestamp with time zone),
  constraint tracking_sessions_ended_at_finite_check
    check (ended_at is null or (
      ended_at > '-infinity'::timestamp with time zone
      and ended_at < 'infinity'::timestamp with time zone
      and ended_at >= started_at
    )),
  constraint tracking_sessions_distance_nonnegative_finite_check
    check (distance_meters is null or (
      distance_meters >= 0
      and distance_meters < 'Infinity'::double precision
    ))
);

comment on table public.tracking_sessions is
  'A user-owned GPS recording. Session UUIDs may be generated on-device while offline.';

create trigger tracking_sessions_set_updated_at
before update on public.tracking_sessions
for each row execute function public.set_updated_at();

create table public.location_records (
  id uuid primary key default pg_catalog.gen_random_uuid(),
  client_record_id uuid not null,
  session_id uuid not null,
  user_id uuid not null,
  recorded_at timestamp with time zone not null,
  latitude double precision not null,
  longitude double precision not null,
  altitude_m double precision,
  accuracy_m double precision,
  speed_mps double precision,
  heading_deg double precision,
  created_at timestamp with time zone not null default pg_catalog.now(),

  -- A client-generated id is the globally unique idempotency key for retries.
  constraint location_records_client_record_id_key unique (client_record_id),
  constraint location_records_session_owner_fkey
    foreign key (session_id, user_id)
    references public.tracking_sessions (id, user_id)
    on delete cascade,
  constraint location_records_recorded_at_finite_check
    check (recorded_at > '-infinity'::timestamp with time zone
       and recorded_at < 'infinity'::timestamp with time zone),
  constraint location_records_latitude_range_check
    check (latitude between -90 and 90),
  constraint location_records_longitude_range_check
    check (longitude between -180 and 180),
  constraint location_records_altitude_finite_check
    check (altitude_m is null or (
      altitude_m > '-Infinity'::double precision
      and altitude_m < 'Infinity'::double precision
    )),
  constraint location_records_accuracy_nonnegative_finite_check
    check (accuracy_m is null or (
      accuracy_m >= 0
      and accuracy_m < 'Infinity'::double precision
    )),
  constraint location_records_speed_nonnegative_finite_check
    check (speed_mps is null or (
      speed_mps >= 0
      and speed_mps < 'Infinity'::double precision
    )),
  constraint location_records_heading_range_check
    check (heading_deg is null or (heading_deg >= 0 and heading_deg < 360))
);

comment on table public.location_records is
  'Append-only GPS samples. client_record_id is stable across retries; id is the server row UUID.';

comment on column public.location_records.client_record_id is
  'Globally unique client-generated UUID used as the safe idempotency key for synchronization.';

-- History and incremental synchronization indexes. Composite indexes start with user_id
-- so they also support user-scoped filters without separate single-column indexes.
create index tracking_sessions_user_started_at_idx
  on public.tracking_sessions (user_id, started_at desc, id);

create index tracking_sessions_user_updated_at_idx
  on public.tracking_sessions (user_id, updated_at desc, id);

create index location_records_user_created_at_idx
  on public.location_records (user_id, created_at, id);

create index location_records_user_recorded_at_idx
  on public.location_records (user_id, recorded_at desc);

create index location_records_session_recorded_at_idx
  on public.location_records (session_id, recorded_at, id);

-- RLS is enabled explicitly. Grants and policies are both required for access control.
alter table public.profiles enable row level security;
alter table public.tracking_sessions enable row level security;
alter table public.location_records enable row level security;

revoke all on table public.profiles from public, anon, authenticated;
revoke all on table public.tracking_sessions from public, anon, authenticated;
revoke all on table public.location_records from public, anon, authenticated;

grant usage on schema public to authenticated;
grant select, delete on table public.profiles to authenticated;
grant insert (id, display_name) on table public.profiles to authenticated;
grant update (display_name) on table public.profiles to authenticated;

grant select, delete on table public.tracking_sessions to authenticated;
grant insert (id, user_id, title, status, started_at, ended_at, distance_meters)
  on table public.tracking_sessions to authenticated;
grant update (title, status, ended_at, distance_meters)
  on table public.tracking_sessions to authenticated;

-- Location samples are immutable after insertion. Users can read or delete their own samples.
grant select, delete on table public.location_records to authenticated;
grant insert (
  client_record_id,
  session_id,
  user_id,
  recorded_at,
  latitude,
  longitude,
  altitude_m,
  accuracy_m,
  speed_mps,
  heading_deg
) on table public.location_records to authenticated;

create policy profiles_select_own
  on public.profiles for select to authenticated
  using (id = (select auth.uid()));

create policy profiles_insert_own
  on public.profiles for insert to authenticated
  with check (id = (select auth.uid()));

create policy profiles_update_own
  on public.profiles for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

create policy profiles_delete_own
  on public.profiles for delete to authenticated
  using (id = (select auth.uid()));

create policy tracking_sessions_select_own
  on public.tracking_sessions for select to authenticated
  using (user_id = (select auth.uid()));

create policy tracking_sessions_insert_own
  on public.tracking_sessions for insert to authenticated
  with check (user_id = (select auth.uid()));

create policy tracking_sessions_update_own
  on public.tracking_sessions for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

create policy tracking_sessions_delete_own
  on public.tracking_sessions for delete to authenticated
  using (user_id = (select auth.uid()));

create policy location_records_select_own
  on public.location_records for select to authenticated
  using (user_id = (select auth.uid()));

-- This policy and the composite FK both require the referenced session to belong
-- to the same authenticated user as the submitted location record.
create policy location_records_insert_own_session
  on public.location_records for insert to authenticated
  with check (
    user_id = (select auth.uid())
    and exists (
      select 1
      from public.tracking_sessions as ts
      where ts.id = public.location_records.session_id
        and ts.user_id = (select auth.uid())
    )
  );

create policy location_records_delete_own
  on public.location_records for delete to authenticated
  using (user_id = (select auth.uid()));

-- Authenticated-only RPC. It uses caller privileges and RLS (not service-role
-- or SECURITY DEFINER privileges), validates session ownership, and returns one
-- acknowledgement per submitted item. Each record is inserted once by its stable
-- client_record_id; exact retries return "duplicate", mismatched reuse is rejected.
create or replace function public.sync_location_records(
  p_session_id uuid,
  p_records jsonb
)
returns table (
  record_ordinal integer,
  client_record_id text,
  acknowledgement text,
  error_code text,
  location_record_id uuid
)
language plpgsql
security invoker
set search_path = ''
as $function$
declare
  v_user_id uuid := auth.uid();
  v_session_owned boolean := false;
  v_item jsonb;
  v_ordinal bigint;
  v_raw_record_id text;
  v_client_record_id uuid;
  v_recorded_at_text text;
  v_recorded_at timestamp with time zone;
  v_latitude double precision;
  v_longitude double precision;
  v_altitude_m double precision;
  v_accuracy_m double precision;
  v_speed_mps double precision;
  v_heading_deg double precision;
  v_existing_id uuid;
  v_same_payload boolean;
begin
  if pg_catalog.jsonb_typeof(p_records) is distinct from 'array' then
    raise exception using
      errcode = '22023',
      message = 'p_records must be a JSON array';
  end if;

  -- Bound a single RPC payload; callers should split larger uploads into chunks.
  if pg_catalog.pg_column_size(p_records) > 524288 then
    raise exception using
      errcode = '22023',
      message = 'batch payload exceeds 512 KiB; split it into smaller requests';
  end if;

  if pg_catalog.jsonb_array_length(p_records) > 500 then
    for v_item, v_ordinal in
      select item.value, item.ordinality
      from pg_catalog.jsonb_array_elements(p_records) with ordinality as item(value, ordinality)
    loop
      record_ordinal := v_ordinal::integer;
      client_record_id := v_item ->> 'record_id';
      acknowledgement := 'rejected';
      error_code := 'batch_too_large';
      location_record_id := null;
      return next;
    end loop;
    return;
  end if;

  if v_user_id is not null then
    select exists (
      select 1
      from public.tracking_sessions as ts
      where ts.id = p_session_id
        and ts.user_id = v_user_id
    )
    into v_session_owned;
  end if;

  for v_item, v_ordinal in
    select item.value, item.ordinality
    from pg_catalog.jsonb_array_elements(p_records) with ordinality as item(value, ordinality)
  loop
    record_ordinal := v_ordinal::integer;
    client_record_id := null;
    acknowledgement := 'rejected';
    error_code := null;
    location_record_id := null;
    v_raw_record_id := null;

    if pg_catalog.jsonb_typeof(v_item) is distinct from 'object' then
      error_code := 'record_must_be_object';
      return next;
      continue;
    end if;

    v_raw_record_id := v_item ->> 'record_id';
    client_record_id := v_raw_record_id;

    if v_user_id is null then
      error_code := 'unauthenticated';
      return next;
      continue;
    end if;

    if not v_session_owned then
      error_code := 'session_not_found';
      return next;
      continue;
    end if;

    if nullif(v_raw_record_id, '') is null then
      error_code := 'missing_record_id';
      return next;
      continue;
    end if;

    begin
      v_client_record_id := v_raw_record_id::uuid;
    exception
      when invalid_text_representation then
        error_code := 'invalid_record_id';
        return next;
        continue;
    end;

    v_recorded_at_text := v_item ->> 'recorded_at';
    if nullif(v_recorded_at_text, '') is null
       or nullif(v_item ->> 'latitude', '') is null
       or nullif(v_item ->> 'longitude', '') is null then
      error_code := 'missing_required_field';
      return next;
      continue;
    end if;

    begin
      v_recorded_at := v_recorded_at_text::timestamp with time zone;
      v_latitude := (v_item ->> 'latitude')::double precision;
      v_longitude := (v_item ->> 'longitude')::double precision;
      v_altitude_m := nullif(v_item ->> 'altitude_m', '')::double precision;
      v_accuracy_m := nullif(v_item ->> 'accuracy_m', '')::double precision;
      v_speed_mps := nullif(v_item ->> 'speed_mps', '')::double precision;
      v_heading_deg := nullif(v_item ->> 'heading_deg', '')::double precision;
    exception
      when invalid_text_representation
        or invalid_datetime_format
        or datetime_field_overflow
        or numeric_value_out_of_range then
        error_code := 'invalid_record_value';
        return next;
        continue;
    end;

    if v_recorded_at <= '-infinity'::timestamp with time zone
       or v_recorded_at >= 'infinity'::timestamp with time zone then
      error_code := 'invalid_recorded_at';
      return next;
      continue;
    end if;

    if v_latitude < -90 or v_latitude > 90
       or v_longitude < -180 or v_longitude > 180 then
      error_code := 'invalid_coordinate';
      return next;
      continue;
    end if;

    if (v_altitude_m is not null and (
          v_altitude_m <= '-Infinity'::double precision
          or v_altitude_m >= 'Infinity'::double precision
        ))
       or (v_accuracy_m is not null and (
          v_accuracy_m < 0
          or v_accuracy_m >= 'Infinity'::double precision
        ))
       or (v_speed_mps is not null and (
          v_speed_mps < 0
          or v_speed_mps >= 'Infinity'::double precision
        ))
       or (v_heading_deg is not null and (
          v_heading_deg < 0 or v_heading_deg >= 360
        )) then
      error_code := 'invalid_sensor_value';
      return next;
      continue;
    end if;

    begin
      insert into public.location_records (
        client_record_id,
        session_id,
        user_id,
        recorded_at,
        latitude,
        longitude,
        altitude_m,
        accuracy_m,
        speed_mps,
        heading_deg
      ) values (
        v_client_record_id,
        p_session_id,
        v_user_id,
        v_recorded_at,
        v_latitude,
        v_longitude,
        v_altitude_m,
        v_accuracy_m,
        v_speed_mps,
        v_heading_deg
      )
      on conflict on constraint location_records_client_record_id_key do nothing
      returning id into location_record_id;
    exception
      when check_violation or foreign_key_violation or not_null_violation then
        acknowledgement := 'rejected';
        if sqlstate = '23503' then
          error_code := 'session_not_found';
        else
          error_code := 'invalid_record_value';
        end if;
        location_record_id := null;
        return next;
        continue;
    end;

    if found then
      acknowledgement := 'accepted';
      error_code := null;
      return next;
      continue;
    end if;

    -- A conflict is a duplicate only when the original row has the same owner,
    -- session, timestamp and payload. Reusing an ID for another payload is rejected.
    select
      existing_record.id,
      existing_record.user_id = v_user_id
        and existing_record.session_id = p_session_id
        and existing_record.recorded_at = v_recorded_at
        and existing_record.latitude = v_latitude
        and existing_record.longitude = v_longitude
        and existing_record.altitude_m is not distinct from v_altitude_m
        and existing_record.accuracy_m is not distinct from v_accuracy_m
        and existing_record.speed_mps is not distinct from v_speed_mps
        and existing_record.heading_deg is not distinct from v_heading_deg
    into v_existing_id, v_same_payload
    from public.location_records as existing_record
    where existing_record.client_record_id = v_client_record_id;

    if not found or v_existing_id is null then
      acknowledgement := 'rejected';
      error_code := 'record_id_conflict';
      location_record_id := null;
    elsif v_same_payload then
      acknowledgement := 'duplicate';
      error_code := null;
      location_record_id := v_existing_id;
    else
      acknowledgement := 'rejected';
      error_code := 'record_id_payload_mismatch';
      location_record_id := null;
    end if;

    return next;
  end loop;
end;
$function$;

revoke all on function public.sync_location_records(uuid, jsonb) from public, anon;
grant execute on function public.sync_location_records(uuid, jsonb) to authenticated;

comment on function public.sync_location_records(uuid, jsonb) is
  'Idempotently inserts up to 500 location records for an owned session and returns one accepted/duplicate/rejected acknowledgement per item.';

commit;
