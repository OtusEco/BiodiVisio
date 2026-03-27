import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

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
  // On récupère rapidement une position puis on l'améliore en arrière-plan (GPS)
  static Future<LocationResult> getUserLocation({
    Function(LatLng position)? onRefined,
    Function()? gpsError,
  }) async {
    final permissionResult = await _checkPermissions();
    if (permissionResult != null) return permissionResult;

    try {
      // Localisation réseau
      final networkPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 3),
        ),
      );

      final networkLatLng = LatLng(
        networkPosition.latitude,
        networkPosition.longitude,
      );

      // Amélioration de la position en arrière plan
      _refinePosition(
        networkLatLng,
        onRefined,
        gpsError,
      );

      return LocationResult.success(networkLatLng);
    } catch (_) {
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
    }
  }

  // Amélioration de la position en arrière plan
  static void _refinePosition(
    LatLng initial,
    Function(LatLng position)? onRefined,
    Function()? gpsError,
  ) async {
    if (onRefined == null) return;

    try {
      final gpsPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final refined = LatLng(
        gpsPosition.latitude,
        gpsPosition.longitude,
      );

      final distance = const Distance().as(
        LengthUnit.Meter,
        initial,
        refined,
      );

      // Mise à jour si la nouvelle position est à >20m de l'ancienne
      if (distance > 20 || gpsPosition.accuracy < 20) {
        onRefined(refined);
      }
    } catch (_) {
      if (gpsError != null) gpsError();
    }
  }

  // Permissions
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