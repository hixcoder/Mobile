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
    expect(find.byType(BottomAppBar), findsOneWidget);
    expect(find.text('Currently'), findsWidgets);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Weekly'), findsOneWidget);
  });

  testWidgets('Search updates all tabs with entered text',
      (WidgetTester tester) async {
    await tester.pumpWidget(const WeatherApp());

    await tester.enterText(find.byType(TextField), 'Paris');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('Currently Paris'), findsOneWidget);
    expect(find.text('Today Paris'), findsNothing);

    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();

    expect(find.text('Today Paris'), findsOneWidget);

    await tester.tap(find.text('Weekly'));
    await tester.pumpAndSettle();

    expect(find.text('Weekly Paris'), findsOneWidget);
  });

  testWidgets('Geolocation button updates all tabs with Geolocation',
      (WidgetTester tester) async {
    await tester.pumpWidget(const WeatherApp());

    await tester.tap(find.byIcon(Icons.my_location));
    await tester.pumpAndSettle();

    expect(find.text('Currently Geolocation'), findsOneWidget);

    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();

    expect(find.text('Today Geolocation'), findsOneWidget);

    await tester.tap(find.text('Weekly'));
    await tester.pumpAndSettle();

    expect(find.text('Weekly Geolocation'), findsOneWidget);
  });
}
