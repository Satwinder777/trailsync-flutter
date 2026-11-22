# TrailSync

**Record the route. Keep it safe offline. Sync it when you’re back online.**

TrailSync is an offline-first GPS tracking app for walks, hikes, rides, and field work. It captures a route on the device, stores each accepted location in SQLite, and keeps the saved route available even when mobile data is unreliable. The default assessment setup uses a built-in mock REST API; an optional Supabase adapter is also available. In either mode, the sync engine sends records in batches and only marks them synced after an acknowledgement.

> **Product promise:** a lost connection should not mean a lost route.

## The idea

Many location apps depend on a live connection for their core workflow. That can fail on trails, rural roads, large work sites, or during a network outage. TrailSync separates **capturing a location** from **uploading a location**:

1. The user starts a tracking session.
2. GPS samples are checked and accepted by the recorder.
3. Each accepted point is written to the device database first.
4. The route can be reviewed locally in history and on the map.
5. Synchronization uploads pending records when the network and backend are available.
6. SQLite updates a record to synced only after an accepted or duplicate acknowledgement.

The device database is the source of truth for unsynchronized work. Uploads use stable UUIDs, so retrying a record does not create a second copy.

## Who it helps

- **Outdoor users:** record a walk or hike where coverage is intermittent.
- **Field teams:** preserve a location trail during site visits or inspections.
- **Portfolio reviewers:** see a practical example of GPS capture, offline storage, and reliable synchronization working together.

## App walkthrough

| Screen | What it is for |
| --- | --- |
| **Dashboard** | Start or stop a route and see session, distance, sync queue, and connectivity summaries. |
| **Tracking** | Follow the live recording state, distance, saved GPS point count, and latest location fix. |
| **Map** | View the current location and a selected route with a polyline and start/end markers. |
| **History** | Browse saved sessions with pagination; open a session for its route, duration, distance, records, and sync state. |
| **Synchronization** | Review pending, acknowledged, and failed counts; request a sync and see its latest result. |

### A typical trip

1. Open TrailSync and grant location permission when prompted.
2. Tap **Start tracking** before setting out.
3. Keep the app open while recording. GPS capture is currently a foreground feature.
4. Tap **Stop** when the trip is over. The accepted points and session remain in local SQLite.
5. Open **History** to review the session or choose **View route on map**.
6. If the device was offline, restore a connection. TrailSync automatically retries pending records; open **Synchronization** to watch the status and acknowledgements.

### Offline behavior

- GPS capture and local history do not depend on the map tile server or Supabase being reachable.
- The route polyline is built from locally saved points.
- The map background uses OpenStreetMap raster tiles and needs Internet access for new visible tiles. TrailSync does not prefetch map tiles for offline use.
- A failed upload leaves a record pending or eligible for retry. It is not removed from local storage.

## How the data moves

~~~mermaid
flowchart LR
    GPS[GPS location] --> FILTER[Validate and filter sample]
    FILTER --> SQLITE[(SQLite on device)]
    SQLITE --> UI[Dashboard · History · Route map]
    SQLITE --> QUEUE[Pending sync queue]
    QUEUE -->|Network and backend available| BATCH[Upload stable UUIDs in batches]
    BATCH --> API[Supabase acknowledgement]
    API -->|Accepted or duplicate| SQLITE
    API -->|Timeout, offline, or failure| RETRY[Keep local and retry later]
    RETRY --> QUEUE
~~~

## What is implemented today

| Capability | Current state |
| --- | --- |
| Foreground GPS recording and start/stop controls | Implemented |
| Location permission and GPS-disabled handling | Implemented |
| Local session and location persistence with Drift/SQLite | Implemented |
| Stable UUIDs for captured location records | Implemented |
| Paginated local history and session details | Implemented |
| Route map with OpenStreetMap tiles and attribution | Implemented; basemap needs Internet |
| Batched mock REST synchronization, per-record acknowledgements, retries, and duplicate-safe IDs | Implemented for the assessment demo |
| Optional Supabase synchronization adapter | Implemented; requires an authenticated Supabase user and migration |
| Sign-up/sign-in UI and authenticated account flow | **Not implemented yet** |
| User preferences and privacy settings screen | **Not implemented yet** |
| Background tracking while the app is closed | **Not implemented** |

**Default demo sync:** the in-process mock REST API is selected by default. Dio sends JSON requests to GET /health, PUT /sessions/{id}, and POST /sessions/{id}/location-records:batch; an interceptor supplies the mock server responses. The mock stores received record IDs for the app process and returns accepted, duplicate, or rejected acknowledgements. This lets reviewers exercise batched uploads and automatic retry without a Supabase account or a separately deployed server. The mock server state resets when the app process restarts; use Supabase mode for a persistent remote backend.

**Supabase mode:** set SYNC_BACKEND to supabase and configure the project URL and publishable key. Credentials alone do not create an authenticated user. The current authentication page is a placeholder, so a signed-in cloud-sync demonstration requires the auth flow to be added. The database migration must also be applied to the Supabase project.

## Background tracking approach

Background GPS is not enabled in the current app. To add it reliably, tracking would move from a screen-owned stream to a lifecycle-aware platform service that keeps writing accepted points to SQLite. Uploading would remain independent, so losing connectivity never stops GPS capture.

- **Android:** start a location foreground service while the user is in the app, declare the location service type and required foreground-service permissions, and show an ongoing notification with a stop action. Request background location permission only if the product needs to start or continue location access outside the user-started foreground session; respect Android's background-start and location limits. See the [Android foreground service types](https://developer.android.com/develop/background-work/services/fgs/service-types) and [background location guidance](https://developer.android.com/develop/sensors-and-location/location/background).
- **iOS:** enable the Location Updates background mode, request the location authorization level justified by the feature, and configure Core Location background updates. Persist each callback promptly, show the system location indicator, and handle delayed delivery because iOS may suspend background apps to conserve battery. See [Apple's background location guide](https://developer.apple.com/documentation/corelocation/handling-location-updates-in-the-background) and [allowsBackgroundLocationUpdates](https://developer.apple.com/documentation/corelocation/cllocationmanager/allowsbackgroundlocationupdates).

On both platforms, background mode would be opt-in through a clear user action, tested with a locked screen and app lifecycle changes, and tuned for distance, accuracy, and battery use. OS delivery is not a guarantee of a fixed GPS interval.

## Architecture

The app uses a feature-first modular structure. Each feature separates presentation, domain rules, and data adapters.

- **Presentation:** Flutter screens and BLoCs for dashboard, tracking, history, map, and synchronization.
- **Domain:** repository contracts, immutable entities, tracking rules, and retry policy.
- **Data:** Drift/SQLite storage, Geolocator, connectivity monitoring, an in-process mock REST adapter, and an optional Supabase adapter.
- **Dependency injection:** get_it wires implementations to repository contracts.
- **Routing:** go_router manages feature navigation.
- **Shared foundation:** design system, app theme, logging, and centralized error mapping.

Key boundaries:

- Widgets render state and dispatch events; they do not query SQLite or Supabase.
- BLoCs coordinate presentation and call repositories; they do not contain SQL or HTTP requests.
- Accepted GPS records are persisted locally before any upload attempt.
- A record is acknowledged locally only after the server returns an accepted or duplicate result.
- Sync failures preserve queued data and schedule a retry with exponential backoff and jitter.

## Technology

- Flutter and Dart
- BLoC (flutter_bloc)
- Drift and SQLite for local-first persistence
- Geolocator for device GPS
- Dio-backed mock REST sync for the assessment demo; Supabase Flutter and PostgreSQL as an optional remote backend
- connectivity_plus plus a backend health check for sync readiness
- flutter_map and OpenStreetMap raster tiles
- get_it, go_router, and flutter_dotenv

## Run the app

Requirements: Flutter SDK installed and an Android or iOS device/emulator configured.

~~~sh
cp .env.example .env
flutter pub get
flutter run
~~~

To demonstrate tracking without a physical GPS movement, set the development-only flag in .env:

~~~dotenv
USE_SIMULATED_LOCATION=true
~~~

The simulated location provider is intended for development and is disabled for production builds. To use device GPS, keep the flag set to false, enable Location on the device, and grant TrailSync location permission.

### Optional Supabase configuration

Set these values in the local .env file:

~~~dotenv
SYNC_BACKEND=supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_PUBLISHABLE_KEY=sb_publishable_your_public_key
SYNC_BATCH_SIZE=100
~~~

Choose mock_rest for the ready-to-run assessment demo, or supabase to select the Supabase adapter. The publishable key is client configuration, not a privileged credential. **Never put a Supabase service-role key, database password, or other server secret in the Flutter app.** Row Level Security must be enabled and configured in Supabase. See [the migration and setup guide](supabase/README.md).

The .env file is bundled with the app at build time; it is not a secure secret store. Use only public client values there.

## OpenStreetMap notes

TrailSync shows OpenStreetMap attribution in the map. The public tile server is appropriate for interactive development and light, user-driven map viewing subject to its [usage policy](https://operations.osmfoundation.org/policies/tiles/). Public tiles are not an offline map-download service and do not include a production uptime guarantee. GPS capture and locally stored route geometry continue to work when map tiles cannot load.

## Development checks

~~~sh
dart format .
flutter analyze
flutter test
flutter build apk --debug
~~~

Drift-generated database code is committed with its schema changes. If the database schema is changed, regenerate it with the project's configured build_runner command before building.

## Project layout

~~~text
lib/
  app/          bootstrap, configuration, DI, routing, theme, database
  core/         shared errors, logging, and design-system widgets
  features/
    dashboard/
    tracking/
    synchronization/
    history/
    map/
    authentication/
    settings/
supabase/
  migrations/   version-controlled PostgreSQL migrations
test/           unit, repository, BLoC, and widget tests
~~~

## Project status

TrailSync demonstrates a reliable **local capture → local review → acknowledged sync** workflow. Core device-side tracking and history are usable now. Authentication and account setup are the next product steps needed to unlock a complete multi-user cloud experience.
