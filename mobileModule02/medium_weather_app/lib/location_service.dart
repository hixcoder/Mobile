import 'location_models.dart';
import 'platform_location_service.dart'
    if (dart.library.html) 'web_location_service.dart' as platform;

export 'location_models.dart';

abstract interface class LocationService {
  Future<LocationResult> getCurrentLocation();
}

LocationService createDefaultLocationService() =>
    platform.createLocationService();
