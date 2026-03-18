import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'motor_schema.dart';

class SwipingScreen extends StatefulWidget {
  const SwipingScreen({super.key});

  @override
  State<SwipingScreen> createState() => _SwipingScreenState();
}

class _SwipingScreenState extends State<SwipingScreen> {
  int swipeCount = 0;
  bool isRunning = false;

  final List<MotorSample> samples = [];
  DateTime startedAt = DateTime.now();

  Offset? dragStart;
  Offset? dragCurrent;

  File? lastExportFile;
  String exportStatus = '';

  void startSession() {
    setState(() {
      swipeCount = 0;
      isRunning = true;
      samples.clear();
      startedAt = DateTime.now();
      dragStart = null;
      dragCurrent = null;
      lastExportFile = null;
      exportStatus = '';
    });
  }

  void stopSession() {
    setState(() {
      isRunning = false;
      dragStart = null;
      dragCurrent = null;
    });
  }

  void handlePanStart(DragStartDetails details, Size swipeAreaSize) {
    if (!isRunning) return;
    if (swipeAreaSize.width <= 0 || swipeAreaSize.height <= 0) return;

    final localPos = details.localPosition;
    final normalizedX = (localPos.dx / swipeAreaSize.width).clamp(0.0, 1.0);
    final normalizedY = (localPos.dy / swipeAreaSize.height).clamp(0.0, 1.0);
    final elapsed =
        DateTime.now().difference(startedAt).inMilliseconds / 1000.0;

    setState(() {
      dragStart = localPos;
      dragCurrent = localPos;

      samples.add(
        MotorSample(
          time: elapsed,
          x: normalizedX,
          y: normalizedY,
          phase: 'began',
        ),
      );
    });
  }

  void handlePanUpdate(DragUpdateDetails details, Size swipeAreaSize) {
    if (!isRunning) return;
    if (swipeAreaSize.width <= 0 || swipeAreaSize.height <= 0) return;

    final localPos = details.localPosition;
    final normalizedX = (localPos.dx / swipeAreaSize.width).clamp(0.0, 1.0);
    final normalizedY = (localPos.dy / swipeAreaSize.height).clamp(0.0, 1.0);
    final elapsed =
        DateTime.now().difference(startedAt).inMilliseconds / 1000.0;

    setState(() {
      dragCurrent = localPos;

      samples.add(
        MotorSample(
          time: elapsed,
          x: normalizedX,
          y: normalizedY,
          phase: 'moved',
        ),
      );
    });
  }

  void handlePanEnd(DragEndDetails details, Size swipeAreaSize) {
    if (!isRunning) return;
    if (swipeAreaSize.width <= 0 || swipeAreaSize.height <= 0) return;
    if (dragCurrent == null) return;

    final localPos = dragCurrent!;
    final normalizedX = (localPos.dx / swipeAreaSize.width).clamp(0.0, 1.0);
    final normalizedY = (localPos.dy / swipeAreaSize.height).clamp(0.0, 1.0);
    final elapsed =
        DateTime.now().difference(startedAt).inMilliseconds / 1000.0;

    setState(() {
      samples.add(
        MotorSample(
          time: elapsed,
          x: normalizedX,
          y: normalizedY,
          phase: 'ended',
        ),
      );

      swipeCount++;
      dragStart = null;
      dragCurrent = null;
    });
  }

  Future<void> exportSession() async {
    if (samples.isEmpty) return;

    final session = MotorSessionExport(
      activity: 'swiping',
      platform: 'android',
      startedAt: startedAt,
      sessionDuration:
          DateTime.now().difference(startedAt).inMilliseconds / 1000.0,
      sampleCount: samples.length,
      samples: samples,
    );

    final prettyJson =
        const JsonEncoder.withIndent('  ').convert(session.toJson());

    try {
      final dir = await getApplicationDocumentsDirectory();
      final filename =
          'swiping_session_${DateTime.now().toUtc().toIso8601String()}'
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
      text: 'Signals to Pathways – Swiping Session Export',
    );
  }

  @override
  Widget build(BuildContext context) {
    final canExport = samples.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Swiping Activity'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Swipe Count: $swipeCount',
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: startSession,
                    child: Text(
                      isRunning ? 'Reset Session' : 'Start Session',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isRunning ? stopSession : null,
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

            const SizedBox(height: 30),

            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final swipeAreaSize =
                      Size(constraints.maxWidth, constraints.maxHeight);

                  return GestureDetector(
                    onPanStart: (details) =>
                        handlePanStart(details, swipeAreaSize),
                    onPanUpdate: (details) =>
                        handlePanUpdate(details, swipeAreaSize),
                    onPanEnd: (details) =>
                        handlePanEnd(details, swipeAreaSize),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black),
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: CustomPaint(
                        painter: SwipePainter(
                          start: dragStart,
                          current: dragCurrent,
                        ),
                        child: const Center(
                          child: Text(
                            'Swipe Here',
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                    ),
                  );
                },
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
                    '(${(s.x ?? 0).toStringAsFixed(3)}, ${(s.y ?? 0).toStringAsFixed(3)}) '
                    '${s.phase ?? ''}',
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

class SwipePainter extends CustomPainter {
  final Offset? start;
  final Offset? current;

  SwipePainter({
    required this.start,
    required this.current,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (start == null || current == null) return;

    final linePaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()..color = Colors.red;

    canvas.drawLine(start!, current!, linePaint);
    canvas.drawCircle(current!, 6, dotPaint);
  }

  @override
  bool shouldRepaint(covariant SwipePainter oldDelegate) {
    return oldDelegate.start != start || oldDelegate.current != current;
  }
}