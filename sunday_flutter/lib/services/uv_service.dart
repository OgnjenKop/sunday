import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:home_widget/home_widget.dart';
import 'notification_service.dart';
import '../models/data_models.dart';

class UVService extends ChangeNotifier {
  double currentUV = 0.0;
  double maxUV = 0.0;
  double tomorrowMaxUV = 0.0;
  bool isLoading = false;
  String? lastError;
  Map<int, int> burnTimeMinutes = {};
  DateTime? todaySunrise;
  DateTime? todaySunset;
  DateTime? tomorrowSunrise;
  DateTime? tomorrowSunset;
  double currentAltitude = 0.0;
  double uvMultiplier = 1.0;
  double currentCloudCover = 0.0;
  bool isOfflineMode = false;
  DateTime? lastSuccessfulUpdate;
  bool hasNoData = false;
  
  bool get shouldShowTomorrowTimes {
    if (todaySunset == null) return false;
    final now = DateTime.now();
    final isToday = now.year == todaySunset!.year && now.month == todaySunset!.month && now.day == todaySunset!.day;
    return isToday && now.isAfter(todaySunset!);
  }

  DateTime? get displaySunrise => shouldShowTomorrowTimes ? tomorrowSunrise : todaySunrise;
  DateTime? get displaySunset => shouldShowTomorrowTimes ? tomorrowSunset : todaySunset;
  double get displayMaxUV => shouldShowTomorrowTimes ? tomorrowMaxUV : maxUV;

  Future<void> fetchUVData(Position location) async {
    isLoading = true;
    lastError = null;
    notifyListeners();

    final latitude = location.latitude;
    final longitude = location.longitude;
    final altitude = location.altitude;

    currentAltitude = altitude >= 0 ? altitude : 0;
    final altitudeKm = currentAltitude / 1000.0;
    uvMultiplier = 1.0 + (altitudeKm * 0.1);

    final urlString =
        'https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&elevation=$altitude&daily=uv_index_max,sunrise,sunset&hourly=uv_index,cloud_cover&timezone=auto&forecast_days=2';

    try {
      final response = await http.get(Uri.parse(urlString));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _processUVData(data);
        _cacheUVData(data, location);
        _scheduleSunNotifications();
        isOfflineMode = false;
        hasNoData = false;
        lastSuccessfulUpdate = DateTime.now();
      } else {
        lastError = 'Failed to load UV data';
        _loadCachedData(location);
      }
    } catch (e) {
      lastError = e.toString();
      _loadCachedData(location);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _processUVData(Map<String, dynamic> data) {
    final daily = data['daily'];
    final hourly = data['hourly'];

    if (daily != null) {
      maxUV = (daily['uv_index_max'][0] as double) * uvMultiplier;
      tomorrowMaxUV = (daily['uv_index_max'][1] as double) * uvMultiplier;
      todaySunrise = DateTime.parse(daily['sunrise'][0]);
      todaySunset = DateTime.parse(daily['sunset'][0]);
      tomorrowSunrise = DateTime.parse(daily['sunrise'][1]);
      tomorrowSunset = DateTime.parse(daily['sunset'][1]);
    }

    if (hourly != null) {
      final now = DateTime.now();
      final hour = now.hour;
      final minute = now.minute;

      final hourlyUV = List<double>.from(hourly['uv_index']);
      if (hour < hourlyUV.length) {
        final currentHourUV = hourlyUV[hour];
        final interpolationFactor = minute / 60.0;
        var interpolatedUV = currentHourUV;
        if (hour + 1 < hourlyUV.length) {
          final nextHourUV = hourlyUV[hour + 1];
          interpolatedUV = currentHourUV + (nextHourUV - currentHourUV) * interpolationFactor;
        }
        currentUV = interpolatedUV * uvMultiplier;
      }

      final hourlyCloudCover = List<double>.from(hourly['cloud_cover']);
      if (hour < hourlyCloudCover.length) {
        currentCloudCover = hourlyCloudCover[hour];
      }
    }
    _calculateSafeExposureTimes();
    HomeWidget.saveWidgetData('uvIndex', currentUV.toStringAsFixed(1));
    // Trigger widget update after saving data
    // (non-blocking; errors ignored intentionally)
    HomeWidget.updateWidget(name: 'HomeWidgetProvider');
  }

  void _scheduleSunNotifications() {
    // avoid duplicate scheduling per day by a simple in-memory check
    final now = DateTime.now();
    final sunrise = todaySunrise;
    final sunset = todaySunset;
    if (sunrise == null || sunset == null) return;
    final solarNoon = DateTime.fromMillisecondsSinceEpoch(
        sunrise.millisecondsSinceEpoch +
            ((sunset.millisecondsSinceEpoch - sunrise.millisecondsSinceEpoch) ~/ 2));
    final preNoon = solarNoon.subtract(const Duration(minutes: 30));

    // Cancel previous IDs for today and reschedule
    NotificationService().cancelIds(['sunrise', 'sunset', 'solarNoon']);
    NotificationService().scheduleAt(
      id: 'sunrise',
      title: 'The sun is up!',
      body: 'Today\'s max UV: ${displayMaxUV.toStringAsFixed(1)}',
      when: sunrise,
    );
    NotificationService().scheduleAt(
      id: 'sunset',
      title: 'The sun is setting',
      body: 'Check your vitamin D progress in Sun Day',
      when: sunset,
    );
    NotificationService().scheduleAt(
      id: 'solarNoon',
      title: 'Solar noon approaching',
      body: 'Peak UV in 30 minutes (UV ${displayMaxUV.toStringAsFixed(1)})',
      when: preNoon.isAfter(now) ? preNoon : now.add(const Duration(minutes: 1)),
    );
  }

  void _calculateSafeExposureTimes() {
    const medTimesAtUV1 = {
      1: 150.0,
      2: 250.0,
      3: 425.0,
      4: 600.0,
      5: 850.0,
      6: 1100.0,
    };

    final uvToUse = currentUV > 0 ? currentUV : 0.1;

    burnTimeMinutes = {};
    for (final entry in medTimesAtUV1.entries) {
      final fullMED = entry.value / uvToUse;
      burnTimeMinutes[entry.key] = fullMED.toInt();
    }
  }

  Future<void> _cacheUVData(Map<String, dynamic> data, Position location) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheData = CachedUVData(
      latitude: location.latitude,
      longitude: location.longitude,
      date: DateTime.now(),
      hourlyUV: List<double>.from(data['hourly']['uv_index']),
      hourlyCloudCover: List<double>.from(data['hourly']['cloud_cover']),
      maxUV: data['daily']['uv_index_max'][0],
      sunrise: DateTime.parse(data['daily']['sunrise'][0]),
      sunset: DateTime.parse(data['daily']['sunset'][0]),
      lastUpdated: DateTime.now(),
    );
    await prefs.setString('cachedUVData', jsonEncode(cacheData.toJson()));
  }

  Future<void> _loadCachedData(Position location) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedDataString = prefs.getString('cachedUVData');
    if (cachedDataString != null) {
      final cachedDataJson = jsonDecode(cachedDataString);
      final cachedData = CachedUVData.fromJson(cachedDataJson);

      final now = DateTime.now();
      if (now.difference(cachedData.lastUpdated).inHours < 24) {
        isOfflineMode = true;
        _processUVData(cachedDataJson);
        notifyListeners();
      } else {
        hasNoData = true;
      }
    } else {
      hasNoData = true;
    }
  }
}
