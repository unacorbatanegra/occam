part of '../../../occam.dart';

/// The only widget that listens: rebuilds [builder] whenever [notifier]
/// changes. Keep it as tight around the changing subtree as possible — that
/// is the whole performance story of this package.
class RxWidget<T> extends StatefulWidget {
  /// The reactive value to listen to.
  final RxInterface<T> notifier;

  /// Builds the subtree for the current value of [notifier].
  final Widget Function(BuildContext context, T value) builder;

  /// Listens to [notifier] and rebuilds via [builder] on every change.
  const RxWidget({
    super.key,
    required this.notifier,
    required this.builder,
  });

  @override
  RxWidgetState<T> createState() => RxWidgetState<T>();
}

/// State backing [RxWidget]. Subscribes in [initState], resubscribes in
/// [didUpdateWidget] when the notifier changes, and unsubscribes in
/// [dispose].
class RxWidgetState<T> extends State<RxWidget<T>> {
  /// The last value read from [RxWidget.notifier].
  late T value;

  @override
  void initState() {
    super.initState();
    value = widget.notifier.value;
    widget.notifier.addListener(_update);
  }

  @override
  void didUpdateWidget(RxWidget<T> oldWidget) {
    if (oldWidget.notifier != widget.notifier) {
      oldWidget.notifier.removeListener(_update);
      widget.notifier.addListener(_update);
      value = widget.notifier.value;
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, value);

  @override
  void dispose() {
    widget.notifier.removeListener(_update);
    super.dispose();
  }

  void _update() {
    // coverage:ignore-start
    // Guards a ChangeNotifier reentrancy edge case (a listener unmounting
    // this widget while notifyListeners() is still iterating its snapshot of
    // listeners), not reachable through this class's own dispose ordering.
    if (!mounted) return;
    // coverage:ignore-end
    setState(() => value = widget.notifier.value);
  }
}
