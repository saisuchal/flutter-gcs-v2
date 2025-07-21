import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../src/provider/provider.dart';

class TelemetryOverlay extends ConsumerWidget {
  const TelemetryOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final telemetry = ref.watch(telemetryProvider);

    if (telemetry == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(8),
      width: 150,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.white, fontSize: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lat: ${telemetry.lat.toStringAsFixed(6)}'),
            Text('Lon: ${telemetry.lon.toStringAsFixed(6)}'),
            Text('Alt: ${telemetry.alt.toStringAsFixed(1)} m'),
            Text('Vx: ${telemetry.vx}'),
            Text('Vy: ${telemetry.vy}'),
            Text('Vz: ${telemetry.vz}'),
            Text('Hdg: ${telemetry.hdg}°'),
          ],
        ),
      ),
    );
  }
}
