import 'package:flutter/material.dart';
import 'package:flutter_gcs/widgets/telemetry_overlay.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' as leaflet;
import '../../src/provider/provider.dart';

class LeafletMapView extends ConsumerWidget {
  const LeafletMapView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final telemetry = ref.watch(telemetryProvider);
    final waypoints = ref.watch(waypointProvider);
    final showOverlay = ref.watch(showMissionOverlayProvider);

    final leaflet.LatLng? dronePosition = telemetry != null
        ? leaflet.LatLng(telemetry.lat, telemetry.lon)
        : null;

    final waypointMarkers = showOverlay
        ? waypoints.asMap().entries.map((e) {
            final pos = e.value['position'];
            final wp = leaflet.LatLng(pos.latitude, pos.longitude);
            return Marker(
              width: 40,
              height: 40,
              point: wp,
              child: const Icon(
                Icons.location_pin,
                color: Colors.blue,
                size: 30,
              ),
            );
          }).toList()
        : <Marker>[];

    final polyline = showOverlay && waypoints.length > 1
        ? Polyline(
            points: waypoints
                .map(
                  (wp) => leaflet.LatLng(
                    wp['position'].latitude,
                    wp['position'].longitude,
                  ),
                )
                .toList(),
            strokeWidth: 3.0,
            color: Colors.blue,
          )
        : null;

    return Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: dronePosition ?? leaflet.LatLng(0, 0),
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.flutter_gcs',
              ),
              if (dronePosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 40,
                      height: 40,
                      point: dronePosition,
                      child: const Icon(
                        Icons.airplanemode_active,
                        color: Colors.red,
                        size: 32,
                      ),
                    ),
                  ],
                ),
              if (waypointMarkers.isNotEmpty)
                MarkerLayer(markers: waypointMarkers),
              if (polyline != null) PolylineLayer(polylines: [polyline]),
            ],
          ),
      
          // ✅ Telemetry Overlay in top-right
          const Positioned(top: 16, right: 16, child: TelemetryOverlay()),
        ],
    );
  }
}
