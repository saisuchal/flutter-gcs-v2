import 'package:flutter/material.dart';
import 'package:flutter_gcs/screens/telemetry_screen/model.dart';
import 'package:flutter_gcs/widgets/telemetry_overlay.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import '../../src/provider/provider.dart';

class GoogleMapView extends ConsumerStatefulWidget {
  const GoogleMapView({super.key});

  @override
  ConsumerState<GoogleMapView> createState() => _GoogleMapViewState();
}

class _GoogleMapViewState extends ConsumerState<GoogleMapView> {
  gmaps.BitmapDescriptor? _droneIcon;
  gmaps.GoogleMapController? _mapController;
  late gmaps.MapType _mapType;

  final List<gmaps.MapType> _mapTypes = [
    gmaps.MapType.normal,
    gmaps.MapType.hybrid,
  ];

  void _cycleMapType() {
    final currentIndex = _mapTypes.indexOf(_mapType);
    final nextIndex = (currentIndex + 1) % _mapTypes.length;
    setState(() {
      _mapType = _mapTypes[nextIndex];
      ref.read(googleMapTypeProvider.notifier).state = _mapType;
    });
  }

  @override
  void initState() {
    super.initState();
    _mapType = ref.read(googleMapTypeProvider);
    _loadCustomMarker();
  }

  void _loadCustomMarker() async {
    _droneIcon = await gmaps.BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/icons/drone.png',
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final telemetry = ref.watch(telemetryProvider);
    final waypoints = ref.watch(waypointProvider);
    final showOverlay = ref.watch(showMissionOverlayProvider);

    final gmaps.LatLng? dronePosition = telemetry != null
        ? gmaps.LatLng(telemetry.lat, telemetry.lon)
        : null;

    ref.listen<TelemetryData?>(telemetryProvider, (previous, next) {
      if (next != null) {
        final updated = gmaps.LatLng(next.lat, next.lon);
        _mapController?.animateCamera(gmaps.CameraUpdate.newLatLng(updated));
      }
    });

    return Scaffold(
        body: Stack(
          children: [
            gmaps.GoogleMap(
              mapType: _mapType,
              zoomControlsEnabled: false,
              initialCameraPosition: gmaps.CameraPosition(
                target:
                    dronePosition ?? const gmaps.LatLng(17.4214339, 78.3479414),
                zoom: 15,
              ),
              markers: {
                if (dronePosition != null)
                  gmaps.Marker(
                    markerId: const gmaps.MarkerId('drone'),
                    position: dronePosition,
                    icon: _droneIcon ?? gmaps.BitmapDescriptor.defaultMarker,
                    rotation: telemetry?.hdg ?? 0,
                    anchor: const Offset(0.5, 0.5),
                    infoWindow: const gmaps.InfoWindow(title: 'Drone'),
                  ),
                if (showOverlay)
                  ...waypoints.asMap().entries.map(
                    (e) => gmaps.Marker(
                      markerId: gmaps.MarkerId('wp${e.key}'),
                      position: e.value['position'],
                      icon: gmaps.BitmapDescriptor.defaultMarker,
                      infoWindow: gmaps.InfoWindow(title: 'WP ${e.key + 1}'),
                    ),
                  ),
              },
              polylines: {
                if (showOverlay && waypoints.length > 1)
                  gmaps.Polyline(
                    polylineId: const gmaps.PolylineId('path'),
                    points: waypoints
                        .map((wp) => wp['position'] as gmaps.LatLng)
                        .toList(),
                    color: Colors.blue,
                    width: 3,
                  ),
              },
              onMapCreated: (controller) => _mapController = controller,
              myLocationEnabled: false,
              compassEnabled: true,
            ),
      
            // ✅ Telemetry Overlay in top-right corner
            const Positioned(top: 16, right: 16, child: TelemetryOverlay()),
          ],
        ),
        floatingActionButton: Align(
          alignment: Alignment.bottomRight,
          child: FloatingActionButton(
            onPressed: _cycleMapType,
            tooltip: 'Change Map Type',
            child: const Icon(Icons.layers),
          ),
        ),
      );
  }
}
