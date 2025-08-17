import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/vitamin_d_calculator.dart';
import '../services/health_manager.dart';

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
            Text('Start Time: ${TimeOfDay.fromDateTime(startTime).format(context)}'),
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
            Text('End Time: ${TimeOfDay.fromDateTime(endTime).format(context)}'),
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
            DropdownButtonFormField<ClothingLevel>(
              value: clothingLevel,
              decoration: const InputDecoration(labelText: 'Clothing Level'),
              items: ClothingLevel.values
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e.toString().split('.').last),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => clothingLevel = v ?? clothingLevel),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<SunscreenLevel>(
              value: sunscreenLevel,
              decoration: const InputDecoration(labelText: 'Sunscreen Level'),
              items: SunscreenLevel.values
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e.toString().split('.').last),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => sunscreenLevel = v ?? sunscreenLevel),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () async {
                if (!endTime.isAfter(startTime)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('End time must be after start time')),
                  );
                  return;
                }
                final calc = context.read<VitaminDCalculator>();
                final amount = await calc.estimateVitaminDForInterval(
                  startTime,
                  endTime,
                  clothing: clothingLevel,
                  sunscreen: sunscreenLevel,
                );
                await context.read<HealthManager>().saveVitaminD(amount, endTime);
                if (!mounted) return;
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
