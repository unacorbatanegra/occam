# AGENTS.md — occam

Minimalist Flutter state management built **on top of** Flutter's own `StatefulWidget`/`State`
instead of replacing it. No `InheritedWidget`, no service locator, no code generation.

Package: `occam` (v1.0.1) · Dart SDK `>=3.0.0 <4.0.0` · deps: `flutter`, `meta` only.

---

## 1. The core idea

One screen = **one view + one controller**, always paired:

| Role | Flutter class it really is | Your subclass |
|---|---|---|
| View — widgets only, no logic | `StatefulWidget` | `class HomePage extends StateWidget<HomeController>` |
| Controller — logic only, no widgets | `State` | `class HomeController extends StateController` |

The trick: normally `build()` lives in the `State`. Occam moves it to the **widget**, so the
view file has the widget tree and the controller file has none. The controller is reachable
from the view via `state`.

```dart
class HomePage extends StateWidget<HomeController> {
  const HomePage({super.key});

  @override
  HomeController createState() => HomeController();   // the pairing

  @override
  Widget build(BuildContext context) => Scaffold(     // build() is HERE, on the widget
        floatingActionButton: FloatingActionButton(
          onPressed: state.onButton,                  // `state` == the controller
          child: const Icon(Icons.add),
        ),
        body: RxWidget<int>(
          notifier: state.counter,
          builder: (ctx, v) => Text('$v'),
        ),
      );
}

class HomeController extends StateController {
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
the tree in `RxWidget`. There is no automatic `Obx`-style dependency tracking — the README
states this was intentional, because implicit tracking made correct disposal of listeners
impossible.

---

## 2. File map

Everything is one Dart library assembled with `part of` from `lib/occam.dart` — so all
private members (`_`) are visible across files. Adding a new file means adding a `part`
directive to `lib/occam.dart`.

```
lib/occam.dart                       library root, `part` list, OccamDebug.debug flag
lib/src/lyfe_cicle/                  ("lifecycle" — note the typo, it is the real path)
  state_widget.dart                  StateWidget + StateElement  ← the heart of the package
  state_controller.dart              StateController (a State with build() forbidden)
  state_parent.dart                  ParentState / ParentStateMixin / ParentStateElement
lib/src/rx/
  rx_notifier.dart                   RxMixin, RxInterface, Rx<T>
  primitives/rx_bool.dart            RxBool
  iterables/rx_list.dart             RxList<T>
  extensions/extensions.dart         `.rx` getters on T, bool, List<T>
lib/src/widgets/rx_widget.dart       RxWidget<T> — the only rebuild primitive
lib/src/utils/extension.dart         navigator / navArgs on StateController
example/                             runnable app exercising every feature
test/                                widget + unit tests, mirrors lib/ layout
```

---

## 3. How `state` actually resolves (the subtle part)

`StateWidget.state` must return the paired `State` object, but a `StatefulWidget` has no
pointer to its `State`. `StateElement` (a custom `StatefulElement`) bridges the gap with a
**two-tier lookup** — read `lib/src/lyfe_cicle/state_widget.dart:28` onward:

1. **Build stack** — `_buildStackByWidget`: a `Map<StateWidget, List<StateElement>>`.
   `StateElement.build()` pushes itself before calling `widget.build(this)` and pops in a
   `finally`. The list (not a single value) is what lets the *same* widget instance be
   nested/rebuilt reentrantly. This is the fast, correct path while a view is building.
2. **Mounted registry** — `_mountedStateElements`: a `Set<StateElement>` maintained in
   `mount`/`unmount`. Fallback for when `state` is touched outside the widget's own
   `build()` (e.g. a child rebuilding independently). Matched with `identical(element.widget, widget)`.

If both miss, `state` throws a `FlutterError` telling you to access it from within `build()`.

**Why keyed by element, not widget:** the registry deliberately keys on the *element* so that
unmounting one instance never invalidates another instance of the same widget class. This
was the fix for the memory-leak / wrong-state class of bug (branch `1.0.1-memory-fix`,
commit `1ec9a53 fix: memory leaks`). Preserve that invariant when touching this file.

`StateElement._elements` is a separate `Expando` used by the `ParentState` machinery.

### Lifecycle hooks

| Hook | When | Use for |
|---|---|---|
| `initState()` | widget mounted, **context not safe** | plain field setup |
| `readyState()` | post-frame after first build, **context safe** | `ModalRoute.of`, `Theme.of`, navigation, async work |
| `dispose()` | teardown | disposing every `Rx` you created |

`readyState()` is scheduled from `StateElement.performRebuild()` via
`addPostFrameCallback`, guarded by `_justMounted` and a `mounted` re-check. It replaces both
`didChangeDependencies()` and context-dependent `initState()` work.

`StateController.build()` **throws by design** — build belongs to the widget. The one legal
reason to override it is mixing in something that requires it, e.g.
`AutomaticKeepAliveClientMixin`, in which case you call `super.build(context)` then return
`widget.build(context)` (see `example/lib/.../bottom/page_1.dart`).

---

## 4. Sharing a controller with a child: `ParentState`

For a stateless child widget that needs a parent controller:

```dart
class ChildConsumer extends ParentState<HomeController> {
  const ChildConsumer({super.key});

  @override
  Widget build(BuildContext context) =>
      TextButton(onPressed: state.onTap, child: const Text('child'));
}
```

`ParentStateElement.build()` resolves the ancestor once on first build via
`findRootAncestorStateOfType<T>()` and caches it in `_otherState`. A generic assert catches
`ParentState<StateController>` used without a concrete subtype.

Note the two overlapping lookups here: `build()` uses `findRootAncestorStateOfType` (**root**
ancestor), while `findStateControllerProvider()` walks with `visitAncestorElements` for the
**nearest** match and throws a descriptive error. They are not interchangeable — for nested
same-type controllers `build()` currently binds to the outermost one.

A controller can also reach upward directly: `context.findRootAncestorStateOfType<HomeController>()`
— `StateController.context` is narrowed to `StatefulElement`, so element APIs are available.

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
| `addValueListener` / `removeValueListener` | `ValueChanged<T>` listeners, deduped in `_valueListeners` |
| `bindStream(stream)` / `closeStream(stream)` | pipe a stream into the value; auto-unsubscribes `onDone` |
| `disposed` | true after `dispose()`, to avoid use-after-dispose |
| `lengthOfListeners` | `@visibleForTesting` count |

`dispose()` removes every tracked listener and cancels every subscription before
`super.dispose()`.

The mixin keeps its own `_listeners` list *in addition* to `ValueNotifier`'s internal list.
`addListener`/`removeListener` must stay symmetric with that list — the `1.0.1` changelog
entry "remove double calling in mixin on listeners" was a bug in exactly this bookkeeping.

- `RxBool` — `toggle()`, logical `& | ^`, and `==` that compares against raw `bool` *or*
  another `RxBool` (with matching `hashCode`).
- `RxList<T>` — `RxInterface<List<T>>` + `ListMixin<T>`, so it behaves like a `List` while
  notifying on `add`, `[]=`, `remove`, `clear`, `removeWhere`, `addAll`, `length=`, and
  `assignAll`. Caveat: it wraps the list you pass in, mutates it in place, and defaults to
  `const []` — pass a growable list.

### Rebuilding: `RxWidget<T>`

The only widget that listens. It caches `value`, subscribes in `initState`, resubscribes in
`didUpdateWidget` when the notifier or its value changed, `setState`s in `_update`, and
unsubscribes in `dispose`. Keep it as tight around the changing text/subtree as possible —
that is the whole performance story of this package.

---

## 6. Conventions when editing this repo

- **Disposal is manual.** Occam never auto-disposes an `Rx`. Every `Rx` created in a
  controller must be disposed in that controller's `dispose()`. Adding an `Rx` field to an
  example or test without disposing it is a bug, not a style issue.
- **`part of`, not `import`.** New source files go under `lib/src/...` and get a `part`
  entry in `lib/occam.dart`. Prefer `part of '../../occam.dart';` (relative, as in
  `rx_widget.dart`) — the bare `part of occam;` form in the older files is deprecated style.
- **Don't leak `print`.** Debug output is gated on `OccamDebug.debug` (default `false`);
  `state_controller.dart` carries `// ignore_for_file: avoid_print` for that reason.
  Commit `a7c940b remove prints` exists because stray prints shipped once.
- **Touching `state_widget.dart` or `state_parent.dart` is high-risk.** Both encode
  element-lifetime invariants that guard against memory leaks and cross-instance state
  bleed. Add a widget test for any change there.
- Tests mirror `lib/` layout under `test/`. Note `test/rx/primitive/rx_bool.dart` lacks the
  `_test` suffix, so `flutter test` does not pick it up — fix the name if you touch it.
- CI (`.github/workflows/test.yml`, master only, Flutter 3.10.5) runs, in order:
  `dart format --set-exit-if-changed ./lib ./test`, `flutter analyze ./lib ./test`,
  `flutter test`. **Run `dart format` before committing** — formatting failures break the
  build first. Lints: `package:flutter_lints`.
- Public API is `lib/occam.dart` only; consumers write `import 'package:occam/occam.dart';`.
  Any rename of a public symbol is a breaking change — bump the version and update
  `CHANGELOG.md` and `README.md` together.

## 7. Commands

```bash
flutter pub get
flutter test
flutter test --coverage
dart format ./lib ./test
flutter analyze ./lib ./test

cd example && flutter run          # routes: / , /secondPage , /bottom
```

## 8. Known rough edges (fair game to fix, don't be surprised by them)

- `lib/src/lyfe_cicle/` is a misspelling of "lifecycle"; renaming it changes the `part`
  paths in `lib/occam.dart`.
- `_RxWidgetState` is a private type returned from a public `createState()` — analyzer
  grumbles, harmless.
- `ParentStateElement.findStateControllerProvider()` is defined but currently unused;
  `build()` uses `findRootAncestorStateOfType` instead (see §4 — different semantics).
- `RxList` defaults to `const []`, which throws on mutation if constructed with no argument
  and then written to.
- The `Native<T>.assignAll` extension on plain `List<T>` shadows nothing but can collide
  with other packages' extensions.
- The README's usage snippet has an extra trailing `}` and predates `super.key`.
