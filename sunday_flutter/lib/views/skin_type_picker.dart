import 'package:flutter/material.dart';
import '../services/vitamin_d_calculator.dart';

class SkinTypePicker extends StatelessWidget {
  final Function(SkinType) onSelectionChanged;

  const SkinTypePicker({super.key, required this.onSelectionChanged});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Skin Type'),
      ),
      body: ListView.builder(
        itemCount: SkinType.values.length,
        itemBuilder: (context, index) {
          final type = SkinType.values[index];
          return ListTile(
            title: Text(type.toString().split('.').last),
            onTap: () {
              onSelectionChanged(type);
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }
}
