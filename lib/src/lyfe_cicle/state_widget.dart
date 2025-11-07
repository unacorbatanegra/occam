part of occam;

abstract class StateWidget<T extends State> extends StatefulWidget {
  const StateWidget({Key? key}) : super(key: key);

  Widget build(BuildContext context);

  T get state => StateElement._stateOf(this);

  @override
  StateElement createElement() => StateElement(this);

  @override
  T createState();
}

class StateElement extends StatefulElement {
  static final _elements = Expando<Element>('State Elements');

  bool _isFirstBuild = true;
  State<StatefulWidget>? _cachedState;

  StateElement(StateWidget widget) : super(widget) {
    _cachedState = state;
    _elements[widget] = this;
  }

  @override
  void mount(Element? parent, Object? newSlot) {
    _isFirstBuild = true;
    super.mount(parent, newSlot);
  }

  @override
  void unmount() {
    _isFirstBuild = false;
    _elements[widget] = null;
    _cachedState = null;
    super.unmount();
  }

  @override
  void update(StatefulWidget newWidget) {
    _cachedState = state;
    assert(newWidget is StateWidget,
        'StateElement can only be updated with another StateWidget');
    _elements[newWidget as StateWidget] = this;
    super.update(newWidget);
  }

  @override
  void performRebuild() {
    if (_isFirstBuild) {
      _isFirstBuild = false;
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

  @override
  Widget build() => widget.build(this);

  static T _stateOf<T extends State>(StateWidget<T> widget) {
    final element = _elements[widget];
    assert(element != null && element is StateElement,
        'State accessed before widget mounted');
    if (element == null || element is! StateElement) {
      throw StateError('State accessed before widget mounted');
    }
    final cached = element._cachedState;
    if (cached == null) {
      final currentState = element.state;
      element._cachedState = currentState;
      return currentState as T;
    }
    return cached as T;
  }
}
