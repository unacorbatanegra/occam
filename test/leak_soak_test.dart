// ignore_for_file: public_member_api_docs
//
// Leak-at-scale regression test: mounts and unmounts thousands of
// StateWidget/RxWidget/ParentState instances and asserts every disposal
// bookkeeping structure returns to zero. LeakTesting (flutter_test_config.dart)
// catches anything this misses via GC reachability; these counters make
// *why* something leaked immediately diagnosable instead of just "Leaks: 1".

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:occam/occam.dart';

const _soakSize = 2000;

void main() {
  testWidgets('$_soakSize StateWidget instances dispose exactly once each',
      (tester) async {
    _SoakController.reset();

    // Column, not ListView: ListView only mounts elements within the
    // viewport + cache extent, so most of the N would never actually build.
    await tester.pumpWidget(
      MaterialApp(
        home: SingleChildScrollView(
          child: Column(
            children: [
              for (var i = 0; i < _soakSize; i++) const _SoakLeaf(),
            ],
          ),
        ),
      ),
    );
    await tester.pumpWidget(const SizedBox());

    expect(_SoakController.created, hasLength(_soakSize));
    for (final c in _SoakController.created) {
      expect(c.counter.disposed, isTrue, reason: 'controller ${c.id}');
      expect(c.counter.lengthOfListeners, 0, reason: 'controller ${c.id}');
    }
  });

  testWidgets('$_soakSize RxWidget mount/unmount cycles release every listener',
      (tester) async {
    final notifiers = List.generate(_soakSize, (_) => 0.rx);

    await tester.pumpWidget(
      MaterialApp(
        home: SingleChildScrollView(
          child: Column(
            children: [
              for (final n in notifiers)
                RxWidget<int>(notifier: n, builder: (ctx, v) => Text('$v')),
            ],
          ),
        ),
      ),
    );
    await tester.pumpWidget(const SizedBox());

    for (final n in notifiers) {
      expect(n.lengthOfListeners, 0);
      n.dispose();
    }
  });

  testWidgets(
      '$_soakSize ParentState consumers under one provider resolve and release',
      (tester) async {
    _SoakController.reset();

    await tester.pumpWidget(
      MaterialApp(
        home: _SoakHost(
          child: SingleChildScrollView(
            child: Column(
              children: [
                for (var i = 0; i < _soakSize; i++) const _SoakConsumer(),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpWidget(const SizedBox());

    expect(
      tester.allElements.whereType<ParentStateElement>(),
      isEmpty,
      reason: 'every consumer element should have unmounted',
    );
  });
}

class _SoakController extends StateController<_SoakLeaf> {
  static int _next = 0;
  static final List<_SoakController> created = [];

  static void reset() {
    _next = 0;
    created.clear();
  }

  final int id = _next++;
  final counter = 0.rx;

  _SoakController() {
    created.add(this);
  }

  @override
  void dispose() {
    counter.dispose();
    super.dispose();
  }
}

class _SoakLeaf extends StateWidget<_SoakController> {
  const _SoakLeaf();

  @override
  _SoakController createState() => _SoakController();

  @override
  Widget build(BuildContext context, _SoakController state) =>
      RxWidget<int>(notifier: state.counter, builder: (ctx, v) => Text('$v'));
}

class _SoakHostController extends StateController<_SoakHost> {}

class _SoakHost extends StateWidget<_SoakHostController> {
  const _SoakHost({required this.child});

  final Widget child;

  @override
  _SoakHostController createState() => _SoakHostController();

  @override
  Widget build(BuildContext context, _SoakHostController state) => child;
}

class _SoakConsumer extends ParentState<_SoakHostController> {
  const _SoakConsumer();

  @override
  Widget build(BuildContext context, _SoakHostController state) =>
      const SizedBox(height: 1);
}
