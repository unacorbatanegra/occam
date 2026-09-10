# Occam

A simple state manager built on native Flutter `StatefulWidget`, made for my own projects.

## Contents

- [Philosophy](#philosophy)
- [Installation](#installation)
- [Quick start](#quick-start)
- [State manager](#state-manager)
- [Sharing a controller: `ParentState`](#sharing-a-controller-parentstate)
- [Rx types](#rx-types)

## Philosophy

There are plenty of state managers, and picking one is hard — each has features you like and
others you don't. As a package grows, it tends to accumulate code for things a given project
never uses: a dependency full of pieces reinventing the wheel for needs you don't have. This
exists because I kept ending up back at one belief: **the best abstraction is the one you can
hold entirely in your head, six months later, without re-reading its source.** Not the one
with the most features — the smallest one that's still enough. That's the name: Occam's
razor, don't multiply entities beyond necessity.

Every design decision in this package answers to that one question — does this make the
mental model bigger, or does it stay the same size? In practice that means:

- **Exactly one way to do each thing.** One way to hold logic (`StateController`), one way to
  render it (`StateWidget`), one way to share it with descendants (`ParentState`), one way to
  react to a value changing (`RxWidget`). Never two competing patterns for the same job —
  every "which do I use here?" is a bit of mental model that didn't need to exist.
- **A boundary you cannot blur.** View and controller are separate *classes*, not just separate
  responsibilities you're trusting yourself to respect. There's no widget-building path with
  access to your logic's internals, and no controller method that receives a `BuildContext`
  it isn't explicitly handed — the split is enforced by the type system, not by convention.
- **Nothing is implicit.** Reactivity only exists where you write `RxWidget`; disposal is
  always the caller's, never automatic; a controller is always looked up by explicit type,
  never by ambient/global state. If you can't point at the line responsible for a behavior,
  something is wrong with the library, not with your understanding of it.

Every other section below is that same idea applied to one concrete piece of the API — if
something here feels like it's doing more than it needs to, that's a bug in the library, not
a feature you're missing.

> This started as a package for my own use, so the API can still change between versions —
> check `CHANGELOG.md` before upgrading.

## Installation

```yaml
dependencies:
  occam: ^2.0.1
```

## Quick start

```dart
class HomePage extends StateWidget<HomeController> {
  const HomePage({super.key});

  @override
  HomeController createState() => HomeController();

  @override
  Widget build(BuildContext context, HomeController state) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: state.onButton,
        child: const Icon(Icons.add),
      ),
      body: RxWidget<int>(
        notifier: state.counter,
        builder: (ctx, value) => Text('$value'),
      ),
    );
  }
}

class HomeController extends StateController<HomePage> {
  final counter = 1.rx;

  void onButton() => counter.value++;

  @override
  void dispose() {
    counter.dispose(); // you own disposal of every Rx you create
    super.dispose();
  }
}
```

One view (`StateWidget`), one controller (`StateController`), one reactive value
(`.rx`) wrapped in the one widget that rebuilds (`RxWidget`). That's the whole package —
the rest of this README is those same four pieces in more detail.

## State manager

`StateWidget<T>` is a `StatefulWidget` paired with a `StateController<T>`. The controller for
*this instance* is passed into `build` as a parameter — never looked up from ambient state —
so a widget mounted several times (a `const` banner reused across a page) can never read
another instance's data.

| Hook | When | Use for |
|---|---|---|
| `initState()` | widget mounted, context **not** safe | plain field setup |
| `readyState()` | post-frame after first build, context **safe** | `ModalRoute.of`, `Theme.of`, navigation |
| `dispose()` | teardown | disposing every `Rx` you created |

```dart
class HomeController extends StateController<HomePage> {
  final counter = 1.rx;

  void onButton() => counter.value++;

  @override
  void readyState() {
    // Runs after the first frame, so context is safe here — unlike
    // initState(). Use it for ModalRoute.of, Theme.of, etc.
  }

  @override
  void dispose() {
    counter.dispose();
    super.dispose();
  }
}
```

## Sharing a controller: `ParentState`

A child that needs an *ancestor's* controller instead of its own extends `ParentState<T>`
— the nearest matching `StateWidget<T>` above it in the tree provides it:

```dart
class ChildConsumer extends ParentState<HomeController> {
  const ChildConsumer({super.key});

  @override
  Widget build(BuildContext context, HomeController state) =>
      TextButton(onPressed: state.onButton, child: const Text('increment'));
}
```

## Rx types

`RxInterface<T>` is a `ValueNotifier<T>` with extra listener/stream bookkeeping, so it
interops with anything in Flutter that takes a `Listenable`/`ValueNotifier`.

```dart
final counter = 1.rx;               // Rx<int>          via extension
final flag    = false.rx;           // RxBool
final items   = <String>[].rx;      // RxList<String>
final model   = Rx<Model>(Model()); // explicit
```

| Member | Behavior |
|---|---|
| `value` setter | skips notifying when the new value equals the current one |
| `call([newValue])` | `counter(5)` sets, `counter()` reads — usable directly as a callback |
| `refresh()` | forces a notify; needed after mutating a field *inside* the held object |
| `update((v) => …)` | functional set |
| `addValueListener` / `removeValueListener` | typed `ValueChanged<T>` listeners |
| `bindStream(stream)` / `closeStream(stream)` | pipes a stream into the value |
| `disposed` | `true` after `dispose()` |

`RxBool` adds logical operators (`&`, `|`, `^`, `toggle()`); `RxList<T>` behaves like a
`List<T>` and notifies on any mutation.

`RxWidget<T>` is the only widget that listens — keep it as tight around the changing subtree
as possible:

```dart
RxWidget<int>(
  notifier: state.counter,
  builder: (ctx, value) => Text('$value'),
)
```

Every `Rx` value must be disposed by whoever created it — occam never disposes one for you.

---

See `AGENTS.md` for the full architecture and the conventions to follow when contributing,
and `CHANGELOG.md` for version history.

Thanks to: [@roipeker](https://github.com/roipeker).
