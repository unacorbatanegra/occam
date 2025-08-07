import 'package:example/src/presentation/pages/home/home_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:occam/occam.dart';

import 'nested_controller.dart';

class NestedChild extends StateWidget<NestedController> {
  const NestedChild({Key? key}) : super(key: key);

  @override
  NestedController createState() => NestedController();

  @override
  Widget build(BuildContext context) {
    // print('build happen');
    return Column(
      children: [
        CupertinoButton(
          onPressed: state.onTap,
          child: const Center(
            child: Text('nested child'),
          ),
        ),
        const TestStateless(),
      ],
    );
  }
}

class TestStateless extends ParentState<HomeController> {
  const TestStateless({Key? key}) : super(key: key);

  void test() {
    // mounted;
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: state.onTestStateless,
      child: Text('This is a test'),
    );
  }
}
