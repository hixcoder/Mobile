import 'dart:async';
import 'dart:js_interop';

import 'package:weather_app/services/location/location_service.dart';

@JS('navigator.geolocation')
external Geolocation? get _geolocation;

@JS()
extension type Geolocation._(JSObject _) implements JSObject {
  external void getCurrentPosition(
    JSFunction success,
    JSFunction error,
  );
}

@JS()
extension type GeolocationPosition._(JSObject _) implements JSObject {
  external GeolocationCoordinates get coords;
}

@JS()
extension type GeolocationCoordinates._(JSObject _) implements JSObject {
  external double get latitude;
  external double get longitude;
}

@JS()
extension type GeolocationPositionError._(JSObject _) implements JSObject {
  external int get code;
}

class WebLocationService implements LocationService {
  @override
  Future<LocationResult> getCurrentLocation() async {
    final geolocation = _geolocation;
    if (geolocation == null) {
      return const LocationResult.failure(LocationFailure.serviceDisabled);
    }

    final completer = Completer<LocationResult>();

    geolocation.getCurrentPosition(
      ((JSAny position) {
        final coords = (position as GeolocationPosition).coords;
        completer.complete(
          LocationResult.success(
            LocationCoordinates(
              latitude: coords.latitude,
              longitude: coords.longitude,
            ),
          ),
        );
      }).toJS,
      ((JSAny error) {
        final code = (error as GeolocationPositionError).code;
        completer.complete(
          LocationResult.failure(_mapBrowserError(code)),
        );
      }).toJS,
    );

    return completer.future;
  }

  LocationFailure _mapBrowserError(int code) {
    return switch (code) {
      1 => LocationFailure.permissionDenied,
      2 => LocationFailure.serviceDisabled,
      _ => LocationFailure.serviceDisabled,
    };
  }
}

LocationService createLocationService() => WebLocationService();
