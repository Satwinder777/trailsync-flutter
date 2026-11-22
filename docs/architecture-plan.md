# TrailSync Architecture and Implementation Plan

> **Status: provisional.** The TrailSync PRD was not present in the checkout when this plan was prepared. The repository currently contains no tracked application files or PRD. This plan is based only on the product summary and technology constraints supplied in the task; it must be reconciled with the complete PRD before implementation is approved.

## 1. Product and architecture direction

TrailSync should be local-first: a GPS recording is committed to SQLite before the app attempts any network operation. The local database is the source of truth for the device's recording and history views. Supabase is the remote backup/synchronization target. A failed or unavailable backend must never prevent starting, continuing, or viewing a recording that is already on the device.

Use feature-first Clean Architecture. Keep widgets focused on rendering and user input. Use BLoC/Cubit as the feature's MVVM ViewModel: it maps presentation events to domain use cases and exposes immutable state. It must not contain SQL, Supabase, or HTTP calls. Repository interfaces live in the domain layer; their implementations and all SDK-specific code live in data.

```text
Presentation (View + BLoC/Cubit/ViewModel)
                 ↓ use cases
Domain (immutable entities, policies, repository contracts)
                 ↑ implemented by
Data (Drift / Geolocator / Supabase adapters, mappers)
```

Do not add a second ViewModel abstraction alongside BLoC. That would duplicate state and lifecycle responsibilities.

## 2. Detailed implementation plan

1. **Reconcile product requirements.** Confirm platform targets, sign-in behavior, foreground/background recording, sampling policy, map availability offline, track sharing, deletion/retention, multi-device sync, and expected data volume. These decisions affect permissions, schema, sync semantics, and dependencies.
2. **Establish app composition.** Create the Flutter entry point, app configuration, feature module boundaries, error mapping, navigation appropriate to the confirmed flows, dependency injection, and environment setup. Keep Supabase URL and publishable/anon key configurable per environment; never include a service-role key in the client.
3. **Build the local domain and database first.** Define immutable `Track`, `TrackPoint`, and recording lifecycle values. Add Drift tables and versioned migrations. Implement local repositories and the recording use cases. Treat each accepted GPS sample as durable local data.
4. **Implement location capture.** Put Geolocator behind a domain-facing location gateway. Handle permission denied, permanently denied, services disabled, poor accuracy, stale/out-of-order samples, pause/resume, and stream cancellation. Only run continuous high-accuracy capture while the user is recording. Add background modes only if the PRD requires them.
5. **Implement local history and map rendering.** Load session metadata and point geometry through repositories. Display saved tracks with flutter_map. A recording must remain viewable without a network; the base map may not be available offline unless a suitable offline tile source is selected.
6. **Add Supabase authentication and remote persistence.** Define SQL migrations for remote tables and explicit grants/RLS. Add data-layer adapters. Keep auth and database SDK calls behind repositories/data sources.
7. **Add synchronization.** Use stable client-generated track IDs and point sequence numbers. Upload bounded point batches with idempotent upserts. Persist progress and retry metadata locally. Make retries safe after timeouts, app restarts, token expiry, or partial batch success. Keep sync separate from recording so network latency never blocks GPS capture.
8. **Harden and release.** Verify privacy/permission disclosures, migrations, account-switch behavior, backend unavailable states, large track rendering, logging redaction, and the chosen map tile provider's license and usage requirements.

## 3. Final modular folder structure

```text
lib/
  main.dart
  app/
    app.dart
    bootstrap.dart
    router/                  # only if required by the PRD's navigation/deep links
    config/                  # environment and public client configuration
    di/
      injection.dart         # get_it composition root
  core/
    errors/                  # shared failure types and exception mapping
    database/
      app_database.dart      # shared Drift database and migration strategy
    network/
      connectivity_monitor.dart
      dio_factory.dart       # only if Dio has a defined HTTP use
    lifecycle/               # app-resume hooks used by sync coordinator
  features/
    auth/
      presentation/          # pages, widgets, AuthBloc
      domain/                # User, AuthRepository, auth use cases
      data/                  # Supabase auth adapter and DTO mapping
    tracking/
      presentation/          # recording page/widgets, RecordingBloc
      domain/                # recording policy, location gateway, use cases
      data/
        local/                # Drift tracking DAO/table access
        device/               # Geolocator adapter
        repositories/         # repository implementations and mappers
    tracks/
      presentation/          # history, detail/map widgets and BLoCs/Cubits
      domain/                # Track/TrackPoint, repository contract, queries
      data/
        local/                # Drift track reads and writes
        remote/               # Supabase track data source
        repositories/
    sync/
      presentation/          # sync status/retry state, if exposed in UI
      domain/                # sync contract and use cases
      data/                  # sync coordinator, outbox/checkpoints, uploader
  l10n/                      # only if localization is in scope

supabase/
  migrations/                # schema, indexes, grants, RLS, rollback strategy
  tests/                     # pgTAP authorization tests

test/
  features/                  # unit, repository, BLoC and widget tests
  fakes/                     # deterministic fake adapters
```

Keep feature-owned behavior inside the feature. `core/` is for genuinely shared infrastructure, not a catch-all for models or business rules. Generated Drift files should stay beside their source tables/queries and follow the repository's generated-file policy.

## 4. Dependencies and reasons

Use compatible stable releases selected when the app scaffold is created; do not pin versions in this plan.

| Dependency | Use | Notes |
|---|---|---|
| `flutter_bloc` | BLoC/Cubit state and presentation-to-domain coordination | BLoCs/Cubits act as MVVM ViewModels; no separate ViewModel package. |
| `equatable` | Value equality for immutable entities and state | Optional if immutable classes implement equality another way. |
| `get_it` | Constructor dependency wiring in the composition root | Widgets and feature code should receive dependencies, not perform arbitrary service-locator lookups. |
| `drift`, `drift_flutter` | Typed SQLite schema, DAOs, migrations, transactions and local query streams | `drift_flutter` provides Flutter database opening support. Add `drift_dev` and `build_runner` as development dependencies for generated code. |
| `supabase_flutter` | Supabase Auth and PostgREST client for PostgreSQL | Remote calls remain inside data sources. Supabase Flutter already exposes auth, database CRUD and Edge Functions. |
| `geolocator` | Device location and permission APIs | Hide behind a gateway so domain logic can be tested without device plugins. |
| `connectivity_plus` | Network-interface changes as a hint to schedule sync | It does not prove that the internet or Supabase is reachable; actual request success/failure is authoritative. |
| `flutter_map`, `latlong2` | Map rendering and geographic coordinate values | Include visible OSM attribution and an identifiable app user agent if using standard OSM tiles. |
| `uuid` | Stable client-generated track IDs | Stable IDs make retries/upserts idempotent. |
| `dio` | Only for a separately defined HTTP API or Edge Function contract | **Open decision:** Supabase Flutter already performs Supabase REST calls. Do not use Dio to duplicate PostgREST CRUD. Remove it from the initial dependency set if no separate HTTP endpoint is required. |
| `flutter_test`, `mocktail` | Flutter test runner and test doubles | User-specified test stack. |
| `bloc_test` | Concise BLoC/Cubit transition tests | Recommended dev dependency; can be omitted if tests use plain `flutter_test`. |

Do not add a router, code-generation model framework, background worker, encryption plugin, analytics SDK, or map provider until a PRD requirement justifies it. If persistent auth sessions must be stored in platform-protected storage, add a secure-storage adapter and configure Supabase's local auth storage; otherwise explicitly document the session-storage threat model.

## 5. Database design

### Local Drift/SQLite

| Table | Key fields | Purpose |
|---|---|---|
| `tracks` | `id` (stable UUID PK), nullable `owner_user_id`, `title`, `started_at_utc`, `ended_at_utc`, `state`, `distance_meters`, `last_point_sequence`, `sync_state`, `attempt_count`, `next_attempt_at`, `last_sync_error`, `deleted_at_utc` | Recording metadata and local sync/checkpoint state. `owner_user_id` is nullable only if signed-out recording is allowed; account binding rules must be agreed first. |
| `track_points` | `track_id`, `sequence_no`, `latitude`, `longitude`, nullable `altitude_m`, `accuracy_m`, `speed_mps`, `heading_deg`, `recorded_at_utc`; primary key `(track_id, sequence_no)` | Append-only GPS samples. Sequence number is stable across retries and unique within a track. |
| `sync_outbox` (optional) | `id`, `aggregate_type`, `aggregate_id`, `operation`, `attempt_count`, `not_before_utc`, `last_error`, `created_at_utc` | Needed if the PRD includes queued rename/delete or other mutations. For a minimal immutable upload flow, per-track sync state and a point checkpoint may be enough. |

Store timestamps consistently in UTC. Store raw accepted GPS samples for sync and calculate display geometry separately; do not discard original samples merely to simplify map rendering. Use transactions when updating a point and the associated local summary/checkpoint. Add indices for track listing by start time, track point lookup by `(track_id, sequence_no)`, and due sync work.

### Supabase/PostgreSQL

| Table | Key fields and constraints | Access |
|---|---|---|
| `tracks` | `id uuid primary key` (client-generated), `owner_id uuid not null references auth.users(id)`, title, start/end timestamps, duration/distance summaries, `updated_at`, nullable `deleted_at` | Authenticated owner can select/insert/update/delete only rows where `owner_id = auth.uid()`. |
| `track_points` | `track_id uuid references tracks(id) on delete cascade`, `sequence_no integer`, coordinates, optional sensor fields, capture timestamp; primary key `(track_id, sequence_no)` | Policies authorize through the parent track owner. Index `(track_id, sequence_no)` and add any required owner lookup index. |

Keep the initial schema relational and avoid adding PostGIS or a separate device table unless spatial server queries or device management are required. Enforce coordinate ranges, nonnegative sequence values, and reasonable payload/batch limits. Put schema, grants, and RLS in reproducible Supabase migrations. Add pgTAP tests for permitted and denied operations for at least two users and an unauthenticated role.

The sync contract should be at-least-once and idempotent: track IDs and point sequence keys are stable; server writes use conflict-safe upserts; the client advances a local checkpoint only after confirmed success. If tracks can be edited or deleted, define last-write/conflict behavior and server tombstones before implementation.

## 6. BLoC/Cubit responsibility plan

| BLoC/Cubit | Owns | Must not own |
|---|---|---|
| `AuthBloc` | Auth status, sign-in/out intent, auth event subscription and user-facing errors | Supabase calls or token persistence code |
| `RecordingBloc` | Start/pause/resume/stop commands, recording lifecycle state, location stream subscription, user-visible elapsed time/distance/quality | SQL, HTTP, direct plugin APIs, or sync retry policy |
| `TracksBloc` or `TracksCubit` | Local-first history list, filters, refresh and delete intent | Query implementation or server ownership rules |
| `TrackDetailCubit` | Local track detail and map polyline presentation state | Loading every track point into a global app state |
| `SyncCubit` (if UI needs it) | Pending count, latest result, retry command and per-track status presentation | Owning the long-lived scheduler or assuming connectivity means internet access |

The data-layer sync coordinator observes app resume, connectivity hints, auth changes and explicit retry requests. It runs bounded work and reports results through a repository/domain stream. Avoid BLoC-to-BLoC dependencies; coordinate through use cases/repositories. Cancel GPS, auth and database subscriptions when their owner closes.

## 7. Dependency injection plan

1. In `bootstrap.dart`, initialize Flutter bindings, load public environment configuration, open the Drift database, initialize Supabase, register adapters/repositories/use cases, then run the app.
2. Register external clients and long-lived services (database, Supabase client, location gateway, connectivity monitor, optional Dio) as singletons/lazy singletons with explicit disposal.
3. Bind domain repository interfaces to data implementations in one `get_it` composition root.
4. Register use cases and feature BLoCs/Cubits as factories so screen lifecycle and subscriptions are isolated.
5. Expose BLoCs with `BlocProvider` at feature or route boundaries. Do not call `GetIt` from domain classes or widgets.
6. In tests, construct feature dependencies explicitly with fake repositories, in-memory Drift, and mocktail adapters; do not initialize a real Supabase project.

## 8. Security and privacy considerations

- Treat GPS history as sensitive personal data. Make recording state obvious, explain permissions before prompting, and request background location only if the PRD requires unattended tracking.
- Supabase's publishable/anon key is a client identifier, not a secret. Never ship `service_role`, database passwords, or other privileged credentials in Dart assets, build defines, logs, or the app binary. Enforce least-privilege grants and RLS on every exposed table.
- Scope each remote record to `auth.uid()` and test cross-user denial. Decide whether signed-out recording is allowed, how it is claimed on first sign-in, and what happens when the user signs out or switches accounts.
- Protect persisted auth tokens with platform-backed secure storage if the threat model requires it. Avoid logging coordinates, tokens, or request bodies containing track data.
- Define local data retention, account deletion, export, backup behavior, and whether SQLite encryption is required. Keep encryption out of scope until the threat model and supported platforms justify a vetted implementation.
- Supabase Free projects can pause after a period of low database activity. The app must handle a paused/unavailable backend without losing local recordings; this plan does not assume a free-tier uptime guarantee. [Supabase project pausing](https://supabase.com/docs/guides/platform/free-project-pausing)
- Standard OpenStreetMap raster tiles are not an offline map download service. Do not prefetch bulk areas from `tile.openstreetmap.org`; show attribution, identify the app, and honor caching rules. If offline base maps are required, choose a source that explicitly permits offline use or self-host tiles and account for its operational/licensing requirements. [OpenStreetMap tile usage policy](https://operations.osmfoundation.org/policies/tiles/)

## 9. Performance and reliability plan

- Persist accepted samples locally before emitting recording success. Keep sync off the GPS callback path and upload bounded batches.
- Tune GPS cadence, minimum movement, accuracy threshold and speed/outlier filtering against the PRD and real-device battery tests; avoid arbitrary high-frequency polling.
- Keep every raw point in SQLite for durable history/sync. Simplify a separate copy of the polyline for map rendering, and load points by track and viewport/segment rather than placing an unbounded history in BLoC state.
- Throttle presentation-only distance/time updates so every GPS event does not rebuild the whole screen. Keep location subscription cancellation deterministic on pause/stop/dispose.
- Use a point cursor/checkpoint and capped exponential retry with jitter. Connectivity is only a scheduling hint; a request timeout, auth failure, quota error, or server pause must be handled distinctly. Re-check connectivity on app resume because background notifications are not reliable on every platform. [connectivity_plus limitations](https://pub.dev/packages/connectivity_plus)
- Add indexes from measured query paths, not speculatively. Benchmark long tracks and large history lists on target devices before adding isolates or more complex caching.
- For OSM tiles, use only currently viewed tiles, retain cache per HTTP headers, and keep attribution visible; do not implement offline bulk tile downloads on the public standard tile server. [Tile policy](https://operations.osmfoundation.org/policies/tiles/)

## 10. Testing strategy

- **Domain unit tests:** recording state transitions, distance calculation, point acceptance/filter rules, pause/resume duration, stable sequence generation, sync batch planning, checkpoint advancement, retry classification and idempotency.
- **Repository tests:** Drift in-memory schema, transactions, ordering, reactive history updates, deletion tombstones and migration tests. Fake remote source tests for partial success, duplicate upsert, timeout, expired auth and server errors.
- **BLoC/Cubit tests:** immutable state transitions for permission denial, service disabled, start/pause/resume/stop, offline history, sync progress/failure/retry and account changes. Use `bloc_test` if accepted; otherwise plain `flutter_test` and `mocktail`.
- **Widget tests:** core recording and history/map states, including loading, empty, permission guidance, offline banner and sync error/retry affordance.
- **Database authorization tests:** pgTAP assertions for every operation and role on each exposed table, including cross-user denial. Run against local Supabase during development, not a production project.
- **Device/manual integration tests:** real Android/iOS permission flows, background/foreground behavior if required, airplane mode, app termination/restart mid-track, long recording battery use, backend pause/unavailability, and high point-count map rendering.
- Do not make ordinary unit/widget tests depend on a live Supabase project or public map tile availability.

## 11. Development milestones and exit criteria

| Milestone | Deliverable | Exit criteria |
|---|---|---|
| 0. PRD and decision review | Confirmed requirements and acceptance criteria | Resolve the open requirements below; agree on target platforms and MVP scope. |
| 1. App foundation | Flutter scaffold, module boundaries, config, DI and error conventions | App launches in development configuration; no backend secrets; dependency list approved. |
| 2. Local model and persistence | Immutable domain model, Drift schema/migrations, local repository | Create/read/update lifecycle data offline; migration and repository tests pass. |
| 3. GPS recording vertical slice | Permission-aware foreground recording saved locally | Start/pause/resume/stop works with the app offline; stream cleanup and core domain tests pass. |
| 4. History and map | Local history, track detail and rendered polyline | Recorded tracks load from SQLite; map attribution/provider choice is compliant; large-track behavior is acceptable. |
| 5. Supabase security and persistence | SQL migrations, auth adapter, remote data source, grants/RLS | RLS test suite proves allowed owner access and denied cross-user/anonymous access. |
| 6. Reliable synchronization | Local retry/checkpoint mechanism and sync status | Retry after restart/partial failure produces no duplicate points and never blocks local recording. |
| 7. Hardening and portfolio release | Permission/privacy copy, responsive failure states, device QA and docs | Platform behavior, account lifecycle, performance and free-tier limitations are documented and verified. |

## 12. Architectural issues and requirements to resolve

1. **The PRD is missing from this checkout.** No product requirements beyond the prompt were available for this plan. The plan cannot yet be called PRD-compliant.
2. **BLoC and MVVM overlap.** Use BLoC/Cubit as the ViewModel; do not introduce a second ViewModel layer.
3. **Dio and Supabase Flutter overlap.** Decide whether the project needs a separate HTTP API. If not, omit Dio rather than duplicating Supabase PostgREST access.
4. **Offline maps are a separate requirement from offline recording.** Public OSM standard tiles do not permit offline area prefetch. Confirm whether the MVP only needs local GPS/track persistence or full offline base maps.
5. **Foreground vs background tracking is unspecified.** Background tracking changes platform permissions, service behavior, battery profile, disclosures, and QA scope. Geolocator requires platform configuration for background updates; on Android 10+ its guidance calls out `ACCESS_BACKGROUND_LOCATION`. [Geolocator platform setup](https://pub.dev/packages/geolocator)
6. **Auth and ownership are unspecified.** Confirm whether auth is mandatory to record, whether signed-out tracks can later sync, and what account switching/sign-out does to local location data.
7. **Sync semantics are unspecified.** Confirm whether sync is upload-only or bidirectional across devices, and define edit/delete conflicts, retry visibility and duplicate handling.
8. **Scale targets are absent.** Define max track length, expected daily track count, GPS sampling policy, history retention and sync batch limits before optimizing storage/API shape.
9. **Free-plan suitability needs an explicit acceptance.** Free projects can pause after low activity, so portfolio demo expectations and recovery UX should account for sleeping/unavailable backend behavior. [Supabase free project pausing](https://supabase.com/kb/faqs/platform/free-project-pausing)
10. **Platform targets and permissions need confirmation.** Android/iOS are assumed from the mobile product description; minimum OS versions, web/desktop support, and app-store privacy wording are not supplied.

**Approval gate:** review this provisional plan against the full PRD, resolve the items above, then approve implementation. No application code has been implemented as part of this planning document.
