part of occam;

abstract class ParentState<T extends StateController> extends StatelessWidget
    with ParentStateMixin<T> {
  const ParentState({Key? key}) : super(key: key);
}

mixin ParentStateMixin<T extends StateController> on StatelessWidget {
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

class ParentStateElement<T extends StateController> extends StatelessElement {
  ParentStateElement(StatelessWidget widget) : super(widget) {
    StateElement._elements[widget] = this;
  }
  T? _otherState;

  T get otherState {
    final state = _otherState;
    assert(state != null, 'ParentStateElement accessed before it was ready');
    return state!;
  }

  @override
  void mount(Element? parent, Object? newSlot) {
    _otherState = null;
    super.mount(parent, newSlot);
  }

  @override
  Widget build() {
    _resolveOtherState();
    return super.build();
  }

  @override
  void unmount() {
    _otherState = null;
    StateElement._elements[widget] = null;
    super.unmount();
  }

  @override
  void update(StatelessWidget newWidget) {
    StateElement._elements[newWidget] = this;
    _resolveOtherState();
    super.update(newWidget);
  }

  void _resolveOtherState() {
    final resolved = findStateControllerProvider();
    if (identical(resolved, _otherState)) {
      return;
    }
    _otherState = resolved;
  }

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
