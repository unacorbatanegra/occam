import 'package:flutter/material.dart';
import 'package:occam/occam.dart';

import '../../widgets/demo_section.dart';
import 'second_controller.dart';

class SecondPage extends StateWidget<SecondController> {
  const SecondPage({super.key});

  @override
  SecondController createState() => SecondController();

  @override
  Widget build(BuildContext context, SecondController state) {
    return Scaffold(
      appBar: AppBar(title: const Text('Second Page')),
      floatingActionButton: FloatingActionButton(
        onPressed: state.onButton,
        tooltip: 'Increment the counter below',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: DemoSection(
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
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: DemoSection(
                title: 'RxList<String> — reactive list',
                children: [
                  RxWidget<String>(
                    notifier: state.notifier,
                    builder: (ctx, value) => Text(value),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: state.addToList,
                    child: const Text('Add to list'),
                  ),
                  const Divider(height: 24),
                  Expanded(
                    child: RxWidget<List<String>>(
                      notifier: state.list,
                      builder: (ctx, value) => value.isEmpty
                          ? const Center(child: Text('No items yet'))
                          : ListView.separated(
                              itemBuilder: (ctx, idx) =>
                                  ListTile(title: Text(value[idx])),
                              separatorBuilder: (ctx, idx) => const Divider(),
                              itemCount: value.length,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
