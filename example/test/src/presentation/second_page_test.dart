import 'package:example/src/presentation/pages/second/second_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Second Page - reactive counter and list', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SecondPage()));

    expect(find.text('reactive 1'), findsOneWidget);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    expect(find.text('reactive 2'), findsOneWidget);

    expect(find.byType(ListTile), findsNothing);
    await tester.tap(find.text('Add to list'));
    await tester.pump();
    expect(find.byType(ListTile), findsOneWidget);
  });
}
