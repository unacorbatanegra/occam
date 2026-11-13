import 'dart:async';

import 'package:leak_tracker_testing/leak_tracker_testing.dart';

/// Loaded automatically by the test runner for every test under this
/// directory. Fails a `testWidgets` if it leaves behind an undisposed
/// `Rx`/`Listenable`/`StreamSubscription` — the exact bug class occam's
/// manual-disposal contract exists to prevent.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  LeakTesting.enable();
  await testMain();
}
