import 'package:flutter/material.dart';
import 'package:weather_app/models/place.dart';

class LocationHeader extends StatelessWidget {
  const LocationHeader({
    super.key,
    required this.place,
    this.fallbackLabel,
  });

  final Place? place;
  final String? fallbackLabel;

  @override
  Widget build(BuildContext context) {
    final label = place?.displayLabel ?? fallbackLabel;
    if (label == null || label.isEmpty) {
      return const SizedBox.shrink();
    }

    return Text(
      label,
      textAlign: TextAlign.center,
      softWrap: true,
      maxLines: 6,
      style: Theme.of(context).textTheme.titleLarge,
    );
  }
}
