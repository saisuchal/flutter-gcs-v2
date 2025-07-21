import 'dart:typed_data';
import 'package:flutter_gcs/screens/telemetry_screen/model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MavlinkParser {
  final StateController<TelemetryData?> telemetryController;

  MavlinkParser(this.telemetryController);

  static const int mavlinkV1Header = 0xFE;
  static const int mavlinkV2Header = 0xFD;

  static const int globalPositionIntMsgId = 33;
  static const int heartbeatMsgId = 0;

  List<int> _buffer = [];

  void parseBytes(Uint8List incoming) {
    _buffer.addAll(incoming);

    while (_buffer.length >= 8) {
      int header = _buffer[0];

      if (header == mavlinkV1Header && _buffer.length >= 8) {
        int payloadLength = _buffer[1];
        int fullLength = 6 + payloadLength + 2;

        if (_buffer.length < fullLength) break;

        List<int> frame = _buffer.sublist(0, fullLength);
        _buffer = _buffer.sublist(fullLength);

        _parseMavlinkV1(Uint8List.fromList(frame));
      } else if (header == mavlinkV2Header && _buffer.length >= 10) {
        int payloadLength = _buffer[1];
        int fullLength = 10 + payloadLength + 2;

        if (_buffer.length < fullLength) break;

        List<int> frame = _buffer.sublist(0, fullLength);
        _buffer = _buffer.sublist(fullLength);

        _parseMavlinkV2(Uint8List.fromList(frame));
      } else {
        print("⚠️ Unknown header: 0x${header.toRadixString(16)}");
        _buffer.removeAt(0);
      }
    }
  }

  void _parseMavlinkV1(Uint8List frame) {
    int payloadLength = frame[1];
    int sysId = frame[3];
    int compId = frame[4];
    int msgId = frame[5];

    Uint8List payload = frame.sublist(6, 6 + payloadLength);
    _dispatch(msgId, payload, sysId, compId);
  }

  void _parseMavlinkV2(Uint8List frame) {
    int payloadLength = frame[1];
    int sysId = frame[5];
    int compId = frame[6];
    int msgId = frame[7] | (frame[8] << 8) | (frame[9] << 16);

    Uint8List payload = frame.sublist(10, 10 + payloadLength);
    _dispatch(msgId, payload, sysId, compId);
  }

  void _dispatch(int msgId, Uint8List payload, int sysId, int compId) {
    switch (msgId) {
      case heartbeatMsgId:
        break;
      case globalPositionIntMsgId:
        if (payload.length < 28) {
          print("❌ GLOBAL_POSITION_INT payload too short");
          return;
        }
        _handleGlobalPositionInt(payload, sysId, compId);
        break;
      default:
        break;
    }
  }

  void _handleGlobalPositionInt(Uint8List payload, int sysId, int compId) {
    int lat = _readInt32LE(payload, 4);
    int lon = _readInt32LE(payload, 8);
    int alt = _readInt32LE(payload, 12);
    int vx = _readInt16LE(payload, 20);
    int vy = _readInt16LE(payload, 22);
    int vz = _readInt16LE(payload, 24);
    int hdg = _readUint16LE(payload, 26);

    final telemetry = TelemetryData(
      lat: lat / 1e7,
      lon: lon / 1e7,
      alt: alt / 1000,
      vx: vx,
      vy: vy,
      vz: vz,
      hdg: hdg / 100.0,
    );

    telemetryController.state = telemetry;

    // print('🌍 GLOBAL_POSITION_INT → sys:$sysId comp:$compId');
    // print(
    //   'lat: ${lat / 1e7}, lon: ${lon / 1e7}, alt: ${alt / 1000}m, '
    //   'vx: $vx, vy: $vy, vz: $vz, hdg: ${hdg / 100}',
    // );
  }

  int _readUint32LE(Uint8List data, int offset) {
    final b = ByteData.sublistView(data, offset, offset + 4);
    return b.getUint32(0, Endian.little);
  }

  int _readInt32LE(Uint8List data, int offset) {
    final b = ByteData.sublistView(data, offset, offset + 4);
    return b.getInt32(0, Endian.little);
  }

  int _readUint16LE(Uint8List data, int offset) {
    final b = ByteData.sublistView(data, offset, offset + 2);
    return b.getUint16(0, Endian.little);
  }

  int _readInt16LE(Uint8List data, int offset) {
    final b = ByteData.sublistView(data, offset, offset + 2);
    return b.getInt16(0, Endian.little);
  }
}
