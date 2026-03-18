import 'dart:math' as _dartMath;
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:share_plus/share_plus.dart';

import 'motor_schema.dart';

class OrientationScreen extends StatefulWidget {
  const OrientationScreen({super.key});

  @override
  State<OrientationScreen> createState() => _OrientationScreenState();
}

class _OrientationScreenState extends State<OrientationScreen> {
  static const int countdownDuration = 5;
  static const int recordingDuration = 10;

  bool isCountingDown = false;
  bool isRecording = false;

  int countdownValue = countdownDuration;
  String statusText = 'Press Start to begin';

  final List<MotorSample> samples = [];
  DateTime startedAt = DateTime.now();

  File? lastExportFile;
  String exportStatus = '';

  StreamSubscription<GyroscopeEvent>? _gyroscopeSub;
  StreamSubscription<AccelerometerEvent>? _accelerometerSub;
  Timer? _countdownTimer;
  Timer? _recordingTimer;
  Timer? _sampleTimer;

  // We use these latest sensor values to create samples at a fixed rate.
  AccelerometerEvent? _latestAccelerometer;
  GyroscopeEvent? _latestGyroscope;

  // These are approximations for display / export.
  double currentPitch = 0.0;
  double currentRoll = 0.0;
  double currentYaw = 0.0;

  @override
  void dispose() {
    _stopAllTimersAndStreams();
    super.dispose();
  }

  void beginSession() {
    _stopAllTimersAndStreams();

    setState(() {
      isCountingDown = true;
      isRecording = false;
      countdownValue = countdownDuration;
      statusText = 'Hold the phone still.\nRecording begins soon.';

      samples.clear();
      startedAt = DateTime.now();
      lastExportFile = null;
      exportStatus = '';

      currentPitch = 0.0;
      currentRoll = 0.0;
      currentYaw = 0.0;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      if (countdownValue > 1) {
        setState(() {
          countdownValue--;
        });
      } else {
        timer.cancel();
        setState(() {
          countdownValue = 0;
          isCountingDown = false;
        });
        _startRecording();
      }
    });
  }

  void _startRecording() {
    startedAt = DateTime.now();

    setState(() {
      isRecording = true;
      statusText = 'Recording... Hold the phone still.';
    });

    _accelerometerSub = accelerometerEvents.listen((event) {
      _latestAccelerometer = event;
    });

    _gyroscopeSub = gyroscopeEvents.listen((event) {
      _latestGyroscope = event;
    });

    // Fixed-rate sampling at 10 Hz.
    _sampleTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted || !isRecording) return;
      _captureSample();
    });

    _recordingTimer = Timer(Duration(seconds: recordingDuration), () {
      if (!mounted) return;
      stopRecording();
    });
  }

  void _captureSample() {
    final accel = _latestAccelerometer;
    final gyro = _latestGyroscope;

    if (accel == null || gyro == null) return;

    final elapsed =
        DateTime.now().difference(startedAt).inMilliseconds / 1000.0;

    // Simple approximations:
    // roll and pitch from accelerometer, yaw integrated from gyro.z
    final ax = accel.x;
    final ay = accel.y;
    final az = accel.z;

    final pitch = (ax == 0 && ay == 0 && az == 0)
    ? 0.0
    : _dartMath.atan2(-ax, _dartMath.sqrt(ay * ay + az * az));

    final roll = (ay == 0 && az == 0)
      ? 0.0
      : _dartMath.atan2(ay, az);

    // Approximate yaw by integrating gyro z over sample interval (0.1s).
    currentYaw += gyro.z * 0.1;

    currentPitch = pitch;
    currentRoll = roll;

    setState(() {
      samples.add(
        MotorSample(
          time: elapsed,
          pitch: currentPitch,
          roll: currentRoll,
          yaw: currentYaw,
        ),
      );
    });
  }

  void stopRecording() {
    _sampleTimer?.cancel();
    _recordingTimer?.cancel();
    _accelerometerSub?.cancel();
    _gyroscopeSub?.cancel();

    setState(() {
      isRecording = false;
      statusText = 'Session complete. You may now export the data.';
    });
  }

  void _stopAllTimersAndStreams() {
    _countdownTimer?.cancel();
    _recordingTimer?.cancel();
    _sampleTimer?.cancel();
    _accelerometerSub?.cancel();
    _gyroscopeSub?.cancel();
  }

  Future<void> exportSession() async {
    if (samples.isEmpty) return;

    final session = MotorSessionExport(
      activity: 'orientation',
      platform: 'android',
      startedAt: startedAt,
      sessionDuration: recordingDuration.toDouble(),
      sampleCount: samples.length,
      samples: samples,
    );

    final prettyJson =
        const JsonEncoder.withIndent('  ').convert(session.toJson());

    try {
      final dir = await getApplicationDocumentsDirectory();
      final filename =
          'orientation_session_${DateTime.now().toUtc().toIso8601String()}'
              .replaceAll(':', '-') +
              '.json';

      final file = File('${dir.path}/$filename');
      await file.writeAsString(prettyJson);

      setState(() {
        lastExportFile = file;
        exportStatus = 'Exported: $filename';
      });
    } catch (e) {
      setState(() {
        exportStatus = 'Export failed: $e';
      });
    }
  }

  Future<void> shareExport() async {
    final file = lastExportFile;
    if (file == null) return;

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Signals to Pathways – Orientation Session Export',
    );
  }

  @override
  Widget build(BuildContext context) {
    final canExport = samples.isNotEmpty && !isCountingDown && !isRecording;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orientation Activity'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              statusText,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 16),

            if (isCountingDown)
              Text(
                '$countdownValue',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('Pitch: ${currentPitch.toStringAsFixed(3)}'),
                    const SizedBox(height: 8),
                    Text('Roll: ${currentRoll.toStringAsFixed(3)}'),
                    const SizedBox(height: 8),
                    Text('Yaw: ${currentYaw.toStringAsFixed(3)}'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: (isCountingDown || isRecording)
                        ? null
                        : beginSession,
                    child: const Text('Start Session'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isRecording ? stopRecording : null,
                    child: const Text('Stop Session'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: canExport ? exportSession : null,
                    child: const Text('Export Session'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: lastExportFile != null ? shareExport : null,
                    child: const Text('Share Export File'),
                  ),
                ),
              ],
            ),

            if (exportStatus.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                exportStatus,
                style: const TextStyle(color: Colors.black54),
              ),
            ],

            const SizedBox(height: 20),

            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    'Hold the phone as still as possible',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: ListView.builder(
                itemCount: samples.length,
                itemBuilder: (context, i) {
                  final s = samples[i];
                  return Text(
                    'Sample ${i + 1}: '
                    't=${s.time.toStringAsFixed(3)}s '
                    'p=${(s.pitch ?? 0).toStringAsFixed(3)} '
                    'r=${(s.roll ?? 0).toStringAsFixed(3)} '
                    'y=${(s.yaw ?? 0).toStringAsFixed(3)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Small helpers

double _safeAtan2(double y, double x) {
  return x == 0 && y == 0 ? 0.0 : atan2Approx(y, x);
}

// Lightweight atan2 approximation wrapper.
double atan2Approx(double y, double x) {
  return mathAtan2(y, x);
}

// Separate function so the code stays readable.
double mathAtan2(double y, double x) {
  return _Math.atan2(y, x);
}

extension _SqrtApprox on double {
  double sqrtApprox() => _Math.sqrt(this);
}

// Minimal math wrapper so you only need one file import set.
class _Math {
  static double atan2(double y, double x) {
    return _dartMath.atan2(y, x);
  }

  static double sqrt(double x) {
    return _dartMath.sqrt(x);
  }
}