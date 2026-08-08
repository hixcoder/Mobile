import 'package:weather_app/models/place.dart';
import 'package:weather_app/models/weather_forecast.dart';

enum ServiceFailure {
  notFound,
  connectionError,
}

class GeocodingSearchResult {
  const GeocodingSearchResult._({
    this.places,
    this.failure,
  });

  const GeocodingSearchResult.success(List<Place> places)
      : this._(places: places);

  const GeocodingSearchResult.failure(ServiceFailure failure)
      : this._(failure: failure);

  final List<Place>? places;
  final ServiceFailure? failure;

  bool get isSuccess => places != null;
}

class WeatherFetchResult {
  const WeatherFetchResult._({
    this.forecast,
    this.failure,
  });

  const WeatherFetchResult.success(WeatherForecast forecast)
      : this._(forecast: forecast);

  const WeatherFetchResult.failure(ServiceFailure failure)
      : this._(failure: failure);

  final WeatherForecast? forecast;
  final ServiceFailure? failure;

  bool get isSuccess => forecast != null;
}
