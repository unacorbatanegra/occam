import 'package:occam/occam.dart';

import 'second_page.dart';

class SecondController extends StateController<SecondPage> {
  final notifier = ''.rx;
  final list = <String>[].rx;
  final counter = 1.rx;

  void onButton() => counter.value++;

  void addToList() => list.add(DateTime.now().toIso8601String());

  @override
  void dispose() {
    counter.dispose();
    notifier.dispose();
    list.dispose();
    super.dispose();
  }
}
