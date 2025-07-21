import 'dart:io';

class DronekitService {
  final String host;
  final int port;

  DronekitService({this.host = '10.0.2.2', this.port = 6000});

  Future<void> send(String command) async {
    try {
      final socket = await Socket.connect(host, port);
      print("📤 Sent DroneKit command: $command");
      socket.write('$command\n');
      await socket.flush();

      socket.listen(
        (data) {
          final response = String.fromCharCodes(data).trim();
          print("📩 DroneKit server response: $response");

          if (response.startsWith("OK")) {
            // Success — optionally notify UI
          } else {
            // Error — optionally handle failure
          }

          socket.destroy();
        },
        onError: (e) {
          print("❌ Socket error: $e");
          socket.destroy();
        },
        onDone: () {
          print("🔌 DroneKit command socket closed");
        },
      );
    } catch (e) {
      print("❌ Failed to send DroneKit command: $e");
    }
  }
}
