import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusforge/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: FocusForgeApp()));

    // Verify that the app builds and shows the main title (though title might be in window bar or not visible)
    // Just verifying it pumps without error is a good start for a smoke test.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
