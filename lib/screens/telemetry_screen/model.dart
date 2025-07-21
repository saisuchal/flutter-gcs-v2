class TelemetryData {
  final double lat;
  final double lon;
  final double alt;
  final int vx;
  final int vy;
  final int vz;
  final double hdg;

  const TelemetryData({
    required this.lat,
    required this.lon,
    required this.alt,
    required this.vx,
    required this.vy,
    required this.vz,
    required this.hdg,
  });
}
