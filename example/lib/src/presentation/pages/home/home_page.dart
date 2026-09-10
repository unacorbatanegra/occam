import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:occam/occam.dart';

import '../../widgets/demo_section.dart';
import 'home_controller.dart';
import 'nested/nested_child.dart';
import 'widgets/child_consumer.dart';

class HomePage extends StateWidget<HomeController> {
  const HomePage({super.key});

  @override
  HomeController createState() => HomeController();

  @override
  Widget build(BuildContext context, HomeController state) {
    return Scaffold(
      appBar: AppBar(title: const Text('Occam Demo')),
      floatingActionButton: FloatingActionButton(
        onPressed: state.onButton,
        tooltip: 'Increment the counter below',
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          DemoSection(
            title: 'Rx<int> — reactive counter',
            children: [
              RxWidget<int>(
                notifier: state.counter,
                builder: (ctx, v) => Text(
                  'reactive $v',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ],
          ),
          DemoSection(
            title: 'Rx<Model> — reactive object',
            children: [
              RxWidget<Model>(
                notifier: state.model,
                builder: (ctx, v) => Text(
                  'reactive $v',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: 8),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: state.onTap,
                child: const Text('Change reactive'),
              ),
            ],
          ),
          DemoSection(
            title: 'ParentState — reading an ancestor controller',
            children: [
              // A child widget reading THIS page's controller.
              const ChildConsumer(),
              const SizedBox(height: 8),
              // A StateWidget nested one level below, itself containing a
              // ParentState (TestStateless) — resolution walks past it.
              const NestedChild(),
            ],
          ),
          DemoSection(
            title: 'Navigation',
            children: [
              FilledButton.tonal(
                onPressed: state.toSecondPage,
                child: const Text('To Second page'),
              ),
              const SizedBox(height: 8),
              FilledButton.tonal(
                onPressed: state.toBottom,
                child: const Text('To Bottom'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
