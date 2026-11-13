import 'package:flutter/material.dart';
import 'package:occam/occam.dart';

import 'playground_page.dart';

/// One field per feature demoed in [PlaygroundPage]. Every `Rx` is disposed in
/// [dispose] — occam never does it for you.
class PlaygroundController extends StateController<PlaygroundPage> {
  /// `readyState()` demo.
  final status = 'initState ran — context is NOT safe yet'.rx;

  /// `RxBool` demo.
  final flag = false.rx;

  /// `call` / `update` / `addValueListener` demo.
  final count = 0.rx;
  final log = <String>[].rx;

  /// `bindStream` / `closeStream` demo.
  final ticks = 0.rx;
  final ticking = false.rx;
  Stream<int>? _stream;

  /// `RxList` demo.
  final items = <int>[1, 2, 3, 4, 5].rx;

  /// `disposed` demo.
  final scratch = 0.rx;
  final scratchStatus = 'alive'.rx;

  /// Runs after the first frame, so `context` is safe — unlike `initState()`.
  @override
  void readyState() {
    status.value =
        'readyState ran — route is ${ModalRoute.of(context)?.settings.name}';
    count.addValueListener(_onCount);
  }

  // --- RxBool ---------------------------------------------------------------
  void toggleFlag() => flag.toggle();

  // --- call / update / addValueListener ---------------------------------------
  /// `rx(newValue)` sets; `rx()` reads.
  void setCountTo5() => count(5);
  void increment() => count(count() + 1);

  /// Functional set.
  void addTen() => count.update((v) => v + 10);

  void _onCount(int v) {
    final kept = log.length >= 4 ? log.skip(log.length - 3) : log;
    log.assignAll([...kept, 'count -> $v']);
  }

  // --- bindStream / closeStream -----------------------------------------------
  void toggleStream() {
    final current = _stream;
    if (current == null) {
      final stream = Stream<int>.periodic(
        const Duration(seconds: 1),
        (i) => i + 1,
      );
      _stream = stream;
      ticks.bindStream(stream);
      ticking.value = true;
    } else {
      ticks.closeStream(current);
      _stream = null;
      ticking.value = false;
    }
  }

  // --- RxList -------------------------------------------------------------------
  void listAddAll() => items.addAll([100, 200]);
  void listAssignAll() => items.assignAll([10, 20, 30]);
  void listRemoveEven() => items.removeWhere((e) => e.isEven);
  void listSetFirst() {
    if (items.isNotEmpty) items[0] = 99;
  }

  void listTruncate() {
    if (items.length > 2) items.length = 2;
  }

  // --- disposed -------------------------------------------------------------------
  void disposeScratch() {
    scratch.dispose(); // idempotent: a second call is a no-op
    scratchStatus.value = 'disposed = ${scratch.disposed}';
  }

  void bumpScratch() {
    if (scratch.disposed) {
      scratchStatus.value = 'skipped: check .disposed before touching it';
      return;
    }
    scratch.value++;
    scratchStatus.value = 'alive: ${scratch.value}';
  }

  @override
  void dispose() {
    // Must come before count.dispose(): removing a listener from a disposed
    // Rx would throw.
    count.removeValueListener(_onCount);
    for (final rx in [flag, ticking, scratchStatus, status]) {
      rx.dispose();
    }
    count.dispose();
    log.dispose();
    ticks.dispose(); // also cancels the stream subscription
    items.dispose();
    scratch.dispose();
    super.dispose();
  }
}
