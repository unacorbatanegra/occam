// ignore_for_file: avoid_print
//
// Widget-level timing benchmarks — run with:
//   flutter test benchmark/widget_benchmark.dart
//
// Informational only, not CI-gated (see rx_notifier_benchmark.dart): widget
// build/layout/paint timing is too CI-runner-dependent for hard thresholds.
// Kept out of test/ so the coverage-gated `flutter test` run never picks it
// up. Uses tester.pumpWidget + Stopwatch rather than flutter_test's
// benchmarkWidgets — that helper is meant for profile-mode `flutter run`
// against a real device, not `flutter test`'s software renderer.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:occam/occam.dart';

void main() {
  testWidgets('mounting N StateWidget vs N plain StatefulWidget',
      (tester) async {
    // Warm up compilation/first-pump cost so it doesn't skew the n=1 sample.
    await _time(tester, const _OccamLeaf());
    await _time(tester, const _PlainLeaf());

    for (final n in [1, 100, 1000]) {
      final occamTime = await _time(
        tester,
        Column(children: [for (var i = 0; i < n; i++) const _OccamLeaf()]),
      );
      final plainTime = await _time(
        tester,
        Column(children: [for (var i = 0; i < n; i++) const _PlainLeaf()]),
      );
      print('n=$n  StateWidget: ${occamTime.inMicroseconds}us  '
          'StatefulWidget: ${plainTime.inMicroseconds}us  '
          '(+${occamTime.inMicroseconds - plainTime.inMicroseconds}us for occam)');
    }
  });

  testWidgets('RxWidget rebuild cost: tight vs wrapping N extra children',
      (tester) async {
    for (final n in [0, 100, 1000]) {
      final notifier = 0.rx;
      await tester.pumpWidget(
        MaterialApp(
          home: RxWidget<int>(
            notifier: notifier,
            builder: (ctx, value) => SingleChildScrollView(
              child: Column(
                children: [
                  Text('$value'),
                  for (var i = 0; i < n; i++) const SizedBox(height: 1),
                ],
              ),
            ),
          ),
        ),
      );

      final stopwatch = Stopwatch()..start();
      notifier.value++;
      await tester.pump();
      stopwatch.stop();
      notifier.dispose();

      print('extra children=$n  rebuild: ${stopwatch.elapsedMicroseconds}us');
    }
  });

  testWidgets('ParentState resolution cost vs ancestor depth', (tester) async {
    for (final depth in [10, 100, 500]) {
      Widget tree = const _DeepConsumer();
      for (var i = 0; i < depth; i++) {
        tree = SizedBox(child: tree);
      }

      final stopwatch = Stopwatch()..start();
      await tester.pumpWidget(
        MaterialApp(home: _DeepHost(child: tree)),
      );
      stopwatch.stop();

      print('depth=$depth  first build (mount + resolve): '
          '${stopwatch.elapsedMicroseconds}us');
    }
  });
}

Future<Duration> _time(WidgetTester tester, Widget child) async {
  final stopwatch = Stopwatch()..start();
  await tester.pumpWidget(MaterialApp(home: child));
  stopwatch.stop();
  return stopwatch.elapsed;
}

class _OccamController extends StateController<_OccamLeaf> {}

class _OccamLeaf extends StateWidget<_OccamController> {
  const _OccamLeaf();

  @override
  _OccamController createState() => _OccamController();

  @override
  Widget build(BuildContext context, _OccamController state) =>
      const SizedBox();
}

class _PlainLeaf extends StatefulWidget {
  const _PlainLeaf();

  @override
  State<_PlainLeaf> createState() => _PlainLeafState();
}

class _PlainLeafState extends State<_PlainLeaf> {
  @override
  Widget build(BuildContext context) => const SizedBox();
}

class _DeepHostController extends StateController<_DeepHost> {}

/// Provides a controller [depth] levels above [_DeepConsumer].
class _DeepHost extends StateWidget<_DeepHostController> {
  const _DeepHost({required this.child});

  final Widget child;

  @override
  _DeepHostController createState() => _DeepHostController();

  @override
  Widget build(BuildContext context, _DeepHostController state) => child;
}

/// Resolves the ancestor [_DeepHostController] via [visitAncestorElements],
/// [depth] `SizedBox`es below it.
class _DeepConsumer extends ParentState<_DeepHostController> {
  const _DeepConsumer();

  @override
  Widget build(BuildContext context, _DeepHostController state) =>
      const SizedBox();
}
