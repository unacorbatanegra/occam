import 'package:flutter/material.dart';
import 'package:occam/occam.dart';

import 'bottom_page.dart';
import 'page_1.dart';

class BottomController extends StateController<BottomPage> {
  final bucket = PageStorageBucket();
  final list = const [
    Page1(key: PageStorageKey('page1')),
    Page2(key: PageStorageKey('page2')),
  ];

  final currentIndex = 0.rx;

  @override
  void dispose() {
    currentIndex.dispose();
    super.dispose();
  }
}
