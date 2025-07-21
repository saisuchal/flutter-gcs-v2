import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_gcs/src/mavlink/mavlink_parser.dart';
import 'package:flutter_gcs/src/provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gcs/src/services/gcs_service.dart'; // Import the interface

class TCPService implements GCSService {
  Socket? _socket;
  late final MavlinkParser _parser;
  bool _reconnecting = false;

  TCPService(Ref ref) {
    final telemetryController = ref.read(telemetryProvider.notifier);
    _parser = MavlinkParser(telemetryController);
  }

  @override
  Future<void> start() async {
    await connect();
  }

  Future<void> connect({String host = '10.0.2.2', int port = 5762}) async {
    try {
      _socket = await Socket.connect(host, port);
      print('✅ Connected to TCP $host:$port');

      _socket!.listen(
        (Uint8List data) {
          _parser.parseBytes(data);
        },
        onDone: () {
          print('🔌 TCP connection closed');
          _attemptReconnect(host, port);
        },
        onError: (e) {
          print('❌ TCP error: $e');
          _attemptReconnect(host, port);
        },
        cancelOnError: true,
      );
    } catch (e) {
      print('❌ Could not connect to TCP $host:$port → $e');
      _attemptReconnect(host, port);
    }
  }

  void _attemptReconnect(String host, int port) {
    if (_reconnecting) return;
    _reconnecting = true;
    Future.delayed(const Duration(seconds: 5), () {
      _reconnecting = false;
      print('🔁 Attempting to reconnect...');
      connect(host: host, port: port);
    });
  }

  @override
Future<void> send(String message) async {
  _socket?.write('$message\n');
  await _socket?.flush();
}

  @override
  void stop() {
    disconnect();
  }

  @override
  void dispose() {
    stop(); // or directly: _socket?.destroy();
  }

  void disconnect() {
    _socket?.destroy();
    print('🛑 TCP disconnected');
  }
}
