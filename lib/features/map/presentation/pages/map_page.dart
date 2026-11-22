import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart';
import 'package:http/retry.dart';
import 'package:latlong2/latlong.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/design_system/widgets/app_card.dart';
import '../../../../core/design_system/widgets/app_page_scaffold.dart';
import '../../../../features/synchronization/presentation/bloc/sync_bloc.dart';
import '../../../../features/synchronization/presentation/bloc/sync_state.dart';
import '../../../../features/tracking/domain/entities/tracking_route_point.dart';
import '../../../../features/tracking/presentation/bloc/tracking_bloc.dart';
import '../../../../features/tracking/presentation/bloc/tracking_state.dart';
import '../bloc/map_bloc.dart';
import '../bloc/map_event.dart';
import '../bloc/map_state.dart';

class MapPage extends StatefulWidget {
  const MapPage({required this.tileUrlTemplate, this.sessionId, super.key});

  final String tileUrlTemplate;
  final String? sessionId;

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  @override
  void initState() {
    super.initState();
    context.read<MapBloc>().add(MapOpened(sessionId: widget.sessionId));
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocListener<TrackingBloc, TrackingState>(
    listenWhen: (previous, current) =>
        previous.lastRecord?.clientRecordId !=
            current.lastRecord?.clientRecordId &&
        current.lastRecord != null,
    listener: (context, state) => context.read<MapBloc>().add(
      MapTrackingRecordReceived(state.lastRecord!),
    ),
    child: AppPageScaffold(
      title: 'Trail map',
      body: Column(
        children: [
          const _SessionPicker(),
          const _LocationStatusBanner(),
          const _NetworkAvailabilityNotice(),
          Expanded(
            child: BlocBuilder<MapBloc, MapState>(
              buildWhen: (previous, current) =>
                  previous.status != current.status ||
                  previous.message != current.message ||
                  previous.routePoints != current.routePoints ||
                  previous.selectedSession?.id != current.selectedSession?.id ||
                  previous.currentLocation != current.currentLocation ||
                  previous.isLoadingRoute != current.isLoadingRoute,
              builder: (context, state) {
                if (state.status == MapLoadStatus.initial ||
                    state.status == MapLoadStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.status == MapLoadStatus.failure) {
                  return _MapError(
                    message: state.message ?? 'Map data could not be loaded.',
                    onRetry: () => context.read<MapBloc>().add(
                      MapOpened(sessionId: widget.sessionId),
                    ),
                  );
                }
                return _MapCanvas(
                  tileUrlTemplate: widget.tileUrlTemplate,
                  routePoints: state.routePoints,
                  selectedSessionId: state.selectedSession?.id,
                  currentPosition: state.currentLocation == null
                      ? null
                      : LatLng(
                          state.currentLocation!.latitude,
                          state.currentLocation!.longitude,
                        ),
                  isLoadingRoute: state.isLoadingRoute,
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

class _SessionPicker extends StatelessWidget {
  const _SessionPicker();

  @override
  Widget build(BuildContext context) =>
      BlocSelector<
        MapBloc,
        MapState,
        ({List<({String id, String label})> sessions, String? selectedId})
      >(
        selector: (state) => (
          sessions: [
            for (final session in state.sessions)
              (
                id: session.id,
                label:
                    '${session.title?.trim().isNotEmpty == true ? session.title : 'Trail'} · '
                    '${_dateLabel(session.startedAt)}',
              ),
          ],
          selectedId: state.selectedSession?.id,
        ),
        builder: (context, selection) {
          if (selection.sessions.isEmpty) {
            return const Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Text(
                'No saved trails yet. Start recording to create one.',
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: DropdownButtonFormField<String>(
              initialValue: selection.selectedId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Route',
                prefixIcon: Icon(Icons.route_outlined),
              ),
              items: [
                for (final session in selection.sessions)
                  DropdownMenuItem(
                    value: session.id,
                    child: Text(session.label, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (sessionId) {
                if (sessionId != null) {
                  context.read<MapBloc>().add(MapSessionSelected(sessionId));
                }
              },
            ),
          );
        },
      );
}

class _LocationStatusBanner extends StatelessWidget {
  const _LocationStatusBanner();

  @override
  Widget build(BuildContext context) =>
      BlocSelector<
        MapBloc,
        MapState,
        ({MapLocationStatus status, String? message})
      >(
        selector: (state) =>
            (status: state.locationStatus, message: state.locationMessage),
        builder: (context, location) {
          if (location.status == MapLocationStatus.available ||
              location.status == MapLocationStatus.checking) {
            return const SizedBox.shrink();
          }
          final isPermission =
              location.status == MapLocationStatus.permissionDenied ||
              location.status == MapLocationStatus.permissionPermanentlyDenied;
          final isServiceDisabled =
              location.status == MapLocationStatus.locationServicesDisabled;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: AppCard(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_disabled_outlined),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      location.message ?? 'Current location is unavailable.',
                    ),
                  ),
                  if (isPermission || isServiceDisabled)
                    TextButton(
                      onPressed: () => context.read<MapBloc>().add(
                        isServiceDisabled
                            ? const MapLocationSettingsRequested()
                            : const MapAppSettingsRequested(),
                      ),
                      child: Text(isServiceDisabled ? 'Settings' : 'Allow'),
                    )
                  else
                    IconButton(
                      tooltip: 'Retry location',
                      onPressed: () => context.read<MapBloc>().add(
                        const MapCurrentLocationRefreshRequested(),
                      ),
                      icon: const Icon(Icons.refresh),
                    ),
                ],
              ),
            ),
          );
        },
      );
}

class _NetworkAvailabilityNotice extends StatelessWidget {
  const _NetworkAvailabilityNotice();

  @override
  Widget build(
    BuildContext context,
  ) => BlocSelector<SyncBloc, SyncState, bool?>(
    selector: (state) => state.hasNetwork,
    builder: (context, hasNetwork) {
      if (hasNetwork != false) return const SizedBox.shrink();
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: AppCard(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(Icons.wifi_off_outlined),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'No network connection. GPS and saved routes stay on this '
                  'device; new map tiles need internet.',
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _MapCanvas extends StatefulWidget {
  const _MapCanvas({
    required this.tileUrlTemplate,
    required this.routePoints,
    required this.selectedSessionId,
    required this.currentPosition,
    required this.isLoadingRoute,
  });

  final String tileUrlTemplate;
  final List<TrackingRoutePoint> routePoints;
  final String? selectedSessionId;
  final LatLng? currentPosition;
  final bool isLoadingRoute;

  @override
  State<_MapCanvas> createState() => _MapCanvasState();
}

class _MapCanvasState extends State<_MapCanvas> {
  late final MapController _controller = MapController();
  late final RetryClient _tileHttpClient = RetryClient(Client(), retries: 0);
  late final NetworkTileProvider _tileProvider = NetworkTileProvider(
    httpClient: _tileHttpClient,
    silenceExceptions: true,
    attemptDecodeOfHttpErrorResponses: false,
  );
  bool _mapReady = false;

  LatLng get _center => widget.routePoints.isNotEmpty
      ? _point(widget.routePoints.last)
      : widget.currentPosition ?? const LatLng(20, 0);

  @override
  void didUpdateWidget(covariant _MapCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    final routeChanged =
        oldWidget.selectedSessionId != widget.selectedSessionId;
    final firstLocationFix =
        oldWidget.currentPosition == null && widget.currentPosition != null;
    final firstRoutePoint =
        oldWidget.routePoints.isEmpty && widget.routePoints.isNotEmpty;
    if (_mapReady && (routeChanged || firstLocationFix || firstRoutePoint)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _controller.move(
            _center,
            routeChanged ? 14 : _controller.camera.zoom,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _tileHttpClient.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.routePoints.map(_point).toList(growable: false);
    final markers = <Marker>[];
    if (route.isNotEmpty) {
      markers.add(
        _locationMarker(route.first, color: AppColors.forest, icon: Icons.flag),
      );
      if (route.length > 1) {
        markers.add(
          _locationMarker(
            route.last,
            color: Colors.deepOrange,
            icon: Icons.flag_outlined,
          ),
        );
      }
    }
    if (widget.currentPosition != null) {
      markers.add(
        _locationMarker(
          widget.currentPosition!,
          color: Colors.blue,
          icon: Icons.my_location,
        ),
      );
    }
    return Stack(
      children: [
        FlutterMap(
          key: ValueKey(
            '${widget.selectedSessionId}_'
            '${widget.currentPosition?.latitude}_'
            '${widget.currentPosition?.longitude}',
          ),
          mapController: _controller,
          options: MapOptions(
            initialCenter: _center,
            initialZoom: 14,
            minZoom: 2,
            maxZoom: 19,
            onMapReady: () => _mapReady = true,
          ),
          children: [
            TileLayer(
              urlTemplate: widget.tileUrlTemplate,
              userAgentPackageName: 'com.satwinder.trailsync',
              tileProvider: _tileProvider,
              maxNativeZoom: 19,
            ),
            if (route.length > 1)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: route,
                    strokeWidth: 5,
                    color: AppColors.forest,
                    borderColor: Colors.white,
                    borderStrokeWidth: 1.5,
                  ),
                ],
              ),
            if (markers.isNotEmpty) MarkerLayer(markers: markers),
            RichAttributionWidget(
              alignment: AttributionAlignment.bottomRight,
              attributions: const [
                TextSourceAttribution('© OpenStreetMap contributors'),
              ],
            ),
          ],
        ),
        Positioned(
          top: AppSpacing.md,
          right: AppSpacing.md,
          child: FloatingActionButton.small(
            heroTag: 'map_recenter',
            tooltip: 'Show current location',
            onPressed: () {
              final center =
                  widget.currentPosition ??
                  (route.isNotEmpty ? route.last : null);
              if (center != null && _mapReady) {
                _controller.move(center, 15);
              }
              context.read<MapBloc>().add(
                const MapCurrentLocationRefreshRequested(),
              );
            },
            child: const Icon(Icons.my_location),
          ),
        ),
        if (widget.routePoints.isEmpty && !widget.isLoadingRoute)
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Text(
                    widget.currentPosition == null
                        ? 'Select a saved trail or enable location to begin.'
                        : 'No route points are saved for this trail yet.',
                  ),
                ),
              ),
            ),
          ),
        if (widget.isLoadingRoute)
          const Positioned(
            top: AppSpacing.md,
            left: AppSpacing.md,
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.sm),
                child: SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

Marker _locationMarker(
  LatLng point, {
  required Color color,
  required IconData icon,
}) => Marker(
  point: point,
  width: 34,
  height: 42,
  alignment: Alignment.topCenter,
  child: Icon(icon, color: color, size: 32),
);

LatLng _point(TrackingRoutePoint point) =>
    LatLng(point.latitude, point.longitude);

class _MapError extends StatelessWidget {
  const _MapError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.map_outlined, size: 44),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Map unavailable',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(message, textAlign: TextAlign.center),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ],
      ),
    ),
  );
}

String _dateLabel(DateTime dateTime) {
  final local = dateTime.toLocal();
  return '${local.month}/${local.day}/${local.year}';
}
