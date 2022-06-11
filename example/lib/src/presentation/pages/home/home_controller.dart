import 'package:occam/occam.dart';

class HomeController extends StateController {
  String customVar = 'unacorbatanegra';
  final counter = 1.rx;

  final model = Rx<Model>(Model(age: '20', name: 'Nico'));
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

  void onButton() {
    counter.value++;
  }

  void onTap() {
    model.value.name = 'unacorbatanegra';
    model.refresh();
  }

  @override
  void dispose() {
    counter.dispose();
    super.dispose();
  }

  void onTestStateless() {
    print(this);
  }

  void toBottom() {
    navigator.pushNamed('/bottom');
  }
}

class Model {
  String name;
  String age;
  Model({
    required this.name,
    required this.age,
  });

  @override
  String toString() => 'Model(name: $name, age: $age)';
}
