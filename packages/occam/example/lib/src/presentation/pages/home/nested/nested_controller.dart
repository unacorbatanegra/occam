// import 'package:flutter/material.dart';

import 'package:example/src/presentation/pages/home/home_controller.dart';
import 'package:occam/occam.dart';

class NestedController extends StateController {
  void onTap() {
    print(context.findRootAncestorStateOfType<HomeController>());

    // print(Theme.of(context).textTheme.button);
    // print(find<HomeController>());

    // final result =
    // result.counter.bindStream(stream)
    // result.toSecondPage();
  }
}
