// ignore_for_file: avoid_print

part of occam;

class StateController<T extends StateWidget> extends State<T> {
  @mustCallSuper
  @override
  Widget build(BuildContext context) {
    throw "$runtimeType.build() is invalid. Use <StateWidget.build()> instead.";
  }

  @override
  @mustCallSuper
  void initState() {
    super.initState();
    if (OccamDebug.debug) print('$this initializated');
  }

  /// Use this instead of didChangeDependencies()
  /// initState()
  /// context is "safe"
  @visibleForOverriding
  @protected
  void readyState() {}

  @override
  StatefulElement get context => super.context as StatefulElement;

  @mustCallSuper
  @override
  void dispose() {
    if (OccamDebug.debug) print('$this disposed');
    for (final callBack in _onDispose ?? <Function?>[]) {
      callBack?.call();
    }
    super.dispose();
  }

  List<Function?>? _onDispose;

  void onDispose(Function callback) {
    _onDispose ??= [];
    _onDispose?.add(callback);
  }
}
