part of 'rx_list_demo_page.dart';

class RxListDemoController extends StateController<RxListDemoPage> {
  final items = <String>[].rx;
  final inputController = TextEditingController();

  void addFromInput() {
    final text = inputController.text.trim();
    if (text.isEmpty) return;
    items.add(text);
    inputController.clear();
  }

  void addSampleItems() {
    items.assignAll(List.generate(5, (index) => 'Sample item ${index + 1}'));
  }

  void shuffleItems() {
    items.value.shuffle();
    items.refresh();
  }

  void removeLast() {
    if (items.isEmpty) return;
    items.removeLast();
  }

  void removeAt(int index) {
    if (index < 0 || index >= items.length) return;
    items.removeAt(index);
  }

  void reorder(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;
    final list = items.value;
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    items.refresh();
  }

  void clearAll() => items.clear();

  @override
  void dispose() {
    items.dispose();
    inputController.dispose();
    super.dispose();
  }
}
