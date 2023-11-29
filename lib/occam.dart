library occam;

import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

part 'src/lyfe_cicle/state_controller.dart';
part 'src/lyfe_cicle/state_parent.dart';
part 'src/lyfe_cicle/state_widget.dart';
part 'src/rx/extensions/extensions.dart';
part 'src/rx/iterables/rx_list.dart';
part 'src/rx/primitives/rx_bool.dart';
part 'src/rx/rx_notifier.dart';
part 'src/utils/extension.dart';
part 'src/widgets/rx_widget.dart';

class OccamDebug {
  static bool debug = false;
}
