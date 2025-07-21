// lib/screens/plan_screen/plan_screen.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gcs/widgets/floating_nav_menu.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart' as latlng;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../src/provider/provider.dart';

class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key});

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  gmaps.GoogleMapController? _mapController;
  gmaps.BitmapDescriptor? _customDroneIcon;
  gmaps.MapType _mapType = gmaps.MapType.normal;

  final List<gmaps.MapType> _mapTypes = [
    gmaps.MapType.normal,
    gmaps.MapType.hybrid,
  ];

  @override
  void initState() {
    super.initState();
    loadIcon();
  }

  void loadIcon() async {
    final icon = await gmaps.BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(25, 25)),
      'assets/icons/arrow.png',
    );
    setState(() => _customDroneIcon = icon);
  }

  void _addWaypoint(gmaps.LatLng position) {
    ref.read(waypointProvider.notifier).add(position);
  }

  void _clearWaypoints() {
    ref.read(waypointProvider.notifier).clear();
    ref.read(showMissionOverlayProvider.notifier).state = false;
  }

  void _locateDrone(gmaps.LatLng? position) {
    if (position != null) {
      _mapController?.animateCamera(gmaps.CameraUpdate.newLatLng(position));
    }
  }

  void _toggleGoogleMapType() {
    final index = _mapTypes.indexOf(_mapType);
    setState(() => _mapType = _mapTypes[(index + 1) % _mapTypes.length]);
  }

  Future<String> _getLocalFilePath(String name) async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$name';
  }

  Future<void> _saveWaypointsToFile(List<Map<String, dynamic>> waypoints) async {
    final path = await _getLocalFilePath('waypoints.json');
    final jsonList = waypoints.map((wp) {
      final gmaps.LatLng pos = wp['position'];
      return {'lat': pos.latitude, 'lon': pos.longitude, 'alt': wp['altitude']};
    }).toList();

    await File(path).writeAsString(jsonEncode(jsonList));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Waypoints saved.')));
  }

  Future<void> _loadWaypointsFromFile() async {
    try {
      final path = await _getLocalFilePath('waypoints.json');
      final jsonStr = await File(path).readAsString();
      final List<dynamic> data = jsonDecode(jsonStr);
      final List<Map<String, dynamic>> loaded = data.map((e) {
        return {
          'position': gmaps.LatLng(e['lat'], e['lon']),
          'altitude': e['alt'],
        };
      }).toList();

      ref.read(waypointProvider.notifier).set(loaded);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('📥 Waypoints loaded.')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Failed to load: $e')));
    }
  }

  Future<void> _sendWaypointsToDrone() async {
    final waypoints = ref.read(waypointProvider);
    if (waypoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ No waypoints to send.')));
      return;
    }

    final telemetry = ref.read(telemetryProvider);
    if (telemetry == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Drone position not available.')));
      return;
    }

    final droneLat = telemetry.lat;
    final droneLon = telemetry.lon;
    const defaultAlt = 10.0;

    final List<Map<String, dynamic>> mission = [
      {'type': 'TAKEOFF', 'lat': droneLat, 'lon': droneLon, 'alt': defaultAlt},
      ...waypoints.map((wp) {
        final pos = wp['position'] as gmaps.LatLng;
        return {
          'type': wp['type'] ?? 'WAYPOINT',
          'lat': pos.latitude,
          'lon': pos.longitude,
          'alt': wp['altitude'],
        };
      }),
    ];

    final message = 'WAYPOINTS:${jsonEncode(mission)}';

    try {
      final gcsService = ref.read(gcsServiceProvider);
      await gcsService.send(message);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🚀 Mission sent from current position.')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Failed to send: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final telemetry = ref.watch(telemetryProvider);
    final waypoints = ref.watch(waypointProvider);
    final mapType = ref.watch(mapProviderTypeProvider);

    final gmaps.LatLng? dronePos = telemetry != null
        ? gmaps.LatLng(telemetry.lat, telemetry.lon)
        : null;
    final latlng.LatLng leafletDronePos = dronePos != null
        ? latlng.LatLng(dronePos.latitude, dronePos.longitude)
        : const latlng.LatLng(0, 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Planner'),
        backgroundColor: Colors.grey[100],
        actions: [
          PopupMenuButton<MapProviderType>(
            onSelected: (type) => ref.read(mapProviderTypeProvider.notifier).state = type,
            itemBuilder: (context) => const [
              PopupMenuItem(value: MapProviderType.google, child: Text('Google Map')),
              PopupMenuItem(value: MapProviderType.leaflet, child: Text('Leaflet Map')),
            ],
            icon: const Icon(Icons.map),
          ),
          IconButton(icon: const Icon(Icons.save), onPressed: () => _saveWaypointsToFile(waypoints)),
          IconButton(icon: const Icon(Icons.folder_open), onPressed: _loadWaypointsFromFile),
          IconButton(icon: const Icon(Icons.delete_forever), onPressed: _clearWaypoints),
          IconButton(icon: const Icon(Icons.send), onPressed: _sendWaypointsToDrone),
        ],
      ),
      body: Stack(
        children: [
          Row(
            children: [
              Expanded(
                flex: 6,
                child: mapType == MapProviderType.google
                    ? Stack(
                        children: [
                          gmaps.GoogleMap(
                            mapType: _mapType,
                            zoomControlsEnabled: false,
                            initialCameraPosition: gmaps.CameraPosition(
                              target: dronePos ?? const gmaps.LatLng(0, 0),
                              zoom: 15,
                            ),
                            onMapCreated: (controller) => _mapController = controller,
                            onTap: _addWaypoint,
                            markers: {
                              ...waypoints.asMap().entries.map((e) {
                                final pos = e.value['position'] as gmaps.LatLng;
                                return gmaps.Marker(
                                  markerId: gmaps.MarkerId('wp${e.key}'),
                                  position: pos,
                                  icon: gmaps.BitmapDescriptor.defaultMarker,
                                  infoWindow: gmaps.InfoWindow(title: 'WP ${e.key + 1}'),
                                );
                              }),
                              if (dronePos != null)
                                gmaps.Marker(
                                  markerId: const gmaps.MarkerId('drone'),
                                  position: dronePos,
                                  rotation: telemetry?.hdg ?? 0,
                                  anchor: const Offset(0.5, 0.5),
                                  icon: _customDroneIcon ??
                                      gmaps.BitmapDescriptor.defaultMarkerWithHue(
                                        gmaps.BitmapDescriptor.hueBlue,
                                      ),
                                  infoWindow: const gmaps.InfoWindow(title: 'Drone'),
                                ),
                            },
                            polylines: {
                              gmaps.Polyline(
                                polylineId: const gmaps.PolylineId('route'),
                                points: waypoints.map((wp) => wp['position'] as gmaps.LatLng).toList(),
                                color: Colors.blue,
                                width: 3,
                              ),
                            },
                          ),
                          Positioned(
                            bottom: 85,
                            right: 16,
                            child: FloatingActionButton(
                              heroTag: 'toggle_map_type',
                              onPressed: _toggleGoogleMapType,
                              tooltip: 'Toggle Map Type',
                              child: const Icon(Icons.layers),
                            ),
                          ),
                          Positioned(
                            bottom: 16,
                            right: 16,
                            child: FloatingActionButton(
                              heroTag: 'locate_drone',
                              onPressed: () => _locateDrone(dronePos),
                              tooltip: 'Locate Drone',
                              child: const Icon(Icons.my_location),
                            ),
                          ),
                        ],
                      )
                    : FlutterMap(
                        options: MapOptions(
                          initialCenter: leafletDronePos,
                          initialZoom: 15,
                          onTap: (_, pos) => _addWaypoint(gmaps.LatLng(pos.latitude, pos.longitude)),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.app',
                          ),
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: waypoints.map((wp) {
                                  final p = wp['position'] as gmaps.LatLng;
                                  return latlng.LatLng(p.latitude, p.longitude);
                                }).toList(),
                                strokeWidth: 4.0,
                                color: Colors.blue,
                              ),
                            ],
                          ),
                          MarkerLayer(
                            markers: [
                              ...waypoints.asMap().entries.map((e) {
                                final pos = e.value['position'] as gmaps.LatLng;
                                return Marker(
                                  point: latlng.LatLng(pos.latitude, pos.longitude),
                                  width: 40,
                                  height: 40,
                                  child: const Icon(Icons.place, color: Colors.red),
                                );
                              }),
                              Marker(
                                point: leafletDronePos,
                                width: 50,
                                height: 50,
                                child: const Icon(Icons.flight, color: Colors.blue),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
              Expanded(
                flex: 4,
                child: Container(
                  color: Colors.grey[200],
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Waypoints:", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          itemCount: waypoints.length,
                          itemBuilder: (context, i) {
                            final wp = waypoints[i];
                            final gmaps.LatLng pos = wp['position'];
                            final double alt = wp['altitude'];
                            return ListTile(
                              leading: CircleAvatar(child: Text('${i + 1}')),
                              title: Text(
                                'Lat: ${pos.latitude.toStringAsFixed(6)}\n'
                                'Lon: ${pos.longitude.toStringAsFixed(6)}\n'
                                'Alt: ${alt.toStringAsFixed(1)} m',
                                style: const TextStyle(fontSize: 14),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red, size: 30),
                                onPressed: () => ref.read(waypointProvider.notifier).remove(i),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Positioned(
            left: 16,
            bottom:16,
            child: FloatingNavMenu(),
          ),
        ],
      ),
    );
  }
}
