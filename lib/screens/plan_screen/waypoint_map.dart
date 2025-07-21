// lib/screens/plan_screen/waypoint_map.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'waypoint_model.dart';

class WaypointMap extends StatelessWidget {
  final List<Waypoint> waypoints;
  final void Function(LatLng) onTap;
  final void Function(GoogleMapController) onMapCreated;

  const WaypointMap({
    super.key,
    required this.waypoints,
    required this.onTap,
    required this.onMapCreated,
  });

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: LatLng(12.9716, 77.5946),
        zoom: 14,
      ),
      onMapCreated: onMapCreated,
      onTap: onTap,
      markers: waypoints
          .map((wp) => Marker(
                markerId: MarkerId('wp${wp.sequence}'),
                position: wp.position,
                infoWindow: InfoWindow(title: 'WP ${wp.sequence + 1}'),
              ))
          .toSet(),
      polylines: {
        Polyline(
          polylineId: const PolylineId('route'),
          points: waypoints.map((wp) => wp.position).toList(),
          color: Colors.blue,
          width: 3,
        ),
      },
    );
  }
}
