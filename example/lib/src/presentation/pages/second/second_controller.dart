import 'package:occam/occam.dart';

class SecondController extends StateController {
  final notifier = ''.rx;
  final list = <String>[].rx;
  final counter = 1.rx;
  @override
  void readyState() {
    print(navArgs);
    notifier.value = navArgs as String;

    // Future.delayed(
    //     const Duration(seconds: 2), () => notifier.value = 'late changed');
  }

  void back() {
    list.add(DateTime.now().toIso8601String());
    // navigator.pop('test result argument');
  }

  void onButton() => counter.value++;

  void test() {}

  @override
  void dispose() {
    counter.dispose();
    notifier.dispose();
    super.dispose();
  }
}
