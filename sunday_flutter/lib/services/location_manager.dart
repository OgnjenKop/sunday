import 'package:flutter/material.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationManager extends ChangeNotifier {
  Position? location;
  Placemark? placemark;
  bool isUpdatingLocation = false;
  bool locationServicesEnabled = true;
  String locationName = '';
  Stream<Position>? _positionStream;
  StreamSubscription<Position>? _positionSub;

  Future<void> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        locationServicesEnabled = false;
        notifyListeners();
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      locationServicesEnabled = false;
      notifyListeners();
      return;
    }

    locationServicesEnabled = true;
    startUpdatingLocation();
  }

  Future<void> startUpdatingLocation() async {
    if (isUpdatingLocation) return;
    isUpdatingLocation = true;
    notifyListeners();

    try {
      location = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
      await _updatePlacemark();
    } catch (e) {
      print(e);
    } finally {
      isUpdatingLocation = false;
      notifyListeners();
    }
  }

  Future<void> startSignificantLocationChanges({double distanceFilterMeters = 500}) async {
    await _positionSub?.cancel();
    final locationSettings = LocationSettings(
      accuracy: LocationAccuracy.low,
      distanceFilter: distanceFilterMeters.toInt(),
    );
    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings);
    _positionSub = _positionStream!.listen((pos) async {
      location = pos;
      await _updatePlacemark();
      notifyListeners();
    });
  }

  Future<void> stopUpdatingLocation() async {
    await _positionSub?.cancel();
    _positionSub = null;
  }

  Future<void> _updatePlacemark() async {
    if (location != null) {
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          location!.latitude,
          location!.longitude,
        );
        if (placemarks.isNotEmpty) {
          placemark = placemarks.first;
          locationName = placemark?.locality ?? placemark?.administrativeArea ?? '';
        }
      } catch (e) {
        print(e);
      }
    }
  }
}
