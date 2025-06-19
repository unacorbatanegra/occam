import 'package:occam/occam.dart';

class HomeController extends StateController {
  String customVar = 'unacorbatanegra';
  final counter = 1.rx;
  final isSwitched = false.rx;
  final items = <String>[].rx;

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

  void onButton() => counter.value++;

  void onTap() {
    model.value.name = 'unacorbatanegra';
    model.refresh();
  }

  String get combinedMessage => isSwitched.value && counter.value % 2 == 0
      ? 'Switch is ON and counter is even!'
      : '';

  void toggleSwitch() => isSwitched.toggle();

  void addItem() {
    items.add('Item [${items.length + 1}]');
  }

  void removeItem() {
    if (items.isNotEmpty) items.removeLast();
  }

  @override
  void dispose() {
    counter.dispose();
    isSwitched.dispose();
    items.dispose();
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
  String toString() => name;
}
