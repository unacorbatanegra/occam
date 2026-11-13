# example

Runnable demo for [occam](../README.md). Start with `lib/main.dart`: it is the
whole package in one file (`CounterPage` + `CounterController`), plus an index of
the other pages.

```bash
flutter run
```

| Route | Page | Shows |
|---|---|---|
| `/counter` | `CounterPage` (in `main.dart`) | `StateWidget`, `StateController`, `.rx`, `RxWidget` |
| `/` | `HomePage` | `Rx<int>`, `Rx<Model>` + `refresh()`, `ParentState` (also nested), navigation |
| `/playground` | `PlaygroundPage` | `readyState()`, `RxBool`, `call`/`update`, `addValueListener`, `bindStream`/`closeStream`, `RxList` mutations, `disposed`, `AutomaticKeepAliveClientMixin` |
| `/secondPage` | `SecondPage` | an `RxList<String>` rendered as a list |
| `/bottom` | `BottomPage` | one `StateWidget` per tab with `PageStorage` |

Tests: `flutter test` (one widget test per demo).
