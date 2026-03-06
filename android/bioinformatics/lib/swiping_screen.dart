import 'package:flutter/material.dart';

class SwipingScreen extends StatefulWidget {
  const SwipingScreen({super.key});

  @override
  State<SwipingScreen> createState() => _SwipingScreenState();
}

class _SwipingScreenState extends State<SwipingScreen> {
  int swipeCount = 0;
  bool isRunning = false;

  Offset? dragStart;
  Offset? dragCurrent;

  void startSession() {
    setState(() {
      swipeCount = 0;
      isRunning = true;
      dragStart = null;
      dragCurrent = null;
    });
  }

  void stopSession() {
    setState(() {
      isRunning = false;
      dragStart = null;
      dragCurrent = null;
    });
  }

  void handlePanStart(DragStartDetails details) {
    if (!isRunning) return;

    setState(() {
      dragStart = details.localPosition;
      dragCurrent = details.localPosition;
    });
  }

  void handlePanUpdate(DragUpdateDetails details) {
    if (!isRunning) return;

    setState(() {
      dragCurrent = details.localPosition;
    });
  }

  void handlePanEnd(DragEndDetails details) {
    if (!isRunning) return;

    setState(() {
      swipeCount++;
      dragStart = null;
      dragCurrent = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Swiping Activity"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              "Swipe Count: $swipeCount",
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: startSession,
              child: const Text("Start Session"),
            ),
            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: stopSession,
              child: const Text("Stop Session"),
            ),
            const SizedBox(height: 40),

            Expanded(
              child: GestureDetector(
                onPanStart: handlePanStart,
                onPanUpdate: handlePanUpdate,
                onPanEnd: handlePanEnd,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                    color: Colors.white,
                  ),
                  child: CustomPaint(
                    painter: SwipePainter(
                      start: dragStart,
                      current: dragCurrent,
                    ),
                    child: const Center(
                      child: Text(
                        "Swipe Here",
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                ),
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

    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(start!, current!, paint);

    final dotPaint = Paint()..color = Colors.red;
    canvas.drawCircle(current!, 6, dotPaint);
  }

  @override
  bool shouldRepaint(covariant SwipePainter oldDelegate) {
    return oldDelegate.start != start || oldDelegate.current != current;
  }
}