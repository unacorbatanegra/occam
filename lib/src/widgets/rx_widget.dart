part of occam;

/// A lightweight bridge between Occam's reactive values and Flutter widgets.
///
/// `RxWidget` listens to the supplied [_RxInterface] (for example, an `Rx<int>`
/// or `RxList<String>`) and rebuilds its [builder] whenever the underlying value
/// changes. This keeps UI updates explicit—when the controller mutates the
/// reactive value or calls `refresh()`, the widget rebuilds with the latest
/// data.
///
/// ```dart
/// class CounterLabel extends StatelessWidget {
///   const CounterLabel({super.key, required this.counter});
///
///   final Rx<int> counter;
///
///   @override
///   Widget build(BuildContext context) {
///     return RxWidget<int>(
///       notifier: counter,
///       builder: (context, value) => Text('Count: $value'),
///     );
///   }
/// }
/// ```
/// Prefer `RxWidget` for small pieces of UI that depend on a single reactive
/// value. For larger widgets or multiple values, compose several `RxWidget`s or
/// expose the controller directly in your `StateWidget`.
class RxWidget<T> extends StatefulWidget {
  /// The reactive value to observe for rebuilds.
  final _RxInterface<T> notifier;

  /// Builds a widget every time [notifier] updates.
  final Widget Function(BuildContext context, T value) builder;

  /// Creates an [RxWidget] that listens to [notifier] and hands the latest value
  /// to [builder].
  const RxWidget({
    Key? key,
    required this.notifier,
    required this.builder,
  }) : super(key: key);

  @override
  _RxWidgetState createState() => _RxWidgetState<T>();
}

class _RxWidgetState<T> extends State<RxWidget<T>> {
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
    } else if (oldWidget.notifier.value != widget.notifier.value) {
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
    if (!mounted) return;
    setState(() => value = widget.notifier.value);
  }
}
