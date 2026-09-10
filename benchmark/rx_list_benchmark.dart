// Micro-benchmarks for RxList vs a plain List — run with:
//   flutter test benchmark/rx_list_benchmark.dart
//
// `flutter test`, not `dart run` — see rx_notifier_benchmark.dart for why.
// Informational only (see that file for why, too). Each RxList
// mutation does the same underlying List operation plus a refresh()
// (notifyListeners()) call — this puts a number on that fixed overhead.

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:occam/occam.dart';

class PlainListAddBenchmark extends BenchmarkBase {
  PlainListAddBenchmark() : super('List<int>.add (plain)');
  final list = <int>[];

  @override
  void run() => list.add(1);

  @override
  void teardown() => list.clear();
}

class RxListAddBenchmark extends BenchmarkBase {
  RxListAddBenchmark() : super('RxList<int>.add (with a listener)');
  final list = RxList<int>();

  @override
  void setup() => list.addListener(() {});

  @override
  void run() => list.add(1);

  @override
  void teardown() => list.clear();
}

class PlainListAssignAllBenchmark extends BenchmarkBase {
  PlainListAssignAllBenchmark() : super('List<int>.assignAll (plain, n=1000)');
  final list = <int>[];
  final replacement = List.generate(1000, (i) => i);

  @override
  void run() => list.assignAll(replacement);
}

class RxListAssignAllBenchmark extends BenchmarkBase {
  RxListAssignAllBenchmark()
      : super('RxList<int>.assignAll (with a listener, n=1000)');
  final list = RxList<int>();
  final replacement = List.generate(1000, (i) => i);

  @override
  void setup() => list.addListener(() {});

  @override
  void run() => list.assignAll(replacement);
}

void main() {
  PlainListAddBenchmark().report();
  RxListAddBenchmark().report();
  PlainListAssignAllBenchmark().report();
  RxListAssignAllBenchmark().report();
}
