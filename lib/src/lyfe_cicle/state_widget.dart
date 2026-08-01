part of '../../occam.dart';

/// A [StatefulWidget] whose logic lives in a [StateController].
///
/// The controller is handed to [build] as a parameter. It is never looked up
/// from ambient state, so an instance can only ever see its own controller —
/// even when the very same widget object is mounted several times, which is
/// what happens with a `const` widget reused across a page:
///
/// ```dart
/// class Categories extends StateWidget<CategoriesController> {
///   const Categories({super.key});
///
///   @override
///   CategoriesController createState() => CategoriesController();
///
///   @override
///   Widget build(BuildContext context, CategoriesController state) {
///     return RxWidget<List<Category>>(
///       notifier: state.items,
///       // `state` here is the parameter, captured by the closure, so it stays
///       // correct even though the builder runs after build() has returned.
///       builder: (ctx, items) => Text('${state.title}: ${items.length}'),
///     );
///   }
/// }
/// ```
abstract class StateWidget<T extends State> extends StatefulWidget {
  const StateWidget({super.key});

  /// Describes this instance's UI.
  ///
  /// [state] is the controller belonging to *this* instance, created once by
  /// [createState] and passed in by the owning element. Closures created here
  /// capture it, so reading it from a `builder:` or a callback stays correct.
  Widget build(BuildContext context, T state);

  @override
  StateElement createElement() => StateElement(this);

  @override
  T createState();
}

class StateElement extends StatefulElement {
  bool _justMounted = true;

  StateElement(StateWidget super.widget);

  @override
  void mount(Element? parent, Object? newSlot) {
    _justMounted = true;
    super.mount(parent, newSlot);
  }

  @override
  void unmount() {
    _justMounted = false;
    super.unmount();
  }

  @override
  void performRebuild() {
    if (_justMounted) {
      _justMounted = false;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) {
          if (!mounted) return;
          (state as StateController).readyState();
        },
      );
    }
    super.performRebuild();
  }

  @override
  StateWidget get widget => super.widget as StateWidget;

  /// Builds through [StateWidget.build], handing it this element's own
  /// controller. This is the only path by which a controller is exposed.
  @override
  Widget build() => widget.build(this, state);
}
