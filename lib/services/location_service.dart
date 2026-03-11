import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

enum LocationErrorType {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  unknown,
}

class LocationResult {
  final LatLng? position;
  final LocationErrorType? error;

  const LocationResult.success(this.position) : error = null;

  const LocationResult.failure(this.error) : position = null;

  bool get isSuccess => position != null;
}

class LocationService {
  static Future<LocationResult> getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      return const LocationResult.failure(LocationErrorType.serviceDisabled);
    }

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        return const LocationResult.failure(LocationErrorType.permissionDenied);
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return const LocationResult.failure(
        LocationErrorType.permissionDeniedForever,
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      return LocationResult.success(
        LatLng(position.latitude, position.longitude),
      );
    } catch (_) {
      return const LocationResult.failure(LocationErrorType.unknown);
    }
  }
}
