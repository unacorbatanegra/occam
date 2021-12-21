import 'package:occam/occam.dart';

import 'second_page.dart';

class SecondController extends StateController<SecondPage> {
  final notifier = ''.rx;
  @override
  void readyState() {
    print(navigatorArguments);
    notifier.value = navigatorArguments as String;

    Future.delayed(
        const Duration(seconds: 2), () => notifier.value = 'late changed');
  }

  void back() {
    navigator.pop('test result argument');
  }

  void test() {}

  @override
  void dispose() {
    // TODO: implement dispose
    notifier.dispose();
    super.dispose();
  }
}
