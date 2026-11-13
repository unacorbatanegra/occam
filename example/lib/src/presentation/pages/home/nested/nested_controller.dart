import 'package:occam/occam.dart';

import 'nested_child.dart';

/// Intentionally empty: [NestedChild] only exists to put a second
/// [StateElement] between the page and [TestStateless].
class NestedController extends StateController<NestedChild> {}
