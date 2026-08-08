import 'package:flutter/services.dart';

import 'location_service.dart';

class PlatformLocationService implements LocationService {
  static const _channel = MethodChannel('com.example.weather_app/geolocation');

  @override
  Future<LocationResult> getCurrentLocation() async {
    try {
      final response =
          await _channel.invokeMapMethod<String, dynamic>('getCurrentLocation');
      if (response == null) {
        return const LocationResult.failure(LocationFailure.serviceDisabled);
      }

      final error = response['error'];
      if (error is String) {
        return LocationResult.failure(_parseError(error));
      }

      final latitude = response['latitude'];
      final longitude = response['longitude'];
      if (latitude is! num || longitude is! num) {
        return const LocationResult.failure(LocationFailure.serviceDisabled);
      }

      return LocationResult.success(
        LocationCoordinates(
          latitude: latitude.toDouble(),
          longitude: longitude.toDouble(),
        ),
      );
    } on MissingPluginException {
      return const LocationResult.failure(LocationFailure.serviceDisabled);
    } on PlatformException {
      return const LocationResult.failure(LocationFailure.serviceDisabled);
    }
  }

  LocationFailure _parseError(String error) {
    return switch (error) {
      'permissionDenied' => LocationFailure.permissionDenied,
      'permissionDeniedForever' => LocationFailure.permissionDeniedForever,
      _ => LocationFailure.serviceDisabled,
    };
  }
}

LocationService createLocationService() => PlatformLocationService();
