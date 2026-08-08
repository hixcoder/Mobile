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

    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Icon(
          Icons.location_on_outlined,
          color: colorScheme.primary,
          size: 28,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          softWrap: true,
          maxLines: 6,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
        ),
      ],
    );
  }
}
