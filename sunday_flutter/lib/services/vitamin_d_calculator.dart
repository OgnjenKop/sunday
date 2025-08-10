import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'uv_service.dart';
// import 'health_manager.dart';

enum ClothingLevel { none, minimal, light, moderate, heavy }
enum SunscreenLevel { none, spf15, spf30, spf50, spf100 }
enum SkinType { type1, type2, type3, type4, type5, type6 }

class VitaminDCalculator extends ChangeNotifier {
  bool isInSun = false;
  ClothingLevel clothingLevel = ClothingLevel.light;
  SunscreenLevel sunscreenLevel = SunscreenLevel.none;
  SkinType skinType = SkinType.type3;
  double currentVitaminDRate = 0.0;
  double sessionVitaminD = 0.0;
  DateTime? sessionStartTime;
  int? userAge;

  Timer? _timer;
  double _lastUV = 0.0;
  final UVService _uvService;
  // final HealthManager _healthManager;

  VitaminDCalculator(this._uvService) {
    _loadUserPreferences();
    _uvService.addListener(_onUVServiceChange);
    // _healthManager.addListener(_onHealthManagerChange);
  }

  void _onUVServiceChange() {
    updateUV(_uvService.currentUV);
  }

  // void _onHealthManagerChange() {
  //   _healthManager.getAge().then((age) {
  //     userAge = age;
  //     updateVitaminDRate(uvIndex: _lastUV);
  //   });
  // }

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
    _lastUV = uvIndex;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      updateVitaminD(uvIndex: _lastUV);
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
    notifyListeners();
  }

  void updateUV(double uvIndex) {
    _lastUV = uvIndex;
    updateVitaminDRate(uvIndex: uvIndex);
  }

  void updateVitaminDRate({required double uvIndex}) {
    const baseRate = 21000.0;
    final uvFactor = (uvIndex * 3.0) / (4.0 + uvIndex);
    final exposureFactor = _getExposureFactor();
    final sunscreenFactor = _getSunscreenFactor();
    final skinFactor = _getSkinFactor();
    final ageFactor = _getAgeFactor();

    currentVitaminDRate = baseRate * uvFactor * exposureFactor * sunscreenFactor * skinFactor * ageFactor;
    notifyListeners();
  }

  void updateVitaminD({required double uvIndex}) {
    if (!isInSun) return;
    updateVitaminDRate(uvIndex: uvIndex);
    sessionVitaminD += currentVitaminDRate / 3600.0;
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
    return 1.0 - (userAge! - 20) * 0.015;
  }

  @override
  void dispose() {
    _uvService.removeListener(_onUVServiceChange);
    // _healthManager.removeListener(_onHealthManagerChange);
    _timer?.cancel();
    super.dispose();
  }
}
