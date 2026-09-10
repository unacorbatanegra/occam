import 'package:example/src/presentation/pages/home/home_page.dart';
import 'package:flutter/material.dart';
import 'package:occam/occam.dart';

class HomeController extends StateController<HomePage> {
  final counter = 1.rx;
  final model = Rx<Model>(Model(age: '20', name: 'Nico'));

  Future<void> toSecondPage() {
    return Navigator.of(context).pushNamed(
      '/secondPage',
      arguments: 'test arguments',
    );
  }

  void toBottom() {
    Navigator.of(context).pushNamed('/bottom');
  }

  void onButton() => counter.value++;

  void onTap() {
    model.value.name = 'unacorbatanegra';
    model.refresh();
  }

  /// Called by [TestStateless], a [ParentState] reading this controller.
  void onTestStateless() => counter.value++;

  @override
  void dispose() {
    counter.dispose();
    model.dispose();
    super.dispose();
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
