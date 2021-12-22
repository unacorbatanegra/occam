import 'package:example/src/presentation/pages/home/nested/nested_child.dart';
import 'package:example/src/presentation/pages/home/widgets/child_consumer.dart';
import 'package:flutter/material.dart';
import 'package:occam/occam.dart';

import 'home_controller.dart';

class HomePage extends StateWidget<HomeController> {
  const HomePage({Key? key}) : super(key: key);

  @override
  HomeController createState() => HomeController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Occam Demo'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: state.onButton,
        child: const Icon(Icons.add),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          RxWidget<int>(
            notifier: state.counter,
            builder: (ctx, v) => Text('reactive $v'),
          ),
          RxWidget<Model>(
            notifier: state.model,
            builder: (ctx, v) => Text('reactive $v'),
          ),
          // ValueListenableBuilder(valueListenable: valueListenable, builder: builder)
          const ChildConsumer(),
          const NestedChild(),
          Center(
            child: ElevatedButton(
              onPressed: state.toSecondPage,
              child: const Text('To Second page'),
            ),
          ),
        ],
      ),
    );
  }
}
