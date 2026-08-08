class HourlyWeather {
  const HourlyWeather({
    required this.time,
    required this.temperatureCelsius,
    required this.description,
    required this.windSpeedKmh,
  });

  final DateTime time;
  final double temperatureCelsius;
  final String description;
  final double windSpeedKmh;

  String get formattedTime {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
