// ignore_for_file: public_member_api_docs, avoid_print
//
// Instance-isolation suite for StateWidget.
//
// ---------------------------------------------------------------------------
// WHAT THIS FILE USED TO TEST, AND WHY IT CHANGED
// ---------------------------------------------------------------------------
// `StateWidget.state` used to be a getter that resolved the controller from
// ambient static state: a per-widget build stack, plus a registry keyed by
// `identical(element.widget, widget)` as a fallback for reads evaluated after
// build() had returned. Measured behaviour with one widget object mounted 4
// times (a `const` widget reused on a page, e.g. a banner or a category row):
//
//   mounted controllers: [lex-0, lex-1, lex-2, lex-3]
//     lex-0 rendered 4 time(s)
//     lex-1 rendered 0 time(s)   <- alive, and unreachable from its own UI
//     lex-2 rendered 0 time(s)
//     lex-3 rendered 0 time(s)
//
// The question "which of the 4 instances is asking?" had no answer: a getter's
// only input is the widget object, and that object was shared. It was answered
// with a silent guess — always the first-mounted instance.
//
// The fix removed the question. `build` now receives the controller:
//
//     Widget build(BuildContext context, T state)
//
// Closures created during build capture that parameter, so a read inside a
// `builder:` or a tap callback — which runs long after build() returned — still
// refers to the right instance. There is no ambient lookup left to get wrong.
//
// So the old detectors are gone: they asserted things about `widget.state`,
// which no longer exists. Cross-instance leakage is now a compile-time
// impossibility rather than a runtime invariant. What remains worth testing:
//
//   1. instance isolation at scale — the plumbing in StateElement.build()
//      passes each element its OWN controller. If that regressed, or if an
//      ambient lookup were reintroduced, these go red.
//   2. deferred reads — the exact shapes that used to leak still work.
//   3. the controller lifecycle — one initState / readyState / dispose per
//      instance, stable identity across rebuilds, never handed out after
//      dispose.
//
// Run both ways; `--no-track-widget-creation` reproduces release const
// behaviour, where separate `const Probe()` expressions collide into one object:
//   flutter test test/lyfe_cicle/state_identity_test.dart
//   flutter test test/lyfe_cicle/state_identity_test.dart --no-track-widget-creation

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:occam/occam.dart';

void main() {
  setUp(ProbeController.reset);

  test('diagnostic: which const forms end up as the same object', () {
    const inlineA = Probe();
    const inlineB = Probe();
    print('kProbe             -> ${identityHashCode(kProbe)}');
    print('const Probe() A    -> ${identityHashCode(inlineA)}');
    print('const Probe() B    -> ${identityHashCode(inlineB)}');
    print('kProbe === inline   : ${identical(kProbe, inlineA)}');
    print('inlineA === inlineB : ${identical(inlineA, inlineB)}');
    print(identical(inlineA, inlineB)
        ? 'MODE: release-like, separate const expressions collide too'
        : 'MODE: debug, only reused references/sites collide');

    expect(identical(kProbe, kProbe), isTrue);
  });

  group('instance isolation', () {
    // Every scenario mounts ONE widget object several times — the setup that
    // used to be unresolvable. Each instance must show its own data.

    testWidgets('2 instances of one widget object', (tester) async {
      await pumpProbes(tester, 2);
      await expectInstanceIsolation(tester, 2);
    });

    testWidgets('one const site evaluated twice (route-builder pattern)',
        (tester) async {
      await pumpHarness(tester, Column(children: [buildProbe(), buildProbe()]));
      await expectInstanceIsolation(tester, 2);
    });

    testWidgets('same object mounted at different depths', (tester) async {
      await pumpHarness(
        tester,
        Column(
          children: const [
            kProbe,
            Padding(
              padding: EdgeInsets.zero,
              child: Center(child: kProbe),
            ),
          ],
        ),
      );
      await expectInstanceIsolation(tester, 2);
    });

    testWidgets('instances kept alive in an IndexedStack (tab pattern)',
        (tester) async {
      await pumpHarness(
        tester,
        const IndexedStack(index: 0, children: [kProbe, kProbe, kProbe]),
      );
      // Only the selected child is painted, so assert on controllers, not text.
      await expectDistinctControllers(tester, 3);
    });

    testWidgets('instances across a nested Navigator', (tester) async {
      // Not pumpHarness: Expanded needs a bounded height, so no scroll view.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                kProbe,
                Expanded(
                  child: Navigator(
                    onGenerateRoute: (_) =>
                        MaterialPageRoute(builder: (_) => kProbe),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await expectInstanceIsolation(tester, 2);
    });

    testWidgets('two widget types, several instances each', (tester) async {
      await pumpHarness(
        tester,
        Column(children: const [kProbe, kOtherProbe, kProbe, kOtherProbe]),
      );
      await settle(tester);
      // Two widget objects, one per type, each mounted twice.
      expect(sharedWidgetObjects(tester), 2, reason: 'scenario precondition');
      for (final c in controllersOf(tester)) {
        expect(find.text('${c.label}:0'), findsOneWidget,
            reason: 'instance data leaked: ${c.label}');
      }
    });

    testWidgets('survivors after a sibling unmounts', (tester) async {
      await pumpProbes(tester, 3);
      await settle(tester);
      final before = controllersOf(tester).map((c) => c.id).toList();

      // Mount one fewer. The children are unkeyed and identical, so Flutter
      // matches them by POSITION: elements 0 and 1 are reused and the last one
      // unmounts. Which one goes is not the point — that the survivors keep
      // their own controllers is.
      await pumpProbes(tester, 3, skipFirst: true);
      await expectInstanceIsolation(tester, 2);

      expect(controllersOf(tester).map((c) => c.id), before.take(2),
          reason: 'survivors should be the same controllers, not fresh ones');
    });

    testWidgets('after a rebuild of the whole subtree', (tester) async {
      await pumpProbes(tester, 4);
      await settle(tester);
      final ids = controllersOf(tester).map((c) => c.id).toList();

      await pumpProbes(tester, 4);
      await expectInstanceIsolation(tester, 4);

      expect(controllersOf(tester).map((c) => c.id), ids,
          reason: 'elements should have been updated, not recreated');
    });

    for (final n in const [1, 2, 3, 5, 8, 16, 32]) {
      testWidgets('$n instances stay isolated', (tester) async {
        await pumpProbes(tester, n);
        await expectInstanceIsolation(tester, n);
        print('isolation n=$n -> ${controllersOf(tester).length} distinct '
            'controllers, each rendering its own data');
      });
    }
  });

  group('deferred reads: the shapes that used to leak', () {
    testWidgets('read inside a builder (the bottom_page.dart shape)',
        (tester) async {
      // `state` is the build parameter, captured by the builder closure. The
      // closure runs when RxWidget's own element builds — after build() has
      // returned. That is exactly where the old registry fallback took over.
      await pumpProbes(tester, 4);
      await settle(tester);

      final controllers = controllersOf(tester);
      print('--- read inside builder, ${controllers.length} instances ---');
      for (final c in controllers) {
        print('  ${c.label} rendered '
            '${tester.widgetList(find.text('${c.label}:0')).length} time(s)');
      }

      expect(controllers, hasLength(4));
      for (final c in controllers) {
        expect(find.text('${c.label}:0'), findsOneWidget,
            reason: 'controller data leaked across instances: ${c.label}');
      }
    });

    testWidgets('tapping instance #k mutates only instance #k', (tester) async {
      const count = 4;
      await pumpProbes(tester, count);
      await settle(tester);

      final controllers = controllersOf(tester);
      expect(controllers, hasLength(count));

      for (var k = 0; k < count; k++) {
        final before = [for (final c in controllers) c.counter.value];

        // The callback reads the captured `state` parameter at tap time.
        await tester.tap(find.byKey(ValueKey('bump-${controllers[k].id}')));
        await tester.pump();

        final after = [for (final c in controllers) c.counter.value];
        for (var i = 0; i < count; i++) {
          expect(
            after[i],
            i == k ? before[i] + 1 : before[i],
            reason: 'tapping instance #$k should bump only itself: '
                '$before -> $after',
          );
        }
      }
    });

    testWidgets('rendered text never shows another instances counter',
        (tester) async {
      await pumpProbes(tester, 3);
      await settle(tester);
      final controllers = controllersOf(tester);

      await tester.tap(find.byKey(ValueKey('bump-${controllers[2].id}')));
      await tester.pump();

      expect(find.text('${controllers[0].label}:0'), findsOneWidget);
      expect(find.text('${controllers[1].label}:0'), findsOneWidget);
      expect(find.text('${controllers[2].label}:1'), findsOneWidget);
    });
  });

  group('control: the controller lifecycle must not change', () {
    // A hard constraint on the design: the controller is created by
    // StatefulElement (one per ELEMENT, via createState) and disposed in
    // unmount. Nothing about how it is *delivered* to build may change that.

    testWidgets('one initState, one readyState, one dispose per instance',
        (tester) async {
      await pumpProbes(tester, 5);
      await settle(tester);
      final mounted = controllersOf(tester).length;

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await settle(tester);

      expect(controllersOf(tester), isEmpty, reason: 'tree should be gone');
      expect(ProbeController.created, hasLength(mounted),
          reason: 'exactly one controller per mounted element — no extras, no '
              'reuse. Got ${ProbeController.created.length} for $mounted');

      for (final c in ProbeController.created) {
        expect(c.initStateCount, 1, reason: 'controller#${c.id} initState');
        expect(c.readyStateCount, 1, reason: 'controller#${c.id} readyState');
        expect(c.disposeCount, 1, reason: 'controller#${c.id} dispose');
      }
    });

    testWidgets('readyState runs once, after initState and after first build',
        (tester) async {
      await pumpProbes(tester, 3);
      await settle(tester);

      for (final c in controllersOf(tester)) {
        final log = c.log;
        expect(log.first, 'init', reason: 'controller#${c.id}: $log');
        expect(log.where((e) => e == 'init'), hasLength(1), reason: '$log');
        expect(log.where((e) => e == 'ready'), hasLength(1), reason: '$log');
        expect(log, contains('build'), reason: 'controller#${c.id}: $log');
        expect(
          log.indexOf('ready'),
          greaterThan(log.indexOf('build')),
          reason: 'readyState() must arrive after the first build, so context '
              'is safe. controller#${c.id}: $log',
        );
      }
    });

    testWidgets('rebuilding keeps the same controller instance',
        (tester) async {
      await pumpProbes(tester, 4);
      await settle(tester);
      final before = {for (final e in stateElementsOf(tester)) e: e.state};
      expect(before, isNotEmpty);

      await pumpProbes(tester, 4);
      await settle(tester);

      final after = {for (final e in stateElementsOf(tester)) e: e.state};
      expect(after.keys, unorderedEquals(before.keys),
          reason: 'elements should have been updated, not recreated');
      for (final element in after.keys) {
        expect(after[element], same(before[element]),
            reason: 'the controller changed identity across a rebuild');
      }
      for (final c in ProbeController.created) {
        expect(c.initStateCount, 1,
            reason: 'controller#${c.id} was re-initialised on rebuild');
        expect(c.readyStateCount, 1,
            reason: 'controller#${c.id} got a second readyState');
      }
    });

    testWidgets('a mounted element never owns a disposed controller',
        (tester) async {
      await pumpProbes(tester, 4);
      await settle(tester);

      await pumpProbes(tester, 4, skipFirst: true);
      await settle(tester);

      final disposed =
          ProbeController.created.where((c) => c.disposeCount > 0).toList();
      expect(disposed, isNotEmpty,
          reason: 'the scenario is supposed to dispose one controller; if none '
              'was disposed it proves nothing');

      for (final c in controllersOf(tester)) {
        expect(c.disposeCount, 0,
            reason: 'a mounted element owns disposed controller#${c.id}');
      }
    });

    testWidgets('dispose is the last thing that happens to a controller',
        (tester) async {
      await pumpProbes(tester, 2);
      await settle(tester);

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await settle(tester);

      for (final c in ProbeController.created) {
        expect(c.disposeCount, 1, reason: 'controller#${c.id}');
        expect(c.log.last, 'dispose',
            reason: 'something ran on controller#${c.id} after dispose: '
                '${c.log}');
      }
    });
  });
}

// ---------------------------------------------------------------------------
// Harness
// ---------------------------------------------------------------------------

Future<void> pumpHarness(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child))),
  );
}

/// Mounts [n] probe instances, all the *same* object ([kProbe]), which is the
/// whole point. [skipFirst] mounts one fewer, to exercise unmount — the
/// children are unkeyed and identical, so Flutter matches them by position and
/// it is the LAST element that goes, whichever list entry was dropped.
Future<void> pumpProbes(WidgetTester tester, int n, {bool skipFirst = false}) {
  return pumpHarness(
    tester,
    Column(children: [for (var i = skipFirst ? 1 : 0; i < n; i++) kProbe]),
  );
}

/// A single `const Probe()` expression site, invoked repeatedly — the shape a
/// route builder or page factory has in real code.
Widget buildProbe() => const Probe();

Future<void> settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
}

Iterable<StateElement> stateElementsOf(WidgetTester tester) =>
    tester.allElements.whereType<StateElement>();

List<ProbeController> controllersOf(WidgetTester tester) => [
      for (final e in stateElementsOf(tester))
        if (e.state is ProbeController) e.state as ProbeController,
    ];

/// How many distinct widget objects the mounted StateWidgets share. The
/// scenarios are only meaningful when this is smaller than the instance count.
int sharedWidgetObjects(WidgetTester tester) => stateElementsOf(tester)
    .map((e) => identityHashCode(e.widget))
    .toSet()
    .length;

/// [n] elements sharing ONE widget object, each with its own controller, each
/// rendering its own data exactly once.
Future<void> expectInstanceIsolation(WidgetTester tester, int n) async {
  await settle(tester);
  await expectDistinctControllers(tester, n);

  for (final c in controllersOf(tester)) {
    expect(
      find.text('${c.label}:0'),
      findsOneWidget,
      reason: 'instance data leaked. Each of $n instances should render its '
          'own label exactly once; ${c.label} did not.',
    );
  }
}

/// The structural half of isolation, for scenarios where not every instance is
/// painted (IndexedStack) and text cannot be asserted.
Future<void> expectDistinctControllers(WidgetTester tester, int n) async {
  await settle(tester);
  final elements = stateElementsOf(tester).toList();

  expect(elements, hasLength(n),
      reason: 'harness mounted the wrong number of StateWidgets');
  expect(
    sharedWidgetObjects(tester),
    lessThan(n == 1 ? 2 : n),
    reason: 'this scenario is supposed to mount $n elements sharing one widget '
        'object. If they are all distinct objects it does not reproduce the '
        'setup it was written for, so passing would mean nothing.',
  );
  expect(
    elements.map((e) => identityHashCode(e.state)).toSet(),
    hasLength(n),
    reason: 'two elements share one controller',
  );
}

// ---------------------------------------------------------------------------
// Probes
// ---------------------------------------------------------------------------

/// The one shared, unkeyed probe instance every scenario mounts several times.
/// A named constant instead of repeated `const Probe()` makes the "several
/// elements, one widget object" setup explicit in every compilation mode.
const kProbe = Probe();
const kOtherProbe = OtherProbe();

class ProbeController extends StateController {
  static int _nextId = 0;

  /// Every controller ever created in the current test, disposed ones included.
  /// A disposed controller is unreachable from the element tree, so auditing
  /// "was it disposed exactly once" needs a ledger that outlives it.
  static final List<ProbeController> created = [];

  /// Ordered lifecycle log, e.g. `['0:init', '0:build', '0:ready']`.
  static final List<String> events = [];

  static void reset() {
    _nextId = 0;
    created.clear();
    events.clear();
  }

  final int id = _nextId++;
  final counter = 0.rx;
  int initStateCount = 0;
  int readyStateCount = 0;
  int disposeCount = 0;

  ProbeController() {
    created.add(this);
  }

  /// Per-instance data: what must never surface under another instance.
  String get label => 'probe-$id';

  /// This controller's events, in order, without the id prefix.
  List<String> get log => [
        for (final e in events)
          if (e.startsWith('$id:')) e.substring('$id:'.length),
      ];

  @override
  void initState() {
    initStateCount++;
    events.add('$id:init');
    super.initState();
  }

  @override
  void readyState() {
    readyStateCount++;
    events.add('$id:ready');
    super.readyState();
  }

  void noteBuild() => events.add('$id:build');

  void bump() => counter.value += 1;

  @override
  void dispose() {
    disposeCount++;
    events.add('$id:dispose');
    counter.dispose();
    super.dispose();
  }
}

/// Reads its controller only through the `state` parameter, and does so from
/// inside a `builder:` closure and a tap callback — both evaluated after
/// build() has returned. These are the exact shapes that used to leak.
class Probe extends StateWidget<ProbeController> {
  const Probe({super.key});

  @override
  ProbeController createState() => ProbeController();

  @override
  Widget build(BuildContext context, ProbeController state) {
    state.noteBuild();
    return RxWidget<int>(
      notifier: state.counter,
      builder: (ctx, value) => TextButton(
        key: ValueKey('bump-${state.id}'),
        onPressed: () => state.bump(),
        child: Text('${state.label}:$value'),
      ),
    );
  }
}

class OtherProbeController extends ProbeController {
  @override
  String get label => 'other-$id';
}

/// A second widget type, so scenarios can mix two shared widget objects.
class OtherProbe extends StateWidget<OtherProbeController> {
  const OtherProbe({super.key});

  @override
  OtherProbeController createState() => OtherProbeController();

  @override
  Widget build(BuildContext context, OtherProbeController state) {
    state.noteBuild();
    return RxWidget<int>(
      notifier: state.counter,
      builder: (ctx, value) => TextButton(
        key: ValueKey('bump-${state.id}'),
        onPressed: () => state.bump(),
        child: Text('${state.label}:$value'),
      ),
    );
  }
}
