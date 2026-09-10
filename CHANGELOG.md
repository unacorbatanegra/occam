## 2.0.0

**Breaking:** `StateWidget.build` now receives the controller as a parameter.

```dart
// before
Widget build(BuildContext context) { ... state.counter ... }

// after
Widget build(BuildContext context, HomeController state) { ... state.counter ... }
```

Migration is one line per widget, and the compiler points at every one. If the
parameter is named `state`, existing method bodies compile unchanged.

- `Fix` a widget mounted more than once from the same object (a `const` widget
  reused on a page, e.g. a banner or a category row) could read another
  instance's controller. Reads evaluated after `build()` returned — inside a
  `builder:` or a callback — resolved through a registry keyed by widget
  identity, which cannot tell shared instances apart and always returned the
  first-mounted one. Measured: 4 instances, all 4 rendering instance 0's data.
  Worse in release than in debug, since `--track-widget-creation` keeps separate
  `const` expressions distinct in debug only.
- `Removed` the `StateWidget.state` getter, along with the static build stack and
  mounted-element registry that backed it. Cross-instance leakage is now a
  compile-time impossibility rather than a runtime invariant.
- Controller lifecycle is unchanged: one `initState`, one `readyState`, one
  `dispose` per instance, with stable identity across rebuilds.

**Breaking:** `ParentState.build` receives the ancestor's controller the same way,
and `ParentStateMixin` is gone — the parameter cannot be added to an arbitrary
`StatelessWidget`, so extend `ParentState<T>` instead.

- `Fix` two `const` instances of one `ParentState` mounted at once overwrote each
  other's provider, and unmounting one broke its still-mounted siblings with a
  null cast.
- `Fix` resolution used the *farthest* matching ancestor
  (`findRootAncestorStateOfType`); it now uses the nearest, so nested providers of
  the same type resolve to the inner one.
- `Removed` `ParentStateElement.findStateControllerProvider()` (unused).
- A missing provider now throws a `FlutterError` naming the expected
  `StateWidget<T>` instead of a bare `String`.
- `Fix` `StateController`/`StateWidget` had drifted apart during this rewrite:
  `StateController<T extends StatefulWidget>` accepted any `StatefulWidget`, not
  just a `StateWidget`, so pairing one with a plain `StatefulWidget` compiled and
  only threw `UnsupportedError` the first time that widget tried to build. Bounds
  are tight again — `StateController<T extends StateWidget<dynamic>>` /
  `StateWidget<T extends StateController<dynamic>>` — so that misuse is a
  compile error, as it was before the rewrite. Every existing
  `StateWidget<T>`/`StateController<T>` pairing in `example/` and `test/` already
  satisfies the tightened bound; nothing else changes for correct usage.
- `Fix` `RxMixin.bindStream` never released its subscription to the source
  stream. `stream.asBroadcastStream()` was called with no `onCancel` — per its
  documented default, cancelling *our* listener only detaches from the broadcast
  wrapper; the wrapper itself stays subscribed to the original stream until that
  stream completes on its own. For a stream backing a real resource (socket,
  platform channel, long-lived query) this meant `closeStream`/`dispose()` never
  actually released it. Fixed by passing `onCancel: (s) => s.cancel()`. Caught by
  `test/flutter_test_config.dart`'s `LeakTesting` plus a test asserting the
  source `StreamController` has no listener after `dispose()`.
- `Fix` `RxMixin` allowed continued use after `dispose()` (`addListener`,
  `removeListener`, `bindStream`, etc. on an already-disposed instance), and
  calling `dispose()` twice threw. Both are guarded now: any use after disposal
  throws a clear `StateError`, and a second `dispose()` call is a no-op.
- `Fix` `RxMixin.call()` couldn't tell "no argument" apart from "explicitly
  passed `null`" for a nullable `Rx<T?>` — both looked identical to a
  `newValue == null` check, so `counter(null)` silently did nothing instead of
  setting the value to `null`. Now uses a sentinel default to tell the two
  apart.
- `Fix` `RxBool.toggle()` notified listeners twice per call — the equality-gated
  `value` setter already notifies (a toggle always changes the value), so the
  extra `refresh()` was a duplicate. Found by a new test asserting listener call
  count.
- `Fix` `RxList()` with no argument defaulted to `const []`; the first mutation
  (`add`, `[]=`, etc.) threw because a `const` list is unmodifiable. Now defaults
  to a fresh, growable empty list, matching what every other `Rx*` default
  expects.
- `Fix` `RxWidgetState.didUpdateWidget` had a dead `else if` branch (comparing the
  same notifier's value to itself, which can never differ) left over from before
  the value was always kept in sync via the listener; removed.
- Added `benchmark/` (`benchmark_harness` micro-benchmarks for `Rx`/`RxList`
  notify and mutation cost, plus widget-level mount/rebuild/`ParentState`-
  resolution timing) — run manually via `flutter test benchmark/*.dart`, and on
  a weekly schedule / manual dispatch in CI. Informational only, not a merge
  gate: timing isn't stable enough across CI runners to hard-fail on. Also
  added `test/leak_soak_test.dart`, which *is* CI-gated: mounts/unmounts 2,000
  `StateWidget`/`RxWidget`/`ParentState` instances and asserts every disposal
  counter and listener/subscription count returns to zero.
- `example/` restyled: Material 3 theme, each demo grouped into a labeled
  `DemoSection` card instead of a bare `Column`, so the running app reads as a
  list of "here's what this feature does" rather than the default unstyled
  widget look.
- `Fix` `example/` used a Dart 2.12 SDK constraint and `flutter_lints ^1.0.0`,
  years behind the root package — `super.key` couldn't even parse under it.
  Bumped to match the root package (`>=3.0.0 <4.0.0`, `flutter_lints ^6.0.0`).
- `Fix` `example/` had never been linted or tested in CI (only `./lib ./test` at
  the repo root were). It was silently broken: `page_1.dart` called
  `super.build(context)` from a `StateController` override — the pre-rewrite
  pattern for `AutomaticKeepAliveClientMixin`, which now throws
  `UnsupportedError` unconditionally — and the `ParentState` demo widgets were
  commented out of the tree entirely. Rewrote the example to the current API,
  wired the `ParentState` demo back in, dropped the now-incompatible keep-alive
  pattern, fixed two more undisposed `Rx` fields (`BottomController.currentIndex`,
  `HomeController.model`), and added an `example` CI job (format + analyze +
  test).
- Full `dartdoc` coverage of the public API (`public_member_api_docs`, enforced
  in CI).
- Tests reorganized to mirror `lib/src/` 1:1 under `test/`; `RxBool` previously
  had zero enforced coverage (a test file was missing the `_test` suffix, so
  `flutter test` never ran it) and a full suite for it now exists. Coverage
  gate: 100% via `test_cov_console`, with a `// coverage:ignore` for the one
  genuinely unreachable line (a `ChangeNotifier` reentrancy guard in
  `RxWidget`).
- `test/flutter_test_config.dart` enables `LeakTesting` for every widget test,
  so a test that leaves an `Rx`/listener/subscription undisposed now fails the
  suite.
- CI: `flutter analyze` now runs with `--fatal-infos` (info-severity lints,
  including the new `public_member_api_docs` and `avoid_print`, were previously
  non-blocking), and a `dart pub publish --dry-run` step catches
  packaging/version/doc issues before a real release would.
- `coverage/lcov.info` was accidentally committed; it's gitignored now.
- Removed `mockito` and `build_runner` dev dependencies — unused anywhere in the
  repo, and fewer dependencies is fewer things `dependabot`/`osv-scanner` has to
  watch.

## 1.0.6

- Add `KeepAliveStateMixin`

## 1.0.4

- Replace the sample app with a catalog of focused demos (reactive basics, ParentState, RxList, and stream binding).
- Add comprehensive documentation to `RxWidget` explaining reactive rebuilds and listener management.
- Refresh the README with guidance on running the catalog and understanding the showcased patterns.
- Fix memory leaks on state references

## 1.0.3

- Update the readme

## 1.0.2

- Test added
- `onDispose` method added in state controller allowing attach a local `cancelToken` and handling it disposed correctly.

## 1.0.1

- Test added
- `Fix` remove double calling in mixin on listeners.

## 1.0.0

Added Flutter 3.7.4 compatibility
