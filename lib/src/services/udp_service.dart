import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_gcs/src/mavlink/mavlink_parser.dart';
import 'package:flutter_gcs/src/provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'gcs_service.dart';

class UDPService implements GCSService {
  RawDatagramSocket? _socket;
  late final MavlinkParser _parser;
  final Ref ref;
  InternetAddress? _lastSender;
  int? _lastSenderPort;

  UDPService(this.ref) {
    final telemetryController = ref.read(telemetryProvider.notifier);
    _parser = MavlinkParser(telemetryController);
  }

  @override
  Future<void> connect({int port = 14550}) async {
    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
      print('📡 UDP listening on 0.0.0.0:$port');

      _socket!.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = _socket!.receive();
          if (datagram != null) {
            _lastSender = datagram.address;
            _lastSenderPort = datagram.port;
            _parser.parseBytes(datagram.data);
          }
        }
      });
    } catch (e) {
      print('❌ UDP socket error: $e');
    }
  }

  @override
  Future<void> send(String message) async {
    final data = Uint8List.fromList(utf8.encode('$message\n'));
    if (_lastSender != null && _lastSenderPort != null) {
      _socket?.send(data, _lastSender!, _lastSenderPort!);
      print("📤 Sent via UDP: $message");
    } else {
      print("⚠️ No known destination for UDP send.");
    }
  }

  @override
  void dispose() {
    _socket?.close();
    _socket = null;
    print('🛑 UDP listener closed');
  }
}


// import 'dart:io';
// import 'dart:typed_data';
// import 'package:flutter_gcs/src/mavlink/mavlink_parser.dart';
// import 'package:flutter_gcs/src/provider/provider.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// class UDPService {
//   RawDatagramSocket? _socket;
//   late final MavlinkParser _parser;
//   final Ref ref;
//   UDPService(this.ref) {
//     final telemetryController = ref.read(telemetryProvider.notifier);
//     _parser = MavlinkParser(telemetryController);
//   }

//   Future<void> startListening({int port = 14550}) async {
//     try {
//       _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
//       print('📡 UDP listening on 0.0.0.0:$port');

//       _socket!.listen((event) {
//         if (event == RawSocketEvent.read) {
//           final datagram = _socket!.receive();
//           if (datagram != null) {
//             final data = datagram.data;
//             _parser.parseBytes(data);
//           }
//         }
//       });
//     } catch (e) {
//       print('❌ UDP socket error: $e');
//     }
//   }

//   void stop() {
//     _socket?.close();
//     print('🛑 UDP listener closed');
//   }
// }


