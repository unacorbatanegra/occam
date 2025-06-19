import 'package:occam/occam.dart';

class HomeController extends StateController {
  String customVar = 'unacorbatanegra';
  final counter = 1.rx;

  @override
  void initState() {
    super.initState();
  }

  @override
  void readyState() async {
    // WidgetsBinding.instance!.addObserver(this);
  }

  void toSecondPage() async {
    final result = await navigator.pushNamed(
      '/secondPage',
      arguments: 'test arguments',
    );
    print(result);
  }

  // @override
  // void didChangeAppLifecycleState(AppLifecycleState state) {

  //   print(state);
  //   super.didChangeAppLifecycleState(state);
  // }

  void onButton() => counter.value++;

  void onTestStateless() {
    print(this);
  }

  void toBottom() {
    navigator.pushNamed('/bottom');
  }
}
