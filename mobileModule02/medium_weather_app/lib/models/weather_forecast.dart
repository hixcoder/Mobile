import 'package:weather_app/models/current_weather.dart';
import 'package:weather_app/models/daily_weather.dart';
import 'package:weather_app/models/hourly_weather.dart';
import 'package:weather_app/models/place.dart';

class WeatherForecast {
  const WeatherForecast({
    required this.place,
    required this.current,
    required this.todayHourly,
    required this.weekly,
  });

  final Place place;
  final CurrentWeather current;
  final List<HourlyWeather> todayHourly;
  final List<DailyWeather> weekly;
}
