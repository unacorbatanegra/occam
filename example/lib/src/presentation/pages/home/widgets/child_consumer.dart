import 'package:example/src/presentation/pages/home/home_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:occam/occam.dart';

class ChildConsumer extends ParentState<HomeController> {
  const ChildConsumer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      onPressed: state.onTap,
      child: const Center(
        child: Text('child consumer'),
      ),
    );
  }
}
