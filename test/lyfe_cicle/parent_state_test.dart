// ignore_for_file: public_member_api_docs, avoid_print
//
// ParentState had the same class of defect as StateWidget, plus two more.
// Before the fix, `ParentStateMixin.state` read from an Expando keyed by the
// widget object:
//
//   1. one slot per widget object — two `const ChildConsumer()` mounted at once
//      overwrote each other, so both resolved to the same provider;
//   2. `unmount()` set that shared slot to null, so unmounting one instance
//      broke its still-mounted siblings with a null cast;
//   3. resolution used findRootAncestorStateOfType, i.e. the FARTHEST matching
//      ancestor, so nested providers of the same type resolved to the outer one.
//
// The controller now arrives as a build parameter, resolved by walking up from
// this element to the nearest matching ancestor. These tests cover all three.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:occam/occam.dart';

void main() {
  setUp(HostController.reset);

  testWidgets('one shared widget object under two providers resolves each own',
      (tester) async {
    // Defect 1. Both consumers are the SAME object (kConsumer); only their
    // position in the tree tells them apart.
    await pumpHosts(tester, 2);

    final hosts = hostControllersOf(tester);
    expect(hosts, hasLength(2));
    expect(consumerElements(tester), hasLength(2));
    expect(
      consumerElements(tester).map((e) => identityHashCode(e.widget)).toSet(),
      hasLength(1),
      reason:
          'both consumers must be one widget object, or this proves nothing',
    );

    for (final host in hosts) {
      expect(find.text(host.label), findsOneWidget,
          reason: 'each consumer must resolve its own provider: ${host.label}');
    }
  });

  testWidgets('a surviving sibling keeps working after one unmounts',
      (tester) async {
    // Defect 2: unmount used to null the slot shared by every instance.
    await pumpHosts(tester, 3);
    final before = hostControllersOf(tester).map((c) => c.label).toList();
    expect(before, hasLength(3));

    await pumpHosts(tester, 2);

    final after = hostControllersOf(tester).map((c) => c.label).toList();
    expect(after, hasLength(2));
    for (final label in after) {
      expect(find.text(label), findsOneWidget,
          reason:
              'survivor $label stopped resolving after a sibling unmounted');
    }
  });

  testWidgets('nested providers of the same type resolve to the nearest',
      (tester) async {
    // Defect 3: findRootAncestorStateOfType returned the outermost.
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Host(child: Host(child: kConsumer)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // allElements is depth-first pre-order, so the outer host comes first.
    final hosts = hostControllersOf(tester);
    expect(hosts, hasLength(2));
    final inner = hosts.last;
    final outer = hosts.first;

    expect(find.text(inner.label), findsOneWidget,
        reason: 'the nearest provider (${inner.label}) should win');
    expect(find.text(outer.label), findsNothing,
        reason: 'the outer provider (${outer.label}) should not be used');
  });

  testWidgets('a missing provider fails with a message that says why',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: kConsumer)),
    );

    final error = tester.takeException();
    expect(error, isA<FlutterError>());
    expect(
      error.toString(),
      contains('could not find an ancestor StateWidget'),
      reason: 'the error must name the missing dependency',
    );
  });

  testWidgets('the provider controller keeps a normal lifecycle',
      (tester) async {
    await pumpHosts(tester, 2);
    for (final c in hostControllersOf(tester)) {
      expect(c.initStateCount, 1, reason: c.label);
      expect(c.readyStateCount, 1, reason: c.label);
    }

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pumpAndSettle();

    for (final c in HostController.created) {
      expect(c.disposeCount, 1, reason: '${c.label} dispose');
    }
  });
}

// ---------------------------------------------------------------------------
// Harness
// ---------------------------------------------------------------------------

/// [n] providers, each wrapping the very same consumer widget object.
Future<void> pumpHosts(WidgetTester tester, int n) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Column(
          children: [for (var i = 0; i < n; i++) const Host(child: kConsumer)],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

List<HostController> hostControllersOf(WidgetTester tester) => [
      for (final e in tester.allElements.whereType<StateElement>())
        if (e.state is HostController) e.state as HostController,
    ];

Iterable<ParentStateElement> consumerElements(WidgetTester tester) =>
    tester.allElements.whereType<ParentStateElement>();

// ---------------------------------------------------------------------------
// Probes
// ---------------------------------------------------------------------------

const kConsumer = Consumer();

class HostController extends StateController {
  static int _next = 0;
  static final List<HostController> created = [];

  static void reset() {
    _next = 0;
    created.clear();
  }

  final int id = _next++;
  int initStateCount = 0;
  int readyStateCount = 0;
  int disposeCount = 0;

  HostController() {
    created.add(this);
  }

  /// Per-instance data a consumer must never read from another provider.
  String get label => 'host-$id';

  @override
  void initState() {
    initStateCount++;
    super.initState();
  }

  @override
  void readyState() {
    readyStateCount++;
    super.readyState();
  }

  @override
  void dispose() {
    disposeCount++;
    super.dispose();
  }
}

/// Provides a [HostController] to its subtree.
class Host extends StateWidget<HostController> {
  const Host({super.key, required this.child});

  final Widget child;

  @override
  HostController createState() => HostController();

  @override
  Widget build(BuildContext context, HostController state) => child;
}

/// Reads the ancestor's controller. Mounted several times from ONE object.
class Consumer extends ParentState<HostController> {
  const Consumer({super.key});

  @override
  Widget build(BuildContext context, HostController state) =>
      Text(state.label, textDirection: TextDirection.ltr);
}
