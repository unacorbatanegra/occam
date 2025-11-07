part of 'keep_alive_demo_page.dart';

/// Controller backing the keep-alive demo, exposing toggles and counters while
/// delegating keep-alive wiring through [KeepAliveStateMixin].
class KeepAliveDemoController extends StateController<KeepAliveDemoPage>
    with KeepAliveStateMixin {
  @override
  void initState() {
    super.initState();
    articles = List.generate(
      30,
      (index) => _Article(
        id: index + 1,
        title: 'In-depth lesson ${index + 1}',
        summary:
            'Explore how keep-alive widgets behave inside scrolling containers and tab views.',
      ),
    );
  }

  late final List<_Article> articles;

  final keepAliveEnabled = true.rx;
  final articleBuilds = 0.rx;

  final ScrollController newsScrollController = ScrollController();

  @override
  bool get keepAlive => keepAliveEnabled.value;

  @override
  Widget buildWithStateWidget(BuildContext context) {
    articleBuilds.value++;
    return super.buildWithStateWidget(context);
  }

  void toggleKeepAlive(bool value) {
    if (keepAliveEnabled.value == value) return;
    keepAliveEnabled(value);
    updateKeepAlive();
  }

  @override
  void dispose() {
    newsScrollController.dispose();
    keepAliveEnabled.dispose();
    articleBuilds.dispose();
    super.dispose();
  }
}

class _Article {
  const _Article({
    required this.id,
    required this.title,
    required this.summary,
  });

  final int id;
  final String title;
  final String summary;
}
