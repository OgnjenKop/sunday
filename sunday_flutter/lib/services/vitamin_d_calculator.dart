import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'uv_service.dart';
import 'health_manager.dart';
import 'package:home_widget/home_widget.dart';
import 'notification_service.dart';

enum ClothingLevel { none, minimal, light, moderate, heavy }
enum SunscreenLevel { none, spf15, spf30, spf50, spf100 }
enum SkinType { type1, type2, type3, type4, type5, type6 }

class VitaminDCalculator extends ChangeNotifier {
  bool isInSun = false;
  ClothingLevel clothingLevel = ClothingLevel.light;
  SunscreenLevel sunscreenLevel = SunscreenLevel.none;
  SkinType skinType = SkinType.type3;
  double currentVitaminDRate = 0.0; // IU/hour
  double sessionVitaminD = 0.0; // IU
  DateTime? sessionStartTime;
  int? userAge;
  double cumulativeMedFraction = 0.0;
  double currentUVQualityFactor = 1.0;
  double currentAdaptationFactor = 1.0;

  Timer? _timer;
  double _lastUV = 0.0;
  final UVService _uvService;
  final HealthManager _healthManager;
  DateTime? _lastUpdateTime;
  DateTime? _lastSessionSaveTime;

  static const double _uvHalfMax = 4.0;
  static const double _uvMaxFactor = 3.0;

  VitaminDCalculator(this._uvService, this._healthManager) {
    _loadUserPreferences();
    _restoreActiveSession();
    _uvService.addListener(_onUVServiceChange);
    _healthManager.addListener(_onHealthManagerChange);
    _initHealthFactors();
  }

  void _onUVServiceChange() {
    updateUV(_uvService.currentUV);
  }

  void _onHealthManagerChange() {
    _initHealthFactors();
  }

  void _loadUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    clothingLevel = ClothingLevel.values[prefs.getInt('clothingLevel') ?? 2];
    sunscreenLevel = SunscreenLevel.values[prefs.getInt('sunscreenLevel') ?? 0];
    skinType = SkinType.values[prefs.getInt('skinType') ?? 2];
    notifyListeners();
  }

  void _saveUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('clothingLevel', clothingLevel.index);
    await prefs.setInt('sunscreenLevel', sunscreenLevel.index);
    await prefs.setInt('skinType', skinType.index);
  }

  void startSession(double uvIndex) {
    if (isInSun) return;
    isInSun = true;
    sessionStartTime = DateTime.now();
    sessionVitaminD = 0.0;
    cumulativeMedFraction = 0.0;
    _lastUV = uvIndex;
    _lastUpdateTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      updateVitaminD(uvIndex: _lastUV);
      _updateMedExposure(uvIndex: _lastUV);
    });
    updateVitaminDRate(uvIndex: uvIndex);
    notifyListeners();
  }

  void stopSession() {
    if (!isInSun) return;
    isInSun = false;
    _timer?.cancel();
    _timer = null;
    sessionStartTime = null;
    cumulativeMedFraction = 0.0;
    _saveActiveSession();
    notifyListeners();
  }

  void updateUV(double uvIndex) {
    _lastUV = uvIndex;
    updateVitaminDRate(uvIndex: uvIndex);
  }

  void updateVitaminDRate({required double uvIndex}) {
    const baseRate = 21000.0; // IU/hour baseline for Type 3 minimal clothing
    final uvFactor = (uvIndex * _uvMaxFactor) / (_uvHalfMax + uvIndex);
    final exposureFactor = _getExposureFactor();
    final sunscreenFactor = _getSunscreenFactor();
    final skinFactor = _getSkinFactor();
    final ageFactor = _getAgeFactor();
    _updateUVQualityFactor();
    currentVitaminDRate = baseRate * uvFactor * exposureFactor * sunscreenFactor * skinFactor * ageFactor * currentUVQualityFactor * currentAdaptationFactor;
    notifyListeners();
    // Update widget with current rate
    HomeWidget.saveWidgetData('vitaminDRate', (currentVitaminDRate / 60.0).toStringAsFixed(0)); // IU/min
    HomeWidget.updateWidget(name: 'HomeWidgetProvider');
  }

  void updateVitaminD({required double uvIndex}) {
    if (!isInSun) return;
    updateVitaminDRate(uvIndex: uvIndex);
    final now = DateTime.now();
    final elapsedSec = _lastUpdateTime == null ? 1.0 : now.difference(_lastUpdateTime!).inMilliseconds / 1000.0;
    _lastUpdateTime = now;
    sessionVitaminD += currentVitaminDRate * (elapsedSec / 3600.0);
    // Update widget's today total by combining with Health if available (approx)
    // We only write session value; a foreground health query would be needed for exact total.
    HomeWidget.saveWidgetData('todaysTotal', sessionVitaminD.toStringAsFixed(0));
    HomeWidget.updateWidget(name: 'HomeWidgetProvider');
    if (_lastSessionSaveTime == null || now.difference(_lastSessionSaveTime!).inSeconds >= 10) {
      _saveActiveSession();
      _lastSessionSaveTime = now;
    }
    notifyListeners();
  }

  void toggleSunExposure(double uvIndex) {
    if (isInSun) {
      stopSession();
    } else {
      startSession(uvIndex);
    }
  }

  double _getExposureFactor() {
    switch (clothingLevel) {
      case ClothingLevel.none:
        return 1.0;
      case ClothingLevel.minimal:
        return 0.8;
      case ClothingLevel.light:
        return 0.5;
      case ClothingLevel.moderate:
        return 0.3;
      case ClothingLevel.heavy:
        return 0.1;
    }
  }

  double _getSunscreenFactor() {
    switch (sunscreenLevel) {
      case SunscreenLevel.none:
        return 1.0;
      case SunscreenLevel.spf15:
        return 0.07;
      case SunscreenLevel.spf30:
        return 0.03;
      case SunscreenLevel.spf50:
        return 0.02;
      case SunscreenLevel.spf100:
        return 0.01;
    }
  }

  double _getSkinFactor() {
    switch (skinType) {
      case SkinType.type1:
        return 1.25;
      case SkinType.type2:
        return 1.1;
      case SkinType.type3:
        return 1.0;
      case SkinType.type4:
        return 0.7;
      case SkinType.type5:
        return 0.4;
      case SkinType.type6:
        return 0.2;
    }
  }

  double _getAgeFactor() {
    if (userAge == null) return 1.0;
    if (userAge! <= 20) return 1.0;
    if (userAge! >= 70) return 0.25;
    return max(0.25, 1.0 - (userAge! - 20) * 0.01);
  }

  void _updateUVQualityFactor() {
    final sunrise = _uvService.todaySunrise;
    final sunset = _uvService.todaySunset;
    if (sunrise == null || sunset == null) {
      currentUVQualityFactor = 1.0;
      return;
    }
    final solarNoonMs = sunrise.millisecondsSinceEpoch + ((sunset.millisecondsSinceEpoch - sunrise.millisecondsSinceEpoch) / 2).round();
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final hoursFromNoon = (nowMs - solarNoonMs).abs() / (1000 * 60 * 60);
    final quality = exp(-hoursFromNoon * 0.2);
    currentUVQualityFactor = quality.clamp(0.1, 1.0);
  }

  void _updateMedExposure({required double uvIndex}) {
    if (!isInSun || uvIndex <= 0) return;
    const medTimesAtUV1 = {
      1: 150.0,
      2: 250.0,
      3: 425.0,
      4: 600.0,
      5: 850.0,
      6: 1100.0,
    };
    final skinIndex = skinType.index + 1;
    final baseMed = medTimesAtUV1[skinIndex] ?? 425.0;
    final uvToUse = max(uvIndex, 0.1);
    final fullMedMinutes = baseMed / uvToUse;
    final medPerSecond = 1.0 / (fullMedMinutes * 60.0);
    final before = cumulativeMedFraction;
    cumulativeMedFraction += medPerSecond;
    if (before < 0.8 && cumulativeMedFraction >= 0.8) {
      NotificationService().showInstant(
        id: 'burnWarning',
        title: 'Approaching burn threshold',
        body: 'You\'ve reached 80% of MED for your skin type.',
      );
    }
  }

  Future<void> _saveActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (!isInSun) {
      await prefs.remove('activeSessionStartTime');
      await prefs.remove('activeSessionVitaminD');
      await prefs.remove('activeSessionMED');
      await prefs.remove('activeSessionLastUV');
      await prefs.remove('activeSessionLastUpdate');
      return;
    }
    if (sessionStartTime != null) {
      await prefs.setString('activeSessionStartTime', sessionStartTime!.toIso8601String());
    }
    await prefs.setDouble('activeSessionVitaminD', sessionVitaminD);
    await prefs.setDouble('activeSessionMED', cumulativeMedFraction);
    await prefs.setDouble('activeSessionLastUV', _lastUV);
    if (_lastUpdateTime != null) {
      await prefs.setString('activeSessionLastUpdate', _lastUpdateTime!.toIso8601String());
    }
  }

  Future<void> _restoreActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    final startIso = prefs.getString('activeSessionStartTime');
    if (startIso == null) return;
    final start = DateTime.tryParse(startIso);
    if (start == null) return;
    final now = DateTime.now();
    if (!(start.year == now.year && start.month == now.month && start.day == now.day)) {
      // Clear old session
      await prefs.remove('activeSessionStartTime');
      await prefs.remove('activeSessionVitaminD');
      await prefs.remove('activeSessionMED');
      await prefs.remove('activeSessionLastUV');
      await prefs.remove('activeSessionLastUpdate');
      return;
    }
    sessionStartTime = start;
    sessionVitaminD = prefs.getDouble('activeSessionVitaminD') ?? 0.0;
    cumulativeMedFraction = prefs.getDouble('activeSessionMED') ?? 0.0;
    _lastUV = prefs.getDouble('activeSessionLastUV') ?? 0.0;
    final lastUpdateIso = prefs.getString('activeSessionLastUpdate');
    _lastUpdateTime = lastUpdateIso != null ? DateTime.tryParse(lastUpdateIso) : null;
    isInSun = true;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      updateVitaminD(uvIndex: _lastUV);
      _updateMedExposure(uvIndex: _lastUV);
    });
    notifyListeners();
  }

  Future<void> _initHealthFactors() async {
    final age = await _healthManager.getAge();
    userAge = age;
    final history = await _healthManager.getVitaminDHistory(7);
    if (history.isNotEmpty) {
      final total = history.values.fold<double>(0.0, (a, b) => a + b);
      final avg = total / 7.0;
      if (avg < 1000) {
        currentAdaptationFactor = 0.8;
      } else if (avg >= 10000) {
        currentAdaptationFactor = 1.2;
      } else {
        currentAdaptationFactor = 0.8 + (avg - 1000) / 9000 * 0.4;
      }
    } else {
      currentAdaptationFactor = 1.0;
    }
    updateVitaminDRate(uvIndex: _lastUV);
  }

  // Optional setters to persist preferences and recalc
  Future<void> setClothingLevel(ClothingLevel level) async {
    clothingLevel = level;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('clothingLevel', level.index);
    updateVitaminDRate(uvIndex: _lastUV);
    notifyListeners();
  }

  Future<void> setSunscreenLevel(SunscreenLevel level) async {
    sunscreenLevel = level;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('sunscreenLevel', level.index);
    updateVitaminDRate(uvIndex: _lastUV);
    notifyListeners();
  }

  Future<void> setSkinType(SkinType type) async {
    skinType = type;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('skinType', type.index);
    updateVitaminDRate(uvIndex: _lastUV);
    notifyListeners();
  }
  @override
  void dispose() {
    _uvService.removeListener(_onUVServiceChange);
    _healthManager.removeListener(_onHealthManagerChange);
    _timer?.cancel();
    super.dispose();
  }

  Future<double> estimateVitaminDForInterval(
    DateTime start,
    DateTime end, {
    ClothingLevel? clothing,
    SunscreenLevel? sunscreen,
    SkinType? skin,
  }) async {
    if (!end.isAfter(start)) return 0.0;
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('cachedUVData');
    List<double>? hourlyUV;
    DateTime? cacheDate;
    if (cached != null) {
      try {
        final json = jsonDecode(cached) as Map<String, dynamic>;
        hourlyUV = (json['hourlyUV'] as List).map((e) => (e as num).toDouble()).toList();
        cacheDate = DateTime.parse(json['date'] as String);
      } catch (_) {
        hourlyUV = null;
      }
    }

    double uvAt(DateTime t) {
      if (hourlyUV != null && cacheDate != null &&
          t.year == cacheDate.year && t.month == cacheDate.month && t.day == cacheDate.day) {
        final h = t.hour;
        final m = t.minute;
        final cur = hourlyUV![h.clamp(0, hourlyUV!.length - 1)];
        final next = hourlyUV![(h + 1).clamp(0, hourlyUV!.length - 1)];
        return cur + (next - cur) * (m / 60.0);
      }
      return _lastUV; // fallback to last known
    }

    // Local copies to avoid mutating state
    final expFactor = () {
      switch (clothing ?? clothingLevel) {
        case ClothingLevel.none:
          return 1.0;
        case ClothingLevel.minimal:
          return 0.8;
        case ClothingLevel.light:
          return 0.5;
        case ClothingLevel.moderate:
          return 0.3;
        case ClothingLevel.heavy:
          return 0.1;
      }
    }();
    final sunFactor = () {
      switch (sunscreen ?? sunscreenLevel) {
        case SunscreenLevel.none:
          return 1.0;
        case SunscreenLevel.spf15:
          return 0.07;
        case SunscreenLevel.spf30:
          return 0.03;
        case SunscreenLevel.spf50:
          return 0.02;
        case SunscreenLevel.spf100:
          return 0.01;
      }
    }();
    final skinFactor = () {
      switch (skin ?? skinType) {
        case SkinType.type1:
          return 1.25;
        case SkinType.type2:
          return 1.1;
        case SkinType.type3:
          return 1.0;
        case SkinType.type4:
          return 0.7;
        case SkinType.type5:
          return 0.4;
        case SkinType.type6:
          return 0.2;
      }
    }();
    final ageFactor = _getAgeFactor();
    final adaptFactor = currentAdaptationFactor;

    double totalIU = 0.0;
    final totalMinutes = end.difference(start).inMinutes;
    DateTime cursor = DateTime(start.year, start.month, start.day, start.hour, start.minute);
    const baseRate = 21000.0;
    for (int i = 0; i < totalMinutes; i++) {
      final uv = uvAt(cursor);
      final uvFactor = (uv * _uvMaxFactor) / (_uvHalfMax + uv);
      final rate = baseRate * uvFactor * expFactor * sunFactor * skinFactor * ageFactor * adaptFactor;
      totalIU += rate / 60.0; // per minute contribution
      cursor = cursor.add(const Duration(minutes: 1));
    }
    return totalIU;
  }
}
