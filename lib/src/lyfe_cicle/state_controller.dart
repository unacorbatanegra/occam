// ignore_for_file: avoid_print

part of occam;

class StateController<T extends StateWidget> extends State<T> {
// class StateController extends State {
  @mustCallSuper
  @alwaysThrows
  @override
  Widget build(BuildContext context) {
    throw "$runtimeType.build() is invalid. Use <StateWidget.build()> instead.";
  }

  @override
  @mustCallSuper
  void initState() {
    super.initState();
    print('$this initializated');
  }

  /// Use this instead of didChangeDependencies() / initState()
  /// context is "safe"
  @visibleForOverriding
  @protected
  void readyState() {}

  @override
  StatefulElement get context => super.context as StatefulElement;

  @mustCallSuper
  @override
  void dispose() {
    print('$this disposed');
    super.dispose();
  }
}
