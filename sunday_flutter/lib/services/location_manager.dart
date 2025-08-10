import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationManager extends ChangeNotifier {
  Position? location;
  Placemark? placemark;
  bool isUpdatingLocation = false;
  bool locationServicesEnabled = true;
  String locationName = '';

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
      location = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      await _updatePlacemark();
    } catch (e) {
      print(e);
    } finally {
      isUpdatingLocation = false;
      notifyListeners();
    }
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
