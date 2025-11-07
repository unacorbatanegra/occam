import 'package:flutter/material.dart';
import 'package:occam/occam.dart';

import '../demo_registry.dart';

part 'catalog_controller.dart';

class CatalogPage extends StateWidget<CatalogController> {
  const CatalogPage({super.key});

  @override
  CatalogController createState() => CatalogController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Occam Example Catalog')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: RxWidget<String>(
              notifier: state.lastOpened,
              builder: (context, value) {
                if (value.isEmpty) {
                  return const Text(
                    'Select a demo to explore how Occam keeps UI and logic simple.',
                  );
                }
                return Text(
                  'Last opened: $value',
                  style: Theme.of(context).textTheme.titleMedium,
                );
              },
            ),
          ),
          const Divider(height: 0),
          Expanded(
            child: ListView.separated(
              itemCount: state.demos.length,
              separatorBuilder:
                  (context, index) =>
                      const Divider(height: 0, indent: 16, endIndent: 16),
              itemBuilder: (context, index) {
                final demo = state.demos[index];
                return DemoTile(entry: demo);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class DemoTile extends ParentState<CatalogController> {
  const DemoTile({required this.entry, super.key});

  final DemoEntry entry;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(entry.title),
      subtitle: Text(entry.description),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => state.openDemo(entry),
    );
  }
}
