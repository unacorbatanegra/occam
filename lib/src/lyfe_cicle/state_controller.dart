part of occam;

class StateController<T extends StateWidget> extends State<T> {
  @mustCallSuper
  @alwaysThrows
  @override
  Widget build(BuildContext context) {
    throw "$runtimeType.build() is invalid. Use <StateWidget.build()> instead.";
  }

  /// Use this instead of didChangeDependencies() / initState()
  /// context is "safe"
  @visibleForOverriding
  @protected
  void readyState() {}

  @override
  StatefulElement get context => super.context as StatefulElement;

  NavigatorState get navigator => Navigator.of(context);

  Object? get navigatorArguments => ModalRoute.of(context)?.settings.arguments;

  @mustCallSuper
  @override
  void dispose() {
    print('$this disposed');
    super.dispose();
  }
}
