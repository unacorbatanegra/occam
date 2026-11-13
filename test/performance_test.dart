// ignore_for_file: public_member_api_docs, avoid_print
//
// Performance regression gates. Nothing here asserts an absolute time (that
// depends on the machine); it asserts
//   1. exact rebuild counts (deterministic),
//   2. ratios against the plain-Flutter equivalent, measured in the same
//      process, taking the best of several runs to cancel scheduler noise,
//   3. that cost scales linearly, not quadratically.
// The limits are loose on purpose: they catch an order-of-magnitude
// regression, not a 10% drift.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:occam/occam.dart';

const _runs = 7;

/// Best (minimum) wall time in microseconds of [body] over [_runs] runs.
int _best(void Function() body) {
  body(); // warm-up: JIT + first-call costs
  var best = 1 << 62;
  for (var i = 0; i < _runs; i++) {
    final sw = Stopwatch()..start();
    body();
    sw.stop();
    if (sw.elapsedMicroseconds < best) best = sw.elapsedMicroseconds;
  }
  return best < 1 ? 1 : best;
}

Future<int> _bestAsync(Future<void> Function() body) async {
  await body();
  var best = 1 << 62;
  for (var i = 0; i < _runs; i++) {
    final sw = Stopwatch()..start();
    await body();
    sw.stop();
    if (sw.elapsedMicroseconds < best) best = sw.elapsedMicroseconds;
  }
  return best < 1 ? 1 : best;
}

void _expectRatio(String what, int occam, int baseline, double limit) {
  final ratio = occam / baseline;
  print('$what: occam=${occam}us baseline=${baseline}us '
      'ratio=${ratio.toStringAsFixed(2)} (limit $limit)');
  expect(
    ratio,
    lessThan(limit),
    reason: '$what is ${ratio.toStringAsFixed(2)}x the plain-Flutter '
        'baseline (limit ${limit}x)',
  );
}

void main() {
  group('rebuild counts', () {
    testWidgets('a change rebuilds only the RxWidget that listens',
        (tester) async {
      final a = 0.rx;
      final b = 0.rx;
      addTearDown(a.dispose);
      addTearDown(b.dispose);
      var parent = 0, rxA = 0, rxB = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(builder: (_) {
            parent++;
            return Column(
              children: [
                RxWidget<int>(
                  notifier: a,
                  builder: (_, v) {
                    rxA++;
                    return Text('a$v');
                  },
                ),
                RxWidget<int>(
                  notifier: b,
                  builder: (_, v) {
                    rxB++;
                    return Text('b$v');
                  },
                ),
              ],
            );
          }),
        ),
      );
      expect([parent, rxA, rxB], [1, 1, 1]);

      a.value++;
      await tester.pump();
      expect([parent, rxA, rxB], [1, 2, 1], reason: 'only A rebuilds');

      b.value++;
      await tester.pump();
      expect([parent, rxA, rxB], [1, 2, 2], reason: 'only B rebuilds');
    });

    testWidgets('setting an equal value rebuilds nothing', (tester) async {
      final rx = 5.rx;
      addTearDown(rx.dispose);
      var builds = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: RxWidget<int>(
            notifier: rx,
            builder: (_, v) {
              builds++;
              return Text('$v');
            },
          ),
        ),
      );
      for (var i = 0; i < 100; i++) {
        rx.value = 5;
      }
      await tester.pump();
      expect(builds, 1);
    });

    testWidgets('N RxWidgets on one Rx: one change = exactly N rebuilds',
        (tester) async {
      const n = 1000;
      final rx = 0.rx;
      addTearDown(rx.dispose);
      var builds = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: SingleChildScrollView(
            child: Column(
              children: [
                for (var i = 0; i < n; i++)
                  RxWidget<int>(
                    notifier: rx,
                    builder: (_, v) {
                      builds++;
                      return const SizedBox(height: 1);
                    },
                  ),
              ],
            ),
          ),
        ),
      );
      expect(builds, n);
      rx.value++;
      await tester.pump();
      expect(builds, 2 * n);
    });

    testWidgets('many changes in one frame coalesce into one rebuild',
        (tester) async {
      final rx = 0.rx;
      addTearDown(rx.dispose);
      var builds = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: RxWidget<int>(
            notifier: rx,
            builder: (_, v) {
              builds++;
              return Text('$v');
            },
          ),
        ),
      );
      for (var i = 0; i < 500; i++) {
        rx.value++;
      }
      await tester.pump();
      expect(builds, 2, reason: '1 initial + 1 for the whole burst');
      expect(find.text('500'), findsOneWidget);
    });

    testWidgets('a StateWidget does not rebuild when its Rx changes',
        (tester) async {
      _Counting.builds = 0;
      await tester.pumpWidget(const MaterialApp(home: _Counting()));
      expect(_Counting.builds, 1);
      _CountingController.last.rx.value++;
      await tester.pump();
      expect(_Counting.builds, 1, reason: 'only the inner RxWidget rebuilds');
      expect(find.text('1'), findsOneWidget);
    });
  });

  group('ratio vs plain Flutter', () {
    test('Rx.value= with a listener vs ValueNotifier.value=', () {
      const ops = 20000;
      final rx = 0.rx;
      final plain = ValueNotifier<int>(0);
      void noop() {}
      rx.addListener(noop);
      plain.addListener(noop);
      final occam = _best(() {
        for (var i = 0; i < ops; i++) {
          rx.value = i + 1;
        }
      });
      final base = _best(() {
        for (var i = 0; i < ops; i++) {
          plain.value = i + 1;
        }
      });
      rx.dispose();
      plain.dispose();
      _expectRatio('set+notify', occam, base, 3);
    });

    test('RxList.add vs List.add + notifyListeners', () {
      const ops = 20000;
      final rx = RxList<int>();
      final plain = <int>[];
      final notifier = ChangeNotifier();
      void noop() {}
      rx.addListener(noop);
      notifier.addListener(noop);
      final occam = _best(() {
        rx.clear();
        for (var i = 0; i < ops; i++) {
          rx.add(i);
        }
      });
      final base = _best(() {
        plain.clear();
        for (var i = 0; i < ops; i++) {
          plain.add(i);
          // ignore: invalid_use_of_protected_member
          notifier.notifyListeners();
        }
      });
      rx.dispose();
      notifier.dispose();
      _expectRatio('list add+notify', occam, base, 3);
    });

    testWidgets('mount 1000 StateWidget vs 1000 StatefulWidget',
        (tester) async {
      const n = 1000;
      Future<void> mount(Widget Function() leaf) async {
        await tester.pumpWidget(
          MaterialApp(
            home: SingleChildScrollView(
              child: Column(children: [for (var i = 0; i < n; i++) leaf()]),
            ),
          ),
        );
        await tester.pumpWidget(const SizedBox());
      }

      final occam = await _bestAsync(() => mount(() => const _OccamLeaf()));
      final base = await _bestAsync(() => mount(() => const _PlainLeaf()));
      _expectRatio('mount+unmount $n', occam, base, 3);
    });

    testWidgets('RxWidget rebuild vs ValueListenableBuilder', (tester) async {
      const n = 300;
      final rx = 0.rx;
      final plain = ValueNotifier<int>(0);
      addTearDown(rx.dispose);
      addTearDown(plain.dispose);

      Future<int> measure(Widget Function(int i) leaf) async {
        await tester.pumpWidget(
          MaterialApp(
            home: SingleChildScrollView(
              child: Column(children: [for (var i = 0; i < n; i++) leaf(i)]),
            ),
          ),
        );
        final t = await _bestAsync(() async {
          rx.value++;
          plain.value++;
          await tester.pump();
        });
        await tester.pumpWidget(const SizedBox());
        return t;
      }

      final occam = await measure(
        (_) => RxWidget<int>(
          notifier: rx,
          builder: (_, v) => Text('$v'),
        ),
      );
      final base = await measure(
        (_) => ValueListenableBuilder<int>(
          valueListenable: plain,
          builder: (_, v, __) => Text('$v'),
        ),
      );
      _expectRatio('rebuild $n listeners', occam, base, 2);
    });
  });

  group('scaling', () {
    /// Time per element for [n] and [n * 10]; linear => ratio ~1,
    /// quadratic => ratio ~10.
    void expectLinear(String what, int Function(int n) timeFor,
        {double limit = 4}) {
      const small = 2000;
      final perSmall = timeFor(small) / small;
      final perBig = timeFor(small * 10) / (small * 10);
      final growth = perBig / perSmall;
      print('$what: ${perSmall.toStringAsFixed(3)}us/elem @ $small -> '
          '${perBig.toStringAsFixed(3)}us/elem @ ${small * 10} '
          '(growth ${growth.toStringAsFixed(2)}x, limit ${limit}x)');
      expect(growth, lessThan(limit),
          reason: '$what per-element cost grew ${growth.toStringAsFixed(2)}x '
              'for 10x elements — not linear');
    }

    test('notifyListeners scales linearly with listener count', () {
      expectLinear('notify', (n) {
        final rx = 0.rx;
        for (var i = 0; i < n; i++) {
          rx.addListener(() {});
        }
        final t = _best(() {
          for (var i = 0; i < 20; i++) {
            rx.refresh();
          }
        });
        rx.dispose();
        return t;
      });
    });

    test('adding listeners scales linearly', () {
      expectLinear('addListener', (n) {
        final listeners = [for (var i = 0; i < n; i++) () {}];
        return _best(() {
          final rx = 0.rx;
          for (final l in listeners) {
            rx.addListener(l);
          }
          rx.dispose();
        });
      });
    });

    test('add+remove listeners stays close to plain ValueNotifier (ratio)', () {
      const n = 5000;
      final listeners = [for (var i = 0; i < n; i++) () {}];
      final occam = _best(() {
        final rx = 0.rx;
        for (final l in listeners) {
          rx.addListener(l);
        }
        for (final l in listeners) {
          rx.removeListener(l);
        }
        rx.dispose();
      });
      final base = _best(() {
        final v = ValueNotifier<int>(0);
        for (final l in listeners) {
          v.addListener(l);
        }
        for (final l in listeners) {
          v.removeListener(l);
        }
        v.dispose();
      });
      // Was ~7x while removeListener also searched a second list.
      _expectRatio('add+remove $n', occam, base, 3);
    });

    testWidgets('ParentState resolution is linear in ancestor depth',
        (tester) async {
      Future<int> timeFor(int depth) async {
        Widget tree = const _DeepConsumer();
        for (var i = 0; i < depth; i++) {
          tree = SizedBox(child: tree);
        }
        return _bestAsync(() async {
          await tester.pumpWidget(MaterialApp(home: _DeepHost(child: tree)));
          await tester.pumpWidget(const SizedBox());
        });
      }

      final shallow = await timeFor(100);
      final deep = await timeFor(1000);
      final growth = (deep / 1000) / (shallow / 100);
      print('ParentState depth: ${shallow}us @100, ${deep}us @1000 '
          '(per-level growth ${growth.toStringAsFixed(2)}x)');
      expect(growth, lessThan(4));
    });
  });
}

class _CountingController extends StateController<_Counting> {
  static late _CountingController last;
  final rx = 0.rx;

  @override
  void initState() {
    super.initState();
    last = this;
  }

  @override
  void dispose() {
    rx.dispose();
    super.dispose();
  }
}

class _Counting extends StateWidget<_CountingController> {
  const _Counting();
  static int builds = 0;

  @override
  _CountingController createState() => _CountingController();

  @override
  Widget build(BuildContext context, _CountingController state) {
    builds++;
    return RxWidget<int>(
      notifier: state.rx,
      builder: (_, v) => Text('$v'),
    );
  }
}

class _OccamController extends StateController<_OccamLeaf> {}

class _OccamLeaf extends StateWidget<_OccamController> {
  const _OccamLeaf();

  @override
  _OccamController createState() => _OccamController();

  @override
  Widget build(BuildContext context, _OccamController state) =>
      const SizedBox(height: 1);
}

class _PlainLeaf extends StatefulWidget {
  const _PlainLeaf();

  @override
  State<_PlainLeaf> createState() => _PlainLeafState();
}

class _PlainLeafState extends State<_PlainLeaf> {
  @override
  Widget build(BuildContext context) => const SizedBox(height: 1);
}

class _DeepHostController extends StateController<_DeepHost> {}

class _DeepHost extends StateWidget<_DeepHostController> {
  const _DeepHost({required this.child});

  final Widget child;

  @override
  _DeepHostController createState() => _DeepHostController();

  @override
  Widget build(BuildContext context, _DeepHostController state) => child;
}

class _DeepConsumer extends ParentState<_DeepHostController> {
  const _DeepConsumer();

  @override
  Widget build(BuildContext context, _DeepHostController state) =>
      const SizedBox();
}
