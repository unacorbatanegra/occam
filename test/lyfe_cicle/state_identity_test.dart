// ignore_for_file: public_member_api_docs, avoid_print
//
// Detector suite for cross-instance state leakage in `StateWidget.state`.
//
// ---------------------------------------------------------------------------
// THE INVARIANT UNDER TEST
// ---------------------------------------------------------------------------
// Reading `state` must yield THIS instance's controller, or FAIL LOUDLY.
// Returning another instance's controller silently is never acceptable.
//
// The suite is written around that invariant on purpose, so it does not presume
// which fix gets chosen. `threw` counts as a pass; `foreign` is the defect.
// Whether the failure arrives at mount time or at read time, and whether the
// API grows a BuildContext parameter, are all compatible with these tests.
//
// ---------------------------------------------------------------------------
// WHY A CORRECT SILENT ANSWER IS IMPOSSIBLE
// ---------------------------------------------------------------------------
// `state` is a getter on the *widget*, so its only input is the widget object.
// When one widget object is mounted N times there is no information available
// to tell the N instances apart — the question has no answer. `build()` works
// only because it establishes "who is building right now" via a stack; outside
// build there is no such ambient. So the defect is not "the fallback picks the
// wrong one", it is "an ambiguous question is answered with a silent guess".
//
// ---------------------------------------------------------------------------
// WHEN ONE WIDGET OBJECT ENDS UP MOUNTED TWICE
// ---------------------------------------------------------------------------
// See canonicalization_probe_test.dart for the measurements. Summary:
//   * A reused reference, or one const site evaluated more than once (route
//     builder called twice, const page in a loop, const widget in a field),
//     collides in EVERY mode.
//   * Two separate `const Page()` expressions collide only when
//     --track-widget-creation is off, i.e. in release/profile — NOT in the
//     default `flutter test` or debug runs. So release is where this is worst,
//     and a debug-only CI cannot see it.
// This suite shares a reference (`kProbe`) so it reproduces in both modes.
// Run it BOTH ways:
//   flutter test test/lyfe_cicle/state_identity_test.dart
//   flutter test test/lyfe_cicle/state_identity_test.dart --no-track-widget-creation

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:occam/occam.dart';

void main() {
  setUp(ProbeController.resetIds);

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

    // The one guarantee the suite depends on, true in every mode.
    expect(identical(kProbe, kProbe), isTrue);
  });

  group('no silent cross-talk', () {
    testWidgets('2 instances of one widget object', (tester) async {
      await pumpProbes(tester, 2);
      await expectNoCrossTalk(tester, expectedInstances: 2);
    });

    testWidgets('one const site evaluated twice (route-builder pattern)',
        (tester) async {
      // Closest shape to the real trigger: a single `const Probe()` site that
      // the app runs more than once. No shared variable, no hand-wiring.
      await pumpHarness(tester, Column(children: [buildProbe(), buildProbe()]));
      await expectNoCrossTalk(tester, expectedInstances: 2);
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
      await expectNoCrossTalk(tester, expectedInstances: 2);
    });

    testWidgets('instances kept alive in an IndexedStack (tab pattern)',
        (tester) async {
      await pumpHarness(
        tester,
        const IndexedStack(index: 0, children: [kProbe, kProbe, kProbe]),
      );
      await expectNoCrossTalk(tester, expectedInstances: 3);
    });

    testWidgets('instances across a nested Navigator', (tester) async {
      await pumpHarness(
        tester,
        Column(
          children: [
            kProbe,
            Expanded(
              child: Navigator(
                onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => kProbe),
              ),
            ),
          ],
        ),
      );
      await expectNoCrossTalk(tester, expectedInstances: 2);
    });

    testWidgets('two widget types, several instances each', (tester) async {
      await pumpHarness(
        tester,
        Column(children: const [kProbe, kOtherProbe, kProbe, kOtherProbe]),
      );
      // Two objects (one per type), each mounted twice.
      await expectNoCrossTalk(tester, expectedInstances: 4, sharedObjects: 2);
    });

    testWidgets('survivors after a sibling unmounts', (tester) async {
      await pumpProbes(tester, 3);
      tester.takeException();
      final before = controllersOf(tester).map((c) => c.id).toList();

      // Drop the FIRST one: it is the instance the buggy lookup always
      // returned, so a stale-resolution bug shows up here too.
      await pumpProbes(tester, 3, skipFirst: true);
      await expectNoCrossTalk(tester, expectedInstances: 2);

      final after = controllersOf(tester).map((c) => c.id);
      if (after.isNotEmpty) {
        expect(after, containsAll(before.skip(1)),
            reason: 'survivors should be the same controllers, not fresh ones');
      }
    });

    testWidgets('after a rebuild of the whole subtree', (tester) async {
      await pumpProbes(tester, 4);
      tester.takeException();
      final ids = controllersOf(tester).map((c) => c.id).toList();
      await pumpProbes(tester, 4);
      await expectNoCrossTalk(tester, expectedInstances: 4);
      if (controllersOf(tester).isNotEmpty) {
        expect(controllersOf(tester).map((c) => c.id), ids,
            reason: 'elements should have been updated, not recreated');
      }
    });
  });

  group('no silent cross-talk from callbacks', () {
    testWidgets('tapping instance #k never mutates another instance',
        (tester) async {
      const count = 4;
      await pumpProbes(tester, count);
      await settle(tester);
      tester.takeException();

      final controllers = controllersOf(tester);
      if (controllers.length != count) {
        // A fix that refuses to mount the ambiguous tree satisfies the
        // invariant; there is simply nothing left to tap.
        print('tree refused to mount ${controllers.length}/$count instances');
        return;
      }

      var threw = 0;
      for (var k = 0; k < count; k++) {
        final before = [for (final c in controllers) c.counter.value];

        // The closure reads `state` when tapped, i.e. outside Probe.build().
        await tester.tap(find.byKey(ValueKey('bump-${controllers[k].id}')));
        await tester.pump();
        final error = tester.takeException();
        if (error != null) threw++;

        final after = [for (final c in controllers) c.counter.value];
        for (var i = 0; i < count; i++) {
          if (i == k) continue;
          expect(
            after[i],
            before[i],
            reason: 'tapping instance #$k mutated instance #$i '
                '(controller ${controllers[i].id}): $before -> $after',
          );
        }
        expect(
          after[k],
          anyOf(before[k] + 1, before[k]),
          reason: 'tapping instance #$k should bump it or fail, not skip',
        );
        if (error == null) {
          expect(after[k], before[k] + 1,
              reason: 'tap on #$k neither bumped it nor raised');
        }
      }
      print('taps: $threw/$count raised instead of resolving');
    });

    testWidgets('rendered text never shows another instances counter',
        (tester) async {
      await pumpProbes(tester, 3);
      await settle(tester);
      tester.takeException();
      final controllers = controllersOf(tester);
      if (controllers.length != 3) return;

      await tester.tap(find.byKey(ValueKey('bump-${controllers[2].id}')));
      await tester.pump();
      final error = tester.takeException();

      // Labels are built from the controller resolved during build (correct
      // path), so a wrong counter surfacing under a label means leakage.
      expect(find.text('${controllers[0].id}:0'), findsOneWidget);
      expect(find.text('${controllers[1].id}:0'), findsOneWidget);
      expect(
        find.text('${controllers[2].id}:${error == null ? 1 : 0}'),
        findsOneWidget,
      );
    });
  });

  group('control: unambiguous resolution keeps working', () {
    // These pass today. They are the regression net: a fix must not break the
    // cases that were never ambiguous. NOTE: dropping the outside-build
    // fallback entirely would turn these red — that is the trade-off to weigh.
    testWidgets('a single instance resolves its own controller',
        (tester) async {
      await pumpProbes(tester, 1);
      await expectNoCrossTalk(tester, expectedInstances: 1, sharedObjects: 1);
      final element = stateElementsOf(tester).single;
      expect(element.widget.state, same(element.state),
          reason: 'one mounted instance is unambiguous and must resolve');
    });

    testWidgets('distinct Keys give distinct identities', (tester) async {
      await pumpHarness(
        tester,
        Column(
          children: const [
            Probe(key: Key('a')),
            Probe(key: Key('b')),
            Probe(key: Key('c')),
          ],
        ),
      );
      await settle(tester);
      for (final element in stateElementsOf(tester)) {
        expect(element.widget.state, same(element.state),
            reason: 'keyed instances are distinct objects and must resolve');
      }
    });
  });

  group('control: readyState() delivery', () {
    // Expected to pass before and after: performRebuild() reads
    // `StatefulElement.state` (the element's own controller), not
    // `widget.state`, so it never goes through the ambiguous path. Kept as a
    // guard against a fix rerouting it through the resolver.
    testWidgets('each instance receives exactly one readyState()',
        (tester) async {
      await pumpProbes(tester, 5);
      await settle(tester);
      tester.takeException();
      final controllers = controllersOf(tester);
      if (controllers.isEmpty) return;

      final report = {for (final c in controllers) c.id: c.readyStateCount};
      expect(report.values, everyElement(1),
          reason: 'readyState() must be delivered once, to its own instance. '
              'Got id -> calls: $report');
    });
  });

  group('scale sweep', () {
    // Benchmark of the blast radius. Today: N-1 of N instances read a foreign
    // controller. After a fix: 0 foreign, whatever the mix of own/threw.
    for (final n in const [1, 2, 3, 5, 8, 16, 32]) {
      testWidgets('$n instances of one widget object', (tester) async {
        await pumpProbes(tester, n);
        await settle(tester);
        tester.takeException();

        final reports = resolutionReports(tester);
        final foreign = reports.where((r) => r.kind == Resolution.foreign);
        final threw = reports.where((r) => r.kind == Resolution.threw);
        final own = reports.where((r) => r.kind == Resolution.own);
        print('sweep n=$n -> ${foreign.length} foreign, ${threw.length} threw, '
            '${own.length} own (of ${reports.length} mounted)');

        expect(
          foreign,
          isEmpty,
          reason: '$n instances mounted, ${foreign.length} silently read a '
              'foreign controller:\n${foreign.join('\n')}',
        );
      });
    }
  });
}

// ---------------------------------------------------------------------------
// Harness
// ---------------------------------------------------------------------------

enum Resolution { own, foreign, threw }

class ResolutionReport {
  final int index;
  final Type widgetType;
  final Resolution kind;
  final String detail;

  ResolutionReport(this.index, this.widgetType, this.kind, this.detail);

  @override
  String toString() => '  element #$index ($widgetType) $detail';
}

Future<void> pumpHarness(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child))),
  );
}

/// Mounts [n] probe instances, all the *same* object ([kProbe]), which is the
/// whole point. [skipFirst] drops the first one to exercise unmount.
Future<void> pumpProbes(WidgetTester tester, int n, {bool skipFirst = false}) {
  final children = <Widget>[
    for (var i = skipFirst ? 1 : 0; i < n; i++) kProbe,
  ];
  return pumpHarness(tester, Column(children: children));
}

/// A single `const Probe()` expression site, invoked repeatedly — the shape a
/// route builder or page factory has in real code.
Widget buildProbe() => const Probe();

/// Settles, tolerating a fix that raises while mounting an ambiguous tree.
Future<void> settle(WidgetTester tester) async {
  try {
    await tester.pumpAndSettle();
  } catch (_) {
    // Mount-time refusal is an acceptable outcome; recorded by the caller.
  }
}

Iterable<StateElement> stateElementsOf(WidgetTester tester) =>
    tester.allElements.whereType<StateElement>();

List<ProbeController> controllersOf(WidgetTester tester) => [
      for (final e in stateElementsOf(tester))
        if (e.state is ProbeController) e.state as ProbeController,
    ];

/// Reads `element.widget.state` — the public getter, from outside any build() —
/// for every mounted instance, and classifies the outcome.
List<ResolutionReport> resolutionReports(WidgetTester tester) {
  final elements = stateElementsOf(tester).toList();
  final reports = <ResolutionReport>[];
  for (var i = 0; i < elements.length; i++) {
    final element = elements[i];
    final own = element.state;
    try {
      final resolved = element.widget.state;
      reports.add(
        identical(resolved, own)
            ? ResolutionReport(i, element.widget.runtimeType, Resolution.own,
                'resolved its own ${describe(own)}')
            : ResolutionReport(i, element.widget.runtimeType,
                Resolution.foreign,
                'owns ${describe(own)} but `widget.state` silently resolved '
                '${describe(resolved)}'),
      );
    } catch (error) {
      reports.add(ResolutionReport(i, element.widget.runtimeType,
          Resolution.threw, 'raised instead of guessing: $error'));
    }
  }
  return reports;
}

/// The core assertion: nobody silently reads someone else's controller.
///
/// [sharedObjects] is how many distinct widget objects the scenario intends to
/// mount (one per widget type by default). It guards against a scenario that
/// passes vacuously because the widgets turned out to be distinct objects and
/// could never have been confused in the first place.
Future<void> expectNoCrossTalk(
  WidgetTester tester, {
  required int expectedInstances,
  int? sharedObjects,
}) async {
  await settle(tester);
  final mountError = tester.takeException();

  final elements = stateElementsOf(tester).toList();
  if (mountError != null && elements.length < expectedInstances) {
    // A fix that refuses to build the ambiguous tree satisfies the invariant.
    print('mount refused (${elements.length}/$expectedInstances mounted): '
        '$mountError');
    return;
  }

  expect(elements, hasLength(expectedInstances),
      reason: 'harness mounted the wrong number of StateWidgets');

  final distinctWidgets =
      elements.map((e) => identityHashCode(e.widget)).toSet().length;
  final intended =
      sharedObjects ?? elements.map((e) => e.widget.runtimeType).toSet().length;
  expect(
    distinctWidgets,
    intended,
    reason: 'this scenario is supposed to mount $expectedInstances elements '
        'sharing $intended widget object(s), but found $distinctWidgets '
        'distinct objects. It does not reproduce the ambiguity it was written '
        'for, so passing would mean nothing.',
  );

  expect(
    elements.map((e) => identityHashCode(e.state)).toSet(),
    hasLength(expectedInstances),
    reason: 'two elements share one controller',
  );

  final foreign =
      resolutionReports(tester).where((r) => r.kind == Resolution.foreign);
  expect(
    foreign,
    isEmpty,
    reason: 'state leaked across instances — a silently wrong controller was '
        'returned:\n${foreign.join('\n')}',
  );
}

String describe(State state) =>
    state is ProbeController ? 'controller#${state.id}' : '$state';

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
  static void resetIds() => _nextId = 0;

  final int id = _nextId++;
  final counter = 0.rx;
  int readyStateCount = 0;

  @override
  void readyState() {
    readyStateCount++;
    super.readyState();
  }

  void bump() => counter.value += 1;

  @override
  void dispose() {
    counter.dispose();
    super.dispose();
  }
}

class Probe extends StateWidget<ProbeController> {
  const Probe({super.key});

  @override
  ProbeController createState() => ProbeController();

  @override
  Widget build(BuildContext context) {
    // Resolved via the build stack: this path is expected to be correct.
    final own = state;
    return RxWidget<int>(
      notifier: own.counter,
      builder: (context, value) => TextButton(
        key: ValueKey('bump-${own.id}'),
        // Read at tap time, from outside Probe.build().
        onPressed: () => state.bump(),
        child: Text('${own.id}:$value'),
      ),
    );
  }
}

class OtherProbeController extends ProbeController {}

class OtherProbe extends StateWidget<OtherProbeController> {
  const OtherProbe({super.key});

  @override
  OtherProbeController createState() => OtherProbeController();

  @override
  Widget build(BuildContext context) {
    final own = state;
    return RxWidget<int>(
      notifier: own.counter,
      builder: (context, value) => TextButton(
        key: ValueKey('bump-${own.id}'),
        onPressed: () => state.bump(),
        child: Text('${own.id}:$value'),
      ),
    );
  }
}
