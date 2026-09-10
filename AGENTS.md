# AGENTS.md — occam

Minimalist Flutter state management built **on top of** Flutter's own `StatefulWidget`/`State`
instead of replacing it. No `InheritedWidget`, no service locator, no code generation.

Package: `occam` (v2.0.0) · Dart SDK `>=3.0.0 <4.0.0` · deps: `flutter`, `meta` only.

---

## 1. The core idea

One screen = **one view + one controller**, always paired:

| Role | Flutter class it really is | Your subclass |
|---|---|---|
| View — widgets only, no logic | `StatefulWidget` | `class HomePage extends StateWidget<HomeController>` |
| Controller — logic only, no widgets | `State` | `class HomeController extends StateController<HomePage>` |

The trick: normally `build()` lives on the `State`. Occam moves it to the **widget**, and the
element hands the controller *in* as a parameter — so the view file has the widget tree and
the controller file has none, and a `build()` closure always closes over the right instance
even if the same `const` widget object is mounted several times.

```dart
class HomePage extends StateWidget<HomeController> {
  const HomePage({super.key});

  @override
  HomeController createState() => HomeController();   // the pairing

  @override
  Widget build(BuildContext context, HomeController state) => Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: state.onButton,
          child: const Icon(Icons.add),
        ),
        body: RxWidget<int>(
          notifier: state.counter,
          builder: (ctx, v) => Text('$v'),
        ),
      );
}

class HomeController extends StateController<HomePage> {
  final counter = 1.rx;                 // reactive int

  void onButton() => counter.value++;

  @override
  void readyState() {                   // context is safe here (post-frame)
    print(navArgs);
  }

  @override
  void dispose() {
    counter.dispose();                  // YOU own disposal
    super.dispose();
  }
}
```

Reactivity is deliberately **explicit**: a value only rebuilds UI when you wrap that part of
the tree in `RxWidget`. There is no automatic `Obx`-style dependency tracking — implicit
tracking makes correct listener disposal much harder to get right.

---

## 2. File map

Everything is one Dart library assembled with `part of` from `lib/occam.dart`, except
`rx_notifier.dart` and `occam_debug.dart`, which are standalone libraries `import`ed and
`export`ed from `occam.dart` (so both the `part` files and external consumers can see
`Rx`/`RxInterface`/`RxMixin`/`OccamDebug`). Adding a new `part` file means adding a `part`
entry to `lib/occam.dart`; adding a new standalone file means adding both an `import` and an
`export`.

```
lib/occam.dart                       library root, import/export/part list
lib/src/occam_debug.dart             OccamDebug.debug flag (standalone library)
lib/src/lyfe_cicle/                  ("lifecycle" — note the typo, it is the real path)
  state_widget.dart                  StateWidget + StateElement  ← the heart of the package
  state_controller.dart              StateController (a State with build() forbidden)
  state_parent.dart                  ParentState + ParentStateElement
lib/src/rx/
  rx_notifier.dart                   RxMixin, RxInterface, Rx<T> (standalone library)
  primitives/rx_bool.dart            RxBool
  iterables/rx_list.dart             RxList<T>
  extensions/extensions.dart         `.rx` getters on T, bool, List<T>
  widgets/rx_widget.dart             RxWidget<T> — the only rebuild primitive
example/                             runnable app exercising every feature
test/                                mirrors lib/ 1:1, plus flutter_test_config.dart
```

---

## 3. How the controller reaches `build()`

`StateElement` (a custom `StatefulElement`) creates the controller the normal Flutter way —
`createState()`, once per element — and simply passes it as a second argument when it calls
`StateWidget.build`:

```dart
@override
Widget build() => widget.build(this, state as StateController<dynamic>);
```

There is no ambient lookup (no static map, no `Expando`, no ancestor search) for a widget to
find its **own** controller — the parameter *is* the lookup, resolved by the element that
owns it. This is why a `const` widget object mounted several times (a banner, a category row
reused down a list) can never leak one instance's data into another's: each element calls
`build()` with its own `state`, and closures created inside `build` (a `builder:`, a tap
callback) capture that parameter, so reads that happen long after `build()` has returned
still refer to the right instance. Before `2.0.0`, `StateWidget.state` was a getter backed by
exactly the kind of registry this design avoids, and it leaked under that scenario — see
`CHANGELOG.md`.

**The one cast this forces:** Flutter's own `StatefulElement.state` getter is typed as plain
`State<StatefulWidget>` (non-generic, by design — Elements aren't parameterized per widget,
which is what keeps the element tree homogeneous). So `StateElement`/`ParentStateElement`
each cast once, at that exact boundary, to `StateController<dynamic>`/`T` respectively. It's
unavoidable while building on `StatefulElement`, and it's made as precise as Dart's type
system allows: `StateController<T extends StateWidget<dynamic>>` and
`StateWidget<T extends StateController<dynamic>>` bound each other, so a `StateController`
can only ever be declared for a `StateWidget` and vice versa — misuse is a compile error, not
a runtime throw the first time a mismatched widget builds. (The `<dynamic>` in those bounds
is not a hole in the pairing: it only says "some `StateWidget`/`StateController`, don't care
which" at the point where Dart, lacking wildcards, needs *a* type argument to satisfy
`strict-raw-types`. Every concrete subclass — `HomeController extends StateController<HomePage>`
— is still checked against the real, specific class.)

### Lifecycle hooks

| Hook | When | Use for |
|---|---|---|
| `initState()` | widget mounted, **context not safe** | plain field setup |
| `readyState()` | post-frame after first build, **context safe** | `ModalRoute.of`, `Theme.of`, navigation, async work |
| `dispose()` | teardown | disposing every `Rx` you created |

`readyState()` is scheduled from `StateElement.performRebuild()` via
`addPostFrameCallback`, guarded by `_justMounted` and a `mounted` re-check, so it fires
exactly once per instance, after the first build.

`StateController.build()` **throws `UnsupportedError` by design** — build belongs to the
widget. There is no legitimate reason to override it; if you need to hook the build phase for
something like `AutomaticKeepAliveClientMixin`, do it in the widget's `build()` instead.

---

## 4. Sharing a controller with a child: `ParentState`

For a widget that needs a *parent's* controller instead of its own:

```dart
class ChildConsumer extends ParentState<HomeController> {
  const ChildConsumer({super.key});

  @override
  Widget build(BuildContext context, HomeController state) =>
      TextButton(onPressed: state.onTap, child: const Text('child'));
}
```

`ParentState` extends `Widget` directly (not `StatelessWidget`) and hands its
`ParentStateElement` a custom `build()` with the extra `state` parameter — `StatelessWidget`
already declares a fixed one-argument `build(BuildContext)`, so a second parameter can't be
added by overriding it. This mirrors how `StatefulWidget`/`StatelessWidget`/
`RenderObjectWidget` are each their own direct subclass of `Widget` with their own `Element`;
`ParentState` is a fourth flavor of that same pattern, not a reinvention of `StatelessWidget`.

`ParentStateElement._findProvider()` walks ancestors with `visitAncestorElements` for the
**nearest** matching `StateElement`, resolves lazily on first build, and caches the result
until `deactivate()` — so a widget reinserted elsewhere resolves again. A missing ancestor
throws a `FlutterError` naming the expected `StateWidget<T>`.

---

## 5. Rx types

`RxInterface<T>` = `ValueNotifier<T>` + `RxMixin<T>`. So an `Rx` **is** a `Listenable`/
`ValueNotifier` and interops with anything in Flutter that takes one.

```dart
final counter = 1.rx;                              // Rx<int>   via extension
final flag    = false.rx;                          // RxBool
final items   = <String>[].rx;                     // RxList<String>
final model   = Rx<Model>(Model(name: 'Nico'));    // explicit
```

`RxMixin` API:

| Member | Behavior |
|---|---|
| `value` setter | **skips notify when `newValue == super.value`** — equality-gated |
| `call([newValue])` | `counter(5)` sets, `counter()` reads; ignores `null` — usable directly as `onTap: rx` |
| `refresh()` | force `notifyListeners()`; needed after mutating a field *inside* an object |
| `update((v) => …)` | functional set |
| `addValueListener` / `removeValueListener` | `ValueChanged<T>` listeners, deduped |
| `bindStream(stream)` / `closeStream(stream)` | pipe a stream into the value; auto-unsubscribes `onDone` |
| `disposed` | true after `dispose()`, to avoid use-after-dispose |
| `lengthOfListeners` | `@visibleForTesting` count |

`dispose()` removes every tracked listener and cancels every subscription before
`super.dispose()`.

- `RxBool` — `toggle()`, logical `& | ^`, and `==` that compares against raw `bool` *or*
  another `RxBool` (with matching `hashCode`).
- `RxList<T>` — `RxInterface<List<T>>` + `ListMixin<T>`, notifying on `add`, `[]=`, `remove`,
  `clear`, `removeWhere`, `addAll`, `length=`, and `assignAll`. It wraps the list you pass in
  and mutates it in place; with no argument it starts with a fresh, growable empty list.

### Rebuilding: `RxWidget<T>`

The only widget that listens. It caches `value`, subscribes in `initState`, resubscribes in
`didUpdateWidget` when the notifier itself changes, `setState`s in `_update`, and
unsubscribes in `dispose`. Keep it as tight around the changing text/subtree as possible —
that is the whole performance story of this package.

---

## 6. Conventions when editing this repo

- **Disposal is manual.** Occam never auto-disposes an `Rx`. Every `Rx` created in a
  controller must be disposed in that controller's `dispose()`. Adding an `Rx` field to an
  example or test without disposing it is a bug, not a style issue — and `test/flutter_test_config.dart`
  now enables `LeakTesting` for every widget test, so a widget test that leaks one will fail.
- **`part of`, not `import`, for anything inside `lib/occam.dart`'s own library.** New files
  under `lib/src/lyfe_cicle/` and `lib/src/rx/{primitives,iterables,extensions,widgets}` get a
  `part` entry in `lib/occam.dart`, using `part of '../../occam.dart';` (relative). The two
  exceptions are `rx_notifier.dart` and `occam_debug.dart`, which are standalone libraries —
  see §2.
- **Don't leak `print`.** `avoid_print` is an error-level lint; the one legitimate print path
  (`state_controller.dart`, gated on `OccamDebug.debug`) carries its own
  `// ignore_for_file: avoid_print` for that reason. Commit `a7c940b remove prints` exists
  because stray prints shipped once — don't reintroduce that class of bug.
- **`public_member_api_docs` is enforced** (as an error, via `--fatal-infos` in CI). Every
  public class/member needs a doc comment, except ones annotated `@override` — they inherit
  the documented contract from their superclass.
- **Touching `state_widget.dart` or `state_parent.dart` is high-risk.** Both encode
  element-lifetime invariants that guard against memory leaks and cross-instance state
  bleed. Add a widget test for any change there — `test/lyfe_cicle/state_widget_test.dart`
  is the instance-isolation regression suite; run it both ways to cover both debug and
  release `const`-canonicalization behavior:
  `flutter test test/lyfe_cicle/state_widget_test.dart --no-track-widget-creation`.
- Tests mirror `lib/` layout 1:1 under `test/`, flattened (no nested subfolders per `Rx` type).
- CI (`.github/workflows/test.yml`, master + PRs) runs, in order: `dart format
  --set-exit-if-changed ./lib ./test`, `flutter analyze --fatal-infos ./lib ./test`,
  `flutter test --coverage` gated at 100% via `test_cov_console`, `dart pub publish
  --dry-run`. A separate `.github/workflows/security.yml` runs OSV-Scanner daily and on every
  push/PR. **Run `dart format` before committing** — formatting failures break the build
  first.
- Public API is `lib/occam.dart` only; consumers write `import 'package:occam/occam.dart';`.
  Any rename of a public symbol is a breaking change — bump the version and update
  `CHANGELOG.md` and `README.md` together.

## 7. Commands

```bash
flutter pub get
flutter test
flutter test --coverage && dart run test_cov_console
dart format ./lib ./test
flutter analyze --fatal-infos ./lib ./test
dart pub publish --dry-run

cd example && flutter run          # routes: / , /secondPage , /bottom

# Benchmarks (informational, not CI-gated — see benchmark/*.dart headers).
# `flutter test`, not `dart run`: occam.dart imports package:flutter.
flutter test benchmark/rx_notifier_benchmark.dart
flutter test benchmark/rx_list_benchmark.dart
flutter test benchmark/widget_benchmark.dart
```

## 8. Known rough edges (fair game to fix, don't be surprised by them)

- `lib/src/lyfe_cicle/` is a misspelling of "lifecycle"; renaming it changes the `part`
  paths in `lib/occam.dart` and every relative `part of` in that directory.
- The `Native<T>.assignAll` extension on plain `List<T>` shadows nothing but can collide
  with other packages' extensions of the same name.
- Dart canonicalizes `const` Widget expressions only when `--track-widget-creation` is off
  (release/profile) or the same const *site* is evaluated more than once; two separate
  `const Probe()` expressions in debug are different objects. This is why
  `state_widget_test.dart` mounts a shared `const` reference (`kProbe`) rather than inline
  `const Probe()` — see that file's `'diagnostic: which const forms end up as the same
  object'` test if this ever needs re-verifying against a new Flutter version.
