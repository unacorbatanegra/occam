import 'package:example/main.dart';
import 'package:example/src/presentation/pages/second/second_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Home Page - reactive int', (tester) async {
    await tester.pumpWidget(const MyApp());

    final button = find.byType(FloatingActionButton);
    expect(button, findsOneWidget);
    expect(find.text('reactive 1'), findsOneWidget);
    await tester.tap(button);
    await tester.pump();
    expect(find.text('reactive 2'), findsOneWidget);
    expect(find.text('reactive 1'), findsNothing);
  });

  testWidgets('Home Page - reactive model', (tester) async {
    await tester.pumpWidget(const MyApp());

    final button = find.widgetWithText(CupertinoButton, 'Change reactive');
    expect(button, findsOneWidget);
    expect(find.text('reactive Nico'), findsOneWidget);
    await tester.tap(button);
    await tester.pump();
    expect(find.text('reactive unacorbatanegra'), findsOneWidget);
    expect(find.text('reactive Nico'), findsNothing);
  });

  testWidgets('Home Page - ChildConsumer reaches the ancestor controller',
      (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('reactive Nico'), findsOneWidget);
    await tester.tap(find.text('child consumer'));
    await tester.pump();
    expect(find.text('reactive unacorbatanegra'), findsOneWidget);
  });

  testWidgets(
      'Home Page - NestedChild reaches the ancestor controller directly',
      (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('reactive 1'), findsOneWidget);
    await tester.tap(find.text('nested child'));
    await tester.pump();
    expect(find.text('reactive 2'), findsOneWidget);
  });

  testWidgets(
      'Home Page - TestStateless (nested ParentState) reaches the ancestor',
      (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('reactive 1'), findsOneWidget);
    await tester.tap(find.text('This is a test'));
    await tester.pump();
    expect(find.text('reactive 2'), findsOneWidget);
  });

  testWidgets('Home Page - test navigation', (tester) async {
    await tester.pumpWidget(const MyApp());

    // The demo sections no longer all fit one screen — scroll the button
    // into view before tapping it.
    await tester.ensureVisible(find.text('To Second page'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('To Second page'));
    await tester.pumpAndSettle();
    expect(find.byType(SecondPage), findsOneWidget);
  });
}
