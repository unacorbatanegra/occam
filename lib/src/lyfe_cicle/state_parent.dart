part of occam;

abstract class ParentState<T extends StateController> extends StatelessWidget
    with ParentStateMixin<T> {
  const ParentState({Key? key}) : super(key: key);
}

mixin ParentStateMixin<T extends StateController> on StatelessWidget {
  T get state =>
      (StateElement._elements[this] as ParentStateElement)._otherState as T;
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
  late T _otherState;

  ParentStateElement(StatelessWidget widget) : super(widget) {
    StateElement._elements[widget] = this;
  }

  bool _justMounted = true;

  @override
  void mount(Element? parent, Object? newSlot) {
    _justMounted = true;
    super.mount(parent, newSlot);
  }

  @override
  Widget build() {
    if (_justMounted) {
      _otherState = findRootAncestorStateOfType<T>()!;
      _justMounted = false;
    }
    return super.build();
  }

  @override
  void unmount() {
    _justMounted = false;
    // _otherState.removeDependant(this);
    super.unmount();
  }

  @override
  void update(StatelessWidget newWidget) {
    StateElement._elements[newWidget] = this;
    super.update(newWidget);
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
