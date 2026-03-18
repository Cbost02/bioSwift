import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'motor_schema.dart';

class ZigZagScreen extends StatefulWidget {
  const ZigZagScreen({super.key});

  @override
  State<ZigZagScreen> createState() => _ZigZagScreenState();
}

class _ZigZagScreenState extends State<ZigZagScreen> {
  bool isRunning = false;

  int strokeCount = 0;
  final List<MotorSample> samples = [];

  DateTime startedAt = DateTime.now();

  int? sessionStartMicros;

  File? lastExportFile;
  String exportStatus = '';

  Size padSize = Size.zero;

  void startOrReset() {
    setState(() {
      isRunning = true;
      strokeCount = 0;
      samples.clear();
      startedAt = DateTime.now();
      sessionStartMicros = null;
      lastExportFile = null;
      exportStatus = '';
    });
  }

  void stop() {
    setState(() {
      isRunning = false;
    });
  }

  void recordSample({
    required String phase,
    required Offset localPos,
    required int eventMicros,
  }) {
    if (!isRunning) return;
    if (padSize.width <= 0 || padSize.height <= 0) return;

    sessionStartMicros ??= eventMicros;
    final elapsedSec =
        (eventMicros - (sessionStartMicros ?? eventMicros)) / 1e6;

    final nx = (localPos.dx / padSize.width).clamp(0.0, 1.0);
    final ny = (localPos.dy / padSize.height).clamp(0.0, 1.0);

    setState(() {
      samples.add(
        MotorSample(
          time: elapsedSec,
          x: nx,
          y: ny,
          phase: phase,
        ),
      );

      if (phase == 'ended') {
        strokeCount += 1;
      }
    });
  }

  Future<void> exportSession() async {
    if (samples.isEmpty) return;

    final session = MotorSessionExport(
      activity: 'zigzag',
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
          'zigzag_session_${DateTime.now().toUtc().toIso8601String()}'
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
      text: 'Signals to Pathways – Zig-Zag Session Export',
    );
  }

  @override
  Widget build(BuildContext context) {
    final canExport = samples.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Zig-Zag Tracing'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Strokes completed: $strokeCount',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: startOrReset,
                    child: Text(isRunning ? 'Reset Session' : 'Start Session'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isRunning ? stop : null,
                    child: const Text('Stop'),
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

            const SizedBox(height: 16),

            _TracingPad(
              onPadSizeChanged: (s) => padSize = s,
              onEvent: (phase, pos, micros) => recordSample(
                phase: phase,
                localPos: pos,
                eventMicros: micros,
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: ListView.builder(
                itemCount: samples.length,
                itemBuilder: (context, i) {
                  final e = samples[i];
                  return Text(
                    'Sample ${i + 1}: '
                    't=${e.time.toStringAsFixed(3)}s '
                    '(${(e.x ?? 0).toStringAsFixed(3)}, ${(e.y ?? 0).toStringAsFixed(3)}) '
                    '${e.phase ?? ''}',
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

class _TracingPad extends StatefulWidget {
  final void Function(Size) onPadSizeChanged;
  final void Function(String phase, Offset localPos, int eventMicros) onEvent;

  const _TracingPad({
    required this.onPadSizeChanged,
    required this.onEvent,
  });

  @override
  State<_TracingPad> createState() => _TracingPadState();
}

class _TracingPadState extends State<_TracingPad> {
  final GlobalKey _key = GlobalKey();

  void _updateSize() {
    final ctx = _key.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject();
    if (box is RenderBox) {
      widget.onPadSizeChanged(box.size);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateSize());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: _key,
      height: 300,
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withOpacity(0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.2)),
      ),
      child: Listener(
        onPointerDown: (e) => widget.onEvent(
          'began',
          e.localPosition,
          e.timeStamp.inMicroseconds,
        ),
        onPointerMove: (e) => widget.onEvent(
          'moved',
          e.localPosition,
          e.timeStamp.inMicroseconds,
        ),
        onPointerUp: (e) => widget.onEvent(
          'ended',
          e.localPosition,
          e.timeStamp.inMicroseconds,
        ),
        child: CustomPaint(
          painter: ZigZagPainter(
            segmentCount: 10,
            amplitudeRatio: 0.25,
            marginRatio: 0.12,
            lineWidth: 6,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class ZigZagPainter extends CustomPainter {
  final int segmentCount;
  final double amplitudeRatio;
  final double marginRatio;
  final double lineWidth;

  ZigZagPainter({
    required this.segmentCount,
    required this.amplitudeRatio,
    required this.marginRatio,
    required this.lineWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final margin = (w < h ? w : h) * marginRatio;
    final usableW = (w - 2 * margin).clamp(1.0, double.infinity);
    final centerY = h * 0.5;
    final amp = h * amplitudeRatio;
    final dx = usableW / (segmentCount <= 0 ? 1 : segmentCount);

    final points = <Offset>[];
    for (int i = 0; i <= segmentCount; i++) {
      final x = margin + dx * i;
      final yOffset = (i == 0) ? 0.0 : (i.isOdd ? -amp : amp);
      final y = (centerY + yOffset).clamp(margin, h - margin);
      points.add(Offset(x, y));
    }

    final path = Path();
    if (points.isNotEmpty) {
      path.moveTo(points.first.dx, points.first.dy);
      for (final p in points.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
    }

    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = lineWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, paint);

    if (points.isNotEmpty) {
      final start = points.first;
      final end = points.last;

      final startPaint = Paint()..color = Colors.green;
      final endPaint = Paint()..color = Colors.blue;

      canvas.drawCircle(start, 7, startPaint);
      canvas.drawCircle(end, 7, endPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ZigZagPainter oldDelegate) {
    return oldDelegate.segmentCount != segmentCount ||
        oldDelegate.amplitudeRatio != amplitudeRatio ||
        oldDelegate.marginRatio != marginRatio ||
        oldDelegate.lineWidth != lineWidth;
  }
}