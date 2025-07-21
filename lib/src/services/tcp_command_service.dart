import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gcs/src/provider/provider.dart';

class TCPCommandService {
  Socket? _socket;
  bool _connected = false;

  /// Establish connection manually before sending
  Future<void> connect({
    required String host,
    required int port,
  }) async {
    try {
      _socket = await Socket.connect(host, port);
      _connected = true;
      print('✅ [TCP CMD] Connected to $host:$port');
    } catch (e) {
      _connected = false;
      print('❌ [TCP CMD] Connection failed: $e');
      rethrow;
    }
  }

  /// Simplified connect using providers (for unified flow)
  Future<void> connectFromRef(WidgetRef ref) async {
  final isWireless = ref.read(isWirelessProvider);
  final host = isWireless ? ref.read(tcpHostProvider) : '10.0.2.2';
  const port = 6000;

  await connect(host: host, port: port);
}


  Future<void> send(String message) async {
    if (_socket == null || !_connected) {
      print('⚠️ [TCP CMD] Not connected — cannot send command.');
      return;
    }

    _socket!.write('$message\n');
    await _socket!.flush();
    print('📤 [TCP CMD] Sent: $message');
  }

  void dispose() {
    _socket?.destroy();
    _socket = null;
    _connected = false;
    print('🛑 [TCP CMD] Disconnected');
  }
}
