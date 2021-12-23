part of occam;

abstract class StateWidget<T extends State> extends StatefulWidget {
  const StateWidget({Key? key}) : super(key: key);

  Widget build(BuildContext context);

  T get state => StateElement._elements[this] as T;

  @override
  StateElement createElement() => StateElement(this);

  @override
  StateController createState();
}

class StateElement extends StatefulElement {
  static final _elements = Expando('State Controllers');

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
    _justMounted = false;
    super.unmount();
  }

  @override
  void update(StatefulWidget newWidget) {
    _elements[newWidget] = state;
    super.update(newWidget);
  }

  @override
  void rebuild() {
    if (_justMounted) {
      _justMounted = false;
      WidgetsBinding.instance?.addPostFrameCallback(
        (_) => (state as StateController).readyState(),
      );
    }
    super.rebuild();
  }

  @override
  StateWidget get widget => super.widget as StateWidget;

  @override
  Widget build() => widget.build(this);
}
