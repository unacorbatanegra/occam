// ignore_for_file: avoid_print

part of occam;

class StateController<T extends StateWidget> extends State<T> {
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
