abstract class GCSService {
  Future<void> connect();
  Future<void> send(String message);
  void dispose();
}
