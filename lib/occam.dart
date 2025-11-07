library occam;

import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

part 'src/lyfe_cicle/state_controller.dart';
part 'src/lyfe_cicle/mixins/keep_alive_state_mixin.dart';
part 'src/lyfe_cicle/state_parent.dart';
part 'src/lyfe_cicle/state_widget.dart';
part 'src/rx/core/rx_core.dart';
part 'src/rx/core/rx_mixin.dart';
part 'src/rx/extensions/extensions.dart';
part 'src/rx/iterables/rx_list.dart';
part 'src/rx/primitives/rx_bool.dart';

part 'src/widgets/rx_widget.dart';

class OccamDebug {
  static bool debug = false;
}
