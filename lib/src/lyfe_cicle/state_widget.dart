part of '../../../occam.dart';

abstract class StateWidget<T extends State> extends StatefulWidget {
  const StateWidget({super.key});

  Widget build(BuildContext context);

  T get state {
    final value = StateElement._elements[this];
    if (value == null) {
      throw FlutterError(
        'StateWidget.state was accessed but the controller is not available. '
        'This can happen during widget tree updates. '
        'If this persists, please report it at https://github.com/unacorbatanegra/occam/issues.',
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
  StateElement(StateWidget widget) : super(widget) {
    _elements[widget] = state;
  }
  static final _elements = Expando('state-controllers');

  bool _justMounted = true;

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
    if (!identical(oldWidget, newWidget)) {
      _elements[oldWidget] = null;
    }
  }

  @override
  void performRebuild() {
    if (_justMounted) {
      _justMounted = false;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) {
          if (!mounted) return;
          final s = state;
          if (s is StateController) {
            s.readyState();
          }
        },
      );
    }
    super.performRebuild();
  }

  @override
  StateWidget get widget => super.widget as StateWidget;

  @override
  Widget build() => widget.build(this);
}
