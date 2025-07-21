import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:usb_serial/usb_serial.dart';
import 'package:flutter_gcs/src/provider/provider.dart';
import 'package:flutter_gcs/src/mavlink/mavlink_parser.dart';
import 'package:flutter_gcs/src/services/gcs_service.dart';

class USBService implements GCSService {
  final Ref ref;
  UsbPort? _port;
  StreamSubscription<Uint8List>? _subscription;
  late final MavlinkParser _parser;

  USBService(this.ref) {
    final telemetryController = ref.read(telemetryProvider.notifier);
    _parser = MavlinkParser(telemetryController);
  }

  @override
  Future<void> connect() async {
    final devices = await UsbSerial.listDevices();

    if (devices.isEmpty) {
      print("❌ [USB] No USB devices found.");
      ref.read(usbConnectionStatusProvider.notifier).state = 'disconnected';
      return;
    }

    final device = devices.first;

    // 🔄 Try to open the port directly (assumes permission is granted via Manifest)
    final port = await device.create();
    if (port == null || !(await port.open())) {
      print("❌ [USB] Failed to open port. Possibly permission denied.");
      ref.read(usbConnectionStatusProvider.notifier).state = 'disconnected';
      return;
    }

    _port = port;

    await _port!.setDTR(true);
    await _port!.setRTS(true);
    await _port!.setPortParameters(
      57600,
      UsbPort.DATABITS_8,
      UsbPort.STOPBITS_1,
      UsbPort.PARITY_NONE,
    );

    print("✅ [USB] Connected to ${device.productName}");
    ref.read(usbConnectionStatusProvider.notifier).state = 'connected';

    _subscription = _port!.inputStream?.listen(
      _handleData,
      onError: (e) {
        print("❌ [USB] Read error: $e");
        ref.read(usbConnectionStatusProvider.notifier).state = 'disconnected';
      },
    );
  }

  void _handleData(Uint8List data) {
    print("📥 [USB] Received ${data.length} bytes");
    _parser.parseBytes(data);
  }

  @override
  Future<void> send(String message) async {
    if (_port == null) {
      print("⚠️ [USB] Not connected — cannot send");
      return;
    }

    final data = Uint8List.fromList(utf8.encode('$message\n'));
    await _port!.write(data);
    print("📤 [USB] Sent: $message");
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _port?.close();
    _port = null;
    ref.read(usbConnectionStatusProvider.notifier).state = 'disconnected';
    print("🛑 [USB] Disconnected and cleaned up.");
  }
}
