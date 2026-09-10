// ignore_for_file: avoid_print

part of '../../occam.dart';

/// A [State] whose `build()` is forbidden — the widget builds instead, via
/// [StateWidget.build]. Pair one with each [StateWidget] via `createState`.
class StateController<T extends StateWidget<dynamic>> extends State<T> {
  @mustCallSuper
  @override
  Widget build(BuildContext context) {
    throw UnsupportedError(
      '$runtimeType.build() is invalid. Use <StateWidget.build()> instead.',
    );
  }

  @override
  @mustCallSuper
  void initState() {
    super.initState();
    if (OccamDebug.debug) print('$this initialized');
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
    if (OccamDebug.debug) print('$this disposed');
    super.dispose();
  }
}
