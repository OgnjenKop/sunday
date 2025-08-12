import 'package:flutter/material.dart';
import 'package:health/health.dart';

class HealthManager extends ChangeNotifier {
  bool isAuthorized = false;
  String? lastError;
  final HealthFactory _health = HealthFactory();

  Future<void> requestAuthorization() async {
    final types = [
      HealthDataType.DIETARY_VITAMIN_D,
      HealthDataType.BODY_FAT_PERCENTAGE,
      HealthDataType.DATE_OF_BIRTH,
    ];

    final permissions = [
      HealthDataAccess.READ_WRITE,
      HealthDataAccess.READ,
      HealthDataAccess.READ,
    ];

    isAuthorized = await _health.requestAuthorization(types, permissions: permissions);
    notifyListeners();
  }

  Future<void> saveVitaminD(double amount, DateTime date) async {
    if (!isAuthorized) {
      await requestAuthorization();
      if (!isAuthorized) return;
    }

    final micrograms = amount * 0.025;
    await _health.writeHealthData(micrograms, HealthDataType.DIETARY_VITAMIN_D, date, date);
  }

  Future<double?> getTodaysVitaminD() async {
    if (!isAuthorized) {
      await requestAuthorization();
      if (!isAuthorized) return null;
    }

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final types = [HealthDataType.DIETARY_VITAMIN_D];
    final data = await _health.getHealthDataFromTypes(startOfDay, endOfDay, types);

    if (data.isNotEmpty) {
      final vitaminDData = data.where((d) => d.type == HealthDataType.DIETARY_VITAMIN_D);
      if (vitaminDData.isNotEmpty) {
        final totalMicrograms = vitaminDData
            .map((d) => (d.value as NumericHealthValue).numericValue.toDouble())
            .reduce((a, b) => a + b);
        return totalMicrograms * 40.0;
      }
    }
    return null;
  }

  Future<int?> getAge() async {
    if (!isAuthorized) {
      await requestAuthorization();
      if (!isAuthorized) return null;
    }

    final types = [HealthDataType.DATE_OF_BIRTH];
    final data = await _health.getHealthDataFromTypes(
        DateTime.now().subtract(const Duration(days: 365 * 100)),
        DateTime.now(),
        types);

    if (data.isNotEmpty) {
      final dobData = data.firstWhere((d) => d.type == HealthDataType.DATE_OF_BIRTH,
          orElse: () => HealthDataPoint(
              NumericHealthValue(0),
              HealthDataType.DATE_OF_BIRTH,
              HealthDataUnit.NO_UNIT,
              DateTime.now(),
              DateTime.now(),
              PlatformType.UNKNOWN,
              "unknown",
              "unknown",
              ));
      if (dobData.value is NumericHealthValue) {
        // The health package on Android returns age as a double
        return (dobData.value as NumericHealthValue).numericValue.toInt();
      }
    }
    return null;
  }

  Future<Map<DateTime, double>> getVitaminDHistory(int days) async {
    if (!isAuthorized) {
      await requestAuthorization();
      if (!isAuthorized) return {};
    }

    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));
    final types = [HealthDataType.DIETARY_VITAMIN_D];
    final data = await _health.getHealthDataFromTypes(startDate, now, types);

    final Map<DateTime, double> dailyTotals = {};
    for (final d in data) {
      if (d.type == HealthDataType.DIETARY_VITAMIN_D) {
        final value = (d.value as NumericHealthValue).numericValue.toDouble();
        final iu = value * 40.0; // micrograms to IU
        final dayStart = DateTime(d.dateFrom.year, d.dateFrom.month, d.dateFrom.day);
        dailyTotals.update(dayStart, (prev) => prev + iu, ifAbsent: () => iu);
      }
    }
    return dailyTotals;
  }
}
