// lib/screens/plan_screen/waypoint_model.dart
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Waypoint {
  final LatLng position;
  final double altitude;
  final int sequence;

  Waypoint({
    required this.position,
    required this.altitude,
    required this.sequence,
  });

  Map<String, dynamic> toJson() => {
        'lat': position.latitude,
        'lon': position.longitude,
        'alt': altitude,
        'seq': sequence,
      };

  factory Waypoint.fromJson(Map<String, dynamic> json) => Waypoint(
        position: LatLng(json['lat'], json['lon']),
        altitude: json['alt'],
        sequence: json['seq'],
      );
}
