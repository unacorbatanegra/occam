// ignore_for_file: public_member_api_docs
//
// StateController: the parts not already exercised by state_widget_test.dart
// (which covers the real lifecycle end to end) — build() being forbidden, and
// the OccamDebug print gate.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:occam/occam.dart';

void main() {
  tearDown(() => OccamDebug.debug = false);

  test('build() throws UnsupportedError, pointing at StateWidget.build', () {
    final controller = _NoopController();
    expect(
      () => controller.build(_FakeContext()),
      throwsA(
        isA<UnsupportedError>().having(
          (e) => e.message,
          'message',
          contains('StateWidget.build()'),
        ),
      ),
    );
  });

  testWidgets('OccamDebug.debug off: no lifecycle prints', (tester) async {
    final logs = await _capturePrints(() async {
      await tester.pumpWidget(const MaterialApp(home: _NoopWidget()));
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pump();
    });
    expect(logs, isEmpty);
  });

  testWidgets('OccamDebug.debug on: prints on init and dispose',
      (tester) async {
    OccamDebug.debug = true;
    final logs = await _capturePrints(() async {
      await tester.pumpWidget(const MaterialApp(home: _NoopWidget()));
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pump();
    });
    expect(logs, hasLength(2));
    expect(logs[0], contains('initialized'));
    expect(logs[1], contains('disposed'));
  });

  testWidgets('context narrows to StatefulElement', (tester) async {
    late StatefulElement captured;
    await tester.pumpWidget(
      MaterialApp(home: _ContextProbe(onReady: (c) => captured = c)),
    );
    await tester.pump();
    expect(captured, isA<StatefulElement>());
  });
}

Future<List<String>> _capturePrints(Future<void> Function() body) async {
  final logs = <String>[];
  await runZoned(
    body,
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) => logs.add(line),
    ),
  );
  return logs;
}

/// A `BuildContext` that's never actually touched — `build()` throws before
/// reading its argument, so any object satisfies the parameter.
class _FakeContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _NoopController extends StateController<_NoopWidget> {}

class _NoopWidget extends StateWidget<_NoopController> {
  const _NoopWidget();

  @override
  _NoopController createState() => _NoopController();

  @override
  Widget build(BuildContext context, _NoopController state) => const SizedBox();
}

class _ContextProbeController extends StateController<_ContextProbe> {
  @override
  void readyState() {
    widget.onReady(context);
    super.readyState();
  }
}

class _ContextProbe extends StateWidget<_ContextProbeController> {
  const _ContextProbe({required this.onReady});

  final ValueChanged<StatefulElement> onReady;

  @override
  _ContextProbeController createState() => _ContextProbeController();

  @override
  Widget build(BuildContext context, _ContextProbeController state) =>
      const SizedBox();
}
