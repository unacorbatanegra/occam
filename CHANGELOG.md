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

## 1.0.1

- Test added
- `Fix` remove double calling in mixin on listeners.

## 1.0.0

Added Flutter 3.7.4 compatibility
