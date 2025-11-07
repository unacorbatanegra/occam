part of occam;

/// Convenience widget to read a `StateController` higher up the tree.
///
/// `ParentState` widgets do not create their own `StateController`; instead,
/// they read the nearest ancestor `StateWidget` of the desired controller type
/// and expose it via the `state` getter. This is handy for composing helper
/// widgets that still need to call controller methods.
///
/// ```dart
/// class CounterActions extends ParentState<CounterController> {
///   const CounterActions({super.key});
///
///   @override
///   Widget build(BuildContext context) {
///     return IconButton(
///       icon: const Icon(Icons.add),
///       onPressed: state.increment,
///     );
///   }
/// }
/// ```
/// Stateless widget that reads a controller from the ancestor tree.
abstract class ParentState<T extends StateController> extends StatelessWidget
    with ParentStateMixin<T> {
  const ParentState({Key? key}) : super(key: key);
}

/// Mixin that exposes a [StateController] through the [state] getter.
mixin ParentStateMixin<T extends StateController> on StatelessWidget {
  /// Provides the nearest ancestor `StateController<T>`.
  T get state =>
      (StateElement._elements[this] as ParentStateElement<T>).otherState;
  @override
  ParentStateElement createElement() {
    assert(const Object() is! T, """
          You have to provide a subclass of StateController:
          $runtimeType extends ParentStateWidget<StateController>
       """);
    return ParentStateElement<T>(this);
  }
}

/// Element that maintains a link to the nearest matching [StateController].
class ParentStateElement<T extends StateController> extends StatelessElement {
  /// Creates the element and registers it in the shared lookup table.
  ParentStateElement(StatelessWidget widget) : super(widget) {
    StateElement._elements[widget] = this;
  }
  T? _otherState;

  /// Returns the resolved controller or throws if accessed too early.
  T get otherState {
    final state = _otherState;
    assert(state != null, 'ParentStateElement accessed before it was ready');
    return state!;
  }

  /// Clears the cached controller when inserting into the tree.
  @override
  void mount(Element? parent, Object? newSlot) {
    _otherState = null;
    super.mount(parent, newSlot);
  }

  /// Recomputes the controller before building descendants.
  @override
  Widget build() {
    _resolveOtherState();
    return super.build();
  }

  /// Removes the registration and cached controller on teardown.
  @override
  void unmount() {
    _otherState = null;
    StateElement._elements[widget] = null;
    super.unmount();
  }

  /// Keeps the cached controller fresh when the widget updates.
  @override
  void update(StatelessWidget newWidget) {
    StateElement._elements[newWidget] = this;
    _resolveOtherState();
    super.update(newWidget);
  }

  /// Resolves (or re-resolves) the controller from the ancestor tree.
  void _resolveOtherState() {
    final resolved = findStateControllerProvider();
    if (identical(resolved, _otherState)) {
      return;
    }
    _otherState = resolved;
  }

  /// Traverses ancestors to find the nearest matching [StateController].
  T findStateControllerProvider() {
    T? _state;
    visitAncestorElements((element) {
      if (element is StateElement && element.state is T) {
        _state = element.state as T;
        return false;
      }
      return true;
    });
    if (_state == null) {
      throw '[ParentStateWidget] can\'t find a parent StateController <$T> dependency in the Widget tree. Make sure you have a StateWidget<$T> somewhere up the tree';
    }
    return _state!;
  }
}
