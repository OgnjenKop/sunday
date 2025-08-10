import 'package:flutter/material.dart';

class SessionCompletionSheet extends StatelessWidget {
  final double sessionAmount;

  const SessionCompletionSheet({super.key, required this.sessionAmount});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Complete'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Vitamin D Synthesized: ${sessionAmount.toStringAsFixed(0)} IU',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // TODO: Save to Health
                Navigator.pop(context);
              },
              child: const Text('Save to Health'),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Continue Tracking'),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                // TODO: End without saving
                Navigator.pop(context);
              },
              child: const Text("End and Don't Save"),
            ),
          ],
        ),
      ),
    );
  }
}
