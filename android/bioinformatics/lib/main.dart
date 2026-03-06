import 'zigzag_screen.dart';
import 'package:flutter/material.dart';
import 'tapping_screen.dart';
import 'swiping_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ColoredBox(
        color: Colors.blue,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                  enabled: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ZigZagScreen()),
                    );
                  },
                ),
                SizedBox(height: 16),
                ActivityCard(
                  title: 'Tapping',
                  subtitle: 'Target taps & consistency',
                  tag: 'Ready',
                  enabled: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TappingScreen()),
                    );
                  }
                ),
                SizedBox(height: 16),
                ActivityCard(
                  title: 'Swiping',
                  subtitle: 'Swipe speed & control',
                  tag: 'Ready',
                  enabled: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SwipingScreen()),
                    );
                  }
                ),
                SizedBox(height: 16),
                ActivityCard(
                  title: 'Oreientation',
                  subtitle: 'Device motion stability',
                  tag: 'Orientation',
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
  final bool enabled;
  final VoidCallback? onTap;

  const ActivityCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.tag,
    this.enabled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: Chip(label: Text(tag)),
        onTap: enabled ? onTap : null,
      ),
    );
  }
}
