import 'package:flutter/material.dart';

class WeatherMessageView extends StatelessWidget {
  const WeatherMessageView({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 40,
                  color: colorScheme.error,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  softWrap: true,
                  maxLines: 6,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colorScheme.error,
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
