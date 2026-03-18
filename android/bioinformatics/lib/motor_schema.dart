class MotorSample {
  final double time;

  // Touch-based samples
  final double? x;
  final double? y;
  final String? phase;

  // Orientation-based samples
  final double? pitch;
  final double? roll;
  final double? yaw;

  MotorSample({
    required this.time,
    this.x,
    this.y,
    this.phase,
    this.pitch,
    this.roll,
    this.yaw,
  });

  Map<String, dynamic> toJson() => {
        'time': time,
        'x': x,
        'y': y,
        'phase': phase,
        'pitch': pitch,
        'roll': roll,
        'yaw': yaw,
      }..removeWhere((key, value) => value == null);
}

class MotorSessionExport {
  final String activity;
  final String platform;
  final DateTime startedAt;
  final double sessionDuration;
  final int sampleCount;
  final List<MotorSample> samples;

  MotorSessionExport({
    required this.activity,
    required this.platform,
    required this.startedAt,
    required this.sessionDuration,
    required this.sampleCount,
    required this.samples,
  });

  Map<String, dynamic> toJson() => {
        'activity': activity,
        'platform': platform,
        'startedAt': startedAt.toUtc().toIso8601String(),
        'sessionDuration': sessionDuration,
        'sampleCount': sampleCount,
        'samples': samples.map((e) => e.toJson()).toList(),
      };
}