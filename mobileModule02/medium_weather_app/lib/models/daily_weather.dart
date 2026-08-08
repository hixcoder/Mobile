class DailyWeather {
  const DailyWeather({
    required this.date,
    required this.minTemperatureCelsius,
    required this.maxTemperatureCelsius,
    required this.description,
  });

  final DateTime date;
  final double minTemperatureCelsius;
  final double maxTemperatureCelsius;
  final String description;

  String get formattedDate {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
