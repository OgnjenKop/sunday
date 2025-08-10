import 'package:flutter/material.dart';
import '../services/vitamin_d_calculator.dart';

class ManualExposureSheet extends StatefulWidget {
  const ManualExposureSheet({super.key});

  @override
  State<ManualExposureSheet> createState() => _ManualExposureSheetState();
}

class _ManualExposureSheetState extends State<ManualExposureSheet> {
  DateTime startTime = DateTime.now();
  DateTime endTime = DateTime.now();
  ClothingLevel clothingLevel = ClothingLevel.light;
  SunscreenLevel sunscreenLevel = SunscreenLevel.none;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Past Exposure'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Start Time: $startTime'),
            ElevatedButton(
              onPressed: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(startTime),
                );
                if (time != null) {
                  setState(() {
                    startTime = DateTime(
                      startTime.year,
                      startTime.month,
                      startTime.day,
                      time.hour,
                      time.minute,
                    );
                  });
                }
              },
              child: const Text('Select Start Time'),
            ),
            const SizedBox(height: 20),
            Text('End Time: $endTime'),
            ElevatedButton(
              onPressed: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(endTime),
                );
                if (time != null) {
                  setState(() {
                    endTime = DateTime(
                      endTime.year,
                      endTime.month,
                      endTime.day,
                      time.hour,
                      time.minute,
                    );
                  });
                }
              },
              child: const Text('Select End Time'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // TODO: Calculate and save vitamin D
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
