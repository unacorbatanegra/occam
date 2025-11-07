import 'package:flutter/material.dart';
import 'package:occam/occam.dart';

part 'rx_list_demo_controller.dart';

class RxListDemoPage extends StateWidget<RxListDemoController> {
  const RxListDemoPage({super.key});

  static const routeName = '/rx-list';

  @override
  RxListDemoController createState() => RxListDemoController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RxList in action'),
        actions: [
          IconButton(
            onPressed: state.clearAll,
            tooltip: 'Clear list',
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: state.inputController,
                    decoration: const InputDecoration(
                      labelText: 'Add an item',
                      hintText: 'Try typing something and press enter',
                    ),
                    onSubmitted: (_) => state.addFromInput(),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: state.addFromInput,
                  icon: const Icon(Icons.send),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton.icon(
                  onPressed: state.addSampleItems,
                  icon: const Icon(Icons.playlist_add),
                  label: const Text('Sample data'),
                ),
                OutlinedButton.icon(
                  onPressed: state.shuffleItems,
                  icon: const Icon(Icons.shuffle),
                  label: const Text('Shuffle'),
                ),
                OutlinedButton.icon(
                  onPressed: state.removeLast,
                  icon: const Icon(Icons.undo),
                  label: const Text('Remove last'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: RxWidget<List<String>>(
                notifier: state.items,
                builder: (context, items) {
                  if (items.isEmpty) {
                    return const Center(
                      child: Text('Nothing yet – add a few items to get started.'),
                    );
                  }
                  return ReorderableListView.builder(
                    itemCount: items.length,
                    onReorder: state.reorder,
                    itemBuilder: (context, index) => Dismissible(
                      key: ValueKey(items[index]),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) => state.removeAt(index),
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        color: Theme.of(context).colorScheme.errorContainer,
                        child: Icon(
                          Icons.delete,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                      child: ListTile(
                        title: Text(items[index]),
                        leading: const Icon(Icons.drag_indicator),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

