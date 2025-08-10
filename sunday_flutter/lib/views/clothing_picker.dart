import 'package:flutter/material.dart';
import '../services/vitamin_d_calculator.dart';

class ClothingPicker extends StatelessWidget {
  final Function(ClothingLevel) onSelectionChanged;

  const ClothingPicker({super.key, required this.onSelectionChanged});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clothing Level'),
      ),
      body: ListView.builder(
        itemCount: ClothingLevel.values.length,
        itemBuilder: (context, index) {
          final level = ClothingLevel.values[index];
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
