import 'package:flutter/material.dart';

class TappingScreen extends StatefulWidget {
  const TappingScreen({super.key});

  @override
  State<TappingScreen> createState() => _TappingScreenState();
}

class _TappingScreenState extends State<TappingScreen> {

  int tapCount = 0;
  bool isRunning = false;

  void startSession() {
    setState(() {
      tapCount = 0;
      isRunning = true;
    });
  }

  void stopSession() {
    setState(() {
      isRunning = false;
    });
  }

  void registerTap() {
    if (!isRunning) return;

    setState(() {
      tapCount++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tapping Activity"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            Text(
              "Tap Count: $tapCount",
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
                onTap: registerTap,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                    color: Colors.white,
                  ),
                  child: const Center(
                    child: Text(
                      "Tap Here",
                      style: TextStyle(fontSize: 20),
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