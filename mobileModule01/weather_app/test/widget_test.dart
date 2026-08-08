import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:weather_app/main.dart';

void main() {
  testWidgets('AppBar shows search field and geolocation button',
      (WidgetTester tester) async {
    await tester.pumpWidget(const WeatherApp());

    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.my_location), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);
  });
}
