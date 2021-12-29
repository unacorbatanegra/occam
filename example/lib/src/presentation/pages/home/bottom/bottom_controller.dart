import 'package:flutter/material.dart';
import 'package:occam/occam.dart';

import 'bottom_page.dart';
import 'page_1.dart';

class BottomController extends StateController<BottomPage> {
  final list = [Page1(), Page2()];

  final currentIndex = 0.rx;


  
}
