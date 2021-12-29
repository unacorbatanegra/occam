import 'package:flutter/material.dart';
import 'package:occam/occam.dart';

import 'bottom_controller.dart';

class BottomPage extends StateWidget<BottomController> {
  const BottomPage({Key? key}) : super(key: key);

  @override
  BottomController createState() => BottomController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RxWidget<int>(
        notifier: state.currentIndex,
        builder: (ctx, value) => PageStorage(
          bucket: state.bucket,
          child: state.list[value],
        ),
      ),
      bottomNavigationBar: RxWidget<int>(
        notifier: state.currentIndex,
        builder: (ctx, value) => BottomNavigationBar(
          currentIndex: value,
          onTap: state.currentIndex,
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Home')
          ],
        ),
      ),
    );
  }
}
