import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: EmptyScreen(),
    );
  }
}

class EmptyScreen extends StatelessWidget {
  const EmptyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: ColoredBox(
        color: Colors.blue,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Signals to Pathways',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Short motor-control activities that record human-motor signals (touch timing and movement).',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                SizedBox(height: 16),
                ActivityCard(
                  title: 'Zig-Zag Tracing',
                  subtitle: 'Trace a path smoothly and accurately',
                  tag: 'Ready',
                ),
                SizedBox(height: 16),
                ActivityCard(
                  title: 'Tapping',
                  subtitle: 'Target taps & consistency',
                  tag: 'Comming soon',
                ),
                SizedBox(height: 16),
                ActivityCard(
                  title: 'Swiping',
                  subtitle: 'Swipe speed & control',
                  tag: 'Comming soon',
                ),
                SizedBox(height: 16),
                ActivityCard(
                  title: 'Oreientation',
                  subtitle: 'Device motion stability',
                  tag: 'Comming soon',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ActivityCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String tag;

  const ActivityCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.tag,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: Chip(label: Text(tag)),
      ),
    );
  }
}
