import 'package:geolocator/geolocator.dart';
import 'dart:developer' as developer;

class LocationService {
  /// Check location permission and request if not granted.
  Future<bool> checkAndRequestPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      developer.log('Location services are disabled.');
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        developer.log('Location permissions are denied.');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      developer.log('Location permissions are permanently denied.');
      return false;
    }

    return true;
  }

  /// Get current device GPS location.
  Future<Position?> getCurrentLocation() async {
    final hasPermission = await checkAndRequestPermission();
    if (!hasPermission) return null;

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      developer.log('Error getting current location: $e');
      return null;
    }
  }

  /// Starts listening to real-time location updates.
  Stream<Position>? startLocationStream({
    int distanceFilter = 10,
    int timeInterval = 5,
  }) {
    try {
      return Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: distanceFilter,
          timeLimit: Duration(seconds: timeInterval * 2),
        ),
      );
    } catch (e) {
      developer.log('Error starting location stream: $e');
      return null;
    }
  }

  /// Calculates the distance in meters between two points.
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }
}
