import 'package:flutter/material.dart';
import 'package:occam/occam.dart';

import 'bottom_page.dart';
import 'page_1.dart';

class BottomController extends StateController<BottomPage> {
   final PageStorageBucket bucket = PageStorageBucket();
  final list = [Page1(key: PageStorageKey('Key1'),), Page2(key: PageStorageKey('Key2'),)];

  final currentIndex = 0.rx;


  
}
