import 'package:flutter/material.dart';

class OrientationScreen extends StatefulWidget {
  const OrientationScreen({super.key});

  @override
  State<OrientationScreen> createState() => _OrientationScreenState();
}

class _OrientationScreenState extends State<OrientationScreen> {
  bool isRunning = false;

  String orientationStatus = "Not started";
  double pitch = 0.0;
  double roll = 0.0;
  double yaw = 0.0;

  void startSession() {
    setState(() {
      isRunning = true;
      orientationStatus = "Collecting orientation data...";
      pitch = 0.0;
      roll = 0.0;
      yaw = 0.0;
    });
  }

  void stopSession() {
    setState(() {
      isRunning = false;
      orientationStatus = "Session stopped";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Orientation Activity"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              orientationStatus,
              style: const TextStyle(fontSize: 20),
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
            const SizedBox(height: 30),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text("Pitch: ${pitch.toStringAsFixed(2)}°"),
                    const SizedBox(height: 8),
                    Text("Roll: ${roll.toStringAsFixed(2)}°"),
                    const SizedBox(height: 8),
                    Text("Yaw: ${yaw.toStringAsFixed(2)}°"),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            Expanded(
              child: Center(
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    border: Border.all(color: Colors.black),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text(
                      "Device Orientation Preview",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18),
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