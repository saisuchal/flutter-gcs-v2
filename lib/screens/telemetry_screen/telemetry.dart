import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'model.dart';
import '../../src/provider/provider.dart';

class TelemetryView extends ConsumerWidget {
  const TelemetryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final telemetry = ref.watch(telemetryProvider);

    if (telemetry == null) {
      return const Text('Waiting for telemetry...');
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Telemetry Data'),backgroundColor: Colors.grey[100],
      ),
      body: Container(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Latitude: ${telemetry.lat}', style: TextStyle(fontSize: 20)),
          Text('Longitude: ${telemetry.lon}', style: TextStyle(fontSize: 20)),
          Text('Altitude: ${telemetry.alt} m', style: TextStyle(fontSize: 20)),
          Text('Vx: ${telemetry.vx} m/s', style: TextStyle(fontSize: 20)),
          Text('Vy: ${telemetry.vy} m/s', style: TextStyle(fontSize: 20)),
          Text('Vz: ${telemetry.vz} m/s', style: TextStyle(fontSize: 20)),
          Text('Heading: ${telemetry.hdg}°', style: TextStyle(fontSize: 20)),
        ],
      ),
    )
    );
    
    
    
    
  }
}
