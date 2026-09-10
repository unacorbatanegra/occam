import 'package:example/src/presentation/pages/home/home_controller.dart';
import 'package:occam/occam.dart';

import 'nested_child.dart';

class NestedController extends StateController<NestedChild> {
  /// Reaches an ancestor controller directly through the element tree,
  /// instead of via [ParentState]. `context` is narrowed to `StatefulElement`
  /// by [StateController], so element APIs like this are available.
  void onTap() {
    context.findRootAncestorStateOfType<HomeController>()?.onButton();
  }
}
