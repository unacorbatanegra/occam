import 'package:flutter/material.dart';
import 'package:occam/occam.dart';

/// A counter whose controller is (or isn't) kept alive when it scrolls out of
/// a `PageView`. Because [StateController] is a plain `State`, Flutter's own
/// `AutomaticKeepAliveClientMixin` works on it unchanged.
class KeepAliveCounter extends StateWidget<KeepAliveCounterController> {
  const KeepAliveCounter({
    super.key,
    required this.label,
    required this.keepAlive,
  });

  final String label;
  final bool keepAlive;

  @override
  KeepAliveCounterController createState() => KeepAliveCounterController();

  @override
  Widget build(BuildContext context, KeepAliveCounterController state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label),
        RxWidget<int>(
          notifier: state.count,
          builder: (ctx, v) => Text(
            'count $v',
            style: Theme.of(ctx).textTheme.headlineSmall,
          ),
        ),
        FilledButton.tonal(
          onPressed: () => state.count.value++,
          child: Text('+1 ($label)'),
        ),
      ],
    );
  }
}

class KeepAliveCounterController extends StateController<KeepAliveCounter>
    with AutomaticKeepAliveClientMixin<KeepAliveCounter> {
  final count = 0.rx;

  @override
  bool get wantKeepAlive => widget.keepAlive;

  @override
  void dispose() {
    count.dispose();
    super.dispose();
  }
}
