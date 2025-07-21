import 'package:flutter/cupertino.dart';
import 'package:flutter_gcs/src/services/gcs_service.dart';
import 'package:flutter_gcs/src/services/tcp_command_service.dart';
import 'package:flutter_gcs/src/services/tcp_telemetry_service.dart';
import 'package:flutter_gcs/src/services/udp_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gcs/src/services/tcp_service.dart';
import 'package:flutter_gcs/src/services/usb_service.dart';
import '../../screens/telemetry_screen/model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;


/// Holds current telemetry data parsed from MAVLink
final telemetryProvider = StateProvider<TelemetryData?>((ref) => null);

/// Provides TCP service instance
final tcpServiceProvider = Provider<TCPService>((ref) {
  return TCPService(ref);
});

/// Provides USB service instance
final usbServiceProvider = Provider<USBService>((ref) {
  return USBService(ref);
});

/// Provides USB service instance
final udpServiceProvider = Provider<UDPService>((ref) {
  return UDPService(ref);
});

final telemetryTcpServiceProvider = Provider((ref) => TCPTelemetryService(ref));
final commandTcpServiceProvider = Provider((ref) => TCPCommandService());

/// IP and port entered by user (shared between telemetry + command TCP services)
final tcpHostProvider = StateProvider<String>((ref) => '10.0.2.2');
final tcpPortProvider = StateProvider<int>((ref) => 5762);

/// Indicates whether device is physical (wireless TCP) or emulator
final isWirelessProvider = StateProvider<bool>((ref) => true);


final gcsServiceProvider = Provider<GCSService>((ref) {
  final selected = ref.watch(selectedProtocolProvider);
  switch (selected) {
    case SelectedProtocol.tcp:
      return ref.watch(tcpServiceProvider);
    case SelectedProtocol.udp:
      return ref.watch(udpServiceProvider);
    case SelectedProtocol.usb:
      return ref.watch(usbServiceProvider);
    case SelectedProtocol.wirelessTcp:
      return ref.watch(tcpServiceProvider);
  }
  // throw UnimplementedError('Selected protocol $selected is not implemented in gcsServiceProvider.');
});

/// Enum for protocol selection
enum SelectedProtocol {
  usb,
  tcp,
  udp,
  wirelessTcp,
}

/// Tracks the currently selected connection protocol
final selectedProtocolProvider = StateProvider<SelectedProtocol>(
  (ref) => SelectedProtocol.tcp,
);



enum MapProviderType {
  google,
  leaflet,
}

final mapProviderTypeProvider = StateProvider<MapProviderType>((ref) => MapProviderType.google);

final googleMapTypeProvider = StateProvider<gmaps.MapType>((ref) => gmaps.MapType.normal);

/// Waypoints list for mission planning
final waypointProvider = StateNotifierProvider<WaypointNotifier, List<Map<String, dynamic>>>(
  (ref) => WaypointNotifier(),
);

class WaypointNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  WaypointNotifier() : super([]);

  void add(gmaps.LatLng position) {
    state = [...state, {'position': position, 'altitude': 10.0}];
  }

  void remove(int index) {
    final updated = [...state]..removeAt(index);
    state = updated;
  }

  void clear() {
    state = [];
  }

  void set(List<Map<String, dynamic>> newWaypoints) {
    state = newWaypoints;
  }
}


final showMissionOverlayProvider = StateProvider<bool>((ref) => false);

/// USB connection status
final usbConnectionStatusProvider = StateProvider<String>((ref) => 'disconnected');
