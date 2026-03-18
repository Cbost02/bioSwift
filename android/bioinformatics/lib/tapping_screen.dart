import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'motor_schema.dart';

class TappingScreen extends StatefulWidget {
  const TappingScreen({super.key});

  @override
  State<TappingScreen> createState() => _TappingScreenState();
}

class _TappingScreenState extends State<TappingScreen> {
  int tapCount = 0;
  bool isRunning = false;

  final List<MotorSample> samples = [];
  DateTime startedAt = DateTime.now();

  File? lastExportFile;
  String exportStatus = '';

  void startSession() {
    setState(() {
      tapCount = 0;
      isRunning = true;
      samples.clear();
      startedAt = DateTime.now();
      lastExportFile = null;
      exportStatus = '';
    });
  }

  void stopSession() {
    setState(() {
      isRunning = false;
    });
  }

  void registerTap(TapUpDetails details, Size tapAreaSize) {
    if (!isRunning) return;
    if (tapAreaSize.width <= 0 || tapAreaSize.height <= 0) return;

    final localPos = details.localPosition;

    final normalizedX =
        (localPos.dx / tapAreaSize.width).clamp(0.0, 1.0);
    final normalizedY =
        (localPos.dy / tapAreaSize.height).clamp(0.0, 1.0);

    final elapsed =
        DateTime.now().difference(startedAt).inMilliseconds / 1000.0;

    setState(() {
      tapCount++;

      samples.add(
        MotorSample(
          time: elapsed,
          x: normalizedX,
          y: normalizedY,
        ),
      );
    });
  }

  Future<void> exportSession() async {
    if (samples.isEmpty) return;

    final session = MotorSessionExport(
      activity: 'tapping',
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
          'tapping_session_${DateTime.now().toUtc().toIso8601String()}'
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
      text: 'Signals to Pathways – Tapping Session Export',
    );
  }

  @override
  Widget build(BuildContext context) {
    final canExport = samples.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tapping Activity'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Tap Count: $tapCount',
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
                  final tapAreaSize =
                      Size(constraints.maxWidth, constraints.maxHeight);

                  return GestureDetector(
                    onTapUp: (details) => registerTap(details, tapAreaSize),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black),
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'Tap Here',
                          style: TextStyle(fontSize: 20),
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
                    'Tap ${i + 1}: '
                    't=${s.time.toStringAsFixed(3)}s '
                    '(${(s.x ?? 0).toStringAsFixed(3)}, ${(s.y ?? 0).toStringAsFixed(3)})',
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