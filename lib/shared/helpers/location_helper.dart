import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationException implements Exception {
  final String key;
  const LocationException(this.key);
}

class LocationHelper {
  static Future<Position> getCurrentPosition({
    Duration timeLimit = const Duration(seconds: 10),
    bool rejectMocked = true,
  }) async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) throw const LocationException('enable_location_services');

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationException('location_permission_denied');
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException('permission_permanently_denied');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: timeLimit,
      ),
    );

    if (rejectMocked && position.isMocked) {
      throw const LocationException('mock_location_detected');
    }
    return position;
  }

  static double distanceMeters(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  /// Best-effort reverse geocoding; returns `null` when offline or unavailable.
  static Future<String?> resolveAddress(double lat, double lng) async {
    try {
      final placemarks = await Geocoding()
          .placemarkFromCoordinates(lat, lng)
          .timeout(const Duration(seconds: 3));
      if (placemarks.isEmpty) return null;
      final place = placemarks.first;
      final parts = <String>[
        if ((place.street ?? '').trim().isNotEmpty) place.street!.trim(),
        if ((place.subLocality ?? '').trim().isNotEmpty)
          place.subLocality!.trim(),
        if ((place.locality ?? '').trim().isNotEmpty) place.locality!.trim(),
      ];
      return parts.isEmpty ? null : parts.toSet().join(', ');
    } catch (_) {
      return null;
    }
  }
}
