import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('RentLanka app loads welcome screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: RentLankaApp()));
    await tester.pumpAndSettle();

    expect(find.text('RentLanka'), findsOneWidget);
  });
}
