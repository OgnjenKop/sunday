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
            'Sun Day',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          FutureBuilder<String?>(
            future: HomeWidget.getWidgetData('uvIndex', defaultValue: '0.0'),
            builder: (context, snapshot) {
              final uv = snapshot.data ?? '0.0';
              return Text(
                'UV $uv',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          FutureBuilder<String?>(
            future: HomeWidget.getWidgetData('vitaminDRate', defaultValue: '0'),
            builder: (context, snapshot) {
              final rate = snapshot.data ?? '0';
              return Text(
                '$rate IU/min',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
              );
            },
          ),
          FutureBuilder<String?>(
            future: HomeWidget.getWidgetData('todaysTotal', defaultValue: '0'),
            builder: (context, snapshot) {
              final total = snapshot.data ?? '0';
              return Text(
                '$total IU today',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
              );
            },
          )
        ],
      ),
    );
  }
}
