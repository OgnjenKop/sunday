import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

class SundayWidget extends StatelessWidget {
  const SundayWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'UV Index',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          FutureBuilder<String?>(
            future: HomeWidget.getWidgetData('uvIndex', defaultValue: '0.0'),
            builder: (context, snapshot) {
              return Text(
                snapshot.data ?? '0.0',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
