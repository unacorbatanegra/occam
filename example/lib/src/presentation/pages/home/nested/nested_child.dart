import 'package:example/src/presentation/pages/home/home_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:occam/occam.dart';

import 'nested_controller.dart';

class NestedChild extends StateWidget<NestedController> {
  const NestedChild({super.key});

  @override
  NestedController createState() => NestedController();

  @override
  Widget build(BuildContext context, NestedController state) {
    return Column(
      children: [
        CupertinoButton(
          onPressed: state.onTap,
          child: const Center(child: Text('nested child')),
        ),
        const TestStateless(),
      ],
    );
  }
}

/// A [ParentState] one level deeper than [ChildConsumer] — demonstrates
/// resolution walking past more than one ancestor to find the controller.
class TestStateless extends ParentState<HomeController> {
  const TestStateless({super.key});

  @override
  Widget build(BuildContext context, HomeController state) {
    return ElevatedButton(
      onPressed: state.onTestStateless,
      child: const Text('This is a test'),
    );
  }
}
