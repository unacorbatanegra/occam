part of occam;

/// Base widget that binds to a [StateController] in the Occam pattern.
///
/// Subclasses override [build] to describe the UI and [createState] to supply
/// the controller. Obtain the controller instance through the [state] getter
/// once the widget is mounted.
abstract class StateWidget<T extends State> extends StatefulWidget {
  /// Creates a widget wired to a [StateController].
  const StateWidget({Key? key}) : super(key: key);

  /// Builds this widget using the provided [context].
  ///
  /// Inside this method call [state] to interact with the backing controller.
  Widget build(BuildContext context);

  /// Returns the controller associated with this widget.
  ///
  /// Accessing [state] before the widget is mounted triggers an assertion (and
  /// throws a [StateError] in debug mode).
  T get state => StateElement._stateOf(this);

  @override
  StateElement createElement() => StateElement(this);

  @override
  T createState();
}

/// Element used to keep track of a [StateWidget] and its controller.
class StateElement extends StatefulElement {
  /// Cache of element instances keyed by their [StateWidget].
  static final _elements = Expando<Element>('State Elements');

  bool _isFirstBuild = true;
  State<StatefulWidget>? _cachedState;

  StateElement(StateWidget widget) : super(widget) {
    _cachedState = state;
    _elements[widget] = this;
  }

  /// Resets the rebuild tracker before inserting the element in the tree.
  @override
  void mount(Element? parent, Object? newSlot) {
    _isFirstBuild = true;
    super.mount(parent, newSlot);
  }

  /// Clears cached references when the element leaves the tree.
  @override
  void unmount() {
    _isFirstBuild = false;
    _elements[widget] = null;
    _cachedState = null;
    super.unmount();
  }

  /// Updates the cached state and reuses the element for the new widget.
  @override
  void update(StatefulWidget newWidget) {
    _cachedState = state;
    assert(newWidget is StateWidget,
        'StateElement can only be updated with another StateWidget');
    _elements[newWidget as StateWidget] = this;
    super.update(newWidget);
  }

  /// Triggers [StateController.readyState] after the first build frame.
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

  /// Strongly typed handle to the widget this element manages.
  @override
  StateWidget get widget => super.widget as StateWidget;

  /// Invokes the widget's [StateWidget.build] implementation.
  @override
  Widget build() => widget.build(this);

  /// Returns the state object for the requested [widget].
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
