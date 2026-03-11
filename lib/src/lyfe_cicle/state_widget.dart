part of occam;

abstract class StateWidget<T extends State> extends StatefulWidget {
  const StateWidget({Key? key}) : super(key: key);

  Widget build(BuildContext context);

  T get state {
    final fromStack = StateElement._stateFromBuildStack(this);
    if (fromStack != null) return fromStack as T;
    final fromRegistry = StateElement._stateFromRegistry(this);
    if (fromRegistry != null) return fromRegistry as T;
    throw FlutterError(
      'StateWidget.state was accessed but the controller is not available. '
      'Access state only from within build(BuildContext context), or the '
      'widget may have been unmounted.',
    );
  }

  @override
  StateElement createElement() => StateElement(this);

  @override
  T createState();
}

class StateElement extends StatefulElement {
  static final _elements = Expando('State Controllers');
  static final List<StateElement> _buildStack = [];
  static final Set<StateElement> _mountedStateElements = {};

  bool _justMounted = true;

  StateElement(StateWidget widget) : super(widget);

  @override
  void mount(Element? parent, Object? newSlot) {
    _justMounted = true;
    _mountedStateElements.add(this);
    super.mount(parent, newSlot);
  }

  @override
  void unmount() {
    _mountedStateElements.remove(this);
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

  /// Fallback when stack is empty (e.g. child rebuild). Keys by element, not
  /// widget, so unmount only removes this element and does not affect others.
  static State? _stateFromRegistry(StateWidget widget) {
    for (final element in _mountedStateElements) {
      if (element.mounted && identical(element.widget, widget)) {
        return element.state;
      }
    }
    return null;
  }
}
