import 'package:flutter/material.dart';

IconData weatherIconForDescription(String description) {
  final value = description.toLowerCase();

  if (value.contains('thunder')) {
    return Icons.thunderstorm_outlined;
  }
  if (value.contains('snow') || value.contains('hail')) {
    return Icons.ac_unit_outlined;
  }
  if (value.contains('rain') || value.contains('drizzle') || value.contains('shower')) {
    return Icons.water_drop_outlined;
  }
  if (value.contains('fog')) {
    return Icons.foggy;
  }
  if (value.contains('overcast') || value.contains('cloud')) {
    return Icons.cloud_outlined;
  }
  if (value.contains('clear')) {
    return Icons.wb_sunny_outlined;
  }

  return Icons.wb_cloudy_outlined;
}
