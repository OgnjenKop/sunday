import 'package:flutter/material.dart';
import '../services/vitamin_d_calculator.dart';

class SunscreenPicker extends StatelessWidget {
  final Function(SunscreenLevel) onSelectionChanged;

  const SunscreenPicker({super.key, required this.onSelectionChanged});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sunscreen Level'),
      ),
      body: ListView.builder(
        itemCount: SunscreenLevel.values.length,
        itemBuilder: (context, index) {
          final level = SunscreenLevel.values[index];
          return ListTile(
            title: Text(level.toString().split('.').last),
            onTap: () {
              onSelectionChanged(level);
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }
}
