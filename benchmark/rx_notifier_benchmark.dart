// Micro-benchmarks for RxMixin — run with:
//   flutter test benchmark/rx_notifier_benchmark.dart
//
// `flutter test`, not `dart run`: occam.dart imports package:flutter, so
// plain `dart run` can't load it (no Flutter engine/dart:ui bindings in the
// standalone Dart VM). `flutter test` just runs this file's main() under the
// Flutter-enabled VM and prints "No tests ran" harmlessly at the end, since
// there's no test()/testWidgets() in here.
//
// Informational only, not CI-gated: wall-clock numbers vary too much across
// machines/CI runners to make good pass/fail thresholds. What's worth
// re-checking after a change to rx_notifier.dart is the *shape* — does
// notifyListeners() still scale linearly with listener count, the way a
// plain List-backed listener registry implies it should.

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:occam/occam.dart';

/// `value =` when the new value equals the current one — the no-op,
/// no-notify path.
class SetUnchangedBenchmark extends BenchmarkBase {
  SetUnchangedBenchmark() : super('Rx<int>.value= (unchanged)');
  final rx = Rx<int>(1);

  @override
  void run() => rx.value = 1;
}

/// `value =` when the new value differs — the notify path, with one
/// listener attached (the common case).
class SetChangedBenchmark extends BenchmarkBase {
  SetChangedBenchmark() : super('Rx<int>.value= (changed, 1 listener)');
  final rx = Rx<int>(0);
  var _next = 1;

  @override
  void setup() => rx.addListener(() {});

  @override
  void run() => rx.value = _next++;
}

/// notifyListeners() cost at a fixed listener count — run once per size in
/// [main] to compare how it scales.
class NotifyBenchmark extends BenchmarkBase {
  NotifyBenchmark(this.listenerCount)
      : super('Rx<int>.refresh() ($listenerCount listeners)');
  final int listenerCount;
  final rx = Rx<int>(0);

  @override
  void setup() {
    for (var i = 0; i < listenerCount; i++) {
      rx.addListener(() {});
    }
  }

  @override
  void run() => rx.refresh();
}

void main() {
  SetUnchangedBenchmark().report();
  SetChangedBenchmark().report();
  for (final n in [1, 10, 100, 1000]) {
    NotifyBenchmark(n).report();
  }
}
