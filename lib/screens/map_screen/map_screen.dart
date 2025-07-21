// import 'package:flutter/material.dart';
// import 'package:flutter_gcs/bottom_navigation_bar.dart';
// import 'package:flutter_gcs/screens/telemetry_screen/model.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import '../telemetry_screen/telemetry.dart'; // Adjust if needed
// import '../../src/provider/provider.dart';

// class HomeScreen extends ConsumerStatefulWidget {

//   HomeScreen({super.key});
  
//   @override
//   ConsumerState<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends ConsumerState<HomeScreen> {
//   BitmapDescriptor? _droneIcon;
//   GoogleMapController? _mapController;

//   @override
//   void initState() {
//     super.initState();
//     _loadCustomMarker();
//   }

//   void _loadCustomMarker() async {
//     _droneIcon = await BitmapDescriptor.asset(
//       const ImageConfiguration(size: Size(48, 48)),
//       'assets/icons/drone.png',
//     );
//     setState(() {}); // Rebuild with marker
//   }

//   @override
// Widget build(BuildContext context) {

//   final telemetry = ref.watch(telemetryProvider);
//   final LatLng? dronePosition = telemetry != null
//     ? LatLng(telemetry.lat, telemetry.lon)
//     : null;

// ref.listen<TelemetryData?>(telemetryProvider, (previous, next) {
//   if (next != null) {
//     final dronePosition = LatLng(next.lat, next.lon);
//     _mapController?.animateCamera(CameraUpdate.newLatLng(dronePosition));
//   }
// });

//   return Scaffold(
//     appBar: AppBar(
//       title: const Text('Flutter GCS'),
//       // actions: [
//       //   TextButton(
//       //     onPressed: () {
//       //       Navigator.push(
//       //         context,
//       //         MaterialPageRoute(builder: (context) => const Telemetry()),
//       //       );
//       //     },
//       //     child: const Text('Connect', style: TextStyle(color: Colors.white)),
//       //   ),
//       // ],
//     ),
//     body: GoogleMap(
//       initialCameraPosition: CameraPosition(
//         target: dronePosition ?? const LatLng(0, 0),
//         zoom: 15,
//       ),
//       markers: {
//         Marker(
//           markerId: const MarkerId('drone'),
//           position: dronePosition ?? const LatLng(0, 0),
//           infoWindow: const InfoWindow(title: 'Drone'),
//           icon: _droneIcon ?? BitmapDescriptor.defaultMarker,
//         ),
//       },
//       onMapCreated: (controller) {
//         _mapController = controller;
//       },
//       myLocationEnabled: true,
//       compassEnabled: true,
//     ),
//   );
// }

// }


import 'package:flutter/material.dart';
import 'package:flutter_gcs/widgets/floating_nav_menu.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../src/provider/provider.dart';
import 'google_map_view.dart';
import 'leaflet_map_view.dart';

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(mapProviderTypeProvider);

    Widget view = switch (selected) {
      MapProviderType.google => const GoogleMapView(),
      MapProviderType.leaflet => const LeafletMapView(),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text("Map View"), backgroundColor: Colors.grey[100],
        actions: [
          Padding(
            padding: const EdgeInsets.only(right:24.0),
            child: DropdownButton<MapProviderType>(
              value: selected,
              items: const [
                DropdownMenuItem(value: MapProviderType.google, child: Text('Google')),
                DropdownMenuItem(value: MapProviderType.leaflet, child: Text('Leaflet')),
              ],
              onChanged: (val) => ref.read(mapProviderTypeProvider.notifier).state = val!,
            ),
          ),
        ],
      ),
      body: Stack(
      children: [
        view,
        const FloatingNavMenu(), // ← add here
      ],
    ),
    );
  }
}
