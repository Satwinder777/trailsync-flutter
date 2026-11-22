# TrailSync

TrailSync is an offline-first GPS tracking and synchronization project. The current implementation includes local SQLite session and location persistence, foreground GPS capture, and a batched Supabase synchronization queue. Authentication screens and sign-in flows are not implemented yet.

## Project structure

```text
lib/
  app/       App bootstrap, configuration, dependency injection, routing, theme and Drift database
  core/      Shared errors, logging and design-system widgets
  features/  authentication, dashboard, tracking, synchronization, history, map, settings
```

Each feature has `presentation`, `domain` and `data` directories. Tracking uses `TrackingBloc` for UI state, domain repository and location-provider interfaces, and Drift/Geolocator adapters in data. Location history is read with bounded keyset pagination. See [feature boundaries](lib/features/README.md) and the [approved architecture plan](docs/architecture-plan.md).

## Local configuration

Copy `.env.example` to `.env` before running the app. Add only public client configuration:

```dotenv
APP_ENV=development
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_PUBLISHABLE_KEY=sb_publishable_your_public_key
USE_SIMULATED_LOCATION=false
SYNC_BATCH_SIZE=100
```

The `.env` file is bundled into the mobile app, so it is not a secure secret store. Never add a Supabase `service_role` key, database password, or other privileged credential. Supabase client configuration is not used by this foundation yet; RLS must be in place before adding client data access.

For a local demo without device GPS, set `USE_SIMULATED_LOCATION=true` in the ignored `.env` file. The deterministic provider is disabled in production. `SYNC_BATCH_SIZE` is bounded to 1–500 to match the server RPC limit. The app checks Supabase Auth's health endpoint before attempting uploads, then upserts the owning session and sends location records in per-session RPC batches. It requires an authenticated Supabase user and the migration in `supabase/migrations/` to be applied.

The dashboard reads local session totals and sync queue status. History uses cursor-paginated local session and record queries. The map renders a bounded route overview from SQLite and uses `flutter_map` with OpenStreetMap raster tiles. `OSM_TILE_URL_TEMPLATE` can point to a compatible tile endpoint. The app shows OpenStreetMap attribution and identifies itself in tile requests; it only fetches tiles for the visible map and does not prefetch tiles for offline use. GPS capture remains available offline, while the map background requires tile network access.

SQLite remains the source of truth for captured points. A point is marked synced only after an `accepted` or `duplicate` acknowledgement; timeouts and rate limits persist a retry time with exponential backoff and jitter. Interrupted `syncing` rows return to `pending` when the database opens. Rejected rows remain in the local failed queue. Pending location rows are not deleted by synchronization.

## Tooling

```sh
flutter pub get
dart format lib test
flutter analyze
flutter test
```

`flutter_lints` supplies the baseline Flutter rules. `analysis_options.yaml` enables stricter type checks, avoids `print`, and asks the Dart formatter to normalize trailing commas and import order.

The database migration, SQL Editor instructions, and validation queries are in [supabase/README.md](supabase/README.md).
