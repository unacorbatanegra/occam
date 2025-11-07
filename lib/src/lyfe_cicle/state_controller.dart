// ignore_for_file: avoid_print

part of occam;

/// Base state class used by [StateWidget] implementations.
class StateController<T extends StateWidget> extends State<T> {
  /// Throws to prevent UI building from the controller.
  @mustCallSuper
  @override
  Widget build(BuildContext context) {
    throw UnsupportedError(
      '$runtimeType.build() is invalid. Use <StateWidget.build()> instead.',
    );
  }

  /// Provides initialization hooks for subclasses.
  @override
  @mustCallSuper
  void initState() {
    super.initState();
    if (OccamDebug.debug) print('$this initialized');
  }

  /// Called after the first frame when the widget is mounted.
  ///
  /// Use this hook for logic that needs a fully initialized element tree, such
  /// as interacting with inherited widgets or routing APIs. Subclasses should
  /// override this method instead of [didChangeDependencies].
  @visibleForOverriding
  @protected
  void readyState() {}

  /// Narrows the type of the stateful context for consumers.
  @override
  StatefulElement get context => super.context as StatefulElement;

  @mustCallSuper
  @override
  void dispose() {
    if (OccamDebug.debug) print('$this disposed');

    super.dispose();
  }
}

/// Mixin that allows a [StateController] to intercept the widget build phase.
///
/// Controllers that mix in this type can provide an alternate build entry-point
/// that receives the same [BuildContext] that would otherwise be passed to the
/// `StateWidget.build` implementation.
mixin StateWidgetBuildMixin<T extends StateWidget> on StateController<T> {
  /// Called by the framework when the widget associated with this controller
  /// should build.
  ///
  /// Implementations should return the widget subtree that would normally be
  /// produced by `widget.build(context)`, optionally wrapping or augmenting it.
  @protected
  Widget buildWithStateWidget(BuildContext context);
}
