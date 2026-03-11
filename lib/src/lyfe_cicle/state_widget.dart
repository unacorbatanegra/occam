part of occam;

abstract class StateWidget<T extends State> extends StatefulWidget {
  const StateWidget({Key? key}) : super(key: key);

  Widget build(BuildContext context);

  T get state {
    final fromStack = StateElement._stateFromBuildStack(this);
    print("fromStack: ${fromStack.hashCode}");
    if (fromStack != null) return fromStack as T;
    final fromRegistry = StateElement._stateFromRegistry(this);
    print("fromRegistry: ${fromRegistry.hashCode}");
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

  /// Stack of currently building elements per widget (supports nested same-widget).
  static final Map<StateWidget, List<StateElement>> _buildStackByWidget = {};
  static final Set<StateElement> _mountedStateElements = {};

  bool _justMounted = true;

  StateElement(StateWidget widget) : super(widget);

  @override
  void mount(Element? parent, Object? newSlot) {
    _justMounted = true;
    _mountedStateElements.add(this);
    print("mount: $hashCode");
    print("mount _mountedStateElements length: ${_mountedStateElements.length}");
    super.mount(parent, newSlot);
  }

  @override
  void unmount() {
    _mountedStateElements.remove(this);
    _justMounted = false;
    print("unmount: $hashCode");
    print("unmount _mountedStateElements length: ${_mountedStateElements.length}");
    print("unmount _buildStackByWidget length: ${_buildStackByWidget.length}");
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
    final w = widget;
    (_buildStackByWidget[w] ??= []).add(this);
    try {
      return widget.build(this);
    } finally {
      final list = _buildStackByWidget[w]!;
      list.removeLast();
      if (list.isEmpty) _buildStackByWidget.remove(w);
    }
  }

  static State? _stateFromBuildStack(StateWidget widget) {
    final list = _buildStackByWidget[widget];
    if (list == null || list.isEmpty) return null;
    return list.last.state;
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
