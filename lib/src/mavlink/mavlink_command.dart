import 'dart:typed_data';

class MavlinkCommand {
  static Uint8List long({
    required int command,
    List<double> params = const [0, 0, 0, 0, 0, 0, 0],
    int targetSystem = 1,
    int targetComponent = 1,
    bool confirm = false,
  }) {
    final payload = ByteData(33);
    for (int i = 0; i < 7; i++) {
      payload.setFloat32(i * 4, i < params.length ? params[i] : 0, Endian.little);
    }

    payload.setUint8(28, targetSystem);
    payload.setUint8(29, targetComponent);
    payload.setUint16(30, command, Endian.little);
    payload.setUint8(32, confirm ? 1 : 0);

    final header = [
      0xFE, // MAVLink v1 header
      33,   // Payload length
      0,    // Seq
      targetSystem,
      targetComponent,
      76    // Message ID for COMMAND_LONG
    ];

    return Uint8List.fromList([
      ...header,
      ...payload.buffer.asUint8List(),
    ]);
  }

  static Uint8List setMode({
    int targetSystem = 1,
    required int baseMode,
    required int customMode,
  }) {
    final payload = ByteData(6);
    payload.setUint8(0, targetSystem);
    payload.setUint8(1, baseMode);
    payload.setUint32(2, customMode, Endian.little);

    final header = [
      0xFE,
      6,
      0,
      targetSystem,
      1,
      11, // SET_MODE msgid
    ];

    return Uint8List.fromList([
      ...header,
      ...payload.buffer.asUint8List(),
    ]);
  }
}
