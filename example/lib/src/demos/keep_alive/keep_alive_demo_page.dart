import 'package:flutter/material.dart';
import 'package:occam/occam.dart';

part 'keep_alive_demo_controller.dart';

/// Demonstrates how `KeepAliveStateMixin` keeps tab content alive between
/// navigations while allowing the controller to opt-in or out at runtime.
class KeepAliveDemoPage extends StateWidget<KeepAliveDemoController> {
  const KeepAliveDemoPage({super.key});

  static const routeName = '/keep-alive';

  @override
  KeepAliveDemoController createState() => KeepAliveDemoController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('KeepAliveStateMixin'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Articles', icon: Icon(Icons.article_outlined)),
              Tab(text: 'Settings', icon: Icon(Icons.settings_outlined)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ArticlesTab(controller: state),
            _SettingsTab(controller: state, theme: theme),
          ],
        ),
      ),
    );
  }
}

/// Scrollable list that relies on the controller's keep-alive behavior to
/// preserve its scroll offset.
class _ArticlesTab extends StatelessWidget {
  const _ArticlesTab({required this.controller});

  final KeepAliveDemoController controller;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      key: const PageStorageKey('keepAliveArticles'),
      controller: controller.newsScrollController,
      padding: const EdgeInsets.all(16),
      itemCount: controller.articles.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final article = controller.articles[index];
        return Card(
          elevation: 0,
          child: ListTile(
            leading: CircleAvatar(
              child: Text(
                article.id.toString().padLeft(2, '0'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(article.title),
            subtitle: Text(article.summary),
          ),
        );
      },
    );
  }
}

/// Provides runtime controls to toggle the keep-alive behavior and observe
/// rebuild counts.
class _SettingsTab extends StatelessWidget {
  const _SettingsTab({required this.controller, required this.theme});

  final KeepAliveDemoController controller;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Runtime configuration', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            child: RxWidget<bool>(
              notifier: controller.keepAliveEnabled,
              builder:
                  (context, enabled) => SwitchListTile(
                    title: const Text('Keep the articles tab alive'),
                    subtitle: const Text(
                      'Scroll down the articles tab, switch to this tab, and go back. '
                      'With keep-alive enabled, the scroll offset and list state are preserved.',
                    ),
                    value: enabled,
                    onChanged: controller.toggleKeepAlive,
                  ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            child: RxWidget<int>(
              notifier: controller.articleBuilds,
              builder:
                  (context, builds) => ListTile(
                    leading: const Icon(Icons.auto_graph),
                    title: const Text('Article tab rebuilds'),
                    subtitle: Text(
                      builds == 1
                          ? 'Built once so far.'
                          : 'Built $builds times so far.',
                    ),
                  ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Align(
              alignment: Alignment.topLeft,
              child: Text.rich(
                TextSpan(
                  text: 'Tip: ',
                  style: theme.textTheme.titleMedium,
                  children: const [
                    TextSpan(
                      text:
                          'Try disabling the keep-alive switch and repeating the steps above '
                          'to see the list rebuild from scratch.',
                      style: TextStyle(fontWeight: FontWeight.normal),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
