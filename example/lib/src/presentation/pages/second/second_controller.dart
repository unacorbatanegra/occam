import 'package:occam/occam.dart';

class SecondController extends StateController {
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
    notifier.dispose();
    super.dispose();
  }
}
