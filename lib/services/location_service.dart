import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';

enum LocationErrorType {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
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
    final permissionResult = await _checkPermissions();

    if (permissionResult != null) {
      return permissionResult;
    }

    try {
      // Position instantanée si disponible
      final lastPosition = await Geolocator.getLastKnownPosition();

      if (lastPosition != null) {
        return LocationResult.success(
          LatLng(lastPosition.latitude, lastPosition.longitude),
        );
      }

      // Localisation réseau
      final networkPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 3),
        ),     
      );

      return LocationResult.success(
        LatLng(networkPosition.latitude, networkPosition.longitude),
      );
    } on TimeoutException {
      try {
        // Localisation GPS
        final gpsPosition = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );

        return LocationResult.success(
          LatLng(gpsPosition.latitude, gpsPosition.longitude),
        );
      } catch (_) {
        return const LocationResult.failure(LocationErrorType.timeout);
      }
    } catch (_) {
      return const LocationResult.failure(LocationErrorType.unknown);
    }
  }

  static Future<LocationResult?> _checkPermissions() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      return const LocationResult.failure(LocationErrorType.serviceDisabled);
    }

    var permission = await Geolocator.checkPermission();

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

    return null;
  }
}