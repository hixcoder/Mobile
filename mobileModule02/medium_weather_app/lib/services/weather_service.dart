import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:weather_app/models/place.dart';
import 'package:weather_app/models/weather_forecast.dart';

abstract interface class WeatherService {
  Future<WeatherForecast?> fetchForecast(Place place);
}

class OpenMeteoWeatherService implements WeatherService {
  OpenMeteoWeatherService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  @override
  Future<WeatherForecast?> fetchForecast(Place place) async {
    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: {
        'latitude': place.latitude.toString(),
        'longitude': place.longitude.toString(),
        'current': 'temperature_2m,weather_code,wind_speed_10m',
        'hourly': 'temperature_2m,weather_code,wind_speed_10m',
        'daily': 'weather_code,temperature_2m_max,temperature_2m_min',
        'timezone': 'auto',
        'forecast_days': '7',
      },
    );

    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      return null;
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['error'] == true) {
      return null;
    }

    return WeatherForecast(place: place);
  }
}

WeatherService createDefaultWeatherService() => OpenMeteoWeatherService();
