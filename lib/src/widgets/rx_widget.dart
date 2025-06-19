part of occam;

class RxWidget<T> extends StatefulWidget {
  final _RxInterface<T> notifier;
  final Widget Function(BuildContext context, T value) builder;

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
    oldWidget.notifier.removeListener(_update);
    value = widget.notifier.value;
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, value);

  void _update() {
    if (!mounted) return;
    setState(() => value = widget.notifier.value);
  }
}
