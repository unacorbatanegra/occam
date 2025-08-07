import 'package:example/main.dart';
import 'package:example/src/presentation/pages/second/second_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets("Home Page - reactive int", (tester) async {
    await tester.pumpWidget(MyApp());

    final button = find.byType(FloatingActionButton);
    expect(button, findsOneWidget);
    expect(find.text("1"), findsOneWidget);
    await tester.tap(button);
    await tester.pump();
    expect(find.text("2"), findsOneWidget);
    expect(find.text("1"), findsNothing);
  });
  testWidgets("Home Page - reactive model", (tester) async {
    await tester.pumpWidget(MyApp());

    final button = find.byType(CupertinoButton);
    expect(button, findsOneWidget);
    expect(find.text("reactive Nico"), findsOneWidget);
    await tester.tap(button);
    await tester.pump();
    expect(find.text("reactive unacorbatanegra"), findsOneWidget);
    expect(find.text("reactive Nico"), findsNothing);
  });
  testWidgets("Home Page - test navigation", (tester) async {
    await tester.pumpWidget(MyApp());

    final button = find.byType(ElevatedButton);
    expect(button, findsOneWidget);

    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.byType(SecondPage), findsOneWidget);
  });
}
