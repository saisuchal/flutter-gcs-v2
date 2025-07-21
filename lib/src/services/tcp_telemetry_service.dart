import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gcs/src/provider/provider.dart';
import 'package:flutter_gcs/src/mavlink/mavlink_parser.dart';

class TCPTelemetryService {
  final Ref ref;
  Socket? _socket;
  late final MavlinkParser _parser;
  bool _reconnecting = false;

  TCPTelemetryService(this.ref) {
    final telemetryController = ref.read(telemetryProvider.notifier);
    _parser = MavlinkParser(telemetryController);
  }

  Future<void> connect({required String host, required int port}) async {
    try {
      _socket = await Socket.connect(host, port);
      print('✅ [TCP TELEMETRY] Connected to $host:$port');

      _socket!.listen(
        (Uint8List data) {
          _parser.parseBytes(data);
        },
        onDone: () {
          print('🔌 [TCP TELEMETRY] Connection closed');
          _attemptReconnect(host, port);
        },
        onError: (e) {
          print('❌ [TCP TELEMETRY] Error: $e');
          _attemptReconnect(host, port);
        },
        cancelOnError: true,
      );
    } catch (e) {
      print('❌ [TCP TELEMETRY] Could not connect → $e');
      _attemptReconnect(host, port);
    }
  }

  void _attemptReconnect(String host, int port) {
    if (_reconnecting) return;
    _reconnecting = true;

    Future.delayed(const Duration(seconds: 5), () {
      _reconnecting = false;
      print('🔁 [TCP TELEMETRY] Attempting to reconnect...');
      connect(host: host, port: port);
    });
  }

  void disconnect() {
    _socket?.destroy();
    print('🛑 [TCP TELEMETRY] Disconnected');
  }
}
