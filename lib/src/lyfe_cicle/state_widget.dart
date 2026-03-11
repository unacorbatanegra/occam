part of occam;

abstract class StateWidget<T extends State> extends StatefulWidget {
  const StateWidget({Key? key}) : super(key: key);

  Widget build(BuildContext context);

  T get state {
    final fromStack = StateElement._stateFromBuildStack(this);
    if (fromStack != null) return fromStack as T;
    final value = StateElement._elements[this];
    if (value == null) {
      throw FlutterError(
        'StateWidget.state was accessed but the controller is not available. '
        'Access state only from within build(BuildContext context), or the '
        'widget may have been unmounted.',
      );
    }
    return value as T;
  }

  @override
  StateElement createElement() => StateElement(this);

  @override
  T createState();
}

class StateElement extends StatefulElement {
  static final _elements = Expando('State Controllers');
  static final List<StateElement> _buildStack = [];

  bool _justMounted = true;

  StateElement(StateWidget widget) : super(widget) {
    _elements[widget] = state;
  }

  @override
  void mount(Element? parent, Object? newSlot) {
    _justMounted = true;
    super.mount(parent, newSlot);
  }

  @override
  void unmount() {
    _elements[widget] = null;
    _justMounted = false;
    super.unmount();
  }

  @override
  void update(StatefulWidget newWidget) {
    final oldWidget = widget;
    _elements[newWidget] = state;
    super.update(newWidget);
    _elements[oldWidget] = null;
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

  @override
  Widget build() {
    _buildStack.add(this);
    try {
      return widget.build(this);
    } finally {
      _buildStack.removeLast();
    }
  }

  static State? _stateFromBuildStack(StateWidget widget) {
    for (var i = _buildStack.length - 1; i >= 0; i--) {
      final element = _buildStack[i];
      if (identical(element.widget, widget)) {
        return element.state;
      }
    }
    return null;
  }
}
