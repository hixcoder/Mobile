class CurrentWeather {
  const CurrentWeather({
    required this.temperatureCelsius,
    required this.description,
    required this.windSpeedKmh,
  });

  final double temperatureCelsius;
  final String description;
  final double windSpeedKmh;
}
