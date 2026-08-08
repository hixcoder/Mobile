import 'package:weather_app/models/location_models.dart';
import 'package:weather_app/services/location/platform_location_service.dart'
    if (dart.library.html) 'package:weather_app/services/location/web_location_service.dart'
    as platform;

export 'package:weather_app/models/location_models.dart';

abstract interface class LocationService {
  Future<LocationResult> getCurrentLocation();
}

LocationService createDefaultLocationService() =>
    platform.createLocationService();
